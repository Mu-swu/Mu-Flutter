import 'package:flutter/material.dart';
import 'package:mu/widgets/navigationbar.dart';
import 'package:mu/congestion_analysis_page.dart';
import 'package:mu/data/database.dart';

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

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        width: 300 * scaleFactor,
        height: 330 * scaleFactor,
        decoration: BoxDecoration(
          color: isLocked ? const Color(0xFFF5F5F5) : const Color(0xFFE9F0FC),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
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
                    width: 110 * scaleFactor,
                    height: 130 * scaleFactor,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Image.asset(
                        imagePath,
                        width: 120 * scaleFactor,
                        height: 120 * scaleFactor,
                      ),
                    ),
                  ),
                  SizedBox(height: 24 * scaleFactor),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF5C5C5C),
                      fontSize: 24 * scaleFactor,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0x4C8D93A1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lock_rounded,
                      size: 100 * scaleFactor,
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

class SpaceStartScreen extends StatefulWidget {
  const SpaceStartScreen({super.key});

  @override
  State<SpaceStartScreen> createState() => _SpaceStartScreenState();
}

class _SpaceStartScreenState extends State<SpaceStartScreen> {
  int? _selectedIndex;
  bool _isLoading = true;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    try {
      final db = AppDatabase.instance;
      const userId = 1;
      final userType = await db.getUserType(userId);

      if (mounted) {
        setState(() {
          _userType = userType ?? '방치형';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("사용자 유형 불러오기 에러 : $e");
      if (mounted) {
        setState(() {
          _userType = "방치형";
          _isLoading = false;
        });
      }
    }
  }

  List<Widget> _buildSpaceCards() {
    switch (_userType) {
      case '방치형':
        return [
          SpaceUnitCard(
            title: '냉장고',
            imagePath: 'assets/home/refr.png',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CongestionAnalysisLayout()),
              );
            },
          ),
          const SpaceUnitCard(title: '서랍장', imagePath: 'assets/home/drawer.png', isLocked: true),
          const SpaceUnitCard(title: '옷장', imagePath: 'assets/home/closet.png', isLocked: true),
        ];
      case '감정형':
        return [
          SpaceUnitCard(
            title: '옷장',
            imagePath: 'assets/home/closet.png',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CongestionAnalysisLayout()),
              );
            },
          ),
          const SpaceUnitCard(title: '냉장고', imagePath: 'assets/home/refr.png', isLocked: true),
          const SpaceUnitCard(title: '서랍장', imagePath: 'assets/home/drawer.png', isLocked: true),
        ];
      case '몰라형':
      default:
        return [
          SpaceUnitCard(
            title: '서랍장',
            imagePath: 'assets/home/drawer.png',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CongestionAnalysisLayout()),
              );
            },
          ),
          const SpaceUnitCard(title: '냉장고', imagePath: 'assets/home/refr.png', isLocked: true),
          const SpaceUnitCard(title: '옷장', imagePath: 'assets/home/closet.png', isLocked: true),
        ];
    }
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
                      fontSize: 28 * scaleFactor,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 150 * scaleFactor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: spaceCards,
                  ),
                ],
              ),
            ),
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