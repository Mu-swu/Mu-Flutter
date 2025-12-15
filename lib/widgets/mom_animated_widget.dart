import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../user_theme_manager.dart';

class MomAnimatedWidget extends StatefulWidget {
  final UserType userType;

  const MomAnimatedWidget({super.key, required this.userType});

  @override
  State<MomAnimatedWidget> createState() => _MomAnimatedWidgetState();
}

class _MomAnimatedWidgetState extends State<MomAnimatedWidget> {
  int _currentIndex = 0;
  Timer? _timer;
  List<String> _frames = [];

  @override
  void initState() {
    super.initState();
    _initFrames();

    _timer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _frames.length;
      });
    });
  }

  void _initFrames() {
    String basePath = 'assets/home/';
    String typePrefix = '';

    switch (widget.userType) {
      case UserType.gam:
        typePrefix = 'gam';
        break;
      case UserType.mol:
        typePrefix = 'mol';
        break;
      case UserType.bang:
      default:
        typePrefix = 'bang';
    }

    _frames = [
      '${basePath}mom_${typePrefix}.png',
      '${basePath}mom2_${typePrefix}.png',
      '${basePath}mom3_${typePrefix}.png',
      '${basePath}mom4_${typePrefix}.png',
      '${basePath}mom5_${typePrefix}.png',
    ];
  }

  @override
  void didUpdateWidget(MomAnimatedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userType != widget.userType) {
      _initFrames();
      _currentIndex = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_frames.isEmpty) return SizedBox();

    return Container(
      width: 600,
      height: 300,
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Image.asset(
          _frames[_currentIndex],
          key: ValueKey<String>(_frames[_currentIndex]),
          fit: BoxFit.contain,
          width: 600,
          height: 300,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
