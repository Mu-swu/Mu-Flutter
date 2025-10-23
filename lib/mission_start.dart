import 'package:flutter/material.dart';
import 'MissionStepPage.dart';
import 'widgets/custom_tag.dart';
import 'widgets/shortbutton.dart';
import 'package:mu/data/database.dart';

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
            return '1시간 30분';
          case '보통':
            return '1시간';
          case '여유':
            return '45분';
          default:
            return '45분';
        }

      case '몰라형':
        switch (status) {
          case '혼잡':
            return '1시간';
          case '보통':
            return '40분';
          case '여유':
            return '20분';
          default:
            return '20분';
        }

      case '방치형':
      default:
        switch (status) {
          case '혼잡':
            return '1시간';
          case '보통':
            return '45분';
          case '여유':
            return '30분';
          default:
            return '30분';
        }
    }
  }

  Duration _parseDuration(String timeString) {
    if (timeString.contains('시간')) {
      final hours = int.tryParse(timeString.replaceAll('시간', '').trim()) ?? 0;
      return Duration(hours: hours);
    } else if (timeString.contains('분')) {
      final minutes = int.tryParse(timeString.replaceAll('분', '').trim()) ?? 0;
      return Duration(minutes: minutes);
    }
    return const Duration(minutes: 30);
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
        String missionImage;

        switch (userTypeString) {
          case '방치형':
            tagLabel = '방치형';
            tagType = TagType.bang;
            missionImage = 'assets/mission/still_re.png';
            break;
          case '감정형':
            tagLabel = '감정형';
            tagType = TagType.gam;
            missionImage = 'assets/mission/still_cl.png';
            break;
          case '몰라형':
          default:
            tagLabel = '몰라형';
            tagType = TagType.mol;
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
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
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
                            // Tag and Title section
                            CustomTag(label: tagLabel, type: tagType),
                            const SizedBox(height: 16),
                            Text(
                              missionTitle,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 44,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
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
                            const SizedBox(height: 48),

                            // Buttons section
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.1,
                              ),
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
                                            builder:
                                                (context) => MissionStepPage(
                                                  orderedMissions:
                                                      orderedMissions,
                                                  currentMissionIndex:
                                                      currentMissionIndex,
                                                  missionTime: missionDuration,
                                                ),
                                          ),
                                        );
                                      },
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
