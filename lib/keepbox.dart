import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:mu/widgets/keepdialogs.dart';
import 'package:mu/widgets/longbutton.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'widgets/ItemSaveSection.dart';
import 'package:mu/data/sampledata.dart';
class keepbox extends StatefulWidget {
  const keepbox({super.key});

  @override
  State<keepbox> createState() => _keepboxState();
}

class _keepboxState extends State<keepbox> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  double _currentLevel = 0.0;
  String _lastWords = '';

  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> categories = [
    {'name': '식품', 'items': <Map<String, String>>[]},
    {'name': '의류', 'items': <Map<String, String>>[]},
    {'name': '기타', 'items': <Map<String, String>>[]},
  ];
  int? selectedIndex;
  String _currentItemName = "새 항목";

  GenerativeModel? _model;
  bool _isGeminiInitialized = false;

  @override
  void initState() {
    super.initState();
    _initGemini();
    _initSpeech();
    categories = List<Map<String, dynamic>>.from(sampleCategories);
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
      _model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey,
      );
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
      final prompt = '다음 품목을 한 단어의 카테고리(예:식품,의류, 기타)로 분류해주세요: $itemName. 답변은 카테고리 단어 하나만 주세요.';
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
      final formattedendDate = DateFormat("yyyy.MM.dd").format(now.add(Duration(days: 7)));
      final newItem = {
        'name': itemName,
        'startDate': formattedDate,
        'endDate': formattedendDate,            // 만료일 선택 전
      };
      setState(() {
        _pushItemToCategory(
          categoryName: '기타',
          item: {...newItem, 'category': '분류 중...'},
        );
      });

      if (_isGeminiInitialized) {
        final geminiCat = await _getCategoryFromGemini(itemName) ?? '기타';

        setState(() {
          // '기타' → 실제 카테고리로 이동
          for (final cat in categories) {
            (cat['items'] as List).removeWhere((it) =>
            it['name'] == itemName); // ← category 상관없이 이름으로 정리
          }
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
                // 이동(=삭제 후 재추가)
                for (final cat in categories) {
                  (cat['items'] as List)
                      .removeWhere((it) => it['name'] == itemName);
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
                // 먼저 모든 카테고리에서 제거
                for (final cat in categories) {
                  (cat['items'] as List).removeWhere((it) => it['name'] == itemName);
                }

                // 새 카테고리 추가
                categories.add({
                  'name': newCat,
                  'items': [ {...newItem, 'category': newCat} ],
                });
              });
            },
          );
        }
      }
    }
     else{
      print('인식된 텍스트가 없습니다.');
  }
}

  void _pushItemToCategory({
    required String categoryName,
    required Map<String, String> item,
  }) {
    // 해당 카테고리 찾기
    final idx = categories.indexWhere((c) => c['name'] == categoryName);
    if (idx != -1) {
      // 중복 추가 방지
      final items = categories[idx]['items'] as List;
      if (!items.any((it) => it['name'] == item['name'])) {
        items.add(item);
      }
    } else {
      // '기타'에 넣기
      final etcIdx = categories.indexWhere((c) => c['name'] == '기타');
      final items = categories[etcIdx]['items'] as List;
      if (!items.any((it) => it['name'] == item['name'])) {
        items.add(item);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final widthRatio = screenWidth / (1280 / 1.2);
    final heightRatio = screenHeight / (832 / 1.2);

    String currentItemName = "새 항목";
    String? currentItemCategory = _isGeminiInitialized ? '카테고리' : '분류 기능 사용 불가';

    if (items.isNotEmpty && selectedIndex != null && selectedIndex! < items.length) {
      currentItemName = items[selectedIndex!]['name']!;
      currentItemCategory = items[selectedIndex!]['category'];
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // 왼쪽 15% 영역
          Container(
            width: screenWidth * 0.15,
            decoration: BoxDecoration(
              gradient: _speechToText.isListening
                  ? const LinearGradient(
                colors: [Color(0xFFF3CDCD), Color(0xFFC9C6F2)],
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
                      color: _speechToText.isListening ? Colors.white : const Color(0xFF7F91FF),
                    ),
                    child: Icon(
                      _speechToText.isListening ? Icons.stop : Icons.mic,
                      size: 36 * widthRatio,
                      color: _speechToText.isListening ? const Color(0xFF7F91FF) : Colors.white,
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
                      color: _lastWords.isNotEmpty ? Colors.blue : Colors.transparent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
          // 오른쪽 90% 영역
          Container(
            width: screenWidth * 0.85,
            padding: EdgeInsets.symmetric(horizontal: 40 * widthRatio),
            color: Colors.white,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () {
                      // TODO: 홈으로 이동 기능은 나중에 구현
                    },
                    icon: const Icon(Icons.home, size: 28),
                  ),
                ),
                SizedBox(height: 80 * heightRatio),
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
                  child: Row(
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
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10 * heightRatio),
                longbutton(
                  text: '저장',
                  onPressed: () {
                    // 저장 로직
                  },
                ),
                SizedBox(height: 24 * heightRatio),
              ],
            ),
          ),
        ],
      ),
    );
  }}