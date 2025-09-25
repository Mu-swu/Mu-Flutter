import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'MissionStepPage.dart';
import 'surveyq.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'congestion_analysis_page.dart';
import 'widgets/navigationbar.dart';
import 'widgets/shortbutton.dart';
import 'mission_start.dart';


// CustomTag 위젯 (요청에 따라 색상과 크기 수정)
enum TagType { bang, gam, mol }
class CustomTag extends StatelessWidget {
  final String label;
  final TagType type;

  const CustomTag({
    super.key,
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (type) {
      case TagType.bang:
        backgroundColor = const Color(0xFFF2D7FF); // 방치형 배경
        textColor = const Color(0xFFE443C3); // 방치형 텍스트
        break;
      case TagType.gam:
        backgroundColor = const Color(0xFFFEE1C7); // 감정형 배경
        textColor = const Color(0xFFDD5B23); // 감정형 텍스트
        break;
      case TagType.mol:
        backgroundColor = const Color(0xFFD7F2C2); // 몰라형 배경
        textColor = const Color(0xFF568316); // 몰라형 텍스트
        break;
      default:
        backgroundColor = Colors.grey[300]!;
        textColor = Colors.black;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 패딩을 늘려서 크기 키움
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 14, // 폰트 사이즈 키움
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Timer Mission',
      theme: ThemeData(primarySwatch: Colors.blue),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'), // 🇰🇷 한국어 달력 등 지원
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const FigmaHomePage(),
        '/mission': (context) => MissionStepPage(),
        '/surveyq': (context) => const SurveyPage(),
        '/congestion': (context) => CongestionAnalysisLayout(),
        '/mission_start': (context) => const MissionStartPage(),
      },
    );
  }
}

class FigmaHomePage extends StatelessWidget {
  const FigmaHomePage({super.key});

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 섹션 (아이콘과 텍스트)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/surveyq');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F0FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.ac_unit, size: 32, color: Colors.blueAccent),
                    ),
                  ),
                  SizedBox(width: 8 * widthRatio),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTag(
                        label: '#정리보단 숨기기',
                        type: TagType.bang,
                      ),
                      SizedBox(height: 5 * heightRatio),
                      const Text(
                        '방치형 비움이',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.help_outline, size: 32, color: Colors.grey),
                ],
              ),
              SizedBox(height: spacing * 2),

              // 메인 콘텐츠 섹션 (2x2 그리드 구조)
              Expanded(
                child: Column(
                  children: [
                    // 첫 번째 행: mom 섹션과 비움 스케줄 섹션 (1.3 비율)
                    Expanded(
                      flex: 13,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 왼쪽: mom 섹션
                          Expanded(
                            flex: 18,
                            child: Container(
                              margin: EdgeInsets.only(right: spacing),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBF4FF),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Image.asset(
                                      'assets/mom.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  // 이미지와 흰색 컨테이너 사이 여백 제거
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Padding( // 상단에 작은 여백을 주어 텍스트 블록을 살짝 아래로 내림
                                            padding: const EdgeInsets.only(top: 10),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: const [
                                                Text(
                                                  '오늘의 챌린지',
                                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  '냉장실 상단 비우기',
                                                  style: TextStyle(fontSize: 16),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ShortButton(
                                            text: '시작하기',
                                            isYes: true,
                                            width: 100 * widthRatio,
                                            height: 40 * heightRatio,
                                            onPressed: () {
                                              Navigator.pushNamed(context, '/mission_start');
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 오른쪽: 비움 스케줄 섹션
                          Expanded(
                            flex: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '비움 스케줄',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 5 * heightRatio),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F5FF),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacing),
                    // 두 번째 행: 비움 현황과 버릴까 말까 상자 섹션 (1 비율)
                    Expanded(
                      flex: 10,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 왼쪽: 비움 현황 섹션
                          Expanded(
                            flex: 18,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '비움 현황',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 5 * heightRatio),
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(right: spacing),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F5FF),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 오른쪽: 버릴까 말까 상자 섹션
                          Expanded(
                            flex: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '버릴까말까 상자',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 5 * heightRatio),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F5FF),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing),
              BottomNavBar(
                selectedIndex: 0, // 현재 선택된 탭 인덱스
                onItemTapped: (index) {
                  if (index == 0) {
                    Navigator.pushNamed(context, '/'); // 홈
                  } else if (index == 1) {
                    Navigator.pushNamed(context, '/congestion'); // 미션
                  } else if (index == 2) {
                    Navigator.pushNamed(context, '/surveyq'); // 마이 (예시)
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}