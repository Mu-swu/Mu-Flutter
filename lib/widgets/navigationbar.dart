import 'package:flutter/material.dart';

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
      height: 40, // 높이 고정
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 홈 탭
          _buildNavItem(
            icon: Icons.home,
            label: '홈',
            index: 0,
            context: context,
          ),
          // 미션 탭
          _buildNavItem(
            icon: Icons.check_circle, // 톱니바퀴 아이콘
            label: '미션',
            index: 1,
            context: context,
          ),
          // 마이 탭
          _buildNavItem(
            icon: Icons.person,
            label: '마이',
            index: 2,
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required BuildContext context,
  }) {
    final bool isSelected = selectedIndex == index;
    final Color color = isSelected ? Colors.black : Colors.grey;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color),
          SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}