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
    const maxTimeInMinutes = 30.0;
    return (minutes / maxTimeInMinutes).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final Color itemBackgroundColor =
        isCompleted ? const Color(0xFFFAFBFF) : Color(0xFFF3F5FF);

    final Color activeGreenFill = const Color(0xFF6AC992);
    final Color activeGreenBorder = const Color(0xFF30AE65);
    final Color activeGreenHand = const Color(0xFF0F6131);
    final Color completedGray = const Color(0xFFDBDEE7);

    final Color clockFaceColor =
       const Color(0xFFF5F5F5);

    final Color progressFillColor =
        isCompleted ? Color(0xFFF5F5F5) : activeGreenFill;
    final Color borderColor =
        isCompleted ? Color(0xFFDBDEE7) : activeGreenBorder;
    final Color handColor = isCompleted ? completedGray : activeGreenHand;

    final Color titleColor =
        isCompleted ? const Color(0xFFB0B8C1) : Color(0xFF5D5D5D);
    final Color timeColor =
        isCompleted ? const Color(0xFFB0B8C1) : Color(0xFF8D93A1);

    final double progress = _calculateProgress();
    final double strokeWidth = 3.0;

    return Container(
      color: itemBackgroundColor,
      child: Column(
        children: [
          SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 17),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'PretendardMedium',
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: TextStyle(fontSize: 14, color: timeColor),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 27,
                  height: 27,
                  child: CustomPaint(
                    painter: _ClockPainter(
                      progress: progress,
                      clockFaceColor: clockFaceColor,
                      progressFillColor: progressFillColor,
                      borderColor: borderColor,
                      handColor: handColor,
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
              color: Color(0xFFF5F5F5),
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
  final Color clockFaceColor;
  final Color progressFillColor;
  final Color borderColor;
  final Color handColor;
  final bool isCompleted;
  final double strokeWidth;

  _ClockPainter({
    required this.progress,
    required this.clockFaceColor,
    required this.progressFillColor,
    required this.borderColor,
    required this.handColor,
    required this.isCompleted,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 10);
    final outerRadius = math.min(size.width, size.height) / 2;
    final innerRadius = outerRadius - strokeWidth;

    final facePaint = Paint()
      ..color = clockFaceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, facePaint);

    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, outerRadius - strokeWidth / 2, borderPaint);

    if (!isCompleted) {
      final progressFillPaint =
          Paint()
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
    final handPaint =
        Paint()
          ..color = handColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    final handLength = (outerRadius - strokeWidth) * 0.6;

    canvas.drawLine(
      center,
      Offset(center.dx, center.dy - handLength),
      handPaint,
    );

    // 원형 중심의 작은 원
    final centerDotPaint =
        Paint()
          ..color = handColor
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.clockFaceColor != clockFaceColor ||
        oldDelegate.progressFillColor != progressFillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
