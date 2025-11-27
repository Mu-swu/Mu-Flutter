import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'MissionStepPage.dart';
import 'widgets/custom_tag.dart';
import 'widgets/longbutton.dart';
import 'package:mu/data/database.dart';
import 'user_theme_manager.dart';

class MissionStartPage extends StatelessWidget {
  const MissionStartPage({super.key});

  Future<Map<String, dynamic>> _loadMissionData() async {
    final db = AppDatabase.instance;
    final userType = await db.getUserType(1) ?? '방치형';
    final orderedMissions = await db.getOrderedMissions(1);
    final currentMissionIndex = await db.getUserMissionIndex(1);

    return {
      'userType': userType,
      'orderedMissions': orderedMissions,
      'currentMissionIndex': currentMissionIndex,
    };
  }
  String _getTimeForStatus(String status, String? userType) {
    switch (userType) {
      case '감정형':
        switch (status) {
          case '혼잡':
            return '30분';
          case '보통':
            return '20분';
          case '여유':
            return '10분';
          default:
            return '10분';
        }
      case '몰라형':
        switch (status) {
          case '혼잡':
            return '30분';
          case '보통':
            return '15분';
          case '여유':
            return '10분';
          default:
            return '10분';
        }
      case '방치형':
      default:
        switch (status) {
          case '혼잡':
            return '30분';
          case '보통':
            return '15분';
          case '여유':
            return '5분';
          default:
            return '5분';
        }
    }
  }

  Duration _parseDuration(String timeString) {
    int hours = 0;
    int minutes = 0;

    if (timeString.contains('시간')) {
      final parts = timeString.split('시간');
      hours = int.tryParse(parts[0].trim()) ?? 0;

      if (parts.length > 1 && parts[1].contains('분')) {
        minutes = int.tryParse(parts[1].replaceAll('분', '').trim()) ?? 0;
      }
    } else if (timeString.contains('분')) {
      minutes = int.tryParse(timeString.replaceAll('분', '').trim()) ?? 0;
    } else {
      return const Duration(minutes: 30);
    }

    return Duration(hours: hours, minutes: minutes);
  }

  String _getSpaceCodeFromMission(Section mission) {
    final String sectionName = mission.name;

    final Set<String> fridgeSet = {"냉장실 한 칸", "얼음/얼린 식재료 칸", "냉동식품 칸"};
    final Set<String> closetSet = {"선반", "행거 구역", "옷장 바닥 공간", "서랍"};
    final Set<String> drawerSet = {"1단", "2단", "3단"};

    if (fridgeSet.contains(sectionName)) return 're'; // Refrigerator
    if (closetSet.contains(sectionName)) return 'cl'; // Closet
    if (drawerSet.contains(sectionName)) return 'dr'; // Drawer

    return 're';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadMissionData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text("데이터 로딩 오류 : ${snapshot.error}")),
          );
        }

        final data = snapshot.data!;
        final String userTypeString = data['userType'];
        final List<Section> orderedMissions = data['orderedMissions'];
        final int currentMissionIndex = data['currentMissionIndex'];

        Section currentMission;
        if (orderedMissions.isEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("오류 : 스케줄링된 미션이 없습니다."),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("스케줄링 하러 가기"),
                  ),
                ],
              ),
            ),
          );
        }
        if (currentMissionIndex >= orderedMissions.length) {
          currentMission = orderedMissions.last;
        } else {
          currentMission = orderedMissions[currentMissionIndex];
        }

        String tagLabel;
        TagType tagType;
        UserType userType;

        switch (userTypeString) {
          case '방치형':
            tagLabel = '방치형';
            tagType = TagType.bang;
            userType = UserType.bang;
            break;
          case '감정형':
            tagLabel = '감정형';
            tagType = TagType.gam;
            userType = UserType.gam;
            break;
          case '몰라형':
          default:
            tagLabel = '몰라형';
            tagType = TagType.mol;
            userType = UserType.mol;
            break;
        }
        final String spaceCode = _getSpaceCodeFromMission(currentMission);
        String missionImage;
        switch (spaceCode) {
          case 're': // 냉장고
            missionImage = 'assets/mission/still_re.png';
            break;
          case 'cl': // 옷장
            missionImage = 'assets/mission/still_cl.png';
            break;
          case 'dr': // 서랍장
          default:
            missionImage = 'assets/mission/still_dr.png';
            break;
        }
        final String missionTitle = currentMission.name;
        final String timeString = _getTimeForStatus(
          currentMission.clutterLevel,
          userTypeString,
        );
        final Duration missionDuration = _parseDuration(timeString);

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 20),
                  child: IconButton(
                    icon: SvgPicture.asset('assets/left.svg'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 30),
                            CustomTag(label: tagLabel, type: tagType),
                            const SizedBox(height: 10),
                            Text(
                              missionTitle,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 44,
                                fontFamily: 'PretendardBold',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),

                            // Mission Image section (with a fixed proportional width)
                            Image.asset(
                              missionImage,
                              width: screenWidth * 0.75,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 60),

                            // Buttons section
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.1,
                              ),
                              child: Column(
                                children: [
                                  LongButton(
                                    text: '시작하기',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => MissionStepPage(
                                                orderedMissions:
                                                    orderedMissions,
                                                currentMissionIndex:
                                                    currentMissionIndex,
                                                missionTime: missionDuration,
                                                userType: userType,
                                              ),
                                        ),
                                      );
                                    },
                                    isEnabled: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
