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
  String missionImage;
  Offset imageOffset;

  switch (spaceCode) {
    case 're':
      imageOffset = Offset(460, 166);
      missionImage = 'assets/mission/mission_re.png';
      break;
    case 'cl':
      missionImage = 'assets/mission/mission_cl.png';
      imageOffset = Offset(215, 210);
      break;
    case 'dr':
    default:
      missionImage = 'assets/mission/mission_dr.png';
      imageOffset = Offset(510, 166);
      break;
  }

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

        Transform.translate(
          offset: imageOffset,
          child: SizedBox(
            width: 202,
            height: 86,
            child: Image.asset(
              missionImage,
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation<double>(1),
            ),
          ),
        ),
      ],
    ),
  );
}
