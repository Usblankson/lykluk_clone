import 'dart:developer';

import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:image_picker/image_picker.dart';
import 'package:lykluk_clone/features/feed/presentation/pages/video_feed_view.dart';
import 'package:tiktoklikescroller/tiktoklikescroller.dart';
import 'package:video_compress/video_compress.dart';

class FeedView extends StatefulWidget {
  const FeedView({Key? key}) : super(key: key);

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  List<String> _mVideoUrlList = [];
  late Controller _mSwipeController;

  @override
  initState() {
    initStateAsync();

    _mSwipeController = Controller()
      ..addListener((event) {
        _handleCallbackEvent(event.direction, event.success, event.pageNo);
      });

    // controller.jumpToPosition(4);
    super.initState();
  }

  void initStateAsync() async {
    final videoBucket = FirebaseStorage.instanceFor(
      bucket: dotenv.get('BUCKET'),
    );

    final videoBucketRef = videoBucket.ref();
    ListResult listResult = await videoBucketRef.listAll();
    List<String> videoUrlList = [];
    for (var item in listResult.items) {
      String videoUrl = await item.getDownloadURL();
      videoUrlList.add(videoUrl);
    }
    setState(() {
      _mVideoUrlList = videoUrlList;
      log(_mVideoUrlList.toString(), name: "Video URLs");
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleCallbackEvent(ScrollDirection direction, ScrollSuccess success,
      int? currentPageIndex) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'LykLuk Clone App',
          style:
              TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: _mVideoUrlList.isNotEmpty
          ? TikTokStyleFullPageScroller(
              contentSize: _mVideoUrlList.length,
              swipePositionThreshold: 0.2,
              // ^ the fraction of the screen needed to scroll
              swipeVelocityThreshold: 2000,
              // ^ the velocity threshold for smaller scrolls
              animationDuration: const Duration(milliseconds: 400),
              // ^ how long the animation will take
              controller: _mSwipeController,
              // ^ registering our own function to listen to page changes
              builder: (BuildContext context, int index) {
                return VideoFeedView(
                  key: Key(index.toString()),
                  videoUrl: _mVideoUrlList[index],
                );
              },
            )
          : Container(
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ImagePicker picker = ImagePicker();
          final XFile? video = await picker.pickVideo(
            source: ImageSource.camera,
            maxDuration: const Duration(
              seconds: 60,
            ),
          );

          if (video != null) {
            final videoBucket = FirebaseStorage.instanceFor(
                bucket: "gs://tiktokclone1234.appspot.com");

            int timestamp = DateTime.now().millisecondsSinceEpoch;

            String videoFilename = "$timestamp.mp4";

            final videoBucketRef = videoBucket.ref();
            final videoFileRef = videoBucketRef.child("/$videoFilename");

            Uint8List finalVideoData;
            UploadTask? uploadTask;
            MediaInfo mediaInfo = await VideoCompress.getMediaInfo(video.path);
            if (mediaInfo.duration != null) {
              int durationSec = (mediaInfo.duration! / 1000).ceil();

              MediaInfo? finalMediaInfo = await VideoCompress.compressVideo(
                video.path,
                startTime: 0,
                // duration is actually endtime
                duration: durationSec > 60 ? durationSec - 60 : 0,
                quality: VideoQuality.LowQuality,
              );
              if (finalMediaInfo != null && finalMediaInfo.file != null) {
                finalVideoData = await finalMediaInfo.file!.readAsBytes();

                uploadTask = videoFileRef.putData(
                  finalVideoData,
                  SettableMetadata(
                    contentType: "video/mp4",
                  ),
                );

                uploadTask.snapshotEvents.listen((taskSnapshot) async {
                  switch (taskSnapshot.state) {
                    case TaskState.running:
                      final value = (taskSnapshot.bytesTransferred /
                          taskSnapshot.totalBytes);
                      final percentage = (value * 100).ceil().toString();
                      log(percentage);

                      break;
                    case TaskState.paused:
                      log('Upload Paused');

                      return;
                    case TaskState.success:
                      log('Upload Success');
                      break;
                    case TaskState.canceled:
                      log('Upload Cancelled');

                      return;
                    case TaskState.error:
                      log('Upload Error');

                      return;
                  }
                });
              }
            }
          }
        },
        tooltip: 'Add Video',
        child: const Icon(Icons.add),
      ),
    );
  }
}
