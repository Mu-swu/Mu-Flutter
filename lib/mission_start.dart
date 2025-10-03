// mission_start.dart
import 'package:flutter/material.dart';
import 'widgets/custom_tag.dart';
import 'widgets/shortbutton.dart';
import 'user_theme_manager.dart'; // Import the user theme manager

class MissionStartPage extends StatelessWidget {
  const MissionStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 기준 해상도 (디자인 기준)
    const baseWidth = 1280.0;
    const baseHeight = 800.0;

    // 확대 비율 계산 (비율 유지하며 살짝 확대)
    final scale = (screenWidth / baseWidth).clamp(1.0, 1.3);
    // Get current user type from the manager
    final currentUserType = UserThemeManager.currentUserType;

    // Determine the tag label and type based on the user type
    String tagLabel;
    TagType tagType;
    switch (currentUserType) {
      case UserType.bang:
        tagLabel = '방치형';
        tagType = TagType.bang;
        break;
      case UserType.gam:
        tagLabel = '감정형';
        tagType = TagType.gam;
        break;
      case UserType.mol:
        tagLabel = '몰라형';
        tagType = TagType.mol;
        break;
    }

    // Determine the mission title and image based on the user type
    String missionTitle;
    String missionImage;
    switch (currentUserType) {
      case UserType.bang:
        missionTitle = '냉장실 한 칸 비우기';
        missionImage = 'assets/still.png'; // Example image for 'bang'
        break;
      case UserType.gam:
        missionTitle = '옷장 한 칸 비우기';
        missionImage = 'assets/still.png'; // Replace with actual image path
        break;
      case UserType.mol:
        missionTitle = '서랍장 한 칸 비우기';
        missionImage = 'assets/still.png'; // Replace with actual image path
        break;
    }


    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: SizedBox(
            width: baseWidth,
            height: baseHeight,
            child: Stack(
              children: [
                // 배경
                Container(
                  width: baseWidth,
                  height: baseHeight,
                  color: Colors.white,
                ),

                // "시작하기" 버튼
                Positioned(
                  left: 653,
                  top: 653,
                  child: ShortButton(
                    text: '시작하기',
                    isYes: true, // 파란색
                    onPressed: () {
                      Navigator.pushNamed(context, '/mission');
                    },
                  ),
                ),

                // "건너뛰기" 버튼
                Positioned(
                  left: 162,
                  top: 653,
                  child: ShortButton(
                    text: '건너뛰기',
                    isYes: false, // 흰색
                    onPressed: () {
                      // 건너뛰기 로직
                    },
                  ),
                ),

                // 미션 제목
                Positioned(
                  left: 506,
                  top: 159,
                  child: Text(
                    missionTitle,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 36,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // 유형 태그
                Positioned(
                  left: 607,
                  top: 117,
                  child: CustomTag(
                    label: tagLabel,
                    type: tagType,
                  ),
                ),

                Center(
                  child: SizedBox(
                    width: 1000,
                    height: 350,
                    child: Image.asset(
                      missionImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}