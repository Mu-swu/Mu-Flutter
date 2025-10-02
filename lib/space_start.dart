import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add this import for kIsWeb
import 'package:mu/widgets/navigationbar.dart'; // Import your BottomNavBar
import 'package:mu/congestion_analysis_page.dart'; // Import the destination page

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
    // 1280x800 화면 비율 기준
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 1280;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        width: 300 * scaleFactor,
        height: 324 * scaleFactor,
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
            // Column을 전체 카드 너비로 확장
            SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center, // 가로 중앙
                children: [
                  SizedBox(height: 70 * scaleFactor), // 카드 상단 여백
                  // 이미지 흰색 상자
                  Container(
                    width: 110 * scaleFactor,
                    height: 110 * scaleFactor,
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
                  SizedBox(height: 24 * scaleFactor), // 이미지와 텍스트 간격
                  // 텍스트
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
            // 잠금 상태 오버레이
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
  // Use a nullable int to avoid issues with initial index on web/desktop
  int? _selectedIndex;

  // Function to determine the initial index based on the current route
  int _getInitialIndex() {
    final route = ModalRoute.of(context)?.settings.name;
    if (route == '/') return 0;
    if (route == '/congestion') return 1;
    if (route == '/my') return 2;
    return 1; // Default to '미션' if the route is unknown
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only set the initial index once
    if (_selectedIndex == null) {
      _selectedIndex = _getInitialIndex();
    }
  }

  // The method to handle navigation bar taps
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushNamed(context, '/'); // Home
    } else if (index == 1) {
      Navigator.pushNamed(context, '/congestion'); // Mission
    } else if (index == 2) {
      Navigator.pushNamed(context, '/my'); // My Page
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 1280;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 163 * scaleFactor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 64 * scaleFactor),
                  Text(
                    '미션',
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontSize: 28 * scaleFactor,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 146 * scaleFactor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SpaceUnitCard(
                        title: '냉장고',
                        imagePath: 'assets/home/refr.png',
                        isLocked: false,
                        onTap: () {
                          // Correctly navigate to the congestion analysis page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CongestionAnalysisLayout(),
                            ),
                          );
                        },
                      ),
                      SpaceUnitCard(
                        title: '서랍장',
                        imagePath: 'assets/home/refr.png', // Replace with drawer image
                        isLocked: true,
                        onTap: () {
                          // This will not be called because isLocked is true
                        },
                      ),
                      SpaceUnitCard(
                        title: '옷장',
                        imagePath: 'assets/home/refr.png', // Replace with closet image
                        isLocked: true,
                        onTap: () {
                          // This will not be called because isLocked is true
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex ?? 1, // Default to 1 if not set
        onItemTapped: _onItemTapped,
      ),
    );
  }
}