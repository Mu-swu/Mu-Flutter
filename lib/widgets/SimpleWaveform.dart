import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
class SimpleWaveform extends StatefulWidget {
  const SimpleWaveform({super.key, required this.level});

  // 0.0 ~ 1.0 사이 음성 레벨 전달
  final double level;

  @override
  State<SimpleWaveform> createState() => _SimpleWaveformState();
}

class _SimpleWaveformState extends State<SimpleWaveform> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0;
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WaveformPainter(level: widget.level, time: _time),
      child: SizedBox.expand(),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double level; // 0~1 음성 세기
  final double time; // 애니메이션 시간

  WaveformPainter({required this.level, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final barCount = 20;
    final spacing = 6.0;
    final barWidth = (size.width - (spacing * (barCount - 1))) / barCount;
    final centerY = size.height / 2;

    // 막대별 중앙에서 거리 구하기 (중앙=barCount/2)
    final centerIndex = (barCount - 1) / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing);

      // 중앙에서 거리 (0~중앙)
      final distanceFromCenter = (i - centerIndex).abs();

      // 거리 기반 가중치 (중앙에 가까울수록 1, 양끝은 낮음)
      // 예: 선형 감쇠
      final positionalWeight = 1.0 - (distanceFromCenter / centerIndex);

      // sine 변동폭 (기존보다 약간 빠르게)
      final sineFactor = sin(i + time * 5);

      // dynamicFactor: sine + 위치 가중치 조합
      final dynamicFactor = positionalWeight * (0.3 + 0.7 * (sineFactor * 0.7 + 0.7));

      // 높이 계산 (실시간 레벨 반영, 5배 확대)
      final barHeight = level * size.height * dynamicFactor * 5;

      canvas.drawLine(
        Offset(x + barWidth / 2, centerY - barHeight / 2),
        Offset(x + barWidth / 2, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.time != time;
  }
}