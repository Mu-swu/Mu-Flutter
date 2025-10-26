import 'package:flutter/material.dart';
import 'package:mu/widgets/navigationbar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'user_theme_manager.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  int _currentMissionLevel = 4;

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
                                _buildMissionSection(widthRatio, heightRatio),
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
          switch (returnedType) {
            case '감정형':
              UserThemeManager.currentUserType = UserType.gam;
              break;
            case '몰라형':
              UserThemeManager.currentUserType = UserType.mol;
              break;
            case '방치형':
              UserThemeManager.currentUserType = UserType.bang;
              break;
          }

          setState(() {});
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

  Widget _buildMissionSection(double widthRatio, double heightRatio) {
    String imagePrefix;
    int maxLevel;
    double imageWidth;

    switch (UserThemeManager.currentUserType) {
      case UserType.bang:
        imagePrefix = 're';
        maxLevel = 3;
        imageWidth = 305;
        break;
      case UserType.gam:
        imagePrefix = 'cl';
        maxLevel = 4;
        imageWidth = 450;
        break;
      case UserType.mol:
        imagePrefix = 'dr';
        maxLevel = 3;
        imageWidth = 305;
        break;
    }

    final actualMissionLevel = _currentMissionLevel.clamp(0, maxLevel);

    final missionImagePath =
        'assets/my/${imagePrefix}${actualMissionLevel}.png';

    return Container(
      padding: EdgeInsets.all(30 * widthRatio),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FF),
        borderRadius: BorderRadius.circular(10 * widthRatio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10 * widthRatio),
          Image.asset(missionImagePath, width: imageWidth * widthRatio),
          SizedBox(height: 50 * widthRatio),
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
                      Text(
                        '완료한 미션',
                        style: TextStyle(
                          fontSize: 16 * widthRatio,
                          color: const Color(0xFF5D5D5D),
                        ),
                      ),
                      SizedBox(height: 20 * heightRatio),
                      Text(
                        '1/3',
                        style: TextStyle(
                          fontSize: 32 * widthRatio,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 15 * widthRatio),
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
                      Text(
                        '달성률',
                        style: TextStyle(
                          fontSize: 16 * widthRatio,
                          color: const Color(0xFF5D5D5D),
                        ),
                      ),
                      SizedBox(height: 20 * heightRatio),
                      Text(
                        '30%',
                        style: TextStyle(
                          fontSize: 32 * widthRatio,
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

  Widget _buildProgressSection(double widthRatio) {
    return Container(
      height: 302,
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
            child: LineChart(
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
                    spots: const [
                      FlSpot(0, 30),
                      FlSpot(1, 80),
                      FlSpot(2, 20),
                      FlSpot(3, 100),
                      FlSpot(4, 60),
                      FlSpot(5, 60),
                      FlSpot(6, 40),
                    ],
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
      height: 302,
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
