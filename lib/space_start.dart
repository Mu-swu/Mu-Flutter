import 'package:flutter/material.dart';
import 'package:mu/widgets/navigationbar.dart';
import 'package:mu/congestion_analysis_page.dart';
import 'package:mu/data/database.dart';


// 사용자 유형별 스타일 정의
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

// 스타일 맵
const Map<String, TutorialStyle> tutorialStyles = {
  '방치형': TutorialStyle(
    balloonColor: Color(0xFFFBF4FF),
    arrowColor: Color(0xFFDB84EF),
    imagePath: 'assets/home/mom_bang.png',
    texts: [
      '자, 냉장고부터 시작하자. 이게 제일 쉬워.',
      '냉장고에 있는 음식들 기억나니? 유통기한만 확인하면돼.',
      '자, 이제 냉장고 문열자. 유통기한 지난 것만 버리면 비움 성공이야!',
    ],
  ),
  '감정형': TutorialStyle(
    balloonColor: Color(0xFFFFF6EF),
    arrowColor: Color(0xFFFFB172),
    imagePath: 'assets/home/mom_gam.png',
    texts: [
      '옷장부터 정리해볼까? 네 마음도 조금씩 정리될거야.',
      '옷에 추억이 참 많지? 하지만 다 품고 있으면 마음이 무거워져.',
      '물건과 이별하는 연습, 작지만 의미 있는 한걸음이야.',
    ],
  ),
  '몰라형': TutorialStyle(
    balloonColor: Color(0xFFF3FBF0),
    arrowColor: Color(0xFFA1C68D),
    imagePath: 'assets/home/mom_mol.png',
    texts: [
      '서랍장부터 해보자~ 작고 귀여운 물건들이 많거든!',
      '작은 물건부터 분류하면 큰 물건은 쉬워져! 기준을 배우기 딱 좋은 공간이야.',
      '서랍 열고 안에 뭐가 있는지 하나씩 꺼내보자!',
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
        // 마지막 텍스트에 도달하면 튜토리얼 종료
        widget.onExit();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final scaleFactor = widget.scaleFactor;
    final firstCardWidth = 300 * scaleFactor;
    final paddingH = 163 * scaleFactor;

    // SpaceStartScreen에서 첫 번째 카드를 가져오는 로직 (임시로)
    final firstCardTitle = tutorialStyles[widget.userType] ==
        tutorialStyles['방치형'] ? '냉장고' :
    (tutorialStyles[widget.userType] == tutorialStyles['감정형'] ? '옷장' : '서랍장');
    final firstCardImage = tutorialStyles[widget.userType] ==
        tutorialStyles['방치형'] ? 'assets/home/refr.png' :
    (tutorialStyles[widget.userType] == tutorialStyles['감정형']
        ? 'assets/home/closet.png'
        : 'assets/home/drawer.png');


    return Stack(
      children: [
        // 1. 전체 배경 (투명한 검정)
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.6),
          ),
        ),

        // 2. 닫기 버튼 (우측 상단)
        Positioned(
          top: 110 * scaleFactor,
          right: paddingH + 10,
          child: GestureDetector(
            onTap: widget.onExit,
            child: Row(
              children: [
                Text(
                  '닫기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20 * scaleFactor,
                    fontFamily: 'PretendardRegular',
                  ),
                ),
                SizedBox(width: 5 * scaleFactor),
                const Icon(Icons.close, color: Colors.white, size: 24),
              ],
            ),
          ),
        ),

        // 3. 🌟 첫 번째 카드 다시 띄우기 🌟
        Positioned(
          top: 110 * scaleFactor + 32 * scaleFactor + 160 * scaleFactor,
          // '미션' 텍스트 아래 + Row의 상단 위치
          left: paddingH,
          child: SpaceUnitCard(
            title: firstCardTitle,
            imagePath: firstCardImage,
            isLocked: false,
            // 튜토리얼 중이므로 onTap은 비활성화
            onTap: null,
          ),
        ),

        // 4. 말풍선 및 캐릭터 (화면 중앙에서 오른쪽으로 50 이동)
        Center(
          child: Transform.translate(
            offset: Offset(100 * scaleFactor, 0), // 🌟 오른쪽으로 50만큼 이동
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 캐릭터 이미지 (왼쪽)
                Image.asset(
                  _style.imagePath,
                  width: 150 * scaleFactor,
                  height: 150 * scaleFactor,
                ),
                SizedBox(width: 16 * scaleFactor),
                // 말풍선 (오른쪽)
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
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.all(30 * scaleFactor),
                      child: Stack( // 🌟 화살표를 오른쪽 아래에 위치시키기 위해 Stack 사용
                        children: [
                          Column(
                            // 🌟 텍스트 왼쪽 정렬 유지
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _style.texts[_currentTextIndex],
                                style: TextStyle(
                                  color: const Color(0xFF333333),
                                  fontSize: 18 * scaleFactor,
                                  fontFamily: 'PretendardMedium',
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ],
                          ),

                          // 🌟 다음 텍스트로 이동 화살표 (오른쪽 아래) 🌟
                          if (_currentTextIndex < _style.texts.length - 1)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Padding(
                                padding: EdgeInsets.only(right: 5 * scaleFactor),
                                child: Icon(
                                  Icons.arrow_drop_down,
                                  color: _style.arrowColor,
                                  size: 30 * scaleFactor,
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
// 둥근 모서리 삼각형 모양의 말풍선을 그리는 CustomPainter
class SpeechBubblePainter extends CustomPainter {
  final Color balloonColor;
  final Color arrowColor; // 현재는 사용하지 않지만, 인자 유지를 위해 남겨둡니다.
  final double scaleFactor;

  SpeechBubblePainter({
    required this.balloonColor,
    required this.arrowColor, // 사용하지 않음
    required this.scaleFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 말풍선 본체 (채우기 Paint)
    final paint = Paint()..color = balloonColor;
    final r = 10.0 * scaleFactor; // 둥근 모서리 반지름

    // 2. 말풍선 본체 (둥근 사각형)
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(r),
    );
    canvas.drawRRect(rect, paint);

    // 3. 말풍선 꼬리 (왼쪽 아래 위치, 말풍선 배경 색상 사용)
    final arrowSize = 15.0 * scaleFactor;
    final arrowTop = size.height / 2; // 말풍선 높이의 중앙


    final newTailPath = Path();

    // 왼쪽 중앙 (0, arrowTop)에서 시작
    newTailPath.moveTo(0, arrowTop - arrowSize / 2);
    newTailPath.lineTo(0, arrowTop + arrowSize / 2);
    // 꼬리 끝점 (말풍선 밖, 왼쪽으로)
    newTailPath.lineTo(-arrowSize, arrowTop);

    newTailPath.close();

    // 꼬리 채우기 Paint (말풍선 배경색 사용)
    final tailPaint = Paint()..color = balloonColor;

    // 꼬리 부분 채우기
    canvas.drawPath(newTailPath, tailPaint);
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
