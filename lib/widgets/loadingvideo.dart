import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LoadingVideo extends StatefulWidget {
  // Add a final variable to store the video asset path.
  final String videoPath;

  // Make the videoPath a required parameter in the constructor.
  const LoadingVideo({Key? key, required this.videoPath}) : super(key: key);

  @override
  State<LoadingVideo> createState() => _LoadingVideoState();
}

class _LoadingVideoState extends State<LoadingVideo> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Use the dynamic videoPath from the widget instance.
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..setLooping(true)
      ..initialize().then((_) {
        setState(() {}); // 초기화 완료 후 빌드
        _controller.play(); // 자동 재생
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
      return const SizedBox.shrink();
    }
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}