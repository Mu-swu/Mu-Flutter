import 'package:flutter/material.dart';

class ItemListSection extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items;
  final VoidCallback onAddPressed;
  final void Function(int) onItemTapped;

  const ItemListSection({
    super.key,
    required this.title,
    required this.items,
    required this.onAddPressed,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthRatio = screenWidth / 1280;
    final heightRatio = screenHeight / 832;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 제목 및 추가 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20 * widthRatio,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, size: 24 * widthRatio),
              onPressed: onAddPressed,
            ),
          ],
        ),
        SizedBox(height: 16 * heightRatio),

        // 리스트 영역
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => onItemTapped(index),
                child: Container(
                  width: 300 * widthRatio,
                  height: 100 * heightRatio,
                  margin: EdgeInsets.only(bottom: 16 * heightRatio),
                  padding: EdgeInsets.all(16 * widthRatio),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(6 * widthRatio),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['name'] ?? '',
                        style: TextStyle(
                          fontSize: 16 * widthRatio,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5C5C5C),
                        ),
                      ),
                      SizedBox(height: 4 * heightRatio),
                      Text(
                        item['date'] ?? '',
                        style: TextStyle(
                          fontSize: 12 * widthRatio,
                          color: Color(0xFF9B9B9B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}