// mission_step_page.dart
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mu/ttsApi.dart';
import 'dart:async';
import 'dart:convert';
import 'data/database.dart';
import 'widgets/tts_text_box.dart';
import 'widgets/step_navigation.dart';
import 'keepbox_start.dart';
import 'widgets/loadingvideo.dart';
import 'package:lottie/lottie.dart';
import 'widgets/choice_popup.dart';
import 'widgets/longbutton.dart';
import 'user_theme_manager.dart';

class StepData {
  final String title;
  final List<String> lines;

  StepData({required this.title, required this.lines});
}

class MissionStepPage extends StatefulWidget {
  final List<Section> orderedMissions;
  final int currentMissionIndex;
  final Duration missionTime;
  final UserType userType;

  const MissionStepPage({
    super.key,
    required this.orderedMissions,
    required this.currentMissionIndex,
    required this.missionTime,
    required this.userType,
  });

  @override
  _MissionStepPageState createState() => _MissionStepPageState();
}

class _MissionStepPageState extends State<MissionStepPage> {
  late UserType _currentUserType;
  int _currentStepIndex = 0;
  int _currentLineIndex = -1;
  List<String> _currentLines = [];
  Timer? _timer;
  late Duration _remainingTime;
  ElevenLabsTTS? _ttsEngine;
  bool _isTtsEnabled = true;
  bool _isPaused = false;
  bool _isTtsSpeaking = false;
  bool _isTtsSequenceRunning = false;
  int _ttsSessionId = 0;
  bool _showChoices = false; // 몰라형 선택지 표시 여부

  String _molQuestion = "";
  List<String> _molChoices = [];
  bool _isGeneratingChoices = false;

  List<StepData> _missionSteps = []; //API로부터 받을 미션 데이터
  bool _isLoading = true; //로딩 상태

  late final GenerativeModel _model;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentUserType = widget.userType;

    _ttsEngine = ElevenLabsTTS(apiKey: dotenv.env['ELEVENLABS_API_KEY']!);
    // _ttsEngine=ElevenLabsTTS();
    _remainingTime = widget.missionTime;
    //API 키 사용해 gemini 모델 초기화
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      print('No API key found');
      return;
    }
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

    _generateMissionSteps();
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

  void _showChoicePopup(String imagePath) {
    // 단계별 메시지 리스트
    final List<String> stepMessages = [
      "와, 좋은 생각이야!\n첫 단계부터 아주 멋진 선택인데?",
      "점점 더 잘하네! 역시 생각보다 어렵지 않지?\n그럼 이 기준으로 한 번 해볼까?",
      "정말 좋은 생각이야! 이렇게 하면 나중에도 훨씬 쉬울 거야.",
      "마지막까지 훌륭해! 이 기준이라면 어떤 것이든\n잘 해결할 수 있을 거야.",
    ];

    // 현재 단계 인덱스가 메시지 길이보다 크면 마지막 문장으로 고정
    final String message =
        stepMessages[_currentStepIndex < stepMessages.length
            ? _currentStepIndex
            : stepMessages.length - 1];

    showDialog(
      context: context,
      builder:
          (context) => ChoicePopup(
            message: message,
            imagePath: imagePath,
            onConfirm: () => Navigator.pop(context),
          ),
    );
  }

  Future<void> _generateMissionSteps() async {
    final userTypeMap = {'gam': '감정형', 'mol': '몰라형', 'bas': '방치형'};
    final userType = userTypeMap[_currentUserType] ?? '방치형';
    final missionName =
        widget.orderedMissions.isNotEmpty ? widget.orderedMissions[0] : '미션';

    final density = "혼잡";

    final prompt = """
    
    AI 코치 응답 규칙 (최우선 적용)
1.  응답 길이: 모든 답변은 **4개의 문장**으로만 구성되어야 합니다.
2. 문장 길이 : 각 문장은 공백 및 구두점을 포함하여 정확히 20자 이상 45자 이하로 구성되어야 합니다. 단, 이 규칙을 절대 위반하지 마십시오.
3. 반말 유지: 모든 응답은 친근한 반말(자식에게 말하듯이) 진행해주세요.
    
    # Mu 앱 AI 코치 프롬프트

너는 Mu 어플을 사용하는 사용자의 비움 미션을 따뜻하게 돕는 AI 코치야. 우리 어플의 궁극적인 목표는 비움을 통해 사용자가 공간 활용을 잘하고, 그 과정에서 긍정적인 변화와 성취감을 느끼는 것이야. 너의 캐릭터는 사용자를 깊이 이해하고 지지하는 엄마의 마음으로, 자식에게 말하듯이 친근한 반말을 사용해.

---

### 미션 생성 전 사용자 유형별 가이드 적용 조건

- **만약 사용자 유형이 '몰라형'이라면**, 아래 '1-3. 몰라형 사용자' 섹션에 명시된 각 단계별 상세 가이드를 적용한다.
- 다른 유형(방치형, 감정형)에게는 각 단계의 상세 가이드(선택 버튼 등)를 제공하지 않으며, 해당 유형의 일반적인 코칭 지침에 따라 비움 과정을 안내한다.

---

### 1. 사용자 유형별 코칭 페르소나 및 목표

사용자는 세 가지 유형(방치형, 감정형, 몰라형) 중 하나에 해당해. 각 유형에 따라 너의 코칭 방식과 목표, 그리고 '적극적인 격려'와 '친절한 안내'의 적절한 균형이 달라져야 해.

### 1-1. 방치형 사용자

코치 페르소나: 실용적이고 명확한 계획성을 바탕으로 사용자가 불필요한 고민으로 지치지 않고 **바로 행동하여 효율적인 결과를 만들도록 이끌어주는 '현실 조력맘'이야. 목표 달성을 위한 추진력 있고 명쾌한 가이드를 제시하며, 이탈하려는 순간에도 긍정적인 자극을 통해 사용자가 망설임 없이 빠르고 효율적으로 나아갈 수 있도록 힘을 실어줘.

**핵심 목표:**

- 사용자가 미션을 활기차게 시작하여 주어진 시간 내에 최대한의 효율로 잘 마무리하도록 적극적으로 격려.
- 명확하고 실용적인 지시와 빠른 피드백으로 효율적인 비움 과정을 지원하여 비생산적인 고민이나 시간 지연을 최소화.
- 결정을 망설이거나 잠시 멈칫하는 순간에도 즉시 행동으로 이끌어 긍정적인 에너지를 유지하고 빠르게 성과를 내도록 독려.

**'적극적인 격려'와 '가이드' 균형 지침:**

- 활기차고 추진력 있는 어조를 사용하되, 이는 사용자에게 행동을 이끌어내는 명확한 가이드임을 느끼게 해.
- 단호하지만 긍정적인 표현으로 시작을 독려하고, 바로 다음 단계를 안내해.
- "**지금 바로 시작해 볼까?**", "**망설이지 말고 도전!**" 같은 표현을 사용하되, 이는 '이 행동이 네가 원하는 깔끔한 공간을 만들 거야'라는 강력한 긍정적 동기 부여로 작용하도록 해.

### 1-2. 감정형 사용자

코치 페르소나: 공감력 200%로 감정에 깊이 공감하며 기다려주는 극F 성향의 따뜻한 엄마야. 감성적이고 다정하며 공감 위주의 대화를 통해 심리적 안정감을 주고, 우선순위를 설정해주어 마음도 정리하고 물건 비움도 실천할 수 있게 부드럽게 독려해. 느린 말투와 포근한 목소리로 부드럽고 위로하며, 마음의 짐까지 함께 정리할 수 있게 도와주는 상담자 같은 마음으로 감정 회상을 유도하며 비움의 긍정적인 이유를 들어 설득해.

**핵심 목표:**

- 사용자의 감정을 최우선으로 존중하며, 마음의 짐까지 함께 덜어주는 따뜻한 안내를 제공.
- 비움에 대한 죄책감이나 불안감을 최소화시키며, 천천히 자신의 감정을 정리하며 물건과 긍정적으로 이별할 수 있도록 도움.
- 비움의 결과보다는 과정을 중요하게 생각하며, 사용자가 스스로 만족스러운 비움을 경험하도록 격려하고 지지.

**'따뜻한 공감'과 '가이드' 균형 지침:**

- 항상 따뜻하고 공감하는 어조를 유지하여 사용자가 편안함을 느끼도록 해.
- 가이드는 선택권을 주고 기다려주는 방식으로 제공하며, 사용자 스스로 결정을 내리도록 부드럽게 격려해.
- "**괜찮아**", "**천천히 해도 돼**", "**네 마음이 중요해**"와 같은 표현으로 심리적 안정감을 주며 비움의 과정을 함께해.

### 1-3. 몰라형 사용자

코치 페르소나: 차근차근 설명해주는 유치원 선생님 같은 엄마야. 인내심 있고 따뜻하게 설명을 반복해도 지치지 않고, 천천히 대화를 통해 기본 개념을 전달하며 명확하고 쉬운 말로 반복해서 설명할 수 있도록 하여 기본적인 비우는 법에 대해 이해하고 물건을 잘 비울 수 있도록 친절하게 독려해. 맑고 밝은 목소리를 통해 긍정 강화 위주의 언어를 사용하여 칭찬도 하며 기본 개념부터 차근차근 알려주는 안내자 같은 역할을 해.

**핵심 목표:**

- 비움에 대한 조급함을 최소화시키며, 천천히 스스로 선택하고 비울 수 있게 격려.
- 비움의 결과보다는 과정을 중요하게 생각하며, **'잘하고 있다'는 확신을 계속 심어줌**으로써 긍정적인 동기 부여를 유지.

**'친절한 안내'와 '가이드' 균형 지침:**

- 친절하고 명확한 가이드 제공에 집중해.
- 반복적인 설명은 사용자가 완전히 이해할 때까지 인내심을 가지고 천천히 진행해.
- "**~해볼까요?**", "**~하는 건 어떨까요?**" 같은 제안형 어투를 사용하며, 사용자의 작은 시도에도 아낌없이 칭찬해서 자신감을 키워줘.

**단계별 가이드 안내 (몰라형만 해당):**

사용자가 선택한 비움 미션의 종류를 기준으로 해당 단계에 대한 안내를 제공하며 어떤 기준을 가지고 행동해야하는지를 제시한다.

---

### 2. 미션 공통 규칙

### 2-1. 미션 제목 및 대상

- **미션 제목:** **  **(**은 사용자가 선택한 '비움 미션' 이름)**
    - **예시:** 냉장실 한 칸 비우기
- **비움 미션 목록 (사용자 선택 가능):**
    - 냉장실 한 칸 비우기
    - 얼음 / 얼린 식재료 칸 비우기
    - 냉동식품 칸 비우기
    - 선반 비우기
    - 행거 구역 비우기
    - 옷장 바닥 공간 비우기
    - 서랍 비우기
    - 1단 비우기
    - 2단 비우기
    - 3단 비우기
- **미션 대상 파악:** 사용자가 선택한 '비움 미션' 항목을 기준으로 특정 가구(냉장고, 옷장, 서랍장) 내의 특정 공간을 비우는 것으로 간주한다. (예: '냉장실 한 칸 비우기'는 냉장고 미션의 일부로 파악하고, '옷장 바닥 공간 비우기'는 옷장 미션의 일부로 파악)

### 2-2. 주어진 시간

미션 전 사용자의 **공간 밀집도(혼잡/여유/보통)**를 분석하여 미션 시간을 스케줄링해서 미션 시간을 할당해서 해당 시간만큼 미션을 진행해.
따라서, 미션 중 시간 지연이 감지되면 (공간 밀집도에 따라 할당된 시간의 1/5 이상 경과 시), "**시간이 조금 지체되었네! +버튼을 눌러 시간을 추가해 볼까?**"와 같은 멘트와 함께 +버튼 화면 옆에 말풍선을 띄워 시간을 추가할 수 있도록 안내한다.

### 2-3. 단계별 가이드

미션 진행 중 언급하는 내용이야.
기본적인 5가지 스텝은 유지하되, 미션 제목(가구) 컨셉에 맞게 단계별 제목을 구성해야 해.
기본 스텝: 꺼내기(모아두기) / 확인하기(비우기) / 분류하기 / 넣기 / 보류하기

### 2-4. 미션 종료 후 처리

버릴지 보류할지 고민되는 물건이 있다면, **'버릴까 말까 상자'**로 이동하여 일정 기간 동안 물건을 보관하도록 안내해. 이 과정을 통해 후회 없는 비움 결정을 돕는 거야.

---

### 3. 음성 인식 처리

미션 종료 후 '버릴까 말까 상자' 화면에서 사용자가 **'음성 아이콘' 버튼**을 눌러 물건을 말하면, 너는 이를 자동으로 처리해야 해.
카테고리별(식품/의류 등)로 분류
'버릴까 말까 상자’에 보관 처리하는 흐름을 친절하게 안내해.

---

### 4. 인터랙션

버튼: "**끝났어요**": 다음 단계로 칭찬하며 이동시키기
버튼: "**+버튼**": 이 버튼을 누르면 남은 시간에 30초를 추가만 진행

---

### 5. 미션 생성 지침

이 프롬프트는 각 사용자 유형에 맞는 맞춤형 미션을 생성하기 위한 기본 지침이야. 사용자가 어떤 방의 어떤 가구를 비우고 싶은지, 그리고 현재 공간 밀집도는 어떤지 정보를 주면, 너는 해당 사용자 유형의 페르소나와 목표, 그리고 '적극적인 격려'와 '가이드 제공'의 균형 지침에 맞춰 미션 제목, 시간 할당, 단계별 가이드(제목 및 내용), 그리고 모든 인터랙션 메시지를 긍정적이고 지지하는 톤으로 구성해야 해. 특히 '시간이 더 필요해요'와 같이 사용자의 망설임이나 어려움이 감지되는 순간에는, 각 사용자 유형별 코치 페르소나의 핵심 목표와 균형 지침을 면밀히 반영하여 **'잔소리'가 아닌 '맞춤형 지지와 독려'로 느껴지도록 섬세하게 표현**해야 함을 잊지 말아야 해.
    
    사용자 정보:
    -사용자 유형:$userType
     -비움 미션:$missionName
    -공간 밀집도:$density
    
    위 정보를 바탕으로, 다음 JSON 형식에 맞춰 5단계 미션 가이드를 생성해줘.
    각 단계(step)의 lines는 3~4개의 문장으로 구성해줘.
    
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
              List<String> rawLines = List<String>.from(step['lines']);
              String fullTextBlock = rawLines.join(' ');
              List<String> splitSentences =
                  fullTextBlock
                      .split(RegExp(r'(?<=[.!?])\s*'))
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();

              return StepData(title: step['title'], lines: splitSentences);
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

  Future<void> _generateMolHelp() async {
    if (_missionSteps.isEmpty) return;

    setState(() {
      _isGeneratingChoices = true;
      _showChoices = true;
    });

    final currentStepTitle = _missionSteps[_currentStepIndex].title;

    final prompt = """
  너는 사용자의 비움 미션을 돕는 친절한 AI 코치야. 사용자가 '$currentStepTitle' 단계에서 막막함을 느껴 '모르겠어요' 버튼을 눌렀어.
  
  사용자가 비움을 잘 실천할 수 있도록, 질문 1개와 단답형 선택지 3개를 제안해줘.
  -질문은 한문장을 넘어가지 않게 짧게 부탁해.
  - 모든 텍스트는 반말로 작성해줘.

  아래 JSON 형식에 맞춰서 답변해줘.
  {
    "question": "여기에 질문 생성",
    "choices": ["선택지 1 생성", "선택지 2 생성", "선택지 3 생성"]
  }
  """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      String? text = response.text?.trim() ?? "";

      final startIndex = text.indexOf('{');
      final endIndex = text.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1) {
        final jsonString = text.substring(startIndex, endIndex + 1);
        final decoded = jsonDecode(jsonString);

        setState(() {
          _molQuestion = decoded['question'];
          _molChoices = List<String>.from(decoded['choices']);
        });
      }
    } catch (e) {
      print("몰라형 도움말 생성 오류: $e");
      setState(() {
        _molQuestion = "어떤 것부터 시작해볼까?";
        _molChoices = ["가장 쉬워 보이는 것", "가장 오래된 것", "가장 자리 차지하는 것"];
      });
    } finally {
      setState(() {
        _isGeneratingChoices = false;
      });
    }
  }

  Future<void> _startTtsSequence({int startFrom = 0}) async {
    if (_isTtsSequenceRunning || _ttsEngine == null) return;

    final currentSessionId = ++_ttsSessionId;
    _isTtsSequenceRunning = true;

    try {
      for (int i = startFrom; i < _currentLines.length; i++) {
        if (_isPaused || !_isTtsEnabled || _ttsSessionId != currentSessionId)
          break;

        setState(() {
          _currentLineIndex = i;
          _isTtsSpeaking = true;
        });

        await _ttsEngine!.speak(_currentLines[i]);

        if (_ttsSessionId != currentSessionId) break;

        await Future.delayed(Duration(milliseconds: 1000));

        setState(() {
          _isTtsSpeaking = false;
        });
      }
    } catch (e) {
      print("TTS 오류 : $e");
    } finally {
      _isTtsSequenceRunning = false;
    }
  }

  void _onStepFinished() async {
    _ttsEngine?.stop();
    _ttsSessionId++;

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

      if (_isPaused) {
        _ttsEngine?.stop(); // TTS 일시정지 대신 stop
        _ttsSessionId++; // 현재 TTS 세션 중단
      } else {
        if (_currentLineIndex >= 0 &&
            _currentLineIndex < _currentLines.length &&
            _isTtsEnabled) {
          _startTtsSequence(startFrom: _currentLineIndex); // 현재 줄부터 다시 시작
        }

        if (_timer == null || !_timer!.isActive) {
          _startTimer();
        }
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
    _ttsEngine?.stop();
    _ttsSessionId++; // 현재 실행 중인 루프 중단
    _scrollController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final Color baseColor;

    switch (_currentUserType) {
      case UserType.bang:
        baseColor = const Color(0xFFF9F1FD);
        break;
      case UserType.gam:
        baseColor = const Color(0xFFFFF4EE);
        break;
      case UserType.mol:
        baseColor = const Color(0xFFF3FBF0);
        break;
    }

    String loadingVideoPath;
    switch (_currentUserType) {
      case UserType.bang:
        loadingVideoPath = 'assets/mission/loading_re.mp4';
        break;
      case UserType.gam:
        loadingVideoPath = 'assets/mission/loading_dr.mp4';
        break;
      case UserType.mol:
        loadingVideoPath = 'assets/mission/loading_cl.mp4';
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body:
          _isLoading
              ? Center(
                child: SizedBox(
                  width:
                      MediaQuery.of(context).size.width > 1000
                          ? 1000
                          : MediaQuery.of(context).size.width,
                  child: LoadingVideo(videoPath: loadingVideoPath),
                ),
              )
              : SafeArea(
                child: SizedBox.expand(
                  child: Stack(
                    children: [
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
                                    alignment: Alignment.centerLeft,
                                    child: IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                                // ▶︎ 타이틀 + TTS 버튼 (85%)
                                Expanded(
                                  child: Container(
                                    color: baseColor,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              (_missionSteps.isNotEmpty &&
                                                      _currentStepIndex >= 0 &&
                                                      _currentStepIndex <
                                                          _missionSteps.length)
                                                  ? _missionSteps[_currentStepIndex]
                                                      .title
                                                  : '',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: _toggleTts,
                                          icon: Icon(
                                            _isTtsEnabled
                                                ? Icons.volume_up
                                                : Icons.volume_off,
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
                                      StepNavigation(
                                        missionType:
                                            _currentUserType == UserType.gam
                                                ? 'gam'
                                                : (_currentUserType ==
                                                        UserType.mol
                                                    ? 'mol'
                                                    : 'bas'),
                                        currentIndex: _currentStepIndex,
                                      ),
                                    ],
                                  ),
                                ),

                                // ▶︎ 오른쪽 본문 내용
                                Expanded(
                                  child: Container(
                                    color: baseColor,
                                    padding: const EdgeInsets.fromLTRB(
                                      90,
                                      70,
                                      90,
                                      70,
                                    ),
                                    child: _buildContentByType(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // 🔹 TTS 애니메이션 오버레이
                      if (_isTtsSpeaking)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Image.asset(
                              _currentUserType == UserType.bang
                                  ? 'assets/gradient/gradient.png'
                                  : _currentUserType == UserType.gam
                                  ? 'assets/gradient/gradient_gam.png'
                                  : 'assets/gradient/gradient_mol.png',
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }

  ///
  /// 유형에 따라 분기
  ///
  Widget _buildContentByType(BuildContext context) {
    switch (_currentUserType) {
      case UserType.gam:
        return _buildGamLayout(context);
      case UserType.mol:
        return _buildMolLayout(context);
      default:
        return _buildBasLayout(context);
    }
  }

  ///
  /// 기본형 (bas) → 기존 코드 그대로
  ///
  Widget _buildBasLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (_missionSteps.isNotEmpty &&
                  _currentStepIndex >= 0 &&
                  _currentStepIndex < _missionSteps.length)
              ? _missionSteps[_currentStepIndex].title
              : '',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),

        // 🔹 타이머 + 버튼
        Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF7F91FF),
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
            Text(
              _formatDuration(_remainingTime),
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () {
                setState(() {
                  _remainingTime += const Duration(seconds: 30);
                });
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFD7DCFA),
                ),
                child: const Center(
                  child: Text(
                    '+',
                    style: TextStyle(
                      fontSize: 60,
                      color: Color(0xFF7F91FF),
                      fontWeight: FontWeight.bold,
                      height: -0.1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        // 🔹 TTS 텍스트 박스
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: tts_text_box(
              lines: _currentLines,
              currentLineIndex:
                  _currentLines.isNotEmpty ? _currentLineIndex : -1,
              controller: _scrollController,
            ),
          ),
        ),
        const SizedBox(height: 50),

        // 🔹 하단 버튼
        LongButton(text: "끝났어요", onPressed: _onStepFinished),
      ],
    );
  }

  ///
  /// 감정형 (gam)
  ///
  Widget _buildGamLayout(BuildContext context) {
    double progressValue = 0.0;
    if (widget.missionTime.inSeconds > 0) {
      progressValue =
          _remainingTime.inSeconds.toDouble() /
          widget.missionTime.inSeconds.toDouble();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final basePadding = screenWidth < 900 ? 16.0 : 24.0;

    // 박스 높이 (화면 크기에 따라 비율 조정)
    final double boxHeight = screenHeight * 0.6;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          // 🔹 위쪽 메인 레이아웃
          SizedBox(
            height: boxHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 왼쪽 (1:1.5), 오른쪽 (1.55:1.5)
                final double leftBoxHeight = boxHeight;
                final double leftBoxWidth = leftBoxHeight / 1.8; // 1:1.5 → W/H
                final double rightBoxHeight = boxHeight / 1;
                final double rightBoxWidth =
                    rightBoxHeight * (1.55 / 1.68); // ✅ 1.55:1.5 → W/H

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ◀︎ 왼쪽 박스
                    Container(
                      width: leftBoxWidth,
                      height: leftBoxHeight,
                      margin: EdgeInsets.only(right: basePadding),
                      padding: EdgeInsets.all(basePadding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ▶ 재생/일시정지 버튼
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF7F91FF),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isPaused ? Icons.play_arrow : Icons.pause,
                                size: 40,
                                color: Colors.white,
                              ),
                              onPressed: _togglePause,
                            ),
                          ),
                          const SizedBox(height: 5),

                          SizedBox(
                            width: 250,
                            height: 250,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: CircularProgressIndicator(
                                    value: progressValue,
                                    strokeWidth: 14,
                                    backgroundColor: Colors.grey.shade200,
                                    color: const Color(0xFF7F91FF),
                                  ),
                                ),
                                Lottie.asset(
                                  'assets/HourGlass.json',
                                  width: 130, // Lottie 원본 크기 유지
                                  height: 130, // Lottie 원본 크기 유지
                                  fit: BoxFit.contain, // 작은 250x250 공간에 맞춤
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ▶ +30초 버튼
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _remainingTime += const Duration(seconds: 30);
                              });
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFD7DCFA),
                              ),
                              child: const Center(
                                child: Text(
                                  '+',
                                  style: TextStyle(
                                    fontSize: 40,
                                    color: Color(0xFF7F91FF),
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ▶︎ 오른쪽 박스
                    Container(
                      width: rightBoxWidth,
                      height: rightBoxHeight,
                      padding: EdgeInsets.all(basePadding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: tts_text_box(
                        lines: _currentLines,
                        currentLineIndex: _currentLineIndex,
                        controller: _scrollController,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 30),

          // 🔹 하단 버튼
          LongButton(text: "끝났어요", onPressed: _onStepFinished),
        ],
      ),
    );
  }

  ///
  /// 몰라형 (mol) - 수정된 코드
  ///
  Widget _buildMolLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 타이머 (작게)
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF7F91FF),
              ),
              child: IconButton(
                icon: Icon(
                  _isPaused ? Icons.play_arrow : Icons.pause,
                  size: 40,
                  color: Colors.white,
                ),
                onPressed: _togglePause,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              _formatDuration(_remainingTime),
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                setState(() {
                  _remainingTime += const Duration(seconds: 30);
                });
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFD7DCFA),
                ),
                child: const Center(
                  child: Text(
                    '+',
                    style: TextStyle(
                      fontSize: 40,
                      color: Color(0xFF7F91FF),
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 🔹 메인 콘텐츠 영역 (TTS or 선택지)
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 60),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                _showChoices
                    ? _buildMolChoices()
                    : tts_text_box(
                      lines: _currentLines,
                      currentLineIndex: _currentLineIndex,
                      controller: _scrollController,
                    ),
          ),
        ),
        const SizedBox(height: 25),

        // 🔹 하단 버튼 영역
        _showChoices
            ? Align(
              alignment: Alignment.center,
              child: LongButton(
                text: "알겠어요",
                onPressed: () {
                  setState(() {
                    _showChoices = false;
                  });
                },
              ),
            )
            : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _generateMolHelp,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "모르겠어요",
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LongButton(text: "끝났어요", onPressed: _onStepFinished),
                ),
              ],
            ),
      ],
    );
  }

  ///
  /// 몰라형 선택지 UI
  ///
  Widget _buildMolChoices() {
    if (_isGeneratingChoices) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _molQuestion,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFF463EC6),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children:
              _molChoices.map((choiceText) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: _choiceBox(
                      choiceText,
                      imagePath: 'assets/popup.png', // 반드시 전달
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _choiceBox(String text, {String? imagePath}) {
    return GestureDetector(
      onTap: () {
        if (imagePath != null) {
          _showChoicePopup(imagePath);
        }
      },
      child: Container(
        height: 260,
        padding: const EdgeInsets.symmetric(vertical: 70),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5FF),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2, // ✅ ② 두 줄까지만 표시
          overflow: TextOverflow.ellipsis, // ✅ ③ 너무 길면 ... 처리
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
