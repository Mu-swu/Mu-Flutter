// mission_start.dart
import 'package:flutter/material.dart';
import 'widgets/custom_tag.dart';
import 'widgets/shortbutton.dart';

class MissionStartPage extends StatelessWidget {
  const MissionStartPage({super.key});

  // AI 응답으로 대체될 문장 변수
  final String aiSentenceLeft = '오늘까지 싹 치워!\n안 그러면 내가 다 버린다.';
  final String aiSentenceRight = '네 물건 때문에 발 디딜 틈도 없겠다!\n그러고도 사람이 사니?';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 기준 해상도 (디자인 기준)
    const baseWidth = 1280.0;
    const baseHeight = 800.0;

    // 확대 비율 계산 (비율 유지하며 살짝 확대)
    final scale = (screenWidth / baseWidth).clamp(1.0, 1.3);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: SizedBox(
            width: baseWidth,
            height: baseHeight,
            child: Stack(
              children: [
                // 배경
                Container(
                  width: baseWidth,
                  height: baseHeight,
                  color: Colors.white,
                ),

                // "시작하기" 버튼
                Positioned(
                  left: 653,
                  top: 653,
                  child: ShortButton(
                    text: '시작하기',
                    isYes: true, // 파란색
                    onPressed: () {
                      Navigator.pushNamed(context, '/mission');
                    },
                  ),
                ),

                // "건너뛰기" 버튼
                Positioned(
                  left: 162,
                  top: 653,
                  child: ShortButton(
                    text: '건너뛰기',
                    isYes: false, // 흰색
                    onPressed: () {
                      // 건너뛰기 로직
                    },
                  ),
                ),

                // 미션 제목
                Positioned(
                  left: 506,
                  top: 159,
                  child: Text(
                    '냉장실 한 칸 비우기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 36,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // 방치형 태그
                Positioned(
                  left: 607,
                  top: 117,
                  child: CustomTag(
                    label: '방치형',
                    type: TagType.bang, // 방치형 → bang
                  ),
                ),

                Center(
                  child: SizedBox(
                    width: 1000,
                    height: 350,
                    child: Image.asset(
                      'assets/still.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}