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

  @override
  void initState() {
    super.initState();
    _loadProgress();
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
