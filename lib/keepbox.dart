import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'widgets/ItemListSection.dart';
import 'widgets/ItemSaveSection.dart';

class keepbox extends StatefulWidget {
  const keepbox({super.key});

  @override
  State<keepbox> createState() => _keepboxState();
}

class _keepboxState extends State<keepbox> {
  final SpeechToText _speechToText=SpeechToText();
  bool _speechEnabled=false;
  String _lastWords='';

  List<Map<String, String>> foodItems = [];
  bool isSaving = false;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  //음성 인식 초기화
  void _initSpeech() async{
    _speechEnabled=await _speechToText.initialize();
    setState(() {});
  }

  //음성 인식 시작
  void _startListening() async{
    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() {
            _lastWords = result.recognizedWords;
            _onSpeechResult(_lastWords);
          });
        }
      },
      localeId: 'ko_KR',
    );
    setState(() {});
  }

  //음성 인식 중지
  void _stopListening()async{
    await _speechToText.stop();
    setState(() {});
  }

  //음성 인식 결과 처리
  void _onSpeechResult(String text){
    if(text.startsWith("버릴까 말까")){
      String itemName=text.substring(7).trim();
      if(itemName.isNotEmpty){
        final now=DateTime.now();
        final formattedDate=DateFormat("MM월 dd일").format(now);
        setState(() {
          foodItems.add({
            'name':itemName,
            'date':formattedDate,
          });

          selectedIndex=foodItems.length-1;
          isSaving=true;
        });
        _stopListening();
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final widthRatio = screenWidth / 1280;
    final heightRatio = screenHeight / 832;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 1280 * widthRatio,
          height: 832 * heightRatio,
          padding: EdgeInsets.all(32 * widthRatio),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF333333), width: 0.5),
            borderRadius: BorderRadius.circular(10 * widthRatio),
            color: Colors.white,
          ),
          child: Row(
            children: [
              // 좌측 안내 영역
              Container(
                width: 640 * widthRatio,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '못 버린 물건이 있나요?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30 * widthRatio,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 20 * heightRatio),
                    //음성 인식 버튼 및 상태 표시
                    Column(
                      children: [
                        IconButton(
                            iconSize:50*widthRatio,
                            icon:Icon(_speechToText.isListening?Icons.mic_off:Icons.mic),
                            onPressed:_speechToText.isNotListening?_startListening:_stopListening,
                            tooltip: '음성으로 추가하기',
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            _speechToText.isListening
                                ? '듣고 있어요...'
                                : _speechEnabled
                                ? '버튼을 누르고 "버릴까 말까 [음식 이름]" 이라고 말해보세요.'
                                : '음성 인식을 사용할 수 없습니다.',
                            style: TextStyle(fontSize: 14*widthRatio),
                            textAlign: TextAlign.center,
                        ),
                        ),
                        Text(_lastWords), //디버깅용
                      ],
                    ),
                    SizedBox(height:20*heightRatio),
                    Image.asset(
                      'assets/box.jpg',
                      width: 224 * 1.3 * widthRatio,
                      height: 226 * 1.3 * heightRatio,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 40 * heightRatio),
                    _infoBox(
                      text:
                      '애매한 건 딱 10초 고민하고, ‘버릴까 말까 상자’에 넣어.\n미련과 혼란은 그 상자 안에 다 넣고, 냉장고 안은 깔끔하게.',
                      widthRatio: widthRatio,
                      heightRatio: heightRatio,
                    ),
                    SizedBox(height: 24 * heightRatio),
                    _infoBox(
                      text:
                      '‘버릴까 말까’ 하고 말하면서 식재료 이름을 말해.\n자동으로 분류하고 ‘버릴까 말까 상자’에 저장해줄게.',
                      widthRatio: widthRatio,
                      heightRatio: heightRatio,
                    ),
                  ],
                ),
              ),

              SizedBox(width: 32 * widthRatio),

              // 우측 콘텐츠
              Expanded(
                child: isSaving
                    ? ItemSaveSection(
                  widthRatio: widthRatio,
                  heightRatio: heightRatio,
                  itemName: foodItems[selectedIndex!]['name']!,
                  onExit: () {
                    setState(() {
                      isSaving = false;
                    });
                  },
                )
                    : ItemListSection(
                  title: '식품',
                  items: foodItems,
                  onAddPressed: () {
                    final now = DateTime.now();
                    final formattedDate = DateFormat('MM월 dd일').format(now);
                    setState(() {
                      foodItems.add({'name': '새 식품', 'date': formattedDate});
                      selectedIndex=foodItems.length-1;
                      isSaving=true;
                    });
                  },
                  onItemTapped: (index) {
                    final now = DateTime.now();
                    final formattedDate = DateFormat('MM월 dd일').format(now);
                    setState(() {
                      foodItems[index]['date'] = formattedDate;
                      selectedIndex = index;
                      isSaving = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBox({
    required String text,
    required double widthRatio,
    required double heightRatio,
  }) {
    return Container(
      width: 500 * widthRatio,
      height: 100 * heightRatio,
      padding: EdgeInsets.all(16 * widthRatio),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10 * widthRatio),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16 * widthRatio,
            color: Color(0xFF5C5C5C),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}