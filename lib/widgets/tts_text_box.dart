import 'package:flutter/material.dart';

Widget tts_text_box({
  required List<String> lines,
  required int currentLineIndex,
  required String spaceCode,
  ScrollController? controller,
}) {
  final safeCurrentLineIndex =
      (currentLineIndex >= 0 && currentLineIndex < lines.length)
          ? currentLineIndex
          : -1;

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 10),
    constraints: const BoxConstraints(minHeight: 180, maxHeight: 280),
    child: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(lines.length, (index) {
                    bool isCurrent = index == safeCurrentLineIndex;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        lines[index],
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily:
                              isCurrent
                                  ? 'PretendardSemiBold'
                                  : 'PretendardRegular',
                          color:
                              isCurrent
                                  ? const Color(0xFF463EC6)
                                  : Color(0xFFB0B8C1),
                          height: 1.8,
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
