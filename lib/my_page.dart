import 'package:flutter/material.dart';
import 'package:mu/widgets/navigationbar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mu/data/database.dart';
import 'user_theme_manager.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  List<Map<String, dynamic>> _spaceStats = [];
  bool _isLoading = true;

  int _currentMissionPageIndex = 0;
  final PageController _missionPageController = PageController();

  int _totalMissions = 0;
  int _completedMissions = 0;
  int _achievementRate = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = AppDatabase.instance;

    final String? dbUserType = await db.getUserType(1);
    if (dbUserType != null) {
      if (dbUserType == '감정형') {
        UserThemeManager.currentUserType = UserType.gam;
      } else if (dbUserType == '몰라형') {
        UserThemeManager.currentUserType = UserType.mol;
      } else {
        UserThemeManager.currentUserType = UserType.bang;
      }
    }

    final status = await db.getMyPageStatistics(1);
    List<Section> allSections = status['sections'];

    final spaceProgressList = await db.getSpaceProgressForUser(1);

    if (spaceProgressList.isEmpty) {
      await db.initializeSpaceProgress(1, dbUserType ?? '방치형');
      final newProgressList = await db.getSpaceProgressForUser(1);
      spaceProgressList.clear();
      spaceProgressList.addAll(newProgressList);
    }

    final unlockedSpaces =
        spaceProgressList.where((sp) => sp.isUnlocked).toList();

    List<Map<String, dynamic>> tempStats = [];

    for (var spaceProgress in unlockedSpaces) {
      String spaceName = spaceProgress.spaceName;

      List<Section> spaceSections =
          allSections.where((s) {
            return db.getSpaceNameForSection(s.name) == spaceName;
          }).toList();

      spaceSections.sort((a, b) {
        if (a.missionOrder != null && b.missionOrder != null) {
          return a.missionOrder!.compareTo(b.missionOrder!);
        }
        return a.id.compareTo(b.id);
      });

      int completedCount = spaceSections.where((s) => s.progress == 100).length;
      int totalCount = spaceSections.length;
      int rate =
          totalCount > 0 ? ((completedCount / totalCount) * 100).toInt() : 0;

      if (spaceSections.isEmpty) {
        List<String> dummyNames;
        if (spaceName == '냉장고')
          dummyNames = ["냉장실 한 칸", "얼음/얼린 식재료 칸", "냉동식품 칸"];
        else if (spaceName == '옷장')
          dummyNames = ["선반", "행거 구역", "옷장 바닥 공간"];
        else
          dummyNames = ["1단", "2단", "3단"];

        spaceSections =
            dummyNames
                .map(
                  (name) => Section(
                    id: -1,
                    userId: 1,
                    name: name,
                    clutterLevel: '',
                    progress: 0,
                  ),
                )
                .toList();
        totalCount = 0;
      }

      tempStats.add({
        'spaceName': spaceName,
        'sections': spaceSections,
        'completed': completedCount,
        'total': totalCount,
        'rate': rate,
      });
    }

    String targetSpaceName;
    switch (UserThemeManager.currentUserType) {
      case UserType.gam:
        targetSpaceName = '옷장';
        break;
      case UserType.mol:
        targetSpaceName = '서랍장';
        break;
      case UserType.bang:
      default:
        targetSpaceName = '냉장고';
        break;
    }

    int initialIndex = tempStats.indexWhere(
      (stat) => stat['spaceName'] == targetSpaceName,
    );
    if (initialIndex == -1) initialIndex = 0;

    if (mounted) {
      setState(() {
        _spaceStats = tempStats;

        _totalMissions = status['total'];
        _completedMissions = status['completed'];
        _achievementRate = status['rate'];

        _isLoading = false;

        _currentMissionPageIndex = initialIndex;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_missionPageController.hasClients) {
            _missionPageController.jumpToPage(initialIndex);
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const baseWidth = 1280.0;
    const baseHeight = 800.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    final horizontalPadding = screenWidth * 0.1;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 80 * heightRatio),
                      _buildTitleSection(widthRatio),
                      SizedBox(height: 32 * heightRatio),
                      _buildTypeSection(widthRatio),
                      SizedBox(height: 30 * heightRatio),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '나의 비움 여정',
                                  style: TextStyle(
                                    fontSize: 20 * widthRatio,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10 * heightRatio),
                                _buildMissionCarousel(widthRatio),
                              ],
                            ),
                          ),
                          SizedBox(width: 20 * widthRatio),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                (UserThemeManager.currentUserType ==
                                        UserType.mol)
                                    ? Text(
                                      '오늘의 비움 꿀팁',
                                      style: TextStyle(
                                        fontSize: 20 * widthRatio,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : Text(
                                      '',
                                      style: TextStyle(
                                        fontSize: 20 * widthRatio,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                SizedBox(height: 10 * heightRatio),
                                _buildSectionForType(widthRatio, heightRatio),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomNavSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionCarousel(double widthRatio) {
    if (_isLoading) {
      return Container(
        height: 310 * widthRatio,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_spaceStats.isEmpty) {
      return Container(
        height: 310 * widthRatio,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text("진행 중인 미션이 없습니다.")),
      );
    }

    bool showIndicator = _spaceStats.length > 1;

    return Container(
      height: 365 * widthRatio,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _missionPageController,
              itemCount: _spaceStats.length,
              onPageChanged: (index) {
                setState(() {
                  _currentMissionPageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final stat = _spaceStats[index];
                return _buildSingleMissionCard(stat, widthRatio);
              },
            ),
          ),

          if (showIndicator)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_spaceStats.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentMissionPageIndex == index
                              ? const Color(0xFFB0B8C1)
                              : const Color(0xFFDBDEE7),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSingleMissionCard(Map<String, dynamic> stat, double widthRatio) {
    List<Section> sections = stat['sections'];
    String spaceName = stat['spaceName'];
    int completedMissions = stat['completed'];
    int totalMissions = stat['total'];
    int achievementRate = stat['rate'];

    List<Map<String, dynamic>> displayItems =
        sections.take(4).map((section) {
          return {'name': section.name, 'isCompleted': section.progress == 100};
        }).toList();

    return Padding(
      padding: EdgeInsets.all(14 * widthRatio),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10 * widthRatio),

          _buildTimelineUI(displayItems, spaceName, widthRatio),

          SizedBox(height: 30 * widthRatio),
          Row(
            children: [
              SizedBox(width: 27),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 24 * widthRatio,
                    horizontal: 30 * widthRatio,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFF),
                    borderRadius: BorderRadius.circular(8 * widthRatio),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '완료한 미션',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFF5D5D5D),
                          fontFamily: 'PretendardRegular',
                        ),
                      ),
                      SizedBox(height: 13 * widthRatio),
                      Text(
                        '$completedMissions/$totalMissions',
                        style: TextStyle(
                          fontSize: 32,
                          fontFamily: 'PretendardMedium',
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 15 * widthRatio),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 24 * widthRatio,
                    horizontal: 16 * widthRatio,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFF),
                    borderRadius: BorderRadius.circular(8 * widthRatio),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '달성률',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFF5D5D5D),
                          fontFamily: 'PretendardRegular',
                        ),
                      ),
                      SizedBox(height: 13 * widthRatio),
                      Text(
                        '$achievementRate%',
                        style: TextStyle(
                          fontSize: 32,
                          fontFamily: 'PretendardMedium',
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 27),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineUI(
    List<Map<String, dynamic>> displayItems,
    String spaceName,
    double widthRatio,
  ) {
    const Color activeColor = Color(0xFF6AC992);
    const Color inactiveColor = Color(0xFFDBDEE7);
    const Color activeBgColor = Color(0xFFC0F1D0);
    const Color inactiveBgColor = Color(0xFFDBDEE7);
    const Color activeTextColor = Color(0xFF30AE65);
    const Color inactiveTextColor = Color(0xFF8D93A1);

    return SizedBox(
      height: 120 * widthRatio,
      child: Row(
        children:
            displayItems.asMap().entries.map((entry) {
              int index = entry.key;
              var item = entry.value;

              final String name = item['name'];
              final bool isCompleted = item['isCompleted'];

              Color leftLineColor = Colors.transparent;
              Color rightLineColor = Colors.transparent;

              if (index > 0) {
                bool prevCompleted = displayItems[index - 1]['isCompleted'];
                leftLineColor =
                    (prevCompleted && isCompleted)
                        ? activeColor
                        : inactiveColor;
              }

              if (index < displayItems.length - 1) {
                bool nextCompleted = displayItems[index + 1]['isCompleted'];
                rightLineColor =
                    (isCompleted && nextCompleted)
                        ? activeColor
                        : inactiveColor;
              }

              String displayName = name;

              return Expanded(
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      top: 22 * widthRatio,
                      left: 0,
                      right: 0,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 5,
                              color:
                                  index == 0
                                      ? Colors.transparent
                                      : leftLineColor,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 5,
                              color:
                                  index == displayItems.length - 1
                                      ? Colors.transparent
                                      : rightLineColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Center(
                            child: Image.asset(
                              isCompleted
                                  ? 'assets/my/done.png'
                                  : 'assets/my/undone.png',
                              width: 42,
                              height: 42,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(height: 8 * widthRatio),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8 * widthRatio,
                            vertical: 4 * widthRatio,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isCompleted ? activeBgColor : inactiveBgColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            spaceName,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isCompleted
                                      ? activeTextColor
                                      : inactiveTextColor,
                              fontFamily: 'PretendardMedium',
                            ),
                          ),
                        ),
                        SizedBox(height: 6 * widthRatio),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            displayName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF5D5D5D),
                              fontFamily: 'PretendardRegular',
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTitleSection(double widthRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '마이페이지',
          style: TextStyle(
            fontSize: 28 * widthRatio,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionForType(double widthRatio, double heightRatio) {
    switch (UserThemeManager.currentUserType) {
      case UserType.bang:
        return _buildProgressSection(widthRatio);
      case UserType.gam:
        return _buildMessageSection(widthRatio, heightRatio);
      case UserType.mol:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildTipsSection(widthRatio, heightRatio)],
        );
      default:
        return _buildProgressSection(widthRatio);
    }
  }

  Widget _buildTypeSection(double widthRatio) {
    String title;
    String description;
    String imagePath;
    Color backgroundColor;

    switch (UserThemeManager.currentUserType) {
      case UserType.bang:
        title = '방치형';
        description =
            '쌓이는 물건들로 언젠가 하겠지 하며 미루게 되죠.\n시간을 정해두고 짧게라도 시간을 내서 하나씩 실천해봐요.';
        imagePath = 'assets/my/mymom_bang.png';
        backgroundColor = const Color(0xFFFBF4FF);
        break;
      case UserType.gam:
        title = '감정형';
        description = '마음이 가라앉을 땐, 뭐든 손에 잘 안 잡혀요.\n그럴땐 욕심내지 말고, 하나만 비워봐요.';
        imagePath = 'assets/my/mymom_gam.png';
        backgroundColor = const Color(0xFFFFF6EF);
        break;
      case UserType.mol:
        title = '몰라형';
        description = "어디서부터 시작해야 할지 몰라 막막하다면,\n'무엇을 비울지'보다는 '어떻게 비울지'를 생각해봐요.";
        imagePath = 'assets/my/mymom_mol.png';
        backgroundColor = const Color(0xFFF3FBF0);
        break;
    }

    return GestureDetector(
      onTap: () async {
        final returnedType = await Navigator.pushNamed(context, '/surveyq');
        if (returnedType != null && returnedType is String) {
          final db = AppDatabase.instance;
          List<String> newMissions = [];
          String newUserTypeStr = '방치형';
          switch (returnedType) {
            case '감정형':
              UserThemeManager.currentUserType = UserType.gam;
              newMissions = ["선반", "행거 구역", "옷장 바닥 공간", "서랍"];
              newUserTypeStr = '감정형';
              break;
            case '몰라형':
              UserThemeManager.currentUserType = UserType.mol;
              newMissions = ["1단", "2단", "3단"];
              newUserTypeStr = '몰라형';
              break;
            case '방치형':
              UserThemeManager.currentUserType = UserType.bang;
              newMissions = ["냉장실 한 칸", "얼음/얼린 식재료 칸", "냉동식품 칸"];
              newUserTypeStr = '방치형';
              break;
          }
          setState(() {
            _spaceStats = [];
            _isLoading = true;
          });

          await db.updateUserType(1, newUserTypeStr);
          await db.deleteAllSectionsForUser(1);
          await db.batchInsertSections(1, newMissions);

          await Future.delayed(Duration(milliseconds: 100));
          await _loadData();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 30 * widthRatio,
          vertical: 30 * widthRatio,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12 * widthRatio),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20 * widthRatio,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8 * widthRatio),
                      Image.asset(
                        'assets/my/right_arrow.png',
                        width: 30 * widthRatio,
                      ),
                    ],
                  ),
                  SizedBox(height: 30 * widthRatio),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16 * widthRatio,
                      color: const Color(0xFF5D5D5D),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16 * widthRatio),
            Image.asset(imagePath, width: 260 * widthRatio),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(double widthRatio) {
    final db = AppDatabase.instance;
    return Container(
      height: 318,
      padding: EdgeInsets.all(30 * widthRatio),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FF),
        borderRadius: BorderRadius.circular(10 * widthRatio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16 * widthRatio),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: db.getWeeklyMissionStats(1),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {}
                final data = snapshot.data ?? [];

                bool isAllZero = data.every((d) => (d['y'] as double) == 0);

                List<FlSpot> spots = [];

                if (!isAllZero) {
                  spots =
                      data.map((d) {
                        return FlSpot(d['x'] as double, d['y'] as double);
                      }).toList();
                }
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        return const FlLine(
                          color: Color(0xffdbdee7),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 21,
                          interval: 1,
                          getTitlesWidget: bottomTitleWidgets,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 10,
                          getTitlesWidget: leftTitleWidgets,
                          reservedSize: 42,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom: BorderSide(color: Color(0xffdbdee7), width: 4),
                        left: BorderSide(color: Color(0xffdbdee7), width: 4),
                        top: BorderSide(color: Color(0xffdbdee7)),
                        right: BorderSide(color: Colors.transparent),
                      ),
                    ),
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: false,
                        color: Color(0xff7f91ff),
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 2,
                              color: Color(0xffd7dcfa),
                              strokeWidth: 2,
                              strokeColor: Color(0xff7f91ff),
                            );
                          },
                        ),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSection(double widthRatio, double heightRatio) {
    return Container(
      padding: EdgeInsets.all(30 * widthRatio),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FF),
        borderRadius: BorderRadius.circular(10 * widthRatio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20 * widthRatio),
          Image.asset('assets/my/clover.png', width: 400 * widthRatio),
          SizedBox(height: 46 * widthRatio),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(18 * widthRatio),
                  decoration: BoxDecoration(
                    color: Color(0xFFFAFBFF),
                    borderRadius: BorderRadius.circular(8 * widthRatio),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 1 * heightRatio),
                      Text(
                        '잘하고 있어. 정말 기특하다. 지금처럼 잘 해내갈 수 있길 엄마가 응원할게. 화이팅!',
                        style: TextStyle(
                          fontSize: 16 * widthRatio,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(double widthRatio, double heightRatio) {
    final List<Map<String, String>> tips = [
      {
        'title': '필요한 개수만 남기기',
        'description':
            '같은 종류의 물건이 여러개라면 무작정 비우기보다는 중복 물건을 최소화하는 전략을 세워봐요. 펜, 메모지, 고무줄, 비닐봉투 등 중복되는 물건의 가장 적절한 개수를 미리 정해 비워가는 거에요.(예:볼펜 5개, 집게 10개씩 남긴다.)',
      },
      {
        'title': '물건 종류별로 정리하기',
        'description':
            '물건의 품목별로 분류하여 정리해 보세요. 물건을 종류별로 모으는 것만큼 비우기에 확실한 방법은 없어요. 흩어져 있던 물건들을 한 곳에 모아 전체 양을 파악할 수 있고, 중복되거나 필요 없는 것을 쉽게 구분할 수 있는 가장 확실한 방법이에요. (예: 볼펜은 볼펜끼리, 문서는 문서끼리 한 구역에 모으기)',
      },
      {
        'title': '사용 주기로 판단해 비우기',
        'description':
            '물건을 마지막으로 사용했거나 사용할수 있는 최대 기간을 정해 바로 비울 수 있도록 결정해요. 화장품, 건강기능식품, 식재료 등 사용 기한이 있는 모든 품목에 구매 또는 개봉일을 라벨로 붙여 관리해주는 거에요. (예: 9월 5일 구매, 2026년 10월 5일까지)...',
      },
    ];

    final int todayTipIndex = DateTime.now().day % tips.length;
    final Map<String, String> todayTip = tips[todayTipIndex];

    return Container(
      height: 400,
      padding: EdgeInsets.all(30 * widthRatio),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FF),
        borderRadius: BorderRadius.circular(10 * widthRatio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 10 * heightRatio),
          Row(
            children: [
              Image.asset('assets/my/idea.png', width: 36 * widthRatio),
              SizedBox(width: 12 * widthRatio),
              Text(
                todayTip['title']!,
                style: TextStyle(
                  fontSize: 18 * widthRatio,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20 * heightRatio),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(25 * widthRatio),
            decoration: BoxDecoration(
              color: Color(0xFFFAFBFF),
              borderRadius: BorderRadius.circular(8 * widthRatio),
            ),
            child: Text(
              todayTip['description']!,
              style: TextStyle(
                fontSize: 16 * widthRatio,
                fontWeight: FontWeight.w500,
                height: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 12, color: const Color(0xFF5D5D5D));
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('월', style: style);
        break;
      case 1:
        text = const Text('화', style: style);
        break;
      case 2:
        text = const Text('수', style: style);
        break;
      case 3:
        text = const Text('목', style: style);
        break;
      case 4:
        text = const Text('금', style: style);
        break;
      case 5:
        text = const Text('토', style: style);
        break;
      case 6:
        text = const Text('일', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }

    return SideTitleWidget(axisSide: meta.axisSide, child: text);
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 12, color: const Color(0xFF5D5D5D));
    String text;
    if (value.toInt() % 20 == 0) {
      text = '${value.toInt()}';
    } else {
      return Container();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 15.0,
      child: Text(text, style: style),
    );
  }

  Widget _buildBottomNavSection() {
    return BottomNavBar(
      selectedIndex: 2, // 현재 선택된 탭 인덱스
      onItemTapped: (index) {
        if (index == 0) {
          Navigator.pushNamed(context, '/'); // 홈
        } else if (index == 1) {
          Navigator.pushNamed(context, '/congestion'); // 미션
        } else if (index == 2) {
          Navigator.pushNamed(context, '/my'); // 마이
        }
      },
    );
  }
}
