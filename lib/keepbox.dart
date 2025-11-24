import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:mu/widgets/keepdialogs.dart';
import 'package:mu/widgets/longbutton.dart';
import 'package:mu/widgets/mission_complete_dialog.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'mission_start.dart';
import 'widgets/ItemSaveSection.dart';
import 'user_theme_manager.dart';
import 'package:mu/data/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:mu/notification_service.dart';

// 사용자 유형별 스타일 정의
class TutorialStyle {
  final Color balloonColor;
  final Color arrowColor;
  final String imagePath;
  final List<String> texts;

  const TutorialStyle({
    required this.balloonColor,
    required this.arrowColor,
    required this.imagePath,
    required this.texts,
  });
}

// 스타일 맵
const Map<String, TutorialStyle> tutorialStyles = {
  '방치형': TutorialStyle(
    balloonColor: Color(0xFFFBF4FF),
    arrowColor: Color(0xFFDB84EF),
    imagePath: 'assets/home/mom_bang.png',
    texts: [
      '작은 물건부터 분류하면, 큰 물건은 쉬워져! 기준을 배우기 딱 좋은 공간이야.',
      '보관할 물건이 없다면 완료 버튼을 눌러 비움 미션을 마칠 수 있어.',
    ],
  ),
  '감정형': TutorialStyle(
    balloonColor: Color(0xFFFFF6EF),
    arrowColor: Color(0xFFFFB172),
    imagePath: 'assets/home/mom_gam.png',
    texts: [
      '작은 물건부터 분류하면, 큰 물건은 쉬워져! 기준을 배우기 딱 좋은 공간이야.',
      '보관할 물건이 없다면 완료 버튼을 눌러 비움 미션을 마칠 수 있어.',
    ],
  ),
  '몰라형': TutorialStyle(
    balloonColor: Color(0xFFF3FBF0),
    arrowColor: Color(0xFFA1C68D),
    imagePath: 'assets/home/mom_mol.png',
    texts: [
      '작은 물건부터 분류하면, 큰 물건은 쉬워져! 기준을 배우기 딱 좋은 공간이야.',
      '보관할 물건이 없다면 완료 버튼을 눌러 비움 미션을 마칠 수 있어.',
    ],
  ),
};

// 왼쪽 마이크 영역 (Positioned.fill)
const Rect LEFT_MIC_AREA = Rect.fromLTWH(0, 0, 0.15, 1.0); // widthRatio * 0.15

// 오른쪽 상자 본체 (ItemSaveSection) 영역
// (37 + 50 + 20) / screenHeight 만큼 상단 여백 (약 107px)
// ItemSaveSection은 오른쪽 85% 영역 전체를 Expanded(child: ItemSaveSection)로 사용합니다.
const double RIGHT_CONTENT_START_Y_RATIO = 107 / 832; // 대략적인 비율
const Rect RIGHT_CONTENT_AREA = Rect.fromLTWH(0.15, 0.13, 0.85, 0.65); // 대략적인 위치

// 저장 버튼 영역 (LongButton)
const Rect SAVE_BUTTON_AREA = Rect.fromLTWH(0.15, 0.88, 0.85, 0.12); // 대략적인 위치
class keepbox extends StatefulWidget {
  final int? nextMissionIndex;
  final int? totalMissionCount;

  const keepbox({super.key, this.nextMissionIndex, this.totalMissionCount});

  @override
  State<keepbox> createState() => _keepboxState();
}

class MaskingPainter extends CustomPainter {
  final Rect? cutoutRect;

  MaskingPainter({this.cutoutRect});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 어둡고 투명한 배경 색상
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // 2. 전체 화면을 어둡게 칠합니다.
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    if (cutoutRect != null) {
      // 3. 뚫어줄 영역을 위한 Paint 설정
      // BlendMode.clear를 사용하여 해당 영역을 투명하게 만듭니다.
      final cutoutPaint = Paint()
        ..blendMode = BlendMode.clear
        ..color = Colors.white; // 색상은 중요하지 않습니다.

      // 4. 뚫어줄 영역 그리기 (말풍선의 둥근 모서리와 동일한 반지름 사용)
      final r = 10.0;
      // 5. 뚫어준 영역을 투명하게 만들기 위해 canvas의 블렌딩 모드를 조정
      canvas.saveLayer(Offset.zero & size, Paint());
      canvas.drawPath(Path()..addRect(Offset.zero & size), backgroundPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(cutoutRect!, Radius.circular(r)), cutoutPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant MaskingPainter oldDelegate) {
    return oldDelegate.cutoutRect != cutoutRect;
  }
}
// TutorialOverlayWithMasking

class TutorialOverlayWithMasking extends StatefulWidget {
  final String userType;
  final int currentStep;
  final VoidCallback onNext;
  final VoidCallback onExit;
  final double widthRatio; // 원본의 scaleFactor 역할을 함
  final double heightRatio;
  final double screenWidth;

  const TutorialOverlayWithMasking({
    super.key,
    required this.userType,
    required this.currentStep,
    required this.onNext,
    required this.onExit,
    required this.widthRatio,
    required this.heightRatio,
    required this.screenWidth,
  });

  @override
  State<TutorialOverlayWithMasking> createState() =>
      _TutorialOverlayWithMaskingState();
}

class _TutorialOverlayWithMaskingState
    extends State<TutorialOverlayWithMasking> {
  late TutorialStyle _style;
  late int _currentTextIndex;

  @override
  void initState() {
    super.initState();
    _style = tutorialStyles[widget.userType] ?? tutorialStyles['몰라형']!;
    _currentTextIndex = widget.currentStep;
  }

  @override
  void didUpdateWidget(covariant TutorialOverlayWithMasking oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStep != oldWidget.currentStep) {
      _currentTextIndex = widget.currentStep;
    }
  }

  void _next() {
    setState(() {
      if (_currentTextIndex < _style.texts.length - 1) {
        _currentTextIndex++;
        widget.onNext(); // 상위 위젯의 _tutorialStep 업데이트
      } else {
        widget.onExit();
      }
    });
  }

  // ⚠️ _getBalloonOffset 함수를 제거하고, build 메서드에서 고정 오프셋을 사용합니다.

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final scaleFactor = widget.widthRatio; // 원본의 scaleFactor를 widthRatio로 사용

    // 단계별로 밝게 뚫어줄 영역을 계산합니다.
    Rect? cutoutRect;
    final double leftMicWidth = widget.screenWidth * 0.15;
    final double longButtonBottom = 24; // 대략적인 여백 (픽셀 기준)
    final double longButtonHeight = 50; // LongButton 내부에서 설정된 높이

    switch (_currentTextIndex) {
      case 0:
      // 첫 번째 문구: 왼쪽 마이크 영역 (전체 높이)
        cutoutRect = Rect.fromLTWH(0, 0, leftMicWidth, screenHeight);
        break;
      case 1:
      // 두 번째 문구: 저장 버튼 영역
      // LongButton의 위치: screenHeight - longButtonBottom - longButtonHeight
        final buttonTop = screenHeight -
            (longButtonBottom * widget.heightRatio) -
            (longButtonHeight * widget.heightRatio);
        final buttonLeft = leftMicWidth + 40 * widget.widthRatio; // 오른쪽 영역 padding
        final buttonRight = widget.screenWidth - 40 * widget.widthRatio;
        cutoutRect = Rect.fromLTWH(
          buttonLeft,
          buttonTop,
          buttonRight - buttonLeft,
          longButtonHeight * widget.heightRatio,
        );
        break;
    }

    return Stack(
      children: [
        // 1. 마스킹을 위한 CustomPainter (전체 배경)
        Positioned.fill(
          child: CustomPaint(
            painter: MaskingPainter(cutoutRect: cutoutRect),
          ),
        ),

        // 2. 닫기 버튼 (우측 상단, 닫기 텍스트 포함)
        Positioned(
          // 원본 TutorialOverlay의 위치 로직을 참고하여 대략적으로 배치합니다.
          // right: paddingH + 10 (이 값이 없으므로 50px 정도로 가정)
          top: 110 * scaleFactor, // keepbox의 상단 여백
          right: 100 * scaleFactor, // 오른쪽 padding
          child: GestureDetector(
            onTap: widget.onExit,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '닫기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * scaleFactor,
                    fontFamily: 'PretendardRegular',
                  ),
                ),
                SizedBox(width: 5 * scaleFactor),
                const Icon(Icons.close, color: Colors.white, size: 28),
              ],
            ),
          ),
        ),

        // 3. 말풍선 및 캐릭터 (원본 TutorialOverlay의 크기와 위치 사용)
        Center(
          child: Transform.translate(
            // ⚠️ 원본 TutorialOverlay의 고정 오프셋을 사용 (크기/위치 문제 해결)
            offset: Offset(100 * scaleFactor, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 캐릭터 이미지 (왼쪽)
                Image.asset(
                  _style.imagePath,
                  width: 150 * scaleFactor,
                  height: 150 * scaleFactor,
                ),
                SizedBox(width: 16 * scaleFactor),
                // 말풍선 (오른쪽)
                GestureDetector(
                  onTap: _next,
                  child: CustomPaint(
                    painter: SpeechBubblePainter(
                      balloonColor: _style.balloonColor,
                      arrowColor: _style.arrowColor,
                      scaleFactor: scaleFactor,
                    ),
                    child: Container(
                      width: 372 * scaleFactor * 0.8, // ⬅️ 축소된 크기 유지
                      height: 168 * scaleFactor * 0.8, // ⬅️ 축소된 크기 유지
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.all(30 * scaleFactor * 0.8), // ⬅️ Padding 보정
                      child: Stack(
                        children: [
                          // 1. 텍스트 (Positioned로 감싸 화살표 영역을 침범하지 않게 함)
                          Positioned(
                            top: 0,
                            left: 0,
                            // 💡 텍스트가 오른쪽 화살표 영역을 침범하지 않도록 제약
                            right: 30 * scaleFactor * 0.8,
                            child: Text(
                              _style.texts[_currentTextIndex],
                              style: TextStyle(
                                color: const Color(0xFF333333),
                                fontSize: 18 * scaleFactor * 0.8,
                                fontFamily: 'PretendardMedium',
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),

                          // 2. 다음 텍스트로 이동 화살표 (오른쪽 아래 끝에 고정)
                          if (_currentTextIndex < _style.texts.length - 1)
                            Positioned(
                              // 🌟 bottom을 0으로 설정하여 무조건 맨 아래에 고정
                              right: 0,
                              bottom: 0,
                              child: Padding(
                                padding: EdgeInsets.only(right: 5 * scaleFactor * 0.8),
                                child: Icon(
                                  Icons.arrow_drop_down,
                                  color: _style.arrowColor,
                                  size: 30 * scaleFactor * 0.8,
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
        ),
      ],
    );
  }
}

// 둥근 모서리 삼각형 모양의 말풍선을 그리는 CustomPainter
class SpeechBubblePainter extends CustomPainter {
  final Color balloonColor;
  final Color arrowColor;
  final double scaleFactor;

  const SpeechBubblePainter({
    required this.balloonColor,
    required this.arrowColor,
    required this.scaleFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 말풍선 본체 (채우기 Paint)
    final paint = Paint()..color = balloonColor;
    final r = 10.0 * scaleFactor; // 둥근 모서리 반지름

    // 2. 말풍선 본체 (둥근 사각형)
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(r),
    );
    canvas.drawRRect(rect, paint);

    // 3. 말풍선 꼬리 (왼쪽 아래 위치, 말풍선 배경 색상 사용)
    final arrowSize = 15.0 * scaleFactor;
    final arrowTop = size.height / 2; // 말풍선 높이의 중앙


    final newTailPath = Path();

    // 왼쪽 중앙 (0, arrowTop)에서 시작
    newTailPath.moveTo(0, arrowTop - arrowSize / 2);
    newTailPath.lineTo(0, arrowTop + arrowSize / 2);
    // 꼬리 끝점 (말풍선 밖, 왼쪽으로)
    newTailPath.lineTo(-arrowSize, arrowTop);

    newTailPath.close();

    // 꼬리 채우기 Paint (말풍선 배경색 사용)
    final tailPaint = Paint()..color = balloonColor;

    // 꼬리 부분 채우기
    canvas.drawPath(newTailPath, tailPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _keepboxState extends State<keepbox> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  double _currentLevel = 0.0;
  String _lastWords = '';
  bool _isTutorialActive = true; // 튜토리얼 시작을 위해 true로 설정
  int _tutorialStep = 0;
  final String _userType = '방치형';


  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> categories = [];
  int? selectedIndex;
  String _currentItemName = "새 항목";

  GenerativeModel? _model;
  bool _isGeminiInitialized = false;

  final AppDatabase _database = AppDatabase.instance;
  bool _isLoading = true;

  final NotificationService _notificationService = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _initGemini();
    _initSpeech();
    NotificationService.instance.init();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTutorial());
  }
  void _startTutorial() {
    setState(() {
      _isTutorialActive = true;
      _tutorialStep = 0;
    });
  }
  void _nextTutorialStep() {
    setState(() {
      if (_tutorialStep < 1) { // 튜토리얼 텍스트가 3개라고 가정 (0, 1, 2)
        _tutorialStep++;
      } else {
        _isTutorialActive = false;
        _tutorialStep = 0;
      }
    });
  }
  // 튜토리얼 종료 함수
  void _exitTutorial() {
    setState(() {
      _isTutorialActive = false;
      _tutorialStep = 0;
    });
  }

  @override
  void dispose() {
    _saveData();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final itemsFromDb = await _database.getAllKeepBoxes();
    final Map<String, List<Map<String, String>>> groupedItems = {};
    final DateFormat formatter = DateFormat("yyyy.MM.dd");

    for (final item in itemsFromDb) {
      final category = item.type;
      final formattedItem = {
        'name': item.name,
        'startDate': formatter.format(item.addedAt),
        'endDate': formatter.format(item.expirationAt),
        'category': category,
      };

      if (!groupedItems.containsKey(category)) {
        groupedItems[category] = [];
      }
      groupedItems[category]!.add(formattedItem);
    }

    final newCategories =
        groupedItems.entries.map((entry) {
          return {'name': entry.key, 'items': entry.value};
        }).toList();

    for (final defaultCat in []) {
      if (!newCategories.any((c) => c['name'] == defaultCat)) {
        newCategories.add({
          'name': defaultCat,
          'items': <Map<String, String>>[],
        });
      }
    }
    setState(() {
      categories = newCategories;
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    if (_isLoading) return;
    await _notificationService.cancelAllNotifications();

    final List<KeepBoxesCompanion> itemsToSave = [];
    final DateFormat formatter = DateFormat("yyyy.MM.dd");

    int notificationId = 0;

    for (final categoryMap in categories) {
      final categoryName = categoryMap['name'] as String;
      final itemList = categoryMap['items'] as List<Map<String, String>>;

      for (final itemMap in itemList) {
        try {
          final addedAt = formatter.parse(itemMap['startDate']!);
          final expirationAt = formatter.parse(itemMap['endDate']!);

          itemsToSave.add(
            KeepBoxesCompanion.insert(
              name: itemMap['name']!,
              type: categoryName,
              addedAt: addedAt,
              expirationAt: expirationAt,
            ),
          );
          // DateTime d3Date = expirationAt.subtract(const Duration(days: 3));

          DateTime scheduleTime = DateTime.now().add(
            const Duration(seconds: 10),
          ); // 테스트용
          /* DateTime scheduleTime = DateTime(
            d3Date.year,
          d3Date.month,
            d3Date.day,
            9,
            0,
          );
          */

          if (scheduleTime.isAfter(DateTime.now())) {
            await _notificationService.scheduleNotification(
              id: notificationId,
              title: '냉장고 속 ${itemMap['name']}의 유예기간이 임박했어요!',
              body: '버려야 할지, 아니면 마지막 기회를 줄지 지금 바로 확인하고 결정해보세요!',
              scheduleDate: scheduleTime,
            );
          }
          notificationId++;
        } catch (e) {
          print("날짜 파싱 오류 : $e, 항목 : ${itemMap['name']}");
        }
      }
    }
    await _database.replaceAllKeepBoxes(itemsToSave);

    final bool isMissionFlow =
        widget.nextMissionIndex != null && widget.totalMissionCount != null;

    if (isMissionFlow) {
      final bool allMissionsCompleted =
          widget.nextMissionIndex! >= widget.totalMissionCount!;

      if (allMissionsCompleted) {
        final String? completedSpaceName =
        await _database.inferCurrentSpaceName(1);

        if (completedSpaceName != null) {
          print("'$completedSpaceName' 미션 완료! 모든 가구 잠금 해제.");
          await _database.completeSpaceAndUnlockAll(1, completedSpaceName);
        } else {
          print("오류: 완료된 가구 이름을 찾지 못해 잠금 해제에 실패했습니다.");
        }
      }

      if (mounted) {
        await showMissionCompleteDialog(
          context: context,
          allMissionsCompleted: allMissionsCompleted,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장되었습니다! (D-3 알림이 예약되었습니다.)')),
        );
      }
    }
  }


  Future<void> _initGemini() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print('오류: .env 파일에서 GEMINI_API_KEY를 찾을 수 없거나 비었습니다.');
      setState(() {
        _isGeminiInitialized = false;
      });
      return;
    }

    try {
      _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      setState(() {
        _isGeminiInitialized = true;
      });
      print('Gemini 모델이 성공적으로 초기화되었습니다.');
    } catch (e) {
      print('Gemini 모델 초기화 중 오류 발생: $e');
      setState(() {
        _isGeminiInitialized = false;
      });
    }
  }

  //음성 인식 초기화
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  //음성 인식 시작
  void _startListening() async {
    setState(() {
      _lastWords = '';
    });
    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() {
            _lastWords = result.recognizedWords;
            _onSpeechResult(_lastWords);
          });
        }
      },
      onSoundLevelChange: (level) {
        setState(() {
          _currentLevel = (level / 100).clamp(0.0, 1.0);
        });
      },
      localeId: 'ko_KR',
    );
    setState(() {});
  }

  //음성 인식 중지
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  Future<String?> _getCategoryFromGemini(String itemName) async {
    if (!_isGeminiInitialized || _model == null) {
      print("Gemini 모델이 초기화되지 않았거나 사용할 수 없습니다.");
      return "분류 오류(모델 준비 안됨)";
    }
    try {
      final prompt =
          '다음 품목을 한 단어의 카테고리(예:식품,의류, 기타)로 분류해주세요: $itemName. 답변은 카테고리 단어 하나만 주세요.';
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      print("Gemini API 응답 : ${response.text}");

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim().replaceAll('.', '');
      }
      return "기타";
    } catch (e) {
      print("Gemini API 호출 오류: $e");
      return "분류 실패";
    }
  }

  //음성 인식 결과 처리
  Future<void> _onSpeechResult(String recognizedText) async {
    String itemName = recognizedText.trim();

    if (itemName.isNotEmpty) {
      final now = DateTime.now();
      final formattedDate = DateFormat("yyyy.MM.dd").format(now);
      final formattedendDate = DateFormat(
        "yyyy.MM.dd",
      ).format(now.add(Duration(days: 7)));
      final newItem = {
        'name': itemName,
        'startDate': formattedDate,
        'endDate': formattedendDate,
      };

      if (_isGeminiInitialized) {
        final geminiCat = await _getCategoryFromGemini(itemName) ?? '기타';

        setState(() {
          _pushItemToCategory(
            categoryName: geminiCat,
            item: {...newItem, 'category': geminiCat},
          );
        });

        if (mounted) {
          keepdialogs(
            context: context,
            itemName: itemName,
            initialCategory: geminiCat,
            categories: categories,
            onConfirm: (chosenCat) {
              setState(() {
                for (final cat in categories) {
                  (cat['items'] as List).removeWhere(
                    (it) => it['name'] == itemName,
                  );
                }
                _pushItemToCategory(
                  categoryName: chosenCat,
                  item: {...newItem, 'category': chosenCat},
                );
                _currentItemName = itemName;
              });
            },
            onAddCategory: (newCat) {
              setState(() {
                for (final cat in categories) {
                  (cat['items'] as List).removeWhere(
                    (it) => it['name'] == itemName,
                  );
                }

                categories.add({
                  'name': newCat,
                  'items': [
                    {...newItem, 'category': newCat},
                  ],
                });
              });
            },
          );
        }
      } else {
        setState(() {
          _pushItemToCategory(
            categoryName: '기타',
            item: {...newItem, 'category': '기타'},
          );
        });
      }
    } else {
      print('인식된 텍스트가 없습니다.');
    }
  }

  void _pushItemToCategory({
    required String categoryName,
    required Map<String, String> item,
  }) {
    final idx = categories.indexWhere((c) => c['name'] == categoryName);
    if (idx != -1) {
      final items = categories[idx]['items'] as List;
      if (!items.any((it) => it['name'] == item['name'])) {
        items.add(item);
      }
    } else {
      final newCategory = {
        'name': categoryName,
        'items': [item],
      };
      categories.add(newCategory);
    }
  }

  void _handleDateChange(String itemName, String newEndDate) {
    setState(() {
      for (final category in categories) {
        final itemList = category['items'] as List;
        for (final item in itemList) {
          if (item['name'] == itemName) {
            item['endDate'] = newEndDate;
            break;
          }
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final widthRatio = screenWidth / (1280 / 1.2);
    final heightRatio = screenHeight / (832 / 1.2);

    String currentItemName = "새 항목";
    String? currentItemCategory = _isGeminiInitialized ? '카테고리' : '분류 기능 사용 불가';

    if (items.isNotEmpty &&
        selectedIndex != null &&
        selectedIndex! < items.length) {
      currentItemName = items[selectedIndex!]['name']!;
      currentItemCategory = items[selectedIndex!]['category'];
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
        Row(
        children: [
          // 왼쪽 15% 영역
          Container(
            width: screenWidth * 0.15,
            decoration: BoxDecoration(
              // Dynamically set the gradient based on user type
              gradient:
                  _speechToText.isListening
                      ? LinearGradient(
                        colors: [
                          UserThemeManager.keepboxGradientStartColor,
                          const Color(0xFFD7DCFA),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                      : null,
              color: _speechToText.isListening ? null : const Color(0xFFF3F5FF),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                // 🔙 뒤로가기 버튼
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 28),
                  ),
                ),

                const Spacer(),

                // 🎙 마이크 또는 정지 아이콘 (동그란 배경 포함)
                GestureDetector(
                  onTap: () {
                    if (!_speechToText.isListening) {
                      _startListening();
                    } else {
                      _stopListening();
                    }
                    setState(() {});
                  },
                  child: Container(
                    width: 80 * widthRatio,
                    height: 80 * widthRatio,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _speechToText.isListening
                              ? Colors.white
                              : const Color(0xFF7F91FF),
                    ),
                    child: Icon(
                      _speechToText.isListening ? Icons.stop : Icons.mic,
                      size: 36 * widthRatio,
                      color:
                          _speechToText.isListening
                              ? const Color(0xFF7F91FF)
                              : Colors.white,
                    ),
                  ),
                ),

                SizedBox(height: 16 * heightRatio),

                // 🗣 텍스트 상태 표시
                Text(
                  _speechToText.isListening ? '눌러서 멈추기' : '눌러서 말하기',
                  style: TextStyle(
                    fontSize: 14 * widthRatio,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: 24 * heightRatio),

                // 📝 마지막 음성 텍스트
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    _lastWords.isNotEmpty ? _lastWords : '',
                    style: TextStyle(
                      fontSize: 12 * widthRatio,
                      color:
                          _lastWords.isNotEmpty
                              ? Colors.blue
                              : Colors.transparent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
          // 오른쪽 영역
          Container(
            width: screenWidth * 0.85,
            padding: EdgeInsets.symmetric(horizontal: 40 * widthRatio),
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(height: 37),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/');
                    },
                    icon: const Icon(Icons.home, size: 28),
                  ),
                ),
                SizedBox(height: 50 * heightRatio),
                Center(
                  child: Text(
                    '버릴까말까 상자',
                    style: TextStyle(
                      fontSize: 28 * widthRatio,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20 * heightRatio),
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 아이템 리스트 영역
                              Expanded(
                                child: ItemSaveSection(
                                  categories: categories,
                                  widthRatio: widthRatio,
                                  heightRatio: heightRatio,
                                  itemName: _currentItemName,
                                  itemCategory: currentItemCategory,
                                  onExit: () {
                                    _lastWords = '';
                                    selectedIndex = null;
                                  },
                                  onDateChanged: _handleDateChange,
                                  onCategoryUpdated: _updateCategoryName,
                                  onCategoryDeleted: _deleteCategory,
                                ),
                              ),
                            ],
                          ),
                ),
                SizedBox(height: 10 * heightRatio),
                LongButton(text: '저장', onPressed: _saveData),
                SizedBox(height: 24 * heightRatio),
              ],
            ),
          ),
        ],
        ), // ⬅️ Row의 닫는 괄호

          // 튜토리얼 오버레이는 Row 밖에, Stack의 자식으로 배치됩니다.
          if (_isTutorialActive)
            TutorialOverlayWithMasking(
              userType: _userType,
              currentStep: _tutorialStep,
              onNext: _nextTutorialStep,
              onExit: _exitTutorial,
              // 화면 크기 비율 전달
              widthRatio: widthRatio,
              heightRatio: heightRatio,
              screenWidth: screenWidth,
            ),


        ], // ⬅️ Stack의 자식 리스트 끝 (추가된 부분)
      ), // ⬅️ Stack의 닫는 괄호
    ); // ⬅️ Scaffold의 닫는 괄호
  }

  // _keepboxState 클래스 내부에 추가

  Future<void> _updateCategoryName(String oldName, String newName) async {
    setState(() {
      final index = categories.indexWhere((cat) => cat['name'] == oldName);
      if (index != -1) {
        categories[index]['name'] = newName;
        final items = categories[index]['items'] as List;
        for (var item in items) {
          item['category'] = newName;
        }
      }
    });
    print("카테고리 이름 변경: $oldName -> $newName");
  }

  Future<void> _deleteCategory(String categoryName) async {
    setState(() {
      categories.removeWhere((cat) => cat['name'] == categoryName);
    });
    print("카테고리 삭제: $categoryName");
  }
}
