import 'package:flutter/material.dart';
import 'package:mu/widgets/longbutton.dart';
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
  final List<bool> _answers = [];
  bool _isSurveyFinished = false;

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
      duration: const Duration(milliseconds: 500),
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
      _cardRotation = (_cardOffset.dx / screenWidth) * (pi / 20);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    _handleAnswer(_cardOffset.dx > 0);
  }

  void _handleAnswer(bool answer) {
    if (_animationController.isAnimating) return;
    _answers.add(answer);
    _animateCardOffScreen(answer ? 1 : -1);
  }

  void _showResult() async {
    final resultType = _calculateResult();

    if (mounted) {
      final String? returnedType = await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  ResultPage(resultType: resultType),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );

      if (returnedType != null && mounted) {
        Navigator.pop(context, returnedType);
      }
    }
  }

  void _animateCardOffScreen(int direction) {
    final screenWidth = MediaQuery.of(context).size.width;
    _cardSlideAnimation = Tween<Offset>(
      begin: _cardOffset,
      end: Offset(direction * screenWidth * 1.5, 0),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _cardRotationAnimation = Tween<double>(
      begin: _cardRotation,
      end: direction * (pi / 4),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward().whenComplete(() {
      if (!mounted) return;

      _animationController.reset();

      setState(() {
        if (_currentQuestionIndex < _questions.length - 1) {
          _currentQuestionIndex++;
          _cardOffset = Offset.zero;
          _cardRotation = 0.0;
        } else {
          _isSurveyFinished = true;
        }
      });
    });
  }

  String _calculateResult() {
    int bangchiScore = 0;
    int gamjeongScore = 0;
    int mollaScore = 0;

    for (int i = 0; i < _answers.length; i++) {
      bool isYes = _answers[i];
      switch (i + 1) {
        case 1:
          if (isYes) bangchiScore++;
          break;
        case 2:
          if (isYes)
            bangchiScore++;
          else
            mollaScore++;
          break;
        case 3:
          if (isYes) gamjeongScore++;
          break;
        case 4:
          if (isYes) bangchiScore++;
          break;
        case 5:
          if (isYes) gamjeongScore++;
          break;
        case 6:
          if (isYes) mollaScore++;
          break;
        case 7:
          if (isYes) {
            gamjeongScore++;
            mollaScore++;
          }
          break;
        case 8:
          if (isYes)
            bangchiScore++;
          else
            mollaScore++;
          break;
        case 9:
          if (isYes) mollaScore++;
          break;
        case 10:
          if (!isYes) bangchiScore++;
          break;
      }
    }

    if (mollaScore >= gamjeongScore && mollaScore >= bangchiScore) return "몰라형";
    if (gamjeongScore > mollaScore && gamjeongScore >= bangchiScore)
      return "감정형";
    return "방치형";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 1920.0;
    const baseHeight = 1080.0;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    final topBarPadding = 100 * widthRatio;
    final horizontalPadding = 200 * widthRatio;
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: topBarPadding,
                vertical: 20 * heightRatio,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 36 * widthRatio,
                      color: const Color(0xFFB0B8C1),
                    ),
                  ),
                  Icon(
                    Icons.volume_up,
                    size: 36 * widthRatio,
                    color: const Color(0xFFB0B8C1),
                  ),
                ],
              ),
            ),
            // Progress Bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 10 * heightRatio,
              ),
              child: LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _questions.length,
                backgroundColor: const Color(0xFFF5F5F5),
                color: const Color(0xFF7F91FF),
                minHeight: 10 * heightRatio,
              ),
            ),

            if (_isSurveyFinished) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "검사가 완료되었습니다!",
                        style: TextStyle(
                          fontSize: 32 * widthRatio,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 20 * heightRatio),
                      Text(
                        "아래 버튼을 눌러 당신의 비움 성향을 확인하세요.",
                        style: TextStyle(
                          fontSize: 22 * widthRatio,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  40 * heightRatio,
                  horizontalPadding,
                  80 * heightRatio,
                ),
                child: LongButton(
                  text: "결과 보기",
                  isEnabled: true,
                  onPressed: _showResult,
                ),
              ),
            ] else ...[
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 50 * heightRatio,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _handleAnswer(false),
                      child: Text(
                        "<<    아니오",
                        style: TextStyle(
                          fontSize: 26 * widthRatio,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _handleAnswer(true),
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
              // Card Stack
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedOpacity(
                      opacity: isLastQuestion ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Image.asset(
                        'assets/test/card_background.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        if (!isLastQuestion)
                          CardTestNo(
                            widthRatio: widthRatio,
                            heightRatio: heightRatio,
                            questionText: _questions[_currentQuestionIndex + 1],
                            imagePath: _imagePaths[_currentQuestionIndex + 1],
                          ),
                        if (_currentQuestionIndex < _questions.length)
                          GestureDetector(
                            key: ValueKey(_currentQuestionIndex),
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
                                  questionText:
                                      _questions[_currentQuestionIndex],
                                  imagePath: _imagePaths[_currentQuestionIndex],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  40 * heightRatio,
                  horizontalPadding,
                  80 * heightRatio,
                ),
                child: LongButton(
                  text: "결과 보기",
                  isEnabled: false,
                  onPressed: _showResult,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Card Widget
class CardTestNo extends StatelessWidget {
  final double widthRatio;
  final double heightRatio;
  final String questionText;
  final String? imagePath;

  const CardTestNo({
    super.key,
    required this.widthRatio,
    required this.heightRatio,
    required this.questionText,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = 630 * widthRatio;
    final cardHeight = cardWidth + 23;

    return Container(
      width: cardWidth,
      height: cardHeight,
      padding: EdgeInsets.only(top: 25, left: 25, right: 25),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child:
                imagePath != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        imagePath!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Text("Image not found"));
                        },
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                questionText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF5C5C5C),
                  fontSize: 27 * widthRatio,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
