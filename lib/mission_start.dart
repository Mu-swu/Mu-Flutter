import 'package:flutter/material.dart';
import 'MissionStepPage.dart';
import 'widgets/custom_tag.dart';
import 'widgets/shortbutton.dart';
import 'user_theme_manager.dart'; // Import the user theme manager

class MissionStartPage extends StatelessWidget {
  final List<String> missionOrder;
  final Duration missionTime;
  const MissionStartPage({super.key, required this.missionOrder, required this.missionTime});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine the tag label and type based on the user type
    String tagLabel;
    TagType tagType;
    final currentUserType = UserThemeManager.currentUserType;
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
    final String missionTitle = missionOrder.isNotEmpty
        ? missionOrder[0]
        : '미션을 선택해주세요';
    String missionImage;
    switch (currentUserType) {
      case UserType.bang:
        missionImage = 'assets/mission/still_re.png'; // Example image for 'bang'
        break;
      case UserType.gam:
        missionImage = 'assets/mission/still_cl.png'; // Replace with actual image path
        break;
      case UserType.mol:
        missionImage = 'assets/mission/still_dr.png'; // Replace with actual image path
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tag and Title section
                CustomTag(
                  label: tagLabel,
                  type: tagType,
                ),
                const SizedBox(height: 16),
                Text(
                  missionTitle,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 36,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Mission Image section (with a fixed proportional width)
                Image.asset(
                  missionImage,
                  width: screenWidth * 0.8,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 48),

                // Buttons section 🚀 수정된 부분
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1), // 좌우 여백을 이미지와 동일하게 설정
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        flex: 1,
                        child: ShortButton(
                          text: '건너뛰기',
                          isYes: false,
                          onPressed: () {
                            // Skip logic
                          },
                          // width와 height를 제거하여 Flexible에 맡깁니다.
                        ),
                      ),
                      const SizedBox(width: 24),
                      Flexible(
                        flex: 1,
                        child: ShortButton(
                          text: '시작하기',
                          isYes: true,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MissionStepPage(
                                  missionOrder: missionOrder,
                                  missionTime: missionTime,
                                ),
                              ),
                            );
                          },
                          // width와 height를 제거하여 Flexible에 맡깁니다.
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}