import 'package:flutter/material.dart';
import 'keepbox.dart';
import 'widgets/shortbutton.dart';

class Keepbox_start extends StatelessWidget {
  const Keepbox_start({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 1280.0;
    const baseHeight = 800.0;

    final scale = (screenWidth / baseWidth).clamp(0.8, 1.3);
    final widthRatio = scale;
    final heightRatio = (screenHeight / baseHeight).clamp(0.8, 1.3);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Container(
            width: screenWidth,
            height: screenHeight,
            padding: EdgeInsets.all(24 * widthRatio),
            color: Colors.white,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, size: 28 * widthRatio),
                  ),
                ),
                SizedBox(height: 16 * heightRatio),

                Text(
                  '못 버린 물건이 있나요?\n 버릴까 말까 상자에 잠시 보관하세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30 * widthRatio,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20 * heightRatio),

                Expanded(
                  child: Image.asset(
                    'assets/box.jpg',
                    width: 400 * widthRatio,
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: 10 * heightRatio),

                Container(
                  width: screenWidth * 0.7,
                  padding: EdgeInsets.symmetric(
                    vertical: 24 * heightRatio,
                    horizontal: 20 * widthRatio,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5FF),
                    borderRadius: BorderRadius.circular(10 * widthRatio),
                  ),
                  child: Text(
                    '버리지 못한 물건이 있다면 \n‘버릴까 말까 상자’로 이동하여 일정 기간 동안 물건을 보관해드려요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16 * widthRatio,
                      color: const Color(0xFF5C5C5C),
                    ),
                  ),
                ),

                SizedBox(height: 40 * heightRatio),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShortButton(
                      text: '종료하기',
                      isYes: false,
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      },
                    ),
                    SizedBox(width: 80 * widthRatio),
                    ShortButton(
                      text: '이동하기',
                      isYes: true,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const keepbox(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20 * heightRatio),
              ],
            ),
          ),
        ),
      ),
    );
  }
}