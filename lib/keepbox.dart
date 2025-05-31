import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
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


  List<Map<String, String>> foodItems = [];
  bool isSaving = false;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  //음성 인식 초기화
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  //음성 인식 시작
  void _startListening() async {
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

  //음성 인식 결과 처리
  void _onSpeechResult(String text) {
    if (text.startsWith("버릴까 말까")) {
      String itemName = text.substring(7).trim();
      if (itemName.isNotEmpty) {
        final now = DateTime.now();
        final formattedDate = DateFormat("MM월 dd일").format(now);
        setState(() {
          foodItems.add({
            'name': itemName,
            'date': formattedDate,
          });

          selectedIndex = foodItems.length - 1;
          isSaving = true;
        });
        _stopListening();
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 확대 비율 (1.2배)
    final widthRatio = screenWidth / (1280 / 1.2);
    final heightRatio = screenHeight / (832 / 1.2);

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
                    height:300 * heightRatio,
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
                ],
              ),
            ),
          ),

          // 오른쪽: ItemSaveSection 고정
          Expanded(
            child: ItemSaveSection(
              widthRatio: widthRatio,
              heightRatio: heightRatio,
              itemName: foodItems.isNotEmpty
                  ? foodItems[selectedIndex ?? 0]['name']!
                  : '새 항목',
              onExit: () {},
            ),
          ),
        ],
      ),
    );
  }
}