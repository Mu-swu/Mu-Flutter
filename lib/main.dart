import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'mission_screen.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Timer Mission',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const FigmaHomePage(),
        '/mission': (context) => MissionStepPage(),
      },
    );
  }
}

class FigmaHomePage extends StatelessWidget {
  const FigmaHomePage({super.key});

  // AI 응답으로 대체될 문장 변수
  final String aiSentenceLeft = '오늘까지 싹 치워!\n안 그러면 내가 다 버린다.';
  final String aiSentenceRight = '네 물건 때문에 발 디딜 틈도 없겠다!\n그러고도 사람이 사니?';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 기준 해상도 기준 (디자인 기준)
    const baseWidth = 1280.0;
    const baseHeight = 800.0;

    // 확대 비율 계산 (비율 유지하며 살짝 확대)
    final scale = (screenWidth / baseWidth).clamp(1.0, 1.3);

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
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/mission');
                    },
                    child: Container(
                      width: 465,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          '시작하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // "건너뛰기" 버튼
                Positioned(
                  left: 162,
                  top: 653,
                  child: Container(
                    width: 463,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBFCFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        '건너뛰기',
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 18,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                // 미션 제목
                Positioned(
                  left: 506,
                  top: 159,
                  child: Text(
                    '냉장실 상단 비우기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 36,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // 방치형 태그
                Positioned(
                  left: 607,
                  top: 117,
                  child: Container(
                    width: 64,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC6C6),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const Positioned(
                  left: 623,
                  top: 125,
                  child: Text(
                    '방치형',
                    style: TextStyle(
                      color: Color(0xFF5C5C5C),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // 왼쪽 말풍선
                Positioned(
                  left: 163,
                  top: 259,
                  child: Container(
                    width: 309,
                    height: 106,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Positioned(
                  left: 238,
                  top: 288,
                  child: Text(
                    aiSentenceLeft,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF5C5C5C),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),

                // 오른쪽 말풍선
                Positioned(
                  left: 809,
                  top: 369,
                  child: Container(
                    width: 308,
                    height: 106,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Positioned(
                  left: 852,
                  top: 398,
                  child: Text(
                    aiSentenceRight,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF5C5C5C),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),

                Positioned(
                  left: 465,
                  top: 250,
                  child: SizedBox(
                    width: 350,
                    height: 350,
                    child: Image.asset('assets/mainimg.jpg'),
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
