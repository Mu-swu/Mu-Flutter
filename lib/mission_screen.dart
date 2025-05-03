import 'dart:async';
import 'package:flutter/material.dart';

class MissionScreen extends StatefulWidget {
  final int totalMinutes; // 테스트용 기본값은 30분

  const MissionScreen({Key? key, this.totalMinutes = 30}) : super(key: key);

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  late Duration remainingTime;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    remainingTime = Duration(minutes: widget.totalMinutes);
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        if (remainingTime.inSeconds > 0) {
          remainingTime -= Duration(seconds: 1);
        } else {
          timer?.cancel();
        }
      });
    });
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('미션 진행 중'),
        centerTitle: true,
      ),
      body: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatDuration(remainingTime),
            style: TextStyle(
              fontSize: 100, // 큰 폰트, 화면 크기에 따라 자동 조절됨
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}