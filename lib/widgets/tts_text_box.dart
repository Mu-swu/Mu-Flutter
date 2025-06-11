import 'package:flutter/material.dart';

Widget tts_text_box({
  required List<String> lines,
  required int currentLineIndex,
  ScrollController? controller,
}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 24),
    constraints: const BoxConstraints(minHeight: 180, maxHeight: 220),
    child: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
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
                    softWrap: true,
                    overflow: TextOverflow.visible,
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
        Positioned(
          bottom: 0,
          right: 0,
          child: Image.asset(
            'assets/boximage.png',
            width: 200,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
      ],
    ),
  );
}
