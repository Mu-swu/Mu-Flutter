import 'package:flutter/material.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 1920.0;
    const baseHeight = 1080.0;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    final horizontalPadding = 200 * widthRatio;

    final leftCardWidth = 450 * widthRatio; // 왼쪽 카드
    final cardHeight = 550 * heightRatio; // 카드 높이 증가
    final cardSpacing = 40 * widthRatio; // 카드 간격

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 텍스트
              Column(
                children: [
                  Text(
                    '1초 뒤면 결과가 나와요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontSize: 32 * widthRatio * 1.2, // 1.2배
                      fontWeight: FontWeight.w700,
                      height: 1.31,
                    ),
                  ),
                  SizedBox(height: 16 * 1.2), // 여백 1.2배
                  Text(
                    '비움 성향에 맞는 답변을\n성실히 분석 중이에요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF5C5C5C),
                      fontSize: 20 * widthRatio * 1.2, // 1.2배
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40 * heightRatio * 1.2), // 이미지와 텍스트 간 여백
// 이미지
              Image.asset(
                'assets/roadingyou.png',
                width: 600 * widthRatio * 1.2, // 1.2배
                fit: BoxFit.contain,
              ),
            ],
          ),
        )
            : Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              SizedBox(height: 60 * heightRatio),
              // 상단 문구
              Center(
                child: Text(
                  "나의 비움 성향은?",
                  style: TextStyle(
                    fontSize: 24 * widthRatio,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5D5D5D),
                  ),
                ),
              ),
              SizedBox(height: 30 * heightRatio),

              // 방치형 중앙 글자
              Text(
                '방치형',
                style: TextStyle(
                  fontSize: 60 * widthRatio,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40 * heightRatio), // 글자와 카드 사이 여백

              // 카드 영역
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 왼쪽 카드 (빈 카드)
                  Container(
                    width: leftCardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF4FF),
                        borderRadius: BorderRadius.circular(10),
                        image: const DecorationImage(
                          image: AssetImage('assets/test/test_ba.png'),
                      ),
                    ),
                  ),

                  SizedBox(width: cardSpacing),

                  // 오른쪽 카드
                  Expanded(
                    child: Container(
                      height: cardHeight,
                      padding: EdgeInsets.symmetric(
                          horizontal: 150 * widthRatio, // 내부 좌우 여백 증가
                          vertical: 30 * heightRatio),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFFBF4FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 30, // 태그 사이 상하 여백 증가
                            children: [
                              _buildTag('정리보단 쌓기'),
                              _buildTag('열심히 미뤄야지'),
                            ],
                          ),
                          SizedBox(height: 40 * heightRatio), // 태그와 텍스트 사이 여백 증가
                          Text(
                            '당신은 방치형 비움이!',
                            style: TextStyle(
                              color: const Color(0xFF5C5C5C),
                              fontSize: 26 * widthRatio,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 12 * heightRatio),
                          Text(
                            '언젠가는 비우겠지라고 생각하시죠?\n지나치게 미루다간 산처럼 쌓일 거에요\n그러다가 눈에 보이지 않으면 \n물건이 있다는 사실 조차 잊어 버리지 않나요?',
                            style: TextStyle(
                              color: const Color(0xFF5C5C5C),
                              fontSize: 26 * widthRatio,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 12 * heightRatio),
                          Text(
                            '매일 시간을 정해 비우다보면 계속 비우게 될 거에요',
                            style: TextStyle(
                              color: const Color(0xFF5C5C5C),
                              fontSize: 26 * widthRatio,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 80 * heightRatio), // 카드와 버튼 사이 간격 증가

              // 버튼
              ElevatedButton(
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
                  Navigator.pop(context);
                },
                child: Text(
                  "다음",
                  style: TextStyle(
                      fontSize: 22 * widthRatio, color: Colors.white),
                ),
              ),

              SizedBox(height: 80 * heightRatio),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: ShapeDecoration(
        color: const Color(0xFFF1D7FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE443C3),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

