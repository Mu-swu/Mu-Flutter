import 'package:flutter/material.dart';
import 'widgets/custom_tag.dart';

class ResultPage extends StatefulWidget {
  final String resultType;

  const ResultPage({super.key, required this.resultType});

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

  Map<String, dynamic> _getResultData(String type) {
    switch (type) {
      case '감정형':
        return {
          'mainTitle': '감정형',
          'leftCardImagePath': 'assets/test/test_ga.png',
          'cardColor': const Color(0xFFFBF4FF),
          'tags': [
            {'label': '추억이 너무 많아', 'type': TagType.gam},
            {'label': '미련 뚝뚝', 'type': TagType.gam},
          ],
          'descriptionTitle': '당신은 감정형 비움이!',
          'descriptionBody1':
              '물건에 서린 추억 때문에 고생하시죠?\n망설이는 마음 당연히 이해되지만\n그러다가 버려야 할 물건도\n버리지 않고 열심히 쌓아두지 않나요?',
          'descriptionBody2': '먼저 마음을 정리하면서 비우다보면 계속 비우게 될 거에요',
        };
      case '몰라형':
        return {
          'mainTitle': '몰라형',
          'leftCardImagePath': 'assets/test/test_mo.png',
          'cardColor': const Color(0xFFF3FBF0),
          'tags': [
            {'label': '정리기준이 어려워', 'type': TagType.mol},
            {'label': '너무 막막해', 'type': TagType.mol},
          ],
          'descriptionTitle': '당신은 몰라형 비움이!',
          'descriptionBody1':
              '어디서부터 시작해야할지 모르시겠죠?\n글을 읽어야하나 영상을 보고 배워야하나\n망설이고 있진 않으신가요?\n횡설수설하다가 비우려던 것도 끝까지 못하셨죠?',
          'descriptionBody2': '기준을 통해 하나하나 비우다보면 계속 비우게 될 거에요',
        };
      case '방치형':
      default:
        return {
          'mainTitle': '방치형',
          'leftCardImagePath': 'assets/test/test_ba.png',
          'cardColor': const Color(0xFFFBF4FF),
          'tags': [
            {'label': '방치형', 'type': TagType.bang},
            {'label': '열심히 미뤄야지', 'type': TagType.bang},
          ],
          'descriptionTitle': '당신은 방치형 비움이!',
          'descriptionBody1':
              '언젠가는 비우겠지라고 생각하시죠?\n지나치게 미루다간 산처럼 쌓일 거에요.\n그러다가 눈에 보이지 않으면\n물건이 있다는 사실조차 잊어버리지 않나요?',
          'descriptionBody2': '매일 시간을 정해 비우다보면 계속 비우게 될 거에요.',
        };
    }
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

    final resultData = _getResultData(widget.resultType);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child:
            _isLoading
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
                        resultData['mainTitle'],
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
                              color: resultData['cardColor'],
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: AssetImage(
                                  resultData['leftCardImagePath'],
                                ),
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
                                vertical: 30 * heightRatio,
                              ),
                              decoration: ShapeDecoration(
                                color: resultData['cardColor'],
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
                                    runSpacing: 30,
                                    children:
                                        (resultData['tags']
                                                as List<Map<String, dynamic>>)
                                            .map(
                                              (tag) => CustomTag(
                                                label: tag['label'],
                                                type: tag['type'],
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  SizedBox(height: 40 * heightRatio),
                                  // 태그와 텍스트 사이 여백 증가
                                  Text(
                                    resultData['descriptionTitle'],
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
                                    resultData['descriptionBody1'],
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
                                    resultData['descriptionBody2'],
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
                          padding: EdgeInsets.symmetric(
                            vertical: 26 * heightRatio,
                          ),
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
                            fontSize: 22 * widthRatio,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      SizedBox(height: 80 * heightRatio),
                    ],
                  ),
                ),
      ),
    );
  }
}
