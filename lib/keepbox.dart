import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:mu/widgets/keepdialogs.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'widgets/SimpleWaveform.dart';
import 'widgets/ItemSaveSection.dart';

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
    {'name': '식품', 'isFilled': false},
    {'name': '의류', 'isFilled': false},
    {'name': '기타', 'isFilled': false},
  ];
  int? selectedIndex;

  GenerativeModel? _model;
  bool _isGeminiInitialized = false;

  @override
  void initState() {
    super.initState();
    _initGemini();
    _initSpeech();
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
      final formattedDate = DateFormat("MM월 dd일").format(now);
      setState(() {
        items.add({
          'name': itemName,
          'date': formattedDate,
          'category': _isGeminiInitialized ? '분류 중...' : '카테고리 분류 불가',
        });
        selectedIndex = items.length - 1;
      });

      if (_isGeminiInitialized) {
        String? category = await _getCategoryFromGemini(itemName);
        if (mounted && selectedIndex != null && selectedIndex! < items.length) {
          setState(() {
            items[selectedIndex!]['category'] = category!;
          });
        }
        if (mounted) {
          showVoiceConfirmDialog(
            context: context,
            itemName: itemName,
            initialCategory: category!,
            onConfirm: (chosenCat) {
              print('최종 선택한 카테고리: $chosenCat');
              if (selectedIndex != null && selectedIndex! < items.length) {
                setState(() {
                  items[selectedIndex!]['category'] = chosenCat;
                  categories[selectedIndex!]['isFilled'] = true;
                });
              }
            },
            onAddCategory: (newCat) {
              print('새로 추가된 카테고리: $newCat');
              if (selectedIndex != null && selectedIndex! < items.length) {
                setState(() {
                  items[selectedIndex!]['category'] = newCat;
                  categories[selectedIndex!]['isFilled'] = true;
                });
              }
            },
          );
        }
      }
    } else{
      print('인식된 텍스트가 없습니다.');
  }
}


@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery
      .of(context)
      .size
      .width;
  final screenHeight = MediaQuery
      .of(context)
      .size
      .height;

  // 확대 비율 (1.2배)
  final widthRatio = screenWidth / (1280 / 1.2);
  final heightRatio = screenHeight / (832 / 1.2);

  String currentItemName = "새 항목";
  String? currentItemCategory = _isGeminiInitialized ? '카테고리' : '분류 기능 사용 불가';

  if (items.isNotEmpty && selectedIndex != null &&
      selectedIndex! < items.length) {
    currentItemName = items[selectedIndex!]['name']!;
    currentItemCategory = items[selectedIndex!]['category'];
  }

  return Scaffold(
    backgroundColor: Colors.white,
    body: Row(
      children: [
        // 왼쪽 음성 영역
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '버릴까 말까 상자',
                  style: TextStyle(
                    fontSize: 28 * widthRatio,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 32 * heightRatio),
                SizedBox(
                  height: 300 * heightRatio,
                  width: 300 * widthRatio,
                  child: SimpleWaveform(level: _currentLevel),
                ),

                SizedBox(height: 24 * heightRatio),

                Text(
                  _lastWords.isNotEmpty ? _lastWords : '여기에 말한 텍스트가 보여집니다',
                  style: TextStyle(fontSize: 16 * widthRatio),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 24 * heightRatio),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: 16 * heightRatio,
                      horizontal: 36 * widthRatio,
                    ),
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _speechToText.isNotListening
                      ? _startListening
                      : _stopListening,
                  child: Text(_speechToText.isListening ? "확인하기" : "눌러서 말하기"),
                ),
                if(!_isGeminiInitialized)
                  Padding(
                    padding: EdgeInsets.only(top: 15 * heightRatio),
                    child: Text(
                      '자동 분류 기능을 사용할 수 없습니다.\nAPI 키 설정을 확인해주세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12 * widthRatio, color: Colors.red),
                    ),
                  )
              ],
            ),
          ),
        ),

        // 오른쪽: ItemSaveSection 고정
        Expanded(
          child: ItemSaveSection(
            categories: categories,
            widthRatio: widthRatio,
            heightRatio: heightRatio,
            itemName: currentItemName,
            itemCategory: currentItemCategory,
            onExit: () {
              _lastWords = '';
              selectedIndex = null;
            },
          ),
        ),
      ],
    ),
  );
}}