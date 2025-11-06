import 'package:flutter/material.dart';

class LongButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final double? fontSize;

  const LongButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Container(
        width: double.infinity,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFF463EC6) : const Color(0xFFDBDEE7),
          borderRadius: BorderRadius.circular(8),
          boxShadow:
              isEnabled
                  ? [
                    BoxShadow(
                      color: const Color(0xFF463EC6).withOpacity(0.15),
                      blurRadius: 10,
                      offset: Offset(2, 2),
                      spreadRadius: 4,
                    ),
                  ]
                  : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'PretendardMedium',
            fontSize: fontSize ?? 18,
            color: isEnabled ? Colors.white : Color(0xFFB0B8C1),
          ),
        ),
      ),
    );
  }
}
