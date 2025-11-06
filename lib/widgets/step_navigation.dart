import 'package:flutter/material.dart';

class StepNavigation extends StatelessWidget {
  final int currentIndex;
  final String missionType;

  const StepNavigation({
    Key? key,
    required this.currentIndex,
    required this.missionType,
  }) : super(key: key);

  final List<String> stepTitles = const ['꺼내기', '확인하기', '분류하기', '넣기', '보류하기'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0),
      child: SizedBox(
        width: 189,
        height: 424,
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
        selectedColor = const Color(0xFFDB84EF);
        break;
      case 'gam':
        selectedColor = const Color(0xFFFFB172);
        break;
      case 'mol':
      default:
        selectedColor = const Color(0xFFA1C68D);
    }

    return Positioned(
      top: stepTop,
      left: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: ShapeDecoration(
                  color: isCurrent ? selectedColor : const Color(0xFFDBDEE7),
                  shape: const OvalBorder(),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'PretendardSemiBold',
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 65,
                  color: const Color(0xFFD6DDE5),
                ),
            ],
          ),

          const SizedBox(width: 12),

          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              stepTitles[index],
              style: TextStyle(
                fontSize: 16,
                fontFamily:
                    isCurrent ? 'PretendardSemiBold' : 'PretendardRegular',
                color:
                    isCurrent
                        ? const Color(0xFF5D5D5D)
                        : const Color(0xFFB0B8C1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
