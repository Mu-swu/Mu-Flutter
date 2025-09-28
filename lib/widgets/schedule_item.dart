import 'package:flutter/material.dart';
import 'dart:math' as math;

class ScheduleItem extends StatelessWidget {
  final String title;
  final String time;
  final bool isCompleted;

  const ScheduleItem({
    super.key,
    required this.title,
    required this.time,
    this.isCompleted = false,
  });

  double _parseTimeToMinutes(String timeString) {
    if (timeString.contains('시간')) {
      final parts = timeString.split('시간');
      final hours = double.tryParse(parts[0].trim());
      return (hours ?? 0) * 60;
    }
    final minutes = double.tryParse(timeString.trim().replaceAll('분', ''));
    return minutes ?? 0;
  }

  double _calculateProgress() {
    final minutes = _parseTimeToMinutes(time);
    const maxTimeInMinutes = 60.0;
    return (minutes / maxTimeInMinutes).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final Color itemBackgroundColor = isCompleted ? const Color(0xFFF5F5F5) : Colors.transparent;
    final Color dividerColor = const Color(0xFFEEEEEE);

    final Color activeGreenFill = const Color(0xFFC6E9C6);
    final Color activeGreenBorder = const Color(0xFF6AC992);
    final Color completedGray = const Color(0xFF8D93A1);

    final Color progressFillColor = isCompleted ? completedGray : activeGreenFill;
    final Color borderAndHandColor = isCompleted ? completedGray : activeGreenBorder;

    final Color titleColor = isCompleted ? const Color(0xFF8D93A1) : Colors.black87;
    final Color timeColor = isCompleted ? const Color(0xFF8D93A1) : Colors.black54;

    final double progress = _calculateProgress();
    final double strokeWidth = 5.0;

    return Container(
      color: itemBackgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 16,
                          color: timeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 38,
                  height: 38,
                  child: CustomPaint(
                    painter: _ClockPainter(
                      progress: progress,
                      progressFillColor: progressFillColor,
                      borderAndHandColor: borderAndHandColor,
                      isCompleted: isCompleted,
                      strokeWidth: strokeWidth,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isCompleted)
            const Divider(
              height: 1,
              color: Color(0xFFEEEEEE),
              indent: 0,
              endIndent: 0,
            ),
        ],
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final double progress;
  final Color progressFillColor;
  final Color borderAndHandColor;
  final bool isCompleted;
  final double strokeWidth;

  _ClockPainter({
    required this.progress,
    required this.progressFillColor,
    required this.borderAndHandColor,
    required this.isCompleted,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2;
    final innerRadius = outerRadius - strokeWidth;

    // 원 테두리
    final borderPaint = Paint()
      ..color = borderAndHandColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, outerRadius - strokeWidth / 2, borderPaint);

    // 완료된 항목은 진행도 채움을 그리지 않음
    if (!isCompleted) {
      // 진행도 채움 (pie-slice)
      final progressFillPaint = Paint()
        ..color = progressFillColor
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        -math.pi / 2,
        2 * math.pi * progress,
        true,
        progressFillPaint,
      );
    }

    // 시계 바늘
    final handPaint = Paint()
      ..color = borderAndHandColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final handLength = (outerRadius - strokeWidth) * 0.5;

    canvas.drawLine(
      center,
      Offset(center.dx, center.dy - handLength),
      handPaint,
    );

    // 원형 중심의 작은 원
    final centerDotPaint = Paint()
      ..color = borderAndHandColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressFillColor != progressFillColor ||
        oldDelegate.borderAndHandColor != borderAndHandColor ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}