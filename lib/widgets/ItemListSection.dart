import 'package:flutter/material.dart';

class ItemListSection extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(String category) onAddPressed;
  final void Function(String category) onItemTapped;

  const ItemListSection({
    super.key,
    required this.items,
    required this.onAddPressed,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final w = screenWidth / 1280;
    final h = screenHeight / 832;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 5 * w),
      child: Row(
        children: items.map((item) {
          final name = item['name'] as String;
          final isFilled = item['isFilled'] as bool? ?? false;

          return Padding(
            padding: EdgeInsets.only(right: 32 * w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단: 카테고리명 + + 버튼
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16 * w,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8 * w),
                    GestureDetector(
                      onTap: () => onAddPressed(name),
                      child: Icon(Icons.add, size: 24 * w),
                    ),
                  ],
                ),
                SizedBox(height: 16 * h),
                // 하단: 이미지
                GestureDetector(
                  onTap: () => onItemTapped(name),
                  child: Container(
                    width: 150 * w,
                    height: 170 * h,
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      image: DecorationImage(
                        image: AssetImage(
                          isFilled ? 'assets/fill.jpg' : 'assets/empty.jpg',
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}