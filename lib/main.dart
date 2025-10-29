import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mu/data/database.dart';
import 'package:mu/my_page.dart';
import 'MissionStepPage.dart';
import 'surveyq.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'space_start.dart';
import 'widgets/navigationbar.dart';
import 'widgets/shortbutton.dart';
import 'widgets/schedule_item.dart';
import 'mission_start.dart';
import 'keepbox.dart';
import 'package:mu/data/sampledata.dart';
import 'user_theme_manager.dart'; // Import the new file
import 'package:mu/data/database.dart';

// You should create this file separately: user_theme_manager.dart
// I've included the content of this new file in the response for your convenience.

int calculateRemainingDays(String endDateString) {
  final now = DateTime.now();
  final endDateParts = endDateString.split('.');
  final endDate = DateTime(
    int.parse(endDateParts[0]),
    int.parse(endDateParts[1]),
    int.parse(endDateParts[2]),
  );
  return endDate.difference(now).inDays;
}

// CustomTag 위젯 (요청에 따라 색상과 크기 수정)
// 기존 TagType enum은 UserThemeManager.currentUserType에 맞게 사용합니다.
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
        '/surveyq': (context) => const SurveyPage(),
        '/congestion': (context) => SpaceStartScreen(),
        '/my': (context) => const MyPage(),
        '/keepbox': (context) => const keepbox(),
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
  final AppDatabase _database = AppDatabase.instance;
  bool _isLoading = true;

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
      await _database.getOrCreateUser(1);
      final String? userTypeString = await _database.getUserType(1);

      UserType loadedType;
      switch (userTypeString) {
        case '감정형':
          loadedType = UserType.gam;
          break;
        case '몰라형':
          loadedType = UserType.mol;
          break;
        case '방치형':
          loadedType = UserType.bang;
          break;
        default:
          loadedType = UserType.bang;
      }
      UserThemeManager.currentUserType = loadedType; // 👈 3. 새 타입 적용
    } catch (e) {
      print("사용자 데이터 로드 실패 : $e");
      UserThemeManager.currentUserType = UserType.bang;
    }

    // 4. 데이터 로드가 끝나면,
    //    로딩 중이었으면 false로 바꾸고, 아니었어도 setState로 화면을 갱신!
    setState(() {
      _isLoading = false;
    });
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

    final allItemsWithRemainingDays =
        sampleCategories
            .expand((category) => (category['items'] as List<dynamic>))
            .where((item) => item['endDate'] != null)
            .map((item) {
              final remainingDays = calculateRemainingDays(
                item['endDate'] as String,
              );
              return {...item, 'remainingDays': remainingDays};
            })
            .toList();

    allItemsWithRemainingDays.sort(
      (a, b) => a['remainingDays'].compareTo(b['remainingDays']),
    );

    final topTwoItems = allItemsWithRemainingDays.take(2).toList();
    final item1 = topTwoItems.isNotEmpty ? topTwoItems[0] : null;
    final item2 = topTwoItems.length > 1 ? topTwoItems[1] : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/surveyq').then((_) {
                        _loadUserData(showLoading: false);
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(12 * overallRatio),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F0FC),
                        borderRadius: BorderRadius.circular(12 * overallRatio),
                      ),
                      child: Image.asset(
                        UserThemeManager.retestImage, // Dynamic image
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
                        label: UserThemeManager.tagLabel, // Dynamic tag label
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
                        UserThemeManager.userTitle, // Dynamic user title
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
                      Navigator.pushNamed(context, '/keepbox');
                    },
                    child: Container(
                      padding: EdgeInsets.all(12 * overallRatio),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F0FC),
                        borderRadius: BorderRadius.circular(12 * overallRatio),
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
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      flex: 13,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 18,
                            child: Container(
                              margin: EdgeInsets.only(right: spacing),
                              padding: EdgeInsets.all(20 * overallRatio),
                              decoration: BoxDecoration(
                                color: UserThemeManager.momBackgroundColor,
                                // Dynamic background color
                                borderRadius: BorderRadius.circular(
                                  24 * overallRatio,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Image.asset(
                                      UserThemeManager.momImage,
                                      // Dynamic image
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20 * overallRatio,
                                        vertical: 10 * overallRatio,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          16 * overallRatio,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: 10 * overallRatio,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '오늘의 챌린지',
                                                  style: TextStyle(
                                                    fontSize: 20 * overallRatio,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '냉장실 상단 비우기',
                                                  style: TextStyle(
                                                    fontSize: 16 * overallRatio,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ShortButton(
                                            text: '시작하기',
                                            isYes: true,
                                            width: 100 * overallRatio,
                                            height: 40 * overallRatio,
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/mission_start',
                                              );
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
                          Expanded(
                            flex: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '비움 스케줄',
                                  style: TextStyle(
                                    fontSize: 20 * overallRatio,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5 * overallRatio),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F5FF),
                                      borderRadius: BorderRadius.circular(
                                        24 * overallRatio,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        24 * overallRatio,
                                      ),
                                      child: ListView(
                                        padding: EdgeInsets.zero,
                                        children: const [
                                          ScheduleItem(
                                            title: '냉장실 한 칸',
                                            time: '45분',
                                            isCompleted: false,
                                          ),
                                          ScheduleItem(
                                            title: '얼음/얼린 식재료 칸',
                                            time: '1시간',
                                            isCompleted: false,
                                          ),
                                          ScheduleItem(
                                            title: '냉동식품 칸',
                                            time: '30분',
                                            isCompleted: true,
                                          ),
                                          ScheduleItem(
                                            title: '냉장실 포켓',
                                            time: '30분',
                                            isCompleted: true,
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
                    SizedBox(height: spacing),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '비움 현황',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: spacing / 4),
                                    Container(
                                      height: proportionalHeight,
                                      margin: EdgeInsets.only(right: spacing),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 40 * overallRatio,
                                        vertical: 20 * overallRatio,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F5FF),
                                        borderRadius: BorderRadius.circular(
                                          24 * overallRatio,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Container(
                                            width: 120 * overallRatio,
                                            height: 120 * overallRatio,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    12 * overallRatio,
                                                  ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(
                                                18.0 * overallRatio,
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      16 * overallRatio,
                                                    ),
                                                child: Image.asset(
                                                  UserThemeManager.statusImage,
                                                  // Dynamic image
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 40 * overallRatio),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '냉장고',
                                                  style: TextStyle(
                                                    fontSize: 20 * overallRatio,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 40 * overallRatio,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                        // Adjust to match desired corner radius
                                                        child: SizedBox(
                                                          height: 20,
                                                          // Set a fixed height for the progress bar
                                                          child: LinearProgressIndicator(
                                                            value: 0.3,
                                                            // 30% progress
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[300],
                                                            // Gray background
                                                            valueColor:
                                                                const AlwaysStoppedAnimation<
                                                                  Color
                                                                >(
                                                                  Color(
                                                                    0xFF6AC992,
                                                                  ), // Green fill color
                                                                ),
                                                          ),
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
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '보관 잔여일',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: spacing / 4),
                                    SizedBox(
                                      height: proportionalHeight,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              margin: EdgeInsets.only(
                                                right: spacing / 2,
                                              ),
                                              padding: EdgeInsets.all(
                                                20 * overallRatio,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFF3F3),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      24 * overallRatio,
                                                    ),
                                              ),
                                              child:
                                                  item1 != null
                                                      ? Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  const Color(
                                                                    0xFFFFE0E0,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                            child: const Text(
                                                              '임박',
                                                              style: TextStyle(
                                                                color: Color(
                                                                  0xFFE60000,
                                                                ),
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                10 *
                                                                overallRatio,
                                                          ),
                                                          Text(
                                                            item1['name']
                                                                as String,
                                                            style: TextStyle(
                                                              fontSize:
                                                                  20 *
                                                                  overallRatio,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  const Color(
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
                                                            'D-${item1['remainingDays']}',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  30 *
                                                                  overallRatio,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                      : const Center(
                                                        child: Text('데이터 없음'),
                                                      ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              margin: EdgeInsets.only(
                                                left: spacing / 2,
                                              ),
                                              padding: EdgeInsets.all(
                                                20 * overallRatio,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF3F5FF),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      24 * overallRatio,
                                                    ),
                                              ),
                                              child:
                                                  item2 != null
                                                      ? Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              top:
                                                                  34 *
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
                                                              item2['name']
                                                                  as String,
                                                              style: TextStyle(
                                                                fontSize:
                                                                    20 *
                                                                    overallRatio,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    const Color(
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
                                                              'D-${item2['remainingDays']}',
                                                              style: TextStyle(
                                                                fontSize:
                                                                    30 *
                                                                    overallRatio,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors
                                                                        .black,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                      : const Center(
                                                        child: Text('데이터 없음'),
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
