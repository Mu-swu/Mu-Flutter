import 'package:flutter/material.dart';
import 'shortbutton.dart';

Future<void> ClearPopup({
  required BuildContext context,
  required String title,
  required String content,
  required String leftButtonText,
  required VoidCallback onLeftPressed,
  required String rightButtonText,
  required VoidCallback onRightPressed,
}) async {
  // 화면 비율 계산은 Dialog 내부에서 MediaQuery를 사용합니다.

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) {
      // 화면 너비를 기준으로 다이얼로그의 너비를 설정 (예: 화면 너비의 400px 또는 70%)
      final screenWidth = MediaQuery.of(context).size.width;
      final dialogWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.7;

      return Dialog(
        backgroundColor: Colors.transparent,
        // Dialog가 화면 중앙에 오도록 insetPadding을 조정
        insetPadding: const EdgeInsets.all(20.0),
        child: Container(
          width: dialogWidth, // 너비 설정
          constraints: const BoxConstraints(maxWidth: 400), // 최대 너비 제한
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 팝업 제목
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              // 팝업 내용
              Text(
                content,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 32),

              // 🌟 숏 버튼 두 개를 나란히 배치하는 Row
              Row(
                children: [
                  // 1. 왼쪽 버튼 (비활성화 스타일 - isYes: false)
                  Expanded(
                    child: ShortButton(
                      text: leftButtonText,
                      isYes: false, // 비활성화 스타일
                      noBackgroundColor: Colors.grey.shade200, // 배경색 지정 (옵션)
                      onPressed: () {
                        Navigator.pop(context); // 팝업 닫기
                        onLeftPressed(); // 외부 액션 실행
                      },
                      height: 56,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 12), // 버튼 사이 간격

                  // 2. 오른쪽 버튼 (활성화 스타일 - isYes: true)
                  Expanded(
                    child: ShortButton(
                      text: rightButtonText,
                      isYes: true, // 활성화 스타일
                      onPressed: () {
                        Navigator.pop(context); // 팝업 닫기
                        onRightPressed(); // 외부 액션 실행
                      },
                      height: 56,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}