import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mu/widgets/navigationbar.dart';
import 'package:mu/congestion_analysis_page.dart';
import 'package:mu/data/database.dart';

class TutorialStyle {
  final Color balloonColor;
  final Color arrowColor;
  final String imagePath;
  final List<String> texts;

  const TutorialStyle({
    required this.balloonColor,
    required this.arrowColor,
    required this.imagePath,
    required this.texts,
  });
}

const Map<String, TutorialStyle> tutorialStyles = {
  '방치형': TutorialStyle(
    balloonColor: Color(0xFFFBF4FF),
    arrowColor: Color(0xFFDB84EF),
    imagePath: 'assets/mission/bang_mom.png',
    texts: [
      '자, 냉장고부터 시작하자.\n이게 제일 쉬워.',
      '냉장고에 있는 음식들\n유통기한 기억나니?\n유통기한만 확인하면돼.',
      '자, 이제 냉장고 문열자.\n유통기한 지난 것만 버리면\n비움 성공이야!',
    ],
  ),
  '감정형': TutorialStyle(
    balloonColor: Color(0xFFFFF6EF),
    arrowColor: Color(0xFFFFB172),
    imagePath: 'assets/mission/gam_mom.png',
    texts: [
      '옷장부터 정리해볼까?\n네 마음도 조금씩 정리될거야.',
      '옷에 추억이 참 많지?\n하지만 다 품고 있으면\n마음이 무거워져.',
      '물건과 이별하는 연습,\n작지만 의미 있는 한걸음이야.',
    ],
  ),
  '몰라형': TutorialStyle(
    balloonColor: Color(0xFFF3FBF0),
    arrowColor: Color(0xFFA1C68D),
    imagePath: 'assets/mission/mol_mom.png',
    texts: [
      '서랍장부터 해보자~\n작고 귀여운 물건들이 많거든!',
      '작은 물건부터 분류하면\n큰 물건은 쉬워져!\n기준을 배우기 딱 좋은 공간이야.',
      '서랍 열고 안에 뭐가 있는지\n하나씩 꺼내보자!',
    ],
  ),
};

class TutorialOverlay extends StatefulWidget {
  final String userType;
  final VoidCallback onExit;
  final double scaleFactor;

  const TutorialOverlay({
    super.key,
    required this.userType,
    required this.onExit,
    required this.scaleFactor,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentTextIndex = 0;
  late TutorialStyle _style;

  @override
  void initState() {
    super.initState();
    _style = tutorialStyles[widget.userType] ?? tutorialStyles['몰라형']!;
  }

  void _nextText() {
    setState(() {
      if (_currentTextIndex < _style.texts.length - 1) {
        _currentTextIndex++;
      } else {
        widget.onExit();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = widget.scaleFactor;
    final firstCardWidth = 300 * scaleFactor;
    final paddingH = 163 * scaleFactor;
    final bool isLastStep = _currentTextIndex == _style.texts.length - 1;

    final firstCardTitle =
        tutorialStyles[widget.userType] == tutorialStyles['방치형']
            ? '냉장고'
            : (tutorialStyles[widget.userType] == tutorialStyles['감정형']
                ? '옷장'
                : '서랍장');
    final firstCardImage =
        tutorialStyles[widget.userType] == tutorialStyles['방치형']
            ? 'assets/home/refr.png'
            : (tutorialStyles[widget.userType] == tutorialStyles['감정형']
                ? 'assets/home/closet.png'
                : 'assets/home/drawer.png');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Container(color: Color(0xFF333333).withOpacity(0.8)),
        ),

        Positioned(
          top: 250 * scaleFactor,
          right: paddingH + 10,
          child: GestureDetector(
            onTap: widget.onExit,
            child: Row(
              children: [
                Text(
                  '닫기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'PretendardRegular',
                  ),
                ),
                SizedBox(width: 5 * scaleFactor),
                SvgPicture.asset('assets/mission/close.svg'),
              ],
            ),
          ),
        ),

        Positioned(
          top: 125 * scaleFactor + 32 * scaleFactor + 160 * scaleFactor,
          left: paddingH,
          child: SpaceUnitCard(
            title: firstCardTitle,
            imagePath: firstCardImage,
            isLocked: false,
            onTap: null,
          ),
        ),

        Center(
          child: Transform.translate(
            offset: Offset(192 * scaleFactor, 123),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  _style.imagePath,
                  width: 150 * scaleFactor,
                  height: 150 * scaleFactor,
                ),
                SizedBox(width: 16 * scaleFactor),
                GestureDetector(
                  onTap: _nextText,
                  child: CustomPaint(
                    painter: SpeechBubblePainter(
                      balloonColor: _style.balloonColor,
                      arrowColor: _style.arrowColor,
                      scaleFactor: scaleFactor,
                    ),
                    child: Container(
                      width: 372 * scaleFactor,
                      height: 168 * scaleFactor,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left: 35 * scaleFactor),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _style.texts[_currentTextIndex],
                                style: TextStyle(
                                  color: const Color(0xFF5D5D5D),
                                  fontSize: 20 * scaleFactor,
                                  fontFamily: 'PretendardRegular',
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ],
                          ),


                          Positioned(
                            right: -90 * scaleFactor,
                            bottom: -15 * scaleFactor,
                            child: Transform.rotate(
                              angle: isLastStep ? (math.pi / 6) : 0,
                              child: SvgPicture.asset(
                                'assets/mission/arrow_down.svg',
                                color: isLastStep ? const Color(0xFF7F91FF) : _style.arrowColor,
                                width: 32 * scaleFactor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SpeechBubblePainter extends CustomPainter {
  final Color balloonColor;
  final Color arrowColor;
  final double scaleFactor;

  SpeechBubblePainter({
    required this.balloonColor,
    required this.arrowColor,
    required this.scaleFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = balloonColor;
    final r = 10.0 * scaleFactor;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(r),
    );
    canvas.drawRRect(rect, paint);

    final arrowSize = 16.0 * scaleFactor;
    final arrowTop = 30.0 * scaleFactor + (arrowSize / 2);
    final cornerRadius = 5.0 * scaleFactor;

    final tailPath = Path();

    tailPath.moveTo(0, arrowTop - arrowSize / 2);

    tailPath.lineTo(-arrowSize + cornerRadius, arrowTop - (cornerRadius / 2));
    tailPath.quadraticBezierTo(
        -arrowSize, arrowTop,
        -arrowSize + cornerRadius, arrowTop + (cornerRadius / 2)
    );

    tailPath.lineTo(0, arrowTop + arrowSize / 2);

    tailPath.close();

    final tailPaint = Paint()..color = balloonColor;

    canvas.drawPath(tailPath, tailPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class SpaceUnitCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool isLocked;
  final VoidCallback? onTap;

  const SpaceUnitCard({
    super.key,
    required this.title,
    required this.imagePath,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 1280;

    final String displayImagePath =
        isLocked ? imagePath.replaceAll('.png', '_lock.png') : imagePath;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        width: 300 * scaleFactor,
        height: 324 * scaleFactor,
        decoration: BoxDecoration(
          color: isLocked ? const Color(0xFFF5F5F5) : const Color(0xFFF3F5FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 75 * scaleFactor),
                  Container(
                    width: 120 * scaleFactor,
                    height: 120 * scaleFactor,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Image.asset(displayImagePath)),
                  ),
                  SizedBox(height: 24 * scaleFactor),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          isLocked
                              ? const Color(0xFFB0B8C1)
                              : const Color(0xFF5D5D5D),
                      fontSize: 24 * scaleFactor,
                      fontFamily: 'PretendardMedium',
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D93A1).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Image.asset('assets/home/lock.png', scale: 1.2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SpaceStartScreen extends StatefulWidget {
  const SpaceStartScreen({super.key});

  @override
  State<SpaceStartScreen> createState() => _SpaceStartScreenState();
}

class _SpaceStartScreenState extends State<SpaceStartScreen> {
  int? _selectedIndex;
  bool _isLoading = true;
  List<SpaceProgress> _spaceProgress = [];
  String _userType = '방치형';

  // 💡 DB 인스턴스 및 사용자 ID 정의
  final AppDatabase db = AppDatabase.instance;
  final int userId = 1;

  // 💡 초기값은 DB에서 로드할 때까지 임시로 false로 설정
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _checkAndLoadTutorialStatus(); // DB에서 미션 인덱스 기반으로 튜토리얼 상태 확인
  }

  // 💡 [추가된 로직]: 미션 인덱스가 0일 때만 튜토리얼 표시
  Future<void> _checkAndLoadTutorialStatus() async {
    try {
      final missionIndex = await db.getUserMissionIndex(userId);

      // 미션 인덱스가 0 (가장 처음)일 때만 튜토리얼을 보여줍니다.
      const int initialIndex = 0;

      if (mounted) {
        setState(() {
          _showTutorial = (missionIndex == initialIndex);
        });
      }
    } catch (e) {
      print("튜토리얼 상태 로드 에러: $e");
      if (mounted) {
        setState(() {
          _showTutorial = false;
        });
      }
    }
  }

  Future<void> _loadProgress() async {
    try {
      final db = AppDatabase.instance;
      const userId = 1;

      final userType = await db.getUserType(userId) ?? '방치형';

      var progress = await db.getSpaceProgressForUser(userId);

      if (progress.isEmpty) {
        await db.initializeSpaceProgress(userId, userType);
        progress = await db.getSpaceProgressForUser(userId);
      }

      final sortedProgress = _sortProgressByUserType(progress, userType);

      if (mounted) {
        setState(() {
          _spaceProgress = sortedProgress;
          _userType = userType;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("진행 상태 불러오기 에러 : $e");
      if (mounted) {
        setState(() {
          _userType = "방치형";
          _isLoading = false;
        });
      }
    }
  }

  void _endTutorial() {
    if (mounted) {
      setState(() {
        _showTutorial = false;
      });
    }
    // 미션 인덱스가 올라가면 자동으로 튜토리얼은 다시 나타나지 않습니다.
  }

  List<SpaceProgress> _sortProgressByUserType(
    List<SpaceProgress> progress,
    String userType,
  ) {
    List<String> order;
    switch (userType) {
      case '방치형':
        order = ['냉장고', '서랍장', '옷장'];
        break;
      case '감정형':
        order = ['옷장', '냉장고', '서랍장'];
        break;
      case '몰라형':
      default:
        order = ['서랍장', '냉장고', '옷장'];
        break;
    }

    progress.sort((a, b) {
      return order.indexOf(a.spaceName).compareTo(order.indexOf(b.spaceName));
    });
    return progress;
  }

  String _getImagePathForSpace(String spaceName) {
    switch (spaceName) {
      case '냉장고':
        return 'assets/home/refr.png';
      case '서랍장':
        return 'assets/home/drawer.png';
      case '옷장':
        return 'assets/home/closet.png';
      default:
        return 'assets/home/refr.png';
    }
  }

  List<Widget> _buildSpaceCards() {
    return _spaceProgress.map((progress) {
      final spaceName = progress.spaceName;
      final bool isLocked = !progress.isUnlocked;
      final String imagePath = _getImagePathForSpace(spaceName);

      return SpaceUnitCard(
        title: spaceName,
        imagePath: imagePath,
        isLocked: isLocked,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CongestionAnalysisLayout(spaceName: spaceName),
            ),
          );
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 1280;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> spaceCards = _buildSpaceCards();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 163 * scaleFactor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 110 * scaleFactor),
                  Text(
                    '미션',
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontSize: 32 * scaleFactor,
                      fontFamily: 'PretendardBold',
                    ),
                  ),
                  SizedBox(height: 160 * scaleFactor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: spaceCards,
                  ),
                ],
              ),
            ),
          ),
          if (!_isLoading && _showTutorial && _userType != null)
            TutorialOverlay(
              userType: _userType!,
              onExit: _endTutorial,
              scaleFactor: scaleFactor,
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex ?? 1,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  int _getInitialIndex() {
    final route = ModalRoute.of(context)?.settings.name;
    if (route == '/') return 0;
    if (route == '/congestion') return 1;
    if (route == '/my') return 2;
    return 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedIndex == null) {
      _selectedIndex = _getInitialIndex();
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushNamed(context, '/');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/congestion');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/my');
    }
  }
}
