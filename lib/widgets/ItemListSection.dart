import 'package:flutter/material.dart';

class ItemListSection extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final void Function(String category) onAddPressed;
  final void Function(String category) onItemTapped;

  const ItemListSection({
    super.key,
    required this.categories,
    required this.onAddPressed,
    required this.onItemTapped,
  });
  @override
  Widget build(BuildContext context) {
    final maxWidth = 960 * 0.45; // 부모 너비 제약 예시

    return SizedBox(
      width: maxWidth,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final name = category['name'] as String;
          final isFilled = category['isFilled'] as bool? ?? false;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: maxWidth/2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(fontSize: 20),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => onAddPressed(name),
                        iconSize: 26,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => onItemTapped(name),
                    child: Container(
                      width: double.infinity,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        image: DecorationImage(
                          image: AssetImage(
                              isFilled ? 'assets/fill.jpg' : 'assets/empty.jpg'),
                          fit: BoxFit.contain,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }}