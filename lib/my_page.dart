import 'package:flutter/material.dart';
import 'package:mu/widgets/navigationbar.dart';
import 'package:fl_chart/fl_chart.dart';

enum TagType { bang, gam, mol }

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  TagType _currentUserType = TagType.mol;

  @override
  Widget build(BuildContext context) {
    const baseWidth = 1280.0;
    const baseHeight = 800.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    final horizontalPadding = screenWidth * 0.15;
    final verticalPadding = screenHeight * 0.02;
    final spacing = 20 * heightRatio;

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
                      _buildSubTitleSection(widthRatio),
                      SizedBox(height: 10 * heightRatio),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMissionSection(
                              widthRatio,
                              heightRatio,
                            ),
                          ),
                          SizedBox(width: 20 * widthRatio),
                          Expanded(child: _buildProgressSection(widthRatio)),
                        ],
                      ),
                      SizedBox(height: spacing),
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

  Widget _buildTypeSection(double widthRatio) {
    String title;
    String description;
    String imagePath;
    Color backgroundColor;

    switch (_currentUserType) {
      case TagType.bang:
        title = '방치형';
        description =
            '쌓이는 물건들로 언젠가 하겠지 하며 미루게 되죠.\n시간을 정해두고 짧게라도 시간을 내서 하나씩 실천해봐요.';
        imagePath = 'assets/my/mymom_bang.png';
        backgroundColor = const Color(0xFFFBF4FF);
        break;
      case TagType.gam:
        title = '감정형';
        description =
            '마음이 가라앉을 땐, 뭐든 손에 잘 안 잡혀요.\n그럴땐 욕심내지 말고, 하나만 비워봐요.';
        imagePath = 'assets/my/mymom_gam.png';
        backgroundColor = const Color(0xFFFFF6EF);
        break;
      case TagType.mol:
        title = '몰라형';
        description = "어디서부터 시작해야 할지 몰라 막막하다면,\n'무엇을 비울지'보다는 '어떻게 비울지'를 생각해봐요.";
        imagePath = 'assets/my/mymom_mol.png';
        backgroundColor = const Color(0xFFF3FBF0);
        break;
    }

    return Container(
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
                SizedBox(height: 30 * widthRatio), // 제목과 설명 사이 간격
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
    );
  }

  Widget _buildSubTitleSection(double widthRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '나의 비움 여정',
          style: TextStyle(
            fontSize: 20 * widthRatio,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMissionSection(double widthRatio, double heightRatio) {
    return Container(
      padding: EdgeInsets.all(30 * widthRatio),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FF),
        borderRadius: BorderRadius.circular(10 * widthRatio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/my/ex.png', width: 260 * widthRatio),
          SizedBox(height: 30 * widthRatio),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(18 * widthRatio),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                      SizedBox(height: 10 * heightRatio),
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
              SizedBox(width: 10 * widthRatio),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(18 * widthRatio),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                      SizedBox(height: 10 * heightRatio),
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
      height: 253,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/my/clover.png', width: 260 * widthRatio),
          SizedBox(height: 30 * widthRatio),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(18 * widthRatio),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                      SizedBox(height: 10 * heightRatio),
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
              SizedBox(width: 10 * widthRatio),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(18 * widthRatio),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                      SizedBox(height: 10 * heightRatio),
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
