import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mu/data/database.dart';
import 'package:mu/my_page.dart';
import 'MissionStepPage.dart';
import 'surveyq.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'space_start.dart';
import 'InventoryPage.dart';
import 'widgets/navigationbar.dart';
import 'widgets/shortbutton.dart';
import 'widgets/schedule_item.dart';
import 'mission_start.dart';
import 'keepbox.dart';
import 'user_theme_manager.dart'; // Import the new file
import 'package:mu/data/sampledata.dart';
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
      initialRoute: '/inven',
      routes: {
        '/': (context) => const FigmaHomePage(),
        '/surveyq': (context) => const SurveyPage(),
        '/congestion': (context) => SpaceStartScreen(),
        '/my': (context) => const MyPage(),
        '/keepbox': (context) => const keepbox(),
        '/inven': (context) => const InventoryPage(),
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
  List<KeepBox> _urgentItems = [];

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
      UserThemeManager.currentUserType = loadedType;
      _urgentItems = await _database.getTopTowUrgentItems();
    } catch (e) {
      print("사용자 데이터 로드 실패 : $e");
      UserThemeManager.currentUserType = UserType.bang;
      _urgentItems = [];
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 이 함수는 State 클래스 내부에 정의되어야 합니다.
  void _showKeepBoxDialog(BuildContext context) {

    Map<String, int>? _editingItem;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: EdgeInsets.zero,
              // 🚀 Dialog 모서리를 둥글게 만듭니다.
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // 👈 모서리 둥글게
              ),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20), // 👈 Container 모서리도 둥글게 (Dialog shape와 일치)
                ),
                // 🚀 내부 콘텐츠 좌우 여백을 80px로 증가
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- 헤더 (제목 및 닫기 버튼) ---
                      Padding(
                        padding: const EdgeInsets.only(top: 30, bottom: 10), // 상단 여백 증가
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 40), // 좌측 여백 증가
                            const Text(
                              '버릴까말까 상자 목록',
                              style: TextStyle(
                                fontSize: 22, // 👈 글자 크기 키움
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 28), // 닫기 버튼 아이콘 크기 키움
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),

                      // --- 카테고리별 목록 (스크롤 가능) ---
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20), // 상하 여백 증가
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                double availableWidth = constraints.maxWidth;
                                double itemWidth = (availableWidth - 20) / 2; // 카테고리 간격 20px 반영

                                return Wrap(
                                  spacing: 20, // 카테고리 간 가로 간격 증가
                                  runSpacing: 20, // 카테고리 간 세로 간격 증가
                                  children: sampleCategories.map((category) {
                                    int categoryIndex = sampleCategories.indexOf(category);

                                    return SizedBox(
                                      width: itemWidth.clamp(120.0, double.infinity), // 최소 너비 증가
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // 카테고리 헤더
                                          Row(
                                            children: [
                                              Text(
                                                category['name'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18, // 👈 글자 크기 키움
                                                  color: Color(0xFF333333),
                                                ),
                                              ),
                                              const Icon(Icons.add, size: 20, color: Color(0xFF8D93A1)), // 아이콘 크기 키움
                                            ],
                                          ),
                                          const SizedBox(height: 12), // 간격 증가

                                          // 카테고리 항목 리스트
                                          ...category['items'].asMap().entries.map((entry) {
                                            int itemIndex = entry.key;
                                            var item = entry.value;

                                            String dateString = item['startDate'] ?? '';
                                            String formattedDate = '';
                                            try {
                                              List<String> parts = dateString.split('.');
                                              if (parts.length >= 3) {
                                                formattedDate = '${parts[1].padLeft(2, '0')}월 ${parts[2].padLeft(2, '0')}일';
                                              }
                                            } catch (_) {
                                              formattedDate = dateString;
                                            }

                                            bool isEditing = _editingItem?['categoryIndex'] == categoryIndex &&
                                                _editingItem?['itemIndex'] == itemIndex;

                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 10.0), // 하단 여백 증가
                                              child: Stack(
                                                children: [
                                                  // 실제 아이템 카드
                                                  GestureDetector(
                                                    onTap: () {
                                                      if (isEditing) {
                                                        setState(() => _editingItem = null);
                                                      }
                                                    },
                                                    onLongPress: () {
                                                      setState(() {
                                                        _editingItem = isEditing
                                                            ? null
                                                            : {'categoryIndex': categoryIndex, 'itemIndex': itemIndex};
                                                      });
                                                    },
                                                    child: Container(
                                                      width: double.infinity,
                                                      padding: const EdgeInsets.all(15), // 패딩 증가
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF3F5FF),
                                                        borderRadius: BorderRadius.circular(10), // 아이템 모서리 둥글게
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Text(item['name'], style: const TextStyle(fontSize: 17, color: Color(0xFF333333))), // 👈 글자 크기 키움
                                                              IconButton(
                                                                icon: const Icon(Icons.more_vert, size: 24, color: Color(0xFF8D93A1)), // 아이콘 크기 키움
                                                                onPressed: () {
                                                                  setState(() {
                                                                    _editingItem = isEditing
                                                                        ? null
                                                                        : {'categoryIndex': categoryIndex, 'itemIndex': itemIndex};
                                                                  });
                                                                },
                                                                padding: EdgeInsets.zero,
                                                                constraints: const BoxConstraints(),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 4), // 간격 증가
                                                          Text(
                                                            formattedDate,
                                                            style: TextStyle(
                                                              fontSize: 14, // 👈 글자 크기 키움
                                                              color: Colors.grey.shade600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),

                                                  // 편집/삭제 메뉴 (두 줄로, 아이콘 포함)
                                                  if (isEditing)
                                                    Positioned(
                                                      top: 0,
                                                      bottom: 0,
                                                      right: 5,
                                                      child: Container(
                                                        width: 130, // 메뉴 너비 증가
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(8), // 메뉴 모서리 둥글게
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black.withOpacity(0.1),
                                                              blurRadius: 6,
                                                              offset: const Offset(0, 3),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                                          children: [
                                                            _buildMenuButton('수정하기', Icons.edit, () { setState(() => _editingItem = null); }),
                                                            const Divider(height: 1, thickness: 1, color: Color(0xFFF3F5FF)),
                                                            _buildMenuButton('삭제하기', Icons.delete, () { setState(() => _editingItem = null); }),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

// 2. _buildMenuButton 함수 (State 클래스 내부에 별도로 정의)
  Widget _buildMenuButton(String text, IconData icon, VoidCallback onPressed) {
    const Color textColor = Color(0xFF333333); // ✅ 진한 회색

    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(fontSize: 14, color: textColor),
            ),
          ],
        ),
      ),
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
    final today=DateTime(now.year,now.month,now.day);
    final item1ExpirationDate = item1 != null
        ? DateTime(item1.expirationAt.year, item1.expirationAt.month,
        item1.expirationAt.day)
        : null;

    final item2ExpirationDate = item2 != null
        ? DateTime(item2.expirationAt.year, item2.expirationAt.month,
        item2.expirationAt.day)
        : null;

    final item1RemainingDays = item1ExpirationDate?.difference(today).inDays;
    final item2RemainingDays = item2ExpirationDate?.difference(today).inDays;

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
                      // 🚀 버튼을 누르면 화면 전환 대신 다이얼로그를 띄웁니다.
                      _showKeepBoxDialog(context);
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
                                                  UserThemeManager
                                                              .currentUserType ==
                                                          UserType.gam
                                                      ? '냉장실 상단 비우기'
                                                      : (UserThemeManager
                                                                  .currentUserType ==
                                                              UserType.mol
                                                          ? '서랍장 2단 비우기'
                                                          : '옷장 서랍 비우기'),
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
                                        children: [
                                          ScheduleItem(
                                            title:
                                                UserThemeManager
                                                            .currentUserType ==
                                                        UserType.mol
                                                    ? '2단'
                                                    : (UserThemeManager
                                                                .currentUserType ==
                                                            UserType.gam
                                                        ? '서랍'
                                                        : '냉장실 한 칸'),
                                            time: '45분',
                                            isCompleted: false,
                                          ),
                                          ScheduleItem(
                                            title:
                                                UserThemeManager
                                                            .currentUserType ==
                                                        UserType.mol
                                                    ? '3단'
                                                    : (UserThemeManager
                                                                .currentUserType ==
                                                            UserType.gam
                                                        ? '행거 구역'
                                                        : '얼음/얼린 식재료 칸'),
                                            time: '1시간',
                                            isCompleted: false,
                                          ),
                                          ScheduleItem(
                                            title:
                                                UserThemeManager
                                                            .currentUserType ==
                                                        UserType.mol
                                                    ? '1단'
                                                    : (UserThemeManager
                                                                .currentUserType ==
                                                            UserType.gam
                                                        ? '옷장 바닥 공간'
                                                        : '냉동식품 칸'),
                                            time: '30분',
                                            isCompleted: true,
                                          ),
                                          ScheduleItem(
                                            title:
                                                UserThemeManager
                                                            .currentUserType ==
                                                        UserType.mol
                                                    ? '보조 포켓'
                                                    : (UserThemeManager
                                                                .currentUserType ==
                                                            UserType.gam
                                                        ? '보조 포켓'
                                                        : '냉장실 포켓'),
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
                                                  UserThemeManager
                                                              .currentUserType ==
                                                          UserType.mol
                                                      ? '서랍'
                                                      : (UserThemeManager
                                                                  .currentUserType ==
                                                              UserType.gam
                                                          ? '옷장'
                                                          : '냉장고'),
                                                  style: TextStyle(
                                                    fontSize: 20 * overallRatio,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 40 * overallRatio,
                                                ),
                                                // 👇 요청하신 'LinearProgressIndicator'와 '30%' 텍스트를 포함하는 Row가 이 자리에 들어갑니다.
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
                                                    SizedBox(width: 10),
                                                    // 진행바와 텍스트 사이 간격
                                                    const Text(
                                                      '30%',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        // 적절한 크기로 설정
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                                  item1 != null &&
                                                          item1RemainingDays !=
                                                              null
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
                                                            item1.name,
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
                                                            'D-${item1RemainingDays}',
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
                                                  item2 != null &&
                                                          item2RemainingDays !=
                                                              null
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
                                                              item2.name,
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
                                                              'D-${item2RemainingDays}',
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
