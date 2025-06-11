import 'package:flutter/material.dart';
Widget tts_text_box({
  required List<String> lines,
  required int currentLineIndex,
  ScrollController? controller,
}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 24),
    constraints: const BoxConstraints(minHeight: 180, maxHeight: 280),
    child: Stack(
      children: [
        // 텍스트 영역 (전체에 깔림)
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20), // 이미지 겹침 방지
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(lines.length, (index) {
                bool isCurrent = index == currentLineIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    lines[index],
                    style: TextStyle(
                      fontSize: isCurrent ? 24 : 20,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w400,
                      color: isCurrent ? Colors.black : Colors.grey[600],
                      height: 1.6,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        // 이미지: 오른쪽 아래 고정
        Positioned(
          bottom: 0,
          right: 0,
          child: SizedBox(
            width: 200,
            height: 80,
            child: Image.asset(
              'assets/boximage.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    ),
  );
}