import 'package:flutter/material.dart';

class ShortButton extends StatelessWidget {
  final String text;
  final bool isYes;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final double? fontSize;

  const ShortButton({
    super.key,
    required this.text,
    required this.isYes,
    this.onPressed,
    this.width,
    this.height,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final btnWidth = width ?? 463;
    final btnHeight = height ?? 64;
    final txtSize = fontSize ?? 18;
    final bool isEnabled = onPressed != null;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: btnWidth,
        height: btnHeight,
        decoration: BoxDecoration(
          color: isYes ? const Color(0xFF463EC6) : const Color(0xFFFBFCFF),
          borderRadius: BorderRadius.circular(8),
          border:
              isYes
                  ? null
                  : Border.all(color: const Color(0xFFB0B8C1), width: 1),
          boxShadow:
              isYes
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
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isYes ? Colors.white : const Color(0xFF5D5D5D),
            fontSize: txtSize,
            fontFamily: 'PretendardMedium',
          ),
        ),
      ),
    );
  }
}
