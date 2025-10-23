import 'package:flutter/material.dart';

class longbutton extends StatelessWidget {
  final String text;        // 버튼 문구
  final VoidCallback? onPressed; // 클릭 액션 (null이면 disabled)
  final bool isEnabled;     // 활성/비활성 여부

  const longbutton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
        isEnabled ? const Color(0xFF463EC6) : const Color(0xFFDBDEE7), // 색상
        padding: const EdgeInsets.symmetric(vertical: 20),
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: isEnabled ? 6 : 0,
        shadowColor: const Color(0x26463EC6),
      ),
      onPressed: isEnabled ? onPressed : null,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          color: isEnabled? Colors.white: Color(0xFFB0B8C1) ,
        ),
      ),
    );
  }
}
