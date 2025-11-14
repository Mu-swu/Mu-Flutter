
import 'package:flutter/material.dart';
import 'package:mu/space_start.dart';
import 'package:mu/widgets/shortbutton.dart';
import 'package:mu/mission_start.dart';
// import 'package:mu/EmptyingSchedulePage.dart';

Future<void> showMissionCompleteDialog({
  required BuildContext context,
  required bool allMissionsCompleted,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {

      return LayoutBuilder(
        builder: (context, constraints) {
          final double dialogWidth = 543;
          final double dialogHeight = 384;
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: dialogWidth,
                height: dialogHeight,
                padding: const EdgeInsets.all(50),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '비움 미션 완료',
                      style: TextStyle(fontSize: 32, fontFamily: 'PretendardBold',color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "비움 미션을 완료했어요!\n다음 미션을 바로 진행할 수 있어요.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20,fontFamily: 'PretendardRegular',color: Color(0xFF5D5D5D)),
                    ),
                    const SizedBox(height: 100),

                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ShortButton(
                            text: "미션 화면으로 가기",
                            isYes: false,
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const SpaceStartScreen(),
                                ),
                              );
                            },
                            width: 185,
                            height: 52,
                            fontSize: 16,
                          ),
                          ShortButton(
                            text: "다음 미션 진행하기",
                            isYes: true,
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              if (allMissionsCompleted) {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              } else {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const MissionStartPage(),
                                  ),
                                );
                              }
                            },
                            width: 185,
                            height: 52,
                            fontSize: 16,
                          ),
                        ],
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