import 'package:flutter/material.dart';

class longbutton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;

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
            isEnabled ? const Color(0xFF463EC6) : const Color(0xFFDBDEE7),
        padding: const EdgeInsets.symmetric(vertical: 20),
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: isEnabled ? 6 : 0,
        shadowColor: const Color(0xFF463EC6),
      ),
      onPressed: isEnabled ? onPressed : null,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'PretendardMedium',
          fontSize: 18,
          color: isEnabled ? Colors.white : Color(0xFFB0B8C1),
        ),
      ),
    );
  }
}
