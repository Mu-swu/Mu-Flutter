import 'package:flutter/material.dart';
import 'package:mu/user_theme_manager.dart';

Widget tts_text_box({
  required List<String> lines,
  required int currentLineIndex,
  ScrollController? controller,
}) {
  final UserType userType = UserThemeManager.currentUserType;
  final safeCurrentLineIndex =
      (currentLineIndex >= 0 && currentLineIndex < lines.length)
          ? currentLineIndex
          : -1;
  String missionImage;
  switch (userType) {
    case UserType.bang:
      missionImage = 'assets/mission/mission_re.png';
      break;
    case UserType.gam:
      missionImage = 'assets/mission/mission_cl.png';
      break;
    case UserType.mol:
      missionImage = 'assets/mission/mission_dr.png';
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
                          height: 1.6,
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
          offset: Offset(460,166),
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
