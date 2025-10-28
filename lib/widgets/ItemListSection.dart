import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';

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
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    // 기본 174 기준, 화면이 크면 174 * scale
    // 예: 960 기준 화면일 때 174이므로, scale = screenWidth / 960
    final scale = screenWidth / 960;

    final baseBoxSize = 174 * scale;

    // maxWidth도 화면 크기에 맞춰 조절
    final maxWidth = screenWidth * 0.45;

    return SizedBox(
      width: maxWidth,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1, // 카테고리 추가 박스 포함
        itemBuilder: (context, index) {
          if (index == categories.length) {
            // 마지막: 카테고리 추가 박스
            return Padding(
              padding: EdgeInsets.only(right: 12 * scale),
              child: SizedBox(
                width: maxWidth / 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50),
                    GestureDetector(
                      onTap: () => onAddPressed(''),
                      child: Container(
                        width: baseBoxSize,
                        height: baseBoxSize,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F5FF),
                          borderRadius: BorderRadius.circular(6 * (baseBoxSize / 174)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5 * (baseBoxSize / 174),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.add, size: 40, color: Colors.blue),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final category = categories[index];
          final name = category['name'] as String;

          final rawItems = category['items'];
          final items = rawItems is List
              ? rawItems.whereType<Map>().map((e) {
            return {
              'name': e['name'].toString(),
              'startDate': e['startDate'].toString(),
              'endDate': e['endDate'].toString(),
            };
          }).toList()
              : <Map<String, String>>[];

          List<Widget> stackChildren = [buildBaseBox(size: baseBoxSize)];
          if (items.isNotEmpty) {
            final latestItems = items.reversed.take(2).toList();
            if (latestItems.length == 1) {
              stackChildren.add(buildItemCard(
                  latestItems[0], rotated: true, size: baseBoxSize * 0.65));
            } else {
              stackChildren.addAll([
                buildItemCard(
                    latestItems[1], rotated: true, size: baseBoxSize * 0.65),
                buildItemCard(
                    latestItems[0], rotated: false, size: baseBoxSize * 0.65),
              ]);
            }
          }

          final contentBox = SizedBox(
            width: baseBoxSize,
            height: baseBoxSize,
            child: Stack(
              alignment: Alignment.center,
              children: stackChildren,
            ),
          );

          return Padding(
            padding: EdgeInsets.only(right: 0 * scale),
            child: SizedBox(
              width: maxWidth / 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 18.0),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/mission/edit.svg',
                        ),
                        iconSize: 20,
                        onPressed: () => onItemTapped(name),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => onAddPressed(name),
                    child: contentBox,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildBaseBox(
      {Color color = const Color(0xFFD7DCFA), required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6 * (size / 174)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5 * (size / 174),
          ),
        ],
      ),
    );
  }

  Widget buildItemCard(Map<String, String> item,
      {bool rotated = false, required double size}) {
    return Transform.rotate(
      angle: rotated ? -9 * pi / 180 : 0,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(8 * (size / 114)),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5FF),
          borderRadius: BorderRadius.circular(4 * (size / 114)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5 * (size / 114),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['name'] ?? '',
              style: TextStyle(
                  fontSize: 16 * (size / 114), fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4 * (size / 114)),
            Text(
              '${item['startDate']} \n ~ ${item['endDate']}',
              style: TextStyle(fontSize: 12 * (size / 114), color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}