import 'package:cached_video_player/cached_video_player.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoFeedView extends StatefulWidget {
  const VideoFeedView({
    Key? key,
    required this.videoUrl,
  }) : super(key: key);

  final String videoUrl;

  @override
  State<VideoFeedView> createState() => _VideoFeedViewState();
}

class _VideoFeedViewState extends State<VideoFeedView> {
  CachedVideoPlayerController? _mVideoController;

  @override
  initState() {
    if (_mVideoController == null && widget.videoUrl.isNotEmpty) {
      _mVideoController = CachedVideoPlayerController.network(
        widget.videoUrl,
      );

      _mVideoController!.setLooping(true);
      _mVideoController!.addListener(() {
        setState(() {});
      });
      _mVideoController!.initialize().then(
            (_) => setState(
              () {},
            ),
          );
    }
    super.initState();
  }

  @override
  void dispose() {
    if (_mVideoController != null) {
      _mVideoController!.dispose();
      _mVideoController = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.9) {
          _mVideoController!.play();
        }
      },
      key: Key(widget.key.toString()),
      child: GestureDetector(
        onTap: () {
          if (_mVideoController!.value.isPlaying) {
            _mVideoController!.pause();
          } else {
            _mVideoController!.play();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.black,
              child: _mVideoController != null &&
                      _mVideoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _mVideoController!.value.aspectRatio,
                      child: CachedVideoPlayer(
                        _mVideoController!,
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            Center(
              child: Icon(
                Icons.play_arrow_rounded,
                size: 120,
                color: _mVideoController!.value.isPlaying
                    ? Colors.transparent
                    : Colors.white.withOpacity(.5),
              ),
            )
          ],
        ),
      ),
    );
  }
}
