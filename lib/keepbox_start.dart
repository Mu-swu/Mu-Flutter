import 'package:flutter/material.dart';
import 'keepbox.dart';

class Keepbox_start extends StatefulWidget {
  const Keepbox_start({super.key});

  @override
  State<Keepbox_start> createState() => _Keepbox_startState();
}

class _Keepbox_startState extends State<Keepbox_start> {
  bool _isTtsEnabled = true;

  void _toggleTts() {
    setState(() {
      _isTtsEnabled = !_isTtsEnabled;
    });
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final widthRatio = screenWidth / 1280;
    final heightRatio = screenHeight / 832;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Container(
            width: screenWidth , // 전체의 80%
            height: screenHeight , // 전체의 90%
            padding: EdgeInsets.all(24 * widthRatio),
            decoration: BoxDecoration(
              //border: Border.all(color: const Color(0xFFE0E0E0)),
              //borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    // 사운드 버튼
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: _toggleTts,
                        icon: Icon(
                          _isTtsEnabled ? Icons.volume_up : Icons.volume_off,
                          size: 28 * widthRatio,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: 16 * heightRatio),

                    // 제목
                    Text(
                      '못 버린 물건이 있나요?',
                      style: TextStyle(
                        fontSize: 30 * widthRatio,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20 * heightRatio),

                    // 이미지 (기존 크기의 1.3배)
                    Image.asset(
                      'assets/box.jpg',
                      width: 400 * widthRatio,
                      height: 300 * heightRatio,
                      fit: BoxFit.contain,
                    ),

                    SizedBox(height: 32 * heightRatio),

                    // 설명 박스
                    Container(
                      width: screenWidth * 0.7,
                      padding: EdgeInsets.symmetric(
                        vertical: 24 * heightRatio,
                        horizontal: 20 * widthRatio,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '버리지 못한 물건이 있다면 ‘버릴까 말까 상자’로 이동하여 일정 기간 동안 물건을 보관해드려요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16 * widthRatio,
                          color: const Color(0xFF5C5C5C),
                        ),
                      ),
                    ),

                    SizedBox(height: 40 * heightRatio),

                    // 버튼 2개
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 종료하기
                        _actionButton(
                          text: '종료하기',
                          backgroundColor: const Color(0xFFFBFCFF),
                          textColor: const Color(0xFF333333),
                          onTap: () {
                            Navigator.pop(context);
                          },
                          widthRatio: widthRatio,
                          heightRatio: heightRatio,
                        ),

                        // 이동하기
                        _actionButton(
                          text: '이동하기',
                          backgroundColor: const Color(0xFF333333),
                          textColor: Colors.white,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const keepbox(),
                              ),
                            );
                          },
                          widthRatio: widthRatio,
                          heightRatio: heightRatio,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
    required double widthRatio,
    required double heightRatio,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 400 * widthRatio,
        height: 64 * heightRatio,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8 * widthRatio),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 18 * widthRatio,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}