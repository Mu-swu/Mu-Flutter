import 'package:flutter/material.dart';
import 'sresult_page.dart';

void main() {
  runApp(const SurveyApp());
}

class SurveyApp extends StatelessWidget {
  const SurveyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: const SurveyPage(),
    );
  }
}

class SurveyPage extends StatelessWidget {
  const SurveyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 1920.0;
    const baseHeight = 1080.0;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    // 상단바 좌우 여백만 100, 나머지는 180
    final topBarPadding = 100 * widthRatio;
    final horizontalPadding = 200 * widthRatio;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ───── 상단바 ─────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: topBarPadding, vertical: 20 * heightRatio),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back,
                        size: 32 * widthRatio, color: const Color(0xFFB0B8C1)),
                  ),
                  Expanded(child: Container()),
                  Text(
                    "나의 정리 유형은?",
                    style: TextStyle(
                        fontSize: 24 * widthRatio,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600]),
                  ),
                  Expanded(child: Container()),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.volume_up,
                        size: 32 * widthRatio, color: const Color(0xFFB0B8C1)),
                  ),
                ],
              ),
            ),

            // ───── 진행바 ─────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: 20 * heightRatio),
              child: Stack(
                children: [
                  Container(
                    height: 20 * heightRatio,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(0), // 직각
                    ),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.3, // 30% 진행
                    child: Container(
                      height: 20 * heightRatio,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7F91FF),
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ───── 예/아니오 선택 ─────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: 30 * heightRatio),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("<<    아니오",
                      style: TextStyle(
                          fontSize: 26 * widthRatio, color: Colors.black54)),
                  Text("네    >>",
                      style: TextStyle(
                          fontSize: 26 * widthRatio, color: Colors.black54)),
                ],
              ),
            ),

            // ───── 중앙 카드 (뒤 기울어진 카드 포함) ─────
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 뒤에 기울어진 카드
                    Transform.rotate(
                      angle: -0.05,
                      child: Container(
                        width: 549 * widthRatio * 0.9,
                        height: 585 * heightRatio * 0.9,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                          BorderRadius.circular(30 * widthRatio * 1.1),
                        ),
                      ),
                    ),
                    // 실제 카드
                    CardTestNo(
                      widthRatio: widthRatio,
                      heightRatio: heightRatio,
                      horizontalPadding: horizontalPadding,
                      scale: 0.9,
                    ),
                  ],
                ),
              ),
            ),

            // ───── 다음 버튼 ─────
            Padding(
              padding: EdgeInsets.only(
                  bottom: 80 * heightRatio,
                  top: 40 * heightRatio,
                  left: horizontalPadding,
                  right: horizontalPadding),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF463EC6),
                  padding: EdgeInsets.symmetric(vertical: 26 * heightRatio),
                  minimumSize: Size(double.infinity, 70 * heightRatio),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                  shadowColor: const Color(0x26463EC6),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResultPage(), // ResultPage 안에서 로딩 처리
                    ),
                  );
                },
                child: Text(
                  "다음",
                  style: TextStyle(
                      fontSize: 22 * widthRatio, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───── 카드 ─────
class CardTestNo extends StatelessWidget {
  final double widthRatio;
  final double heightRatio;
  final double horizontalPadding;
  final double scale;

  const CardTestNo({
    super.key,
    required this.widthRatio,
    required this.heightRatio,
    required this.horizontalPadding,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = 549 * widthRatio * scale;
    final cardHeight = 585 * heightRatio * scale;

    return Container(
      width: cardWidth,
      height: cardHeight,
      padding: EdgeInsets.symmetric(
          horizontal: 48 * widthRatio * scale,
          vertical: 42 * heightRatio * scale),
      decoration: ShapeDecoration(
        color: const Color(0xFFF3F5FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30 * widthRatio * scale),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 369 * heightRatio * scale,
            padding: EdgeInsets.all(30 * widthRatio * scale),
            decoration: ShapeDecoration(
              color: const Color(0xFFFAFBFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18 * widthRatio * scale),
              ),
            ),
          ),
          SizedBox(height: 42 * heightRatio * scale),
          Text(
            '물건을 버릴 때\n아까워서 쉽게 버리지 못해요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF5C5C5C),
              fontSize: 30 * widthRatio * scale,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
