import 'package:flutter/material.dart';

class StepNavigation extends StatelessWidget {
  final int currentIndex;

  const StepNavigation({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  final List<String> stepTitles = const [
    '꺼내기',
    '비우기',
    '분류하기',
    '넣기',
    '보류하기',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 24.0), // ← 왼쪽·위 여백 추가
      child: SizedBox(
        width: 200,
        height: 320, // 높이도 줄여서 간격 줄이기
        child: Stack(
          children: [
            // 수직선

            // 단계들
            for (int index = 0; index < stepTitles.length; index++)
              _buildStep(index),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int index) {
    final isCurrent = index == currentIndex;
    final stepTop = 0 + (index * 64.0);

    return Positioned(
      top: stepTop,
      left: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 원
          Container(
            width: 28,
            height: 28,
            decoration: ShapeDecoration(
              color: isCurrent ? const Color(0xFFEF8484) : const Color(0xFFD6DDE5),
              shape: const OvalBorder(),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 12), // 원과 텍스트 사이 여백
          Text(
            stepTitles[index],
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              color: isCurrent ? const Color(0xFF5C5C5C) : const Color(0xFFB0B8C1),
            ),
          ),
        ],
      ),
    );
  }
}