import 'package:flutter/material.dart';

class StepNavigation extends StatelessWidget {
  final int currentIndex;
  final String missionType;

  const StepNavigation({
    Key? key,
    required this.currentIndex,
    required this.missionType,
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
      padding: const EdgeInsets.only(left: 24.0, top: 24.0),
      child: SizedBox(
        width: 200,
        height: 480,
        child: Stack(
          children: [
            for (int index = 0; index < stepTitles.length; index++)
              _buildStep(index),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int index) {
    final isCurrent = index == currentIndex;
    final isLast = index == stepTitles.length - 1;
    final stepTop = index * 90.0;

    Color selectedColor;
    switch (missionType) {
      case 'bas':
        selectedColor = const Color(0xFFC484EF);
        break;
      case 'gam':
        selectedColor = const Color(0xFFFFB472);
        break;
      case 'mol':
      default:
        selectedColor = const Color(0xFFACC79D);
    }

    return Positioned(
      top: stepTop,
      left: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 원 + 선
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: ShapeDecoration(
                  color: isCurrent ? selectedColor : const Color(0xFFD6DDE5),
                  shape: const OvalBorder(),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              // 아래 선 (마지막이 아니면)
              if (!isLast)
                Container(
                  width: 3,
                  height: 65, // 선의 길이
                  color: const Color(0xFFD6DDE5),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // 텍스트
          Padding(
            padding: const EdgeInsets.only(top: 4.0), // 텍스트 위치 보정
            child: Text(
              stepTitles[index],
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Pretendard',
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                color: isCurrent ? const Color(0xFF5C5C5C) : const Color(0xFFB0B8C1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}