import 'package:flutter/material.dart';
import 'sresult_page.dart';
import 'dart:math';

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

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> with TickerProviderStateMixin {
  final List<String> _questions = [
    '물건을 버릴 때\n아까워서 쉽게 버리지 못해요',
    '집 안 물건이 어디에 있는지\n대부분 알고 있어요',
    '정리하기 전에\n어떻게 정리할지 생각해요',
    '눈에 보이지 않으면\n물건이 있다는 사실을 잊어요',
    '정리할 때\n색상이나 디자인도 고려해요',
    '정리를 시작하면\n끝을 봐야 직성이 풀려요',
    '감정이 담긴 물건은\n정리하기 힘들어요',
    '나만의 정리 기준이나\n방식이 있어요',
    '버리기보다는\n그냥 숨겨놓는게 편해요',
    '한 번 정리한 공간은\n오래도록 유지돼요',
  ];

  final List<String> _imagePaths = [
    'assets/test/test1.png',
    'assets/test/test2.png',
    'assets/test/test3.png',
    'assets/test/test4.png',
    'assets/test/test5.png',
    'assets/test/test6.png',
    'assets/test/test7.png',
    'assets/test/test8.png',
    'assets/test/test9.png',
    'assets/test/test10.png',
  ];

  int _currentQuestionIndex = 0;

  late AnimationController _animationController;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _cardRotationAnimation;
  Offset _cardOffset = Offset.zero;
  double _cardRotation = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animationController.addListener(() {
      if (!_isDragging) {
        setState(() {
          _cardOffset = _cardSlideAnimation.value;
          _cardRotation = _cardRotationAnimation.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _animationController.stop();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _cardOffset += details.delta;

      final screenWidth = MediaQuery.of(context).size.width;
      final rotationFactor = (_cardOffset.dx / screenWidth) * 0.1;
      _cardRotation = rotationFactor * (pi / 8);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final minDragDistance = screenWidth * 0.25;

    if (_cardOffset.dx > minDragDistance) {
      _animateCardOffScreen(1);
    } else if (_cardOffset.dx < -minDragDistance) {
      _animateCardOffScreen(-1);
    } else {
      _animateCardBackToCenter();
    }
  }

  void _animateCardBackToCenter() {
    _cardSlideAnimation = Tween<Offset>(
      begin: _cardOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _cardRotationAnimation = Tween<double>(
      begin: _cardRotation,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward().whenComplete(() {
      setState(() {
        _cardOffset = Offset.zero;
        _cardRotation = 0.0;
      });
      _animationController.reset();
    });
  }

  void _animateCardOffScreen(int direction) {
    _cardSlideAnimation = Tween<Offset>(
      begin: _cardOffset,
      end: Offset(
        direction * 2 * MediaQuery.of(context).size.width,
        -0.2 * MediaQuery.of(context).size.height,
      ),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _cardRotationAnimation = Tween<double>(
      begin: _cardRotation,
      end: direction * (pi / 2),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward().whenComplete(() {
      setState(() {
        if (_currentQuestionIndex < _questions.length - 1) {
          _currentQuestionIndex++;
          _cardOffset = Offset.zero;
          _cardRotation = 0.0;
          _animationController.reset();
        } else {
          Future.delayed(const Duration(milliseconds: 400), () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        const ResultPage(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          });
        }
      });
    });
  }

  void _onNoTap() {
    _animateCardOffScreen(-1);
  }

  void _onYesTap() {
    _animateCardOffScreen(1);
  }

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

    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ───── 상단바 ─────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: topBarPadding,
                vertical: 20 * heightRatio,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      size: 32 * widthRatio,
                      color: const Color(0xFFB0B8C1),
                    ),
                  ),
                  Expanded(child: Container()),
                  Text(
                    "나의 정리 유형은?",
                    style: TextStyle(
                      fontSize: 24 * widthRatio,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                  Expanded(child: Container()),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.volume_up,
                      size: 32 * widthRatio,
                      color: const Color(0xFFB0B8C1),
                    ),
                  ),
                ],
              ),
            ),

            // ───── 진행바 ─────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20 * heightRatio,
              ),
              child: Stack(
                children: [
                  Container(
                    height: 15 * heightRatio,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(0), // 직각
                    ),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor:
                        (_currentQuestionIndex + 1) / _questions.length,
                    child: Container(
                      height: 15 * heightRatio,
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
                horizontal: horizontalPadding,
                vertical: 30 * heightRatio,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _onNoTap,
                    child: Text(
                      "<<    아니오",
                      style: TextStyle(
                        fontSize: 26 * widthRatio,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _onYesTap,
                    child: Text(
                      "네    >>",
                      style: TextStyle(
                        fontSize: 26 * widthRatio,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ───── 중앙 카드 (뒤 기울어진 카드 포함) ─────
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 뒷배경용 빈 카드
                    Transform.rotate(
                      angle: -0.1, // 원하는 각도를 라디안(radian) 값으로 입력
                      child: CardTestNo(
                        widthRatio: widthRatio,
                        heightRatio: heightRatio,
                        horizontalPadding: horizontalPadding,
                        imagePath: null,
                        questionText: '검사 완료!',
                      ),
                    ),

                    // --- 2. 다음 질문 카드 (중간) ---
                    if (_currentQuestionIndex + 1 < _questions.length)
                      Transform.scale(
                        scale: 1.0,
                        child: Padding(
                          padding: EdgeInsets.only(top: 0 * heightRatio),
                          child: CardTestNo(
                            widthRatio: widthRatio,
                            heightRatio: heightRatio,
                            horizontalPadding: horizontalPadding,
                            questionText: _questions[_currentQuestionIndex + 1],
                            imagePath: _imagePaths[_currentQuestionIndex + 1],
                          ),
                        ),
                      ),

                    // --- 3. 현재 질문 카드 (맨 앞) ---
                    if (_currentQuestionIndex < _questions.length)
                      GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: Transform.translate(
                          offset: _cardOffset,
                          child: Transform.rotate(
                            angle: _cardRotation,
                            child: CardTestNo(
                              widthRatio: widthRatio,
                              heightRatio: heightRatio,
                              horizontalPadding: horizontalPadding,
                              scale: 1.0,
                              questionText: _questions[_currentQuestionIndex],
                              imagePath: _imagePaths[_currentQuestionIndex],
                            ),
                          ),
                        ),
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
                right: horizontalPadding,
              ),
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
                onPressed: _onYesTap,
                child: Text(
                  isLastQuestion ? "결과보기" : "다음",
                  style: TextStyle(
                    fontSize: 22 * widthRatio,
                    color: Colors.white,
                  ),
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
  final String questionText;
  final String? imagePath;

  const CardTestNo({
    super.key,
    required this.widthRatio,
    required this.heightRatio,
    required this.horizontalPadding,
    this.scale = 1.0,
    required this.questionText,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = 549 * widthRatio * scale;
    final cardHeight = cardWidth + 40;

    return Container(
      width: cardWidth,
      height: cardHeight,
      padding: EdgeInsets.symmetric(
        horizontal: 48 * widthRatio * scale,
        vertical: 0 * heightRatio * scale,
      ),
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
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18 * widthRatio * scale),
              child: Image.asset(
                imagePath!,
                width: double.infinity,
                height: 250 * heightRatio * scale,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    "",
                  );
                },
              ),
            )
          else
            SizedBox(height: 250 * heightRatio * scale),
          SizedBox(height: 25 * heightRatio * scale),
          Text(
            questionText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF5C5C5C),
              fontSize: 27 * widthRatio * scale,
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
