import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LoadingVideo extends StatefulWidget {
  const LoadingVideo({Key? key}) : super(key: key);

  @override
  State<LoadingVideo> createState() => _LoadingVideoState();
}

class _LoadingVideoState extends State<LoadingVideo> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/loadingvideo.mp4')
      ..setLooping(true)
      ..initialize().then((_) {
        setState(() {});        // 초기화 완료 후 빌드
        _controller.play();     // 자동 재생
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      // 비디오 초기화 전에는 빈 박스나 스피너를 잠깐 보여줄 수 있음
      return const SizedBox.shrink();
    }
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}