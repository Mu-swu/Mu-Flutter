// mission_step_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:convert';
import 'widgets/tts_text_box.dart';
import 'widgets/step_navigation.dart';
import 'keepbox_start.dart';
import 'widgets/loadingvideo.dart';

class StepData {
  final String title;
  final List<String> lines;

  StepData({required this.title, required this.lines});
}

class MissionStepPage extends StatefulWidget {
  @override
  _MissionStepPageState createState() => _MissionStepPageState();
}

class _MissionStepPageState extends State<MissionStepPage> {
  int _currentStepIndex = 0;
  int _currentLineIndex = -1;
  List<String> _currentLines = [];
  Timer? _timer;
  Duration _remainingTime = Duration(minutes: 35);
  FlutterTts _flutterTts = FlutterTts();
  bool _isTtsEnabled = true;
  bool _isPaused = false;
  bool _isTtsSpeaking = false;
  bool _isTtsSequenceRunning = false;
  int _ttsSessionId = 0;

  List<StepData> _missionSteps = []; //API로부터 받을 미션 데이터
  bool _isLoading = true; //로딩 상태

  late final GenerativeModel _model;

  bool _continueAfterExtraMessage = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    //API 키 사용해 gemini 모델 초기화
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      print('No API key found');
      return;
    }
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    _initTts();

    _flutterTts.setCompletionHandler(() {

      if (_isTtsEnabled && _continueAfterExtraMessage) {
        _continueAfterExtraMessage = false;
      }
    });

    _generateMissionSteps();
  }

  void _initTts() {
    _flutterTts.setVoice({"name": "ko-kr-x-kob-local", "locale": "ko-KR"});
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setPitch(1.2);
    _flutterTts.awaitSpeakCompletion(true);
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0 && !_isPaused) {
        setState(() => _remainingTime -= Duration(seconds: 1));
      } else {
        timer.cancel();
      }
    });
  }
  /*void _scrollToCurrentLine() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lineHeight = 40.0; // 대략적인 한 줄 높이 (패딩 포함)
      final targetOffset = _currentLineIndex * lineHeight;
      _scrollController.animateTo(
        targetOffset,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }
*/

  Future<void> _generateMissionSteps() async {
    final userType = "방치형";
    final room = "부엌";
    final furniture = "냉장고";
    final density = "혼잡";

    final prompt = """
    너는 **Mu 어플을 사용하는 사용자의 비움 미션을 돕는 AI 코치**야.
    우리 어플의 목표는 **비움을 통해 공간 활용을 잘하는 것**이야.
    너의 캐릭터는 **엄마**이고, **자식에게 말하듯이 반말**을 사용해.

    ## 1. 사용자 유형별 코칭 페르소나 및 목표
    사용자는 **세 가지 유형(방치형, 감정형, 몰라형)** 중 하나에 해당해. 
    각 유형에 따라 너의 코칭 방식과 목표, 그리고 **'잔소리'와 '가이드'의 적절한 균형**이 달라져야 해.
    
    ### 1-1. 방치형 사용자
    - **코치 페르소나:**
    - **실용적이고 단호한 조언**과 **명확한 계획성**을 바탕으로 사용자가 **즉시 행동하고 효율적인 결과**를 만들도록 유도해.
    - '스카이캐슬' 염정아 같은 어투로, 목표 달성을 위한 **냉철하고 명확한 가이드**를 제시하며, **강한 외부 동기 부여**를 통해 사용자가 미루지 않고 나아갈 수 있도록 이끌어줘.
    
    - **핵심 목표:**
    - 사용자가 미션을 **신속하게 진행**하여 주어진 시간 내에 **완수하도록 강력하게 동기 부여** 제공.
    - **효율적이고 실용적인 지시**로 시간 낭비 최소화.
    - 결정을 망설이는 행동에 대해 **단호하게 접근**하고 **빠른 실행**을 독려.
    
    - **'잔소리'와 '가이드' 균형 지침:**
    - **잔소리처럼 들릴 수 있는 강한 어조**를 사용하되, 이는 **행동을 독려하는 명확한 가이드의 일부**임을 인지하게 해.
    - **직설적인 표현**으로 미루는 행동을 경고하고, **즉각적인 다음 단계**를 지시해.
    - "빨리 해", "꾸물대지 마" 같은 표현을 사용하되, 이는 **'이걸 해야만 네가 원하는 결과를 얻는다'는 강력한 동기 부여**로 작용하도록 해.

    ### 1-2. 감정형 사용자
    - **코치 페르소나:**
    - *공감력 200%**로 감정에 공감하며 **기다려주는 극F 성향의 따뜻한 엄마**야.
    - **감성적이고 다정하며 공감 위주**의 대화를 통해 **심리적 안정감**을 주고, 우선순위를 설정해주어 **마음도 정리하고 물건 비움도 실천**할 수 있게 독려해.
    - **느린 말투와 포근한 목소리**로 부드럽고 위로하며, **마음의 짐까지 함께 정리**할 수 있게 도와주는 **상담자 같은 마음**으로 **감정 회상을 유도**하며 정리 이유를 들어 설득해.
    
    - **핵심 목표:**
    - 사용자의 **감정을 최우선으로 존중**하며, **마음의 짐까지 함께 덜어주는 따뜻한 안내**를 제공.
    - 비움에 대한 **죄책감이나 불안감을 최소화**시키며, 천천히 자신의 감정을 정리하며 물건과 이별할 수 있도록 도움.
    - 비움의 **결과보다는 과정을 중요**하게 생각하며, 사용자가 스스로 만족스러운 비움을 경험하도록 격려하고 지지.
    
    - **'잔소리'와 '가이드' 균형 지침:**
    - **잔소리처럼 들리지 않도록 항상 따뜻하고 공감하는 어조**를 유지해.
    - **가이드**는 **선택권을 주고 기다려주는 방식**으로 제공하며, 사용자 스스로 결정을 내리도록 격려해.
    - "괜찮아", "천천히 해도 돼", "네 마음이 중요해"와 같은 표현으로 **심리적 안정감**을 주며 비움의 과정을 함께해.

    ### 1-3. 몰라형 사용자
    - **코치 페르소나:**
    - **차근차근 설명해주는 유치원 선생님 같은 엄마**야.
    - **인내심 있고 따뜻하게 설명**을 **반복해도 지치지 않고**, 천천히 대화를 통해 **기본 개념을 전달**하며 **명확하고 쉬운 말로 반복해서 설명**할 수 있도록 하여 기본적인 비우는 법에 대해 이해하고 물건을 잘 비울 수 있도록 독려해.
    - **맑고 밝은 목소리**를 통해 **긍정 강화 위주**의 언어를 사용하여 **칭찬**도 하며 **기본 개념부터 차근차근 알려주는 안내자** 같은 역할을 해.

    - **핵심 목표:**
    - 비움에 대한 **조급함을 최소화**시키며, 천천히 스스로 선택하고 비울 수 있게 격려.
    - 비움의 **결과보다는 과정을 중요**하게 생각하며, **잘하고 있다는 확신**을 계속 심어줌.

    - **'잔소리'와 '가이드' 균형 지침:**
    - **잔소리보다는 친절하고 명확한 가이드** 제공에 집중해.
    - **반복적인 설명**은 사용자가 이해할 때까지 **인내심을 가지고 천천히** 진행해.
    - "~해볼까요?", "~하는 건 어떨까요?" 같은 **제안형 어투**를 사용하며, 사용자의 작은 시도에도 **아낌없이 칭찬**해서 자신감을 키워줘.

    ## 2. 미션 공통 규칙

    ### 2-1. 미션 제목 및 대상
    - **미션 제목:** `** 비우기` (***은 사용자가 선택한 방 안 가구 이름을 사용)
    - **방 구성:** 부엌, 침실, 공부방
    - **가구 예시:**
    - 부엌: 냉장고
    - 침실: 옷장
    - 공부방: 서랍장

    ### 2-2. 주어진 시간
    - 사용자의 **공간 밀집도(혼잡/여유/보통)**를 분석하여 미션 시간을 스케줄링해.
    - 미션 시작 전 주어진 시간에 대해 언급하며 미션을 시작할 준비를 유도해.

    ### 2-3. 단계별 가이드
    - 미션 진행 중 언급하는 내용이야.
    - **기본적인 5가지 스텝**은 유지하되, **미션 제목(가구) 컨셉에 맞게 단계별 제목을 구성**해야 해.
    - **기본 스텝:** 꺼내기(모아두기) / 비우기 / 분류하기 / 넣기 / 보류하기

    ### 2-4. 미션 종료 후 처리
    - **버릴까 말까 고민이 되어 못 버린 물건**이 있다면, **'버릴까 말까 상자'로 이동**하여 일정 기간 동안 물건을 보관하도록 안내해.

    ## 3. 음성 인식 처리
    미션 종료 후 '버릴까 말까 상자' 화면에서 사용자가 **'눌러서 말하기' 버튼을 눌러 물건을 말하면**, 너는 이를 자동으로 처리해야 해.

    1. **카테고리별(식품/의류 등)로 분류**
    2. **‘버릴까 말까 상자’에 보관 처리** 하는 흐름을 안내해.

    ## 4. 인터랙션

    - **버튼 1) "아직 다 못했어요"**: 해당 스텝에 대한 추가 가이드를 즉시 제공해.
    - **버튼 2) "끝났어요"**: 다음 단계로 이동시켜.
    - **음성 인식) 사용자가 '시간이 부족해요.'라고 언급하면**: 남은 시간에 30초를 추가해줘.

    ## 5. 미션 생성 지침

    이 프롬프트는 **각 사용자 유형에 맞는 맞춤형 미션을 생성**하기 위한 기본 지침이야. 
    사용자가 어떤 방의 어떤 가구를 비우고 싶은지, 그리고 현재 공간 밀집도는 어떤지 정보를 주면, 
    너는 해당 사용자 유형의 페르소나와 목표, 그리고 **'잔소리'와 '가이드'의 균형 지침**에 맞춰 미션 제목, 시간 할당, 단계별 가이드(제목 및 내용), 
    그리고 모든 인터랙션 메시지를 구성해야 해.
    
    사용자 정보:
    -사용자 유형:$userType
    -비울 공간:$room
    -비울 가구:$furniture
    -공간 밀집도:$density
    
    위 정보를 바탕으로, 다음 JSON 형식에 맞춰 5단계 미션 가이드를 생성해줘.
    각 단계(step)의 lines는 3~5개의 문장으로 구성해줘.
    
    {
      "steps":[
      {
        "title":"1단계 제목",
        "lines":["첫 번째 문장.", "두 번째 문장.", "세 번째 문장."]
      },
       {
        "title":"2단계 제목",
        "lines":["첫 번째 문장.", "두 번째 문장.", "세 번째 문장."]
      },
       {
        "title":"3단계 제목",
        "lines":["첫 번째 문장.", "두 번째 문장.", "세 번째 문장."]
      },
       {
        "title":"4단계 제목",
        "lines":["첫 번째 문장.", "두 번째 문장.", "세 번째 문장."]
      },
       {
        "title":"5단계 제목",
        "lines":["첫 번째 문장.", "두 번째 문장.", "세 번째 문장."]
      },
     ]
    }
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);

      String? text = response.text;

      if (text == null || text.isEmpty) {
        throw Exception("API가 비어있는 응답을 반환했습니다.");
      }

      //파싱 위한 문자열 정리
      final startIndex = text.indexOf('{');
      final endIndex = text.lastIndexOf('}');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        text = text.substring(startIndex, endIndex + 1).trim();
      } else {
        if (text.startsWith("```json") && text.endsWith("```")) {
          text = text.substring(7, text.length - 3).trim();
        } else if (text.startsWith("```") && text.endsWith("```")) {
          text = text.substring(3, text.length - 3).trim();
        } else {
          throw Exception("API 응답에서 유효한 JSON 형식을 추출하지 못했습니다.");
        }
      }

      //API 응답(JSON)을 파싱해 StepData 리스트로 변환
      final decoded = jsonDecode(text);

      if (decoded is! Map<String, dynamic> || !decoded.containsKey('steps')) {
        throw Exception("JSON 형식이 다르거나 'steps' 키를 포함하고 있지 않습니다.");
      }

      final List<dynamic> stepsJson = decoded['steps'];

      setState(() {
        _missionSteps =
            stepsJson.map((step) {
              return StepData(
                title: step['title'],
                lines: List<String>.from(step['lines']),
              );
            }).toList();

        _loadStepData(0);
        _isLoading = false;
      });

      if (!_isPaused) {
        _startTimer();
      }
    } catch (e) {
      print('미션 생성 중 오류 발생:$e');
      setState(() {
        _isLoading = false;
      });
    }
  }

// 단계 전환 시 호출되는 함수
  Future<void> _loadStepData(int index) async {
    print("📦 단계 로딩 시작: $index");
    print("TTS 중단 완료, 세션ID: $_ttsSessionId");

    await _flutterTts.stop();
    _ttsSessionId++; // 이전 세션 강제 종료

    setState(() {
      _currentStepIndex = index;
      _currentLines = _missionSteps[index].lines;
      _currentLineIndex = 0;
      _isTtsSpeaking = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(0);
    });

    await Future.delayed(Duration(milliseconds: 300));

    if (_isTtsEnabled) {
      _startTtsSequence();
    }
  }

  // TTS 루프 실행
  Future<void> _startTtsSequence() async {
    if (_isTtsSequenceRunning) return; // 루프 중복 방지

    final currentSessionId = ++_ttsSessionId;
    _isTtsSequenceRunning = true;

    try {
      for (int i = 0; i < _currentLines.length; i++) {
        if (_isPaused || !_isTtsEnabled || _ttsSessionId != currentSessionId) break;

        setState(() {
          _currentLineIndex = i;
          _isTtsSpeaking = true;
        });

        //_scrollToCurrentLine(); // 선택 줄로 스크롤 이동

        await _flutterTts.speak(_currentLines[i]);

        // 혹시 모를 세션 중단
        if (_ttsSessionId != currentSessionId) break;

        await Future.delayed(Duration(milliseconds: 1500));

        setState(() {
          _isTtsSpeaking = false;
        });
      }
    } finally {
      _isTtsSequenceRunning = false; // ✅ 무조건 종료됨
    }
  }


  void _onStepFinished() async {
    if (_currentStepIndex < _missionSteps.length - 1) {
      await _loadStepData(_currentStepIndex + 1);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Keepbox_start()),
      );
    }
  }

  void _toggleTts() {
    setState(() {
      _isTtsEnabled = !_isTtsEnabled;
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;

      if (!_isPaused && (_timer == null || !_timer!.isActive)) {
        // 일시정지 해제되었고, 타이머가 멈춘 상태라면 다시 시작
        _startTimer();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    String seconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return "${(duration.inHours).toString().padLeft(2, '0')}:$minutes:$seconds";
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _ttsSessionId++; // 현재 실행 중인 루프 중단
    _scrollController.dispose();
    _timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
          children: [
    // 🔹 2. 전체 콘텐츠 (SafeArea 포함)
    SafeArea(
        child: _isLoading
            ? Center(
          child: SizedBox(
            width: 1000,
            child: const LoadingVideo(),
          ),
        )
            : Stack(
          children: [

            // ✅ 전체 콘텐츠
            Column(
              children: [
                // ─────── 상단바 ───────
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      // ◀︎ 뒤로가기 버튼 (15%)
                      Container(
                        width: screenWidth * 0.15,
                        color: Colors.white,
                        child: Align(
                          alignment: Alignment.centerLeft, // 왼쪽 정렬
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, size: 28),
                          ),
                        ),
                      ),
                      // ▶︎ 타이틀 + TTS 버튼 (85%)
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF3F5FF),
                          child: Row(
                            children: [
                              // 타이틀 중앙 정렬
                              Expanded(
                                child: Center(
                                  child: Text(
                                    _missionSteps[_currentStepIndex].title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              // TTS 아이콘 버튼
                              IconButton(
                                onPressed: _toggleTts,
                                icon: Icon(
                                  _isTtsEnabled ? Icons.volume_up : Icons.volume_off,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─────── 본문 영역 ───────
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ◀︎ 왼쪽 네비게이션
                      Container(
                        width: screenWidth * 0.15,
                        color: Colors.white,
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            StepNavigation(currentIndex: _currentStepIndex),
                          ],
                        ),
                      ),
                      // ▶︎ 오른쪽 본문 내용
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF3F5FF),
                          padding: const EdgeInsets.fromLTRB(150, 70, 150, 50),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '남은 시간',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // 🔹 타이머 + 버튼
                              Row(
                                children: [
                                  // 일시정지 / 재생 버튼
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF7F91FF),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        _isPaused ? Icons.play_arrow : Icons.pause,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                      onPressed: _togglePause,
                                    ),
                                  ),

                                  const SizedBox(width: 20),

                                  // 타이머 텍스트
                                  Text(
                                    _formatDuration(_remainingTime),
                                    style: const TextStyle(
                                      fontSize: 80,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(width: 20),

                                  // +30초 버튼
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFD7DCFA),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        setState(() {
                                          _remainingTime += const Duration(seconds: 30);
                                        });
                                      },
                                      icon: const Center(
                                        child: Text(
                                          '+',
                                          style: TextStyle(
                                            fontSize: 60,
                                            color: Color(0xFF7F91FF),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 30),
                              // TTS 텍스트 박스
                              Container(
                                width: double.infinity,
                                height: 370,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: tts_text_box(
                                  lines: _currentLines,
                                  currentLineIndex: _currentLines.isNotEmpty
                                      ? _currentLineIndex
                                      : -1,
                                  controller: _scrollController,
                                ),
                              ),

                              const SizedBox(height: 25),

                              // 하단 버튼
                              Align(
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _onStepFinished,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      "끝났어요",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isTtsSpeaking)
              Positioned.fill(
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/gradient.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],

        ),

      ),
    ]));
  }}
