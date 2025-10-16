import 'package:flutter/material.dart';
import 'package:mu/user_theme_manager.dart';
Widget tts_text_box({
  required List<String> lines,
  required int currentLineIndex,
  ScrollController? controller,

}) {
  final UserType userType = UserThemeManager.currentUserType;
  // 안전하게 currentLineIndex 처리
  final safeCurrentLineIndex = (currentLineIndex >= 0 && currentLineIndex < lines.length)
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
    margin: const EdgeInsets.symmetric(vertical: 24),
    constraints: const BoxConstraints(minHeight: 180, maxHeight: 280),
    child: Stack(
      children: [
        // 텍스트 영역
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 0), // 전체 우측 패딩
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(lines.length, (index) {
                    bool isCurrent = index == safeCurrentLineIndex;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: 16.0,
                        right: _getRightPadding(index, lines.length),
                      ),
                      child: Text(
                        lines[index],
                        style: TextStyle(
                          fontSize: isCurrent ? 24 : 20,
                          fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.w400,
                          color: isCurrent ? const Color(0xFF463EC6) : Colors.grey[600],
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

        // 이미지: 오른쪽 아래 고정
        Positioned(
          bottom: 0,
          right: 0,
          child: SizedBox(
            width: 200,
            height: 80,
            child: Image.asset(
              missionImage,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    ),
  );

}
//하단 텍스트만 우측 여백 확보
double _getRightPadding(int index, int totalLines) {
  const int linesToProtect = 2; // 맨 마지막 2줄만 이미지 피해 패딩 적용
  if (index >= totalLines - linesToProtect) {
    return 200; // 이미지 너비만큼 우측 패딩
  }
  return 0;
}