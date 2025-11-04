import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 84,
      decoration: const BoxDecoration(color: const Color(0xFFFAFBFF)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 220.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              selectedIconPath: 'assets/bottom_icons/home_selected.svg',
              unselectedIconPath: 'assets/bottom_icons/home_unselected.svg',
              label: '홈',
              index: 0,
              context: context,
            ),
            // 미션 탭
            _buildNavItem(
              selectedIconPath: 'assets/bottom_icons/mission_selected.svg',
              unselectedIconPath: 'assets/bottom_icons/mission_unselected.svg',
              label: '미션',
              index: 1,
              context: context,
            ),
            // 마이 탭
            _buildNavItem(
              selectedIconPath: 'assets/bottom_icons/my_selected.svg',
              unselectedIconPath: 'assets/bottom_icons/my_unselected.svg',
              label: '마이',
              index: 2,
              context: context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String selectedIconPath,
    required String unselectedIconPath,
    required String label,
    required int index,
    required BuildContext context,
  }) {
    final bool isSelected = selectedIndex == index;
    final Color color = isSelected ? Color(0xFF333333) : Color(0xFFB0B8C1);

    final String currentIconPath =
        isSelected ? selectedIconPath : unselectedIconPath;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.translucent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(currentIconPath),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily:
                  isSelected ? 'PretendardSemibold' : 'PretendardRegular',
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
