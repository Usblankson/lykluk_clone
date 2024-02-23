import 'package:flutter/material.dart';
import 'package:lykluk_clone/features/feed/presentation/pages/feed_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async{
      await load();
    });
    super.initState();
  }

  Future<void> load() async {
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const FeedView()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromRGBO(242, 247, 255, 1),
      body: Center(
        child: Text(
          'LykLuk Clone App',
          style: TextStyle(
              color: Colors.deepPurple,
              fontSize: 32,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
