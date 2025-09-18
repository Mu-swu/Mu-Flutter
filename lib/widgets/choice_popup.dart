import 'package:flutter/material.dart';

// choice_popup.dart
class ChoicePopup extends StatelessWidget {
  final String message;       // 🔹 추가
  final String imagePath;
  final VoidCallback onConfirm;

  const ChoicePopup({
    super.key,
    required this.message,     // 🔹 필수로 받음
    required this.imagePath,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 543,
        height: 384,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 텍스트 영역
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                message,  // 전달받은 message 사용
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF5C5C5C),
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ),

            // 이미지 영역
            Container(
              width: 389,
              height: 150,

              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),

            // 버튼
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 389,
                height: 52,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF463EC6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    "알겠어요",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
