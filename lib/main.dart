import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mu/data/database.dart';
import 'package:mu/my_page.dart';
import 'package:mu/widgets/dday_banner.dart';
import 'surveyq.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'space_start.dart';
import 'InventoryPage.dart';
import 'widgets/navigationbar.dart';
import 'widgets/shortbutton.dart';
import 'widgets/schedule_item.dart';
import 'keepbox.dart';
import 'user_theme_manager.dart';
import 'package:mu/data/sampledata.dart';
import 'package:mu/notification_service.dart';
import 'widgets/schedule_item.dart';
import 'package:mu/mission_start.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum TagType { bang, gam, mol }

class CustomTag extends StatelessWidget {
  final String label;
  final TagType type;

  const CustomTag({super.key, required this.label, required this.type});

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
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

final PageController _pageController = PageController();
int _currentPage = 0;

final List<Map<String, dynamic>> _dataList = [
  {
    "title": "냉장고",
    "image": "assets/home/refr.png",
    "space": "냉장고",
    "progress": 0,
  },
  {
    "title": "옷장",
    "image": "assets/home/closet.png",
    "space": "옷장",
    "progress": 0,
  },
  {
    "title": "서랍장",
    "image": "assets/home/drawer.png",
    "space": "서랍장",
    "progress": 0,
  },
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await NotificationService.instance.init();
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
      supportedLocales: const [Locale('ko')],
      initialRoute: '/',
      routes: {
        '/': (context) => const FigmaHomePage(),
        '/surveyq': (context) => const SurveyPage(),
        '/congestion': (context) => SpaceStartScreen(),
        '/my': (context) => const MyPage(),
        '/keepbox': (context) => const keepbox(),
        '/inven': (context) => const InventoryPage(),
        '/mission_start': (context) => const MissionStartPage(),
      },
    );
  }
}

class FigmaHomePage extends StatefulWidget {
  const FigmaHomePage({super.key});

  @override
  State<FigmaHomePage> createState() => _FigmaHomePageState();
}

class _FigmaHomePageState extends State<FigmaHomePage> {
  final db = AppDatabase.instance;
  bool _isLoading = true;
  List<KeepBox> _urgentItems = [];
  List<KeepBox> _impendingItems = [];
  String _userSpace = "냉장고";
  bool _showOverlayBanner = false;

  String _userTypeString = '방치형';
  List<Section> _orderedMissions = [];
  int _currentMissionIndex = 0;
  Section? _challengeMission;
  int _currentSpaceProgressPercentage = 0;

  List<Map<String, dynamic>> _dashboardItems = [];
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData(showLoading: true);
  }

  Future<void> _loadUserData({bool showLoading = false}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      await db.getOrCreateUser(1);
      final String? userType = await db.getUserType(1);
      _userTypeString = userType ?? '방치형';

      UserType loadedType;
      switch (_userTypeString) {
        case '감정형':
          loadedType = UserType.gam;
          _userSpace = '옷장';
          break;
        case '몰라형':
          loadedType = UserType.mol;
          _userSpace = '서랍장';
          break;
        case '방치형':
        default:
          loadedType = UserType.bang;
          _userSpace = '냉장고';
      }
      UserThemeManager.currentUserType = loadedType;
      _urgentItems = await db.getTopTowUrgentItems();

      _orderedMissions = await db.getOrderedMissions(1);
      _currentMissionIndex = await db.getUserMissionIndex(1);

      if (_currentMissionIndex < _orderedMissions.length) {
        _challengeMission = _orderedMissions[_currentMissionIndex];
      } else {
        _challengeMission = null;
      }
      final status = await db.getMyPageStatistics(1);
      List<Section> allSections = status['sections'];

      final List<Map<String, dynamic>> allFurnitureData = [
        {
          "title": "냉장고",
          "image": "assets/home/refr.png",
          "space": "냉장고",
          "progress": 0,
        },
        {
          "title": "서랍장",
          "image": "assets/home/drawer.png",
          "space": "서랍장",
          "progress": 0,
        },
        {
          "title": "옷장",
          "image": "assets/home/closet.png",
          "space": "옷장",
          "progress": 0,
        },
      ];

      List<Map<String, dynamic>> calculatedItems =
      allFurnitureData.map((item) {
        String spaceName = item['space'];

        List<Section> spaceSections =
        allSections.where((s) {
          return db.getSpaceNameForSection(s.name) == spaceName;
        }).toList();

        if (spaceSections.isEmpty) {
          return {...item, "progress": 0};
        }

        int completedCount =
            spaceSections.where((s) => s.progress == 100).length;
        int totalCount = spaceSections.length;
        int rate =
        totalCount > 0
            ? ((completedCount / totalCount) * 100).toInt()
            : 0;

        return {...item, "progress": rate};
      }).toList();

      var currentSpaceItem = calculatedItems.firstWhere(
            (item) => item['space'] == _userSpace,
        orElse: () => calculatedItems[0],
      );

      if ((currentSpaceItem['progress'] as num) < 100) {
        _dashboardItems = [currentSpaceItem];
      } else {
        _dashboardItems = calculatedItems;
      }

    } catch (e, stackTrace) {
      print("사용자 데이터 로드 실패 : $e");
      print("상세 위치 : $stackTrace");
      UserThemeManager.currentUserType = UserType.bang;
      _dashboardItems = [];
    }

    final items = await db.getImpendingDDayItems();
    final bool hasImpendingItems = items.isNotEmpty;

    setState(() {
      _impendingItems = items;
      _isLoading = false;
      _currentPage = 0;
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }

    if (hasImpendingItems && mounted) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        setState(() {
          _showOverlayBanner = true;
        });
      }

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _showOverlayBanner = false;
          });
        }
      });
    }
  }

  String _getMissionTime(Section mission) {
    final status = mission.clutterLevel;
    switch (_userTypeString) {
      case '감정형':
        switch (status) {
          case '혼잡':
            return '30분';
          case '보통':
            return '20분';
          case '여유':
            return '10분';
          default:
            return '10분';
        }
      case '몰라형':
        switch (status) {
          case '혼잡':
            return '30분';
          case '보통':
            return '15분';
          case '여유':
            return '10분';
          default:
            return '10분';
        }
      case '방치형':
      default:
        switch (status) {
          case '혼잡':
            return '30분';
          case '보통':
            return '15분';
          case '여유':
            return '5분';
          default:
            return '5분';
        }
    }
  }

  List<String> _getDummyMissions() {
    switch (_userTypeString) {
      case '감정형': // 옷장
        return ["선반", "행거 구역", "옷장 바닥 공간", "서랍"];

      case '몰라형': // 서랍장
        return ["1단", "2단", "3단"];

      case '방치형': // 냉장고
      default:
        return ["냉장실 한 칸", "얼음/얼린 식재료 칸", "냉동식품 칸"];
    }
  }

  Widget _buildPageIndicator() {
    bool isFirstFurnitureClear =
        _dashboardItems.isNotEmpty &&
        (_dashboardItems[0]['progress'] as num) >= 100;

    if (_dashboardItems.length <= 1 || !isFirstFurnitureClear) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_dashboardItems.length, (index) {
        final bool isActive = index == _currentPage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFFB0B8C1) : const Color(0xFFDBDEE7),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    const baseWidth = 1280.0;
    const baseHeight = 800.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final overallRatio =
        screenWidth / baseWidth < screenHeight / baseHeight
            ? screenWidth / baseWidth
            : screenHeight / baseHeight;

    final horizontalPadding = 150.0 * overallRatio;
    final verticalPadding = 20.0 * overallRatio;
    final spacing = 20.0 * overallRatio;

    final item1 = _urgentItems.isNotEmpty ? _urgentItems[0] : null;
    final item2 = _urgentItems.length > 1 ? _urgentItems[1] : null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final item1ExpirationDate =
        item1 != null
            ? DateTime(
              item1.expirationAt.year,
              item1.expirationAt.month,
              item1.expirationAt.day,
            )
            : null;

    final item2ExpirationDate =
        item2 != null
            ? DateTime(
              item2.expirationAt.year,
              item2.expirationAt.month,
              item2.expirationAt.day,
            )
            : null;

    final item1RemainingDays = item1ExpirationDate?.difference(today).inDays;
    final item2RemainingDays = item2ExpirationDate?.difference(today).inDays;

    bool isFirstFurnitureClear =
        _dashboardItems.isNotEmpty &&
        (_dashboardItems[0]['progress'] as num) >= 100;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                top: verticalPadding + 20,
                left: horizontalPadding,
                right: horizontalPadding,
                bottom: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 헤더 (로고, 타이틀, 박스 아이콘)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final returnedType = await Navigator.pushNamed(
                            context,
                            '/surveyq',
                          );

                          if (returnedType != null && returnedType is String) {
                            setState(() {
                              _isLoading = true;
                            });

                            final db = AppDatabase.instance;
                            List<String> newMissions = [];
                            String newUserTypeStr = '방치형';

                            switch (returnedType) {
                              case '감정형':
                                UserThemeManager.currentUserType = UserType.gam;
                                newMissions = ["선반", "행거 구역", "옷장 바닥 공간", "서랍"];
                                newUserTypeStr = '감정형';
                                break;
                              case '몰라형':
                                UserThemeManager.currentUserType = UserType.mol;
                                newMissions = ["1단", "2단", "3단"];
                                newUserTypeStr = '몰라형';
                                break;
                              case '방치형':
                                UserThemeManager.currentUserType =
                                    UserType.bang;
                                newMissions = [
                                  "냉장실 한 칸",
                                  "얼음/얼린 식재료 칸",
                                  "냉동식품 칸",
                                ];
                                newUserTypeStr = '방치형';
                                break;
                            }

                            await db.updateUserType(1, newUserTypeStr);
                            await db.deleteAllSectionsForUser(1);
                            await db.batchInsertSections(1, newMissions);

                            await _loadUserData(showLoading: false);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12 * overallRatio),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F0FC),
                            borderRadius: BorderRadius.circular(
                              12 * overallRatio,
                            ),
                          ),
                          child: Image.asset(
                            UserThemeManager.retestImage,
                            width: 42 * overallRatio,
                            height: 42 * overallRatio,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(width: 20 * overallRatio),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTag(
                            label: UserThemeManager.tagLabel,
                            type:
                                UserThemeManager.currentUserType == UserType.gam
                                    ? TagType.gam
                                    : (UserThemeManager.currentUserType ==
                                            UserType.mol
                                        ? TagType.mol
                                        : TagType.bang),
                          ),
                          SizedBox(height: 5 * overallRatio),
                          Text(
                            UserThemeManager.userTitle,
                            style: TextStyle(
                              fontSize: 32 * overallRatio,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/inven');
                        },
                        child: Container(
                          padding: EdgeInsets.all(12 * overallRatio),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F0FC),
                            borderRadius: BorderRadius.circular(
                              12 * overallRatio,
                            ),
                          ),
                          child: Image.asset(
                            'assets/main_box.png',
                            width: 42 * overallRatio,
                            height: 42 * overallRatio,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20 * overallRatio),

                  // 메인 컨텐츠 영역
                  Expanded(
                    child: Column(
                      children: [
                        // 상단부: 오늘의 챌린지 & 비움 스케줄
                        Expanded(
                          flex: 13,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 18,
                                child: Container(
                                  margin: EdgeInsets.only(right: spacing),
                                  padding: EdgeInsets.all(40 * overallRatio),
                                  decoration: BoxDecoration(
                                    color: UserThemeManager.momBackgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Image.asset(
                                          UserThemeManager.momImage,
                                          fit: BoxFit.contain,
                                          width: 130,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 40 * overallRatio,
                                            vertical: 10 * overallRatio,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '오늘의 챌린지',
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'PretendardBold',
                                                        fontSize: 20,
                                                        height: 1.2,
                                                      ),
                                                    ),
                                                    if (_challengeMission !=
                                                            null ||
                                                        !_orderedMissions
                                                            .isEmpty) ...[
                                                      SizedBox(height: 6),
                                                      // ★ 제목과 내용 사이의 적절한 간격
                                                      Text(
                                                        _challengeMission !=
                                                                null
                                                            ? '${_challengeMission!.name} 비우기'
                                                            : '모든 미션을 완료했어요!',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontFamily:
                                                              'PretendardRegular',
                                                          color: Color(
                                                            0xFF5D5D5D,
                                                          ),
                                                          height: 1.0,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              // 텍스트와 버튼 사이 간격
                                              ShortButton(
                                                text: '시작하기',
                                                fontSize: 16,
                                                isYes:
                                                    _challengeMission != null ||
                                                    _orderedMissions.isEmpty,
                                                width: 120,
                                                height: 50,
                                                onPressed:
                                                    (_challengeMission !=
                                                                null ||
                                                            _orderedMissions
                                                                .isEmpty)
                                                        ? () {
                                                          Navigator.pushNamed(
                                                            context,
                                                            '/congestion',
                                                          ).then((_) {
                                                            _loadUserData(
                                                              showLoading:
                                                                  false,
                                                            );
                                                          });
                                                        }
                                                        : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '비움 스케줄',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontFamily: 'PretendardBold',
                                      ),
                                    ),
                                    SizedBox(height: 7 * overallRatio),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFAFBFF),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child:
                                              _orderedMissions.isEmpty
                                                  ? ListView(
                                                    padding: EdgeInsets.zero,
                                                    children:
                                                        _getDummyMissions().map(
                                                          (title) {
                                                            return ScheduleItem(
                                                              title: title,
                                                              time: '',
                                                              isCompleted: true,
                                                            );
                                                          },
                                                        ).toList(),
                                                  )
                                                  : ListView(
                                                    padding: EdgeInsets.zero,
                                                    children:
                                                        _orderedMissions
                                                            .asMap()
                                                            .entries
                                                            .map((entry) {
                                                              int index =
                                                                  entry.key;
                                                              Section mission =
                                                                  entry.value;
                                                              bool isCompleted =
                                                                  index <
                                                                  _currentMissionIndex;

                                                              return ScheduleItem(
                                                                title:
                                                                    mission
                                                                        .name,
                                                                time:
                                                                    _getMissionTime(
                                                                      mission,
                                                                    ),
                                                                isCompleted:
                                                                    isCompleted,
                                                              );
                                                            })
                                                            .toList(),
                                                  ),
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

                        // 하단부: 비움 현황 & 보관 잔여일
                        Expanded(
                          flex: 10,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final totalRightSectionWidth =
                                  constraints.maxWidth * (10 / 28);
                              final singleStorageBoxWidth =
                                  (totalRightSectionWidth - spacing) / 2;
                              final proportionalHeight =
                                  singleStorageBoxWidth * (140 / 146);

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 18,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(
                                            right: spacing,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Text(
                                                '비움 현황',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontFamily: 'PretendardBold',
                                                  height: 2.0,
                                                ),
                                              ),

                                              const Spacer(),
                                              if (_dashboardItems.length > 1 &&
                                                  isFirstFurnitureClear) ...[
                                                InkWell(
                                                  onTap: () {
                                                    if (_currentPage > 0) {
                                                      _pageController
                                                          .previousPage(
                                                            duration:
                                                                const Duration(
                                                                  milliseconds:
                                                                      300,
                                                                ),
                                                            curve:
                                                                Curves.easeOut,
                                                          );
                                                    }
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          4.0,
                                                        ),
                                                    child: SvgPicture.asset(
                                                      'assets/my/left.svg',
                                                      width: 15,
                                                      height: 15,
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 15),

                                                InkWell(
                                                  onTap: () {
                                                    if (_currentPage <
                                                        _dashboardItems.length -
                                                            1) {
                                                      _pageController.nextPage(
                                                        duration:
                                                            const Duration(
                                                              milliseconds: 300,
                                                            ),
                                                        curve: Curves.easeOut,
                                                      );
                                                    }
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          4.0,
                                                        ),
                                                    child: SvgPicture.asset(
                                                      'assets/my/right.svg',
                                                      width: 15,
                                                      height: 15,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 15),
                                              ],
                                            ],
                                          ),
                                        ),

                                        SizedBox(height: 12.0 * overallRatio),
                                        Container(
                                          height: proportionalHeight,
                                          margin: EdgeInsets.only(
                                            right: spacing,
                                          ),
                                          child:
                                              _dashboardItems.isEmpty
                                                  ? Center(
                                                    child: Text("데이터 없음"),
                                                  )
                                                  : Stack(
                                                    children: [
                                                      PageView.builder(
                                                        controller:
                                                            _pageController,
                                                        itemCount:
                                                            _dashboardItems
                                                                .length,
                                                        onPageChanged: (
                                                          int index,
                                                        ) {
                                                          setState(() {
                                                            _currentPage =
                                                                index;
                                                          });
                                                        },
                                                        itemBuilder: (
                                                          context,
                                                          index,
                                                        ) {
                                                          final data =
                                                              _dashboardItems[index];

                                                          return Container(
                                                            padding: EdgeInsets.symmetric(
                                                              horizontal:
                                                                  40 *
                                                                  overallRatio,
                                                              vertical:
                                                                  20 *
                                                                  overallRatio,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Color(
                                                                    0xFFF3F5FF,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                ),
                                                            child: Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .stretch,
                                                              children: [
                                                                Container(
                                                                  width: 100,
                                                                  height: 100,
                                                                  decoration: BoxDecoration(
                                                                    color: const Color(
                                                                      0xFFFAFBFF,
                                                                    ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          6,
                                                                        ),
                                                                  ),
                                                                  child: Padding(
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                          18.0 *
                                                                              overallRatio,
                                                                        ),
                                                                    child: ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            16 *
                                                                                overallRatio,
                                                                          ),
                                                                      child: Image.asset(
                                                                        data['image'],
                                                                        fit:
                                                                            BoxFit.contain,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width:
                                                                      25 *
                                                                      overallRatio,
                                                                ),

                                                                // 텍스트 및 진행률 영역
                                                                Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Text(
                                                                        data['space'],
                                                                        style: const TextStyle(
                                                                          fontSize:
                                                                              18,
                                                                          fontFamily:
                                                                              'PretendardMedium',
                                                                          color: Color(
                                                                            0xFF5D5D5D,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        height:
                                                                            10 *
                                                                            overallRatio,
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        children: [
                                                                          Expanded(
                                                                            child: ClipRRect(
                                                                              borderRadius: BorderRadius.circular(
                                                                                2,
                                                                              ),
                                                                              child: SizedBox(
                                                                                height:
                                                                                    10,
                                                                                child: LinearProgressIndicator(
                                                                                  value:
                                                                                      data['progress'] /
                                                                                      100.0,
                                                                                  backgroundColor: const Color(
                                                                                    0xFFDBDEE7,
                                                                                  ),
                                                                                  valueColor: const AlwaysStoppedAnimation<
                                                                                    Color
                                                                                  >(
                                                                                    Color(
                                                                                      0xFF6AC992,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                13,
                                                                          ),
                                                                          Text(
                                                                            '${data['progress'].round()}%',
                                                                            style: const TextStyle(
                                                                              fontSize:
                                                                                  14,
                                                                              fontFamily:
                                                                                  'PretendardRegular',
                                                                              color: Color(
                                                                                0xFF8D93A1,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                      if (_dashboardItems
                                                              .length >
                                                          1)
                                                        Positioned(
                                                          bottom:
                                                              15 * overallRatio,
                                                          left:
                                                              60 +
                                                              (25 *
                                                                  overallRatio),
                                                          right:
                                                              (40 *
                                                                  overallRatio) +
                                                              spacing,
                                                          child: Center(
                                                            child:
                                                                _buildPageIndicator(),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 오른쪽: 보관 잔여일 (수정된 부분)
                                  Expanded(
                                    flex: 10,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '보관 잔여일',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontFamily: 'PretendardBold',
                                            color: Color(0xFF333333),
                                            height: 2.0,
                                          ),
                                        ),
                                        SizedBox(height: 12.0 * overallRatio),
                                        SizedBox(
                                          height: proportionalHeight,
                                          child:
                                              item1 == null
                                                  ? Container(
                                                    width: double.infinity,
                                                    padding: EdgeInsets.all(
                                                      24 * overallRatio,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFF3F5FF,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '아직 보관된 물품이 없어요.',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontFamily:
                                                                'PretendardRegular',
                                                            color: Color(
                                                              0xFFB0B8C1,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(height: 8),
                                                        Text(
                                                          '버릴까말까 상자에 보관할 물품을 등록해\n보세요.',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontFamily:
                                                                'PretendarRegular',
                                                            color: Color(
                                                              0xFFB0B8C1,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                  : Row(
                                                    children: [
                                                      // ------------------------------------------------
                                                      // [왼쪽 박스 : item1]
                                                      // ------------------------------------------------
                                                      Expanded(
                                                        child: Container(
                                                          margin:
                                                              EdgeInsets.only(
                                                                right:
                                                                    spacing / 2,
                                                              ),
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal:
                                                                    24 *
                                                                    overallRatio,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                item1RemainingDays! <=
                                                                        3
                                                                    ? const Color(
                                                                      0xFFFFF3F3,
                                                                    )
                                                                    : const Color(
                                                                      0xFFF3F5FF,
                                                                    ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                          child:
                                                              item1RemainingDays <=
                                                                      3
                                                                  ? Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Container(
                                                                        padding: const EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              6,
                                                                          vertical:
                                                                              3,
                                                                        ),
                                                                        decoration: BoxDecoration(
                                                                          color: const Color(
                                                                            0xFFFFD7D7,
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                                2,
                                                                              ),
                                                                        ),
                                                                        child: const Text(
                                                                          '임박',
                                                                          style: TextStyle(
                                                                            color: Color(
                                                                              0xFFEC5353,
                                                                            ),
                                                                            fontSize:
                                                                                12,
                                                                            fontFamily:
                                                                                'PretendardMedium',
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        height:
                                                                            5 *
                                                                            overallRatio,
                                                                      ),
                                                                      Text(
                                                                        item1!
                                                                            .name,
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              16,
                                                                          fontFamily:
                                                                              'PretendardMedium',
                                                                          color: const Color(
                                                                            0xFF5D5D5D,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        'D-${item1RemainingDays}',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              32,
                                                                          fontFamily:
                                                                              'PretendardMedium',
                                                                          color: Color(
                                                                            0xFF333333,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  )
                                                                  : Padding(
                                                                    padding: EdgeInsets.only(
                                                                      top:
                                                                          53 *
                                                                          overallRatio,
                                                                    ),
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Text(
                                                                          item1!
                                                                              .name,
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            fontFamily:
                                                                                'PretendardMedium',
                                                                            color: const Color(
                                                                              0xFF5D5D5D,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              5 *
                                                                              overallRatio,
                                                                        ),
                                                                        Text(
                                                                          'D-${item1RemainingDays}',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                32,
                                                                            fontFamily:
                                                                                'PretendardMedium',
                                                                            color: Color(
                                                                              0xFF333333,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                        ),
                                                      ),

                                                      // ------------------------------------------------
                                                      // [오른쪽 박스 : item2]
                                                      // ------------------------------------------------
                                                      Expanded(
                                                        child:
                                                            item2 == null
                                                                ? Container(
                                                                  margin: EdgeInsets.only(
                                                                    right:
                                                                        spacing /
                                                                        2,
                                                                  ),
                                                                )
                                                                : Container(
                                                                  margin: EdgeInsets.only(
                                                                    right:
                                                                        spacing /
                                                                        2,
                                                                  ),
                                                                  padding: EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        24 *
                                                                        overallRatio,
                                                                  ),
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        item2RemainingDays! <=
                                                                                3
                                                                            ? const Color(
                                                                              0xFFFFF3F3,
                                                                            )
                                                                            : const Color(
                                                                              0xFFF3F5FF,
                                                                            ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          10,
                                                                        ),
                                                                  ),
                                                                  child:
                                                                      item2RemainingDays <=
                                                                              3
                                                                          ? Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            children: [
                                                                              Container(
                                                                                padding: const EdgeInsets.symmetric(
                                                                                  horizontal:
                                                                                      6,
                                                                                  vertical:
                                                                                      3,
                                                                                ),
                                                                                decoration: BoxDecoration(
                                                                                  color: const Color(
                                                                                    0xFFFFD7D7,
                                                                                  ),
                                                                                  borderRadius: BorderRadius.circular(
                                                                                    2,
                                                                                  ),
                                                                                ),
                                                                                child: const Text(
                                                                                  '임박',
                                                                                  style: TextStyle(
                                                                                    color: Color(
                                                                                      0xFFEC5353,
                                                                                    ),
                                                                                    fontSize:
                                                                                        12,
                                                                                    fontFamily:
                                                                                        'PretendardMedium',
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              SizedBox(
                                                                                height:
                                                                                    5 *
                                                                                    overallRatio,
                                                                              ),
                                                                              Text(
                                                                                item2!.name,
                                                                                maxLines:
                                                                                    1,
                                                                                overflow:
                                                                                    TextOverflow.ellipsis,
                                                                                style: TextStyle(
                                                                                  fontSize:
                                                                                      16,
                                                                                  fontFamily:
                                                                                      'PretendardMedium',
                                                                                  color: const Color(
                                                                                    0xFF5D5D5D,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                'D-${item2RemainingDays}',
                                                                                style: TextStyle(
                                                                                  fontSize:
                                                                                      32,
                                                                                  fontFamily:
                                                                                      'PretendardMedium',
                                                                                  color: Color(
                                                                                    0xFF333333,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          )
                                                                          : Padding(
                                                                            padding: EdgeInsets.only(
                                                                              top:
                                                                                  53 *
                                                                                  overallRatio,
                                                                            ),
                                                                            child: Column(
                                                                              crossAxisAlignment:
                                                                                  CrossAxisAlignment.start,
                                                                              mainAxisAlignment:
                                                                                  MainAxisAlignment.start,
                                                                              children: [
                                                                                Text(
                                                                                  item2!.name,
                                                                                  maxLines:
                                                                                      1,
                                                                                  overflow:
                                                                                      TextOverflow.ellipsis,
                                                                                  style: TextStyle(
                                                                                    fontSize:
                                                                                        16,
                                                                                    fontFamily:
                                                                                        'PretendardMedium',
                                                                                    color: const Color(
                                                                                      0xFF5D5D5D,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                SizedBox(
                                                                                  height:
                                                                                      5 *
                                                                                      overallRatio,
                                                                                ),
                                                                                Text(
                                                                                  'D-${item2RemainingDays}',
                                                                                  style: TextStyle(
                                                                                    fontSize:
                                                                                        32,
                                                                                    fontFamily:
                                                                                        'PretendardMedium',
                                                                                    color: Color(
                                                                                      0xFF333333,
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
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20 * overallRatio),
                ],
              ),
            ),
          ),

          // 알림 배너 (Overlay)
          if (_impendingItems.isNotEmpty)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              top: _showOverlayBanner ? 0 : -200,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_showOverlayBanner,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 10.0,
                    ),
                    child: DDayBanner(
                      item: _impendingItems.first,
                      space: _userSpace,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 0,
        onItemTapped: (index) {
          if (index == 0) {
          } else if (index == 1) {
            Navigator.pushNamed(context, '/congestion');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/my');
          }
        },
      ),
    );
  }
}
