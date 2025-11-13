import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mu/keepbox.dart';
import 'package:mu/ttsApi.dart';
import 'package:mu/widgets/shortbutton.dart';
import 'dart:async';
import 'dart:convert';
import 'data/database.dart';
import 'widgets/tts_text_box.dart';
import 'widgets/step_navigation.dart';
import 'keepbox_start.dart';
import 'widgets/loadingvideo.dart';
import 'widgets/choice_popup.dart';
import 'widgets/longbutton.dart';
import 'user_theme_manager.dart';

List<StepData> _parseMissionSteps(String jsonText) {
  String text = jsonText;

  final startIndex = text.indexOf('{');
  final endIndex = text.lastIndexOf('}');

  if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
    text = text.substring(startIndex, endIndex + 1).trim();
  }
  final decoded = jsonDecode(text);

  if (decoded is! Map<String, dynamic> || !decoded.containsKey('steps')) {
    throw Exception("JSON 형식이 다르거나 'steps' 키를 포함하고 있지 않습니다.");
  }

  final List<dynamic> stepsJson = decoded['steps'];

  return stepsJson.map((step) {
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
}

class StepData {
  final String title;
  final List<String> lines;

  StepData({required this.title, required this.lines});
}

class _MolChoiceData {
  final String question;
  final List<String> choices;

  _MolChoiceData(this.question, this.choices);
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

  List<StepData> _missionSteps = [];
  bool _isLoading = true;

  late final GenerativeModel _model;

  final ScrollController _scrollController = ScrollController();
  final List<_MolChoiceData> _molStepData = [
    _MolChoiceData("다음 세 가지 중 하나를 선택해보자. 어떤 기준으로 해야할지 생각해볼까?", [
      "필요성",
      "용도별",
      "사용 주기",
    ]),
    _MolChoiceData("다음 세 가지 중 하나를 선택해보자. 어떤 기준으로 해야할지 생각해볼까?", [
      "유통기한",
      "상한 정도",
      "보관 기간",
    ]),
    _MolChoiceData("다음 세 가지 중 하나를 선택해보자. 어떤 기준으로 해야할지 생각해볼까?", [
      "남길 물건",
      "버릴 물건",
      "애매한 물건",
    ]),
    _MolChoiceData("다음 세 가지 중 하나를 선택해보자. 어떤 기준으로 해야할지 생각해볼까?", [
      "자주 쓰는",
      "모양/크기",
      "품목별",
    ]),
    _MolChoiceData("다음 세 가지 중 하나를 선택해보자. 어떤 기준으로 해야할지 생각해볼까?", [
      "기한",
      "장소",
      "가치",
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _currentUserType = widget.userType;
    _remainingTime = widget.missionTime;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAsync();
    });
  }

  Future<void> _initializeAsync() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    _ttsEngine = ElevenLabsTTS(
      apiKey: dotenv.env['ELEVENLABS_API_KEY']!,
      userType: _currentUserType,
    );
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      await _generateMissionSteps();
    }
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
    final List<String> stepMessages = [
      "와, 좋은 생각이야!\n첫 단계부터 아주 멋진 선택인데?",
      "점점 더 잘하네!\n역시 생각보다 어렵지 않지?\n그럼 이 기준으로 한 번 해볼까?",
      "정말 좋은 생각이야!\n이렇게 하면 나중에도 훨씬 쉬울 거야.",
      "이제 정말 잘하네!\n역시 생각보다 어렵지 않지?\n그럼 이 기준으로 한 번 해볼까?",
      "마지막까지 훌륭해!\n이 기준이라면 어떤 것이든\n잘 해결할 수 있을 거야.",
    ];

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

    if (widget.orderedMissions.isEmpty ||
        widget.currentMissionIndex >= widget.orderedMissions.length) {
      print("오류: 미션 정보를 찾을 수 없습니다. (인덱스: ${widget.currentMissionIndex})");
      setState(() => _isLoading = false);
      return;
    }

    final Section currentMission =
        widget.orderedMissions[widget.currentMissionIndex];

    final String missionName = currentMission.name;

    final String density = currentMission.clutterLevel;

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

    const int maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('API Key 확인: ${dotenv.env['GEMINI_API_KEY']}');
        print('Gemini API 호출 시도: $attempt회');

        final response = await _model
            .generateContent([Content.text(prompt)])
            .timeout(
              const Duration(seconds: 20),
              onTimeout: () {
                throw Exception("Gemini API 응답 시간 초과");
              },
            );

        String? text = response.text;

        if (text == null || text.isEmpty) {
          throw Exception("API가 비어있는 응답을 반환했습니다.");
        }

        final newMissionSteps = await compute(_parseMissionSteps, text);

        setState(() {
          _missionSteps = newMissionSteps;
          _loadStepData(0);
          _isLoading = false;
        });

        if (!_isPaused) _startTimer();
        return;
      } catch (e) {
        print('미션 생성 중 오류 발생 (시도 $attempt회): $e');

        if (attempt == maxRetries) {
          print("최대 재시도 횟수($maxRetries회) 초과. 초기화 실패 처리.");

          setState(() {
            _isLoading = false;
          });
          return;
        }

        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<void> _loadStepData(int index) async {
    setState(() {
      _currentStepIndex = index;
      _currentLines = _missionSteps[index].lines;
      _currentLineIndex = 0;
      _isTtsSpeaking = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(0);
    });

    //await Future.delayed(Duration(milliseconds: 300));

    if (_isTtsEnabled) {
      _startTtsSequence();
    }
  }

  Future<void> _generateMolHelp() async {
    if (_missionSteps.isEmpty) return;

    if (_currentStepIndex < 0 || _currentStepIndex >= _molStepData.length) {
      print("Error: Invalid step index for Mol choices: $_currentStepIndex");
      final data = _molStepData[0];
      setState(() {
        _molQuestion = data.question;
        _molChoices = data.choices;
        _showChoices = true;
      });
      return;
    }
    final data = _molStepData[_currentStepIndex];

    setState(() {
      _molQuestion = data.question;
      _molChoices = data.choices;
      _showChoices = true;
    });
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
      final int nextMissionIndex = widget.currentMissionIndex + 1;
      await AppDatabase.instance.updateUserMissionIndex(1, nextMissionIndex);
      print("✅ 미션 단계 완료! DB 인덱스를 ${nextMissionIndex}로 업데이트.");

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => keepbox(
                nextMissionIndex: nextMissionIndex,
                totalMissionCount: widget.orderedMissions.length,
              ),
        ),
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
        _ttsEngine?.stop();
        _ttsSessionId++;
      } else {
        if (_currentLineIndex >= 0 &&
            _currentLineIndex < _currentLines.length &&
            _isTtsEnabled) {
          _startTtsSequence(startFrom: _currentLineIndex);
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
    _ttsSessionId++;
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
        baseColor = const Color(0xFFFFF6EF);
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child:
            _isLoading
                ? Center(
                  key: const ValueKey('loading'),
                  child: SizedBox(
                    width:
                        MediaQuery.of(context).size.width > 1000
                            ? 1000
                            : MediaQuery.of(context).size.width,
                    child: LoadingVideo(videoPath: loadingVideoPath),
                  ),
                )
                : SafeArea(
                  key: const ValueKey('mission_content'),
                  child: SizedBox.expand(
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            // ─────── 상단바 ───────
                            SizedBox(
                              height: 150,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    width: screenWidth * 0.15,
                                    color: Colors.white,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: IconButton(
                                        onPressed: () => Navigator.pop(context),
                                        icon: SvgPicture.asset(
                                          'assets/left.svg',
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 30,
                                      ),
                                      color: baseColor,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                (_missionSteps.isNotEmpty &&
                                                        _currentStepIndex >=
                                                            0 &&
                                                        _currentStepIndex <
                                                            _missionSteps
                                                                .length)
                                                    ? _missionSteps[_currentStepIndex]
                                                        .title
                                                    : '',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontFamily:
                                                      'PretendardRegular',
                                                  color: Color(0xFF5D5D5D),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: _toggleTts,
                                            icon: SvgPicture.asset(
                                              'assets/mission/sound_on.svg',
                                              width: 36,
                                              height: 36,
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
                                  // 왼쪽 네비게이션
                                  Container(
                                    width: screenWidth * 0.15,
                                    color: Colors.white,
                                    child: Column(
                                      children: [
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

                                  // 오른쪽 본문 내용
                                  Expanded(
                                    child: Container(
                                      color: baseColor,
                                      padding: const EdgeInsets.fromLTRB(
                                        80,
                                        3,
                                        80,
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

                        // TTS 애니메이션 오버레이
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
  /// 방치형 (bas)
  ///
  Widget _buildBasLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ('    남은 시간'),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF5D5D5D),
            fontFamily: 'PretendardRegular',
          ),
        ),

        // 타이머 + 버튼
        Row(
          children: [
            IconButton(
              icon: SvgPicture.asset(
                'assets/mission/pause.svg',
                width: 84,
                height: 84,
              ),
              onPressed: _togglePause,
            ),
            const SizedBox(width: 20),
            Text(
              _formatDuration(_remainingTime),
              style: const TextStyle(
                fontSize: 80,
                color: Color(0xFF333333),
                fontFamily: 'PretendardSemiBold',
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () {
                setState(() {
                  _remainingTime += const Duration(seconds: 30);
                });
              },
              child: IconButton(
                icon: SvgPicture.asset(
                  'assets/mission/plus_time.svg',
                  width: 84,
                  height: 84,
                ),
                iconSize: 72,
                onPressed: null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // TTS 텍스트 박스
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(43),
            decoration: BoxDecoration(
              color: Color(0xFFFEFAFF),
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

        // 하단 버튼
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          //위쪽 메인 레이아웃
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  flex: 309,
                  child: Container(
                    margin: EdgeInsets.only(right: 20),
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFFCFA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 재생/일시정지 버튼
                        IconButton(
                          icon: SvgPicture.asset(
                            'assets/mission/pause.svg',
                            width: 64,
                            height: 64,
                          ),
                          onPressed: _togglePause,
                        ),
                        SizedBox(height: 15),
                        SizedBox(
                          width: 201,
                          height: 201,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  value: progressValue,
                                  strokeWidth: 14,
                                  backgroundColor: Color(0xFFD9D9D9),
                                  color: const Color(0xFF463EC6),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: Image.asset(
                                  'assets/mission/hourglass.gif',
                                  fit: BoxFit.contain, // 비율 유지하며 맞추기
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _remainingTime += const Duration(seconds: 30);
                            });
                          },
                          child: IconButton(
                            icon: SvgPicture.asset(
                              'assets/mission/plus_time.svg',
                              width: 64,
                              height: 64,
                            ),
                            onPressed: null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                //오른쪽 박스
                Flexible(
                  flex: 466,
                  child: Container(
                    padding: EdgeInsets.all(30),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color(0xFFFFFCFA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: tts_text_box(
                      lines: _currentLines,
                      currentLineIndex: _currentLineIndex,
                      controller: _scrollController,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 60),

          //하단 버튼
          LongButton(text: "끝났어요", onPressed: _onStepFinished),
        ],
      ),
    );
  }

  ///
  /// 몰라형 (mol)
  ///
  Widget _buildMolLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ('  남은 시간'),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF5D5D5D),
            fontFamily: 'PretendardRegular',
          ),
        ),

        // 타이머 + 버튼
        Row(
          children: [
            IconButton(
              icon: SvgPicture.asset(
                'assets/mission/pause.svg',
                width: 64,
                height: 64,
              ),
              onPressed: _togglePause,
            ),
            const SizedBox(width: 10),
            Text(
              _formatDuration(_remainingTime),
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 48,
                fontFamily: 'PretendardSemiBold',
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                setState(() {
                  _remainingTime += const Duration(seconds: 30);
                });
              },
              child: IconButton(
                icon: SvgPicture.asset(
                  'assets/mission/plus_time.svg',
                  width: 64,
                  height: 64,
                ),
                iconSize: 72,
                onPressed: null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        //메인 콘텐츠 영역
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 60),
            decoration: BoxDecoration(
              color: Color(0xFFFDFFFA),
              borderRadius: BorderRadius.circular(10),
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
        const SizedBox(height: 55),

        // 하단 버튼 영역
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
                Flexible(
                  child: ShortButton(
                    text: "모르겠어요",
                    isYes: false,
                    onPressed: _generateMolHelp,
                    height: 64,
                    fontSize: 18,
                    noBackgroundColor: Colors.transparent,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 25),
        Row(
          children: [
            SizedBox(width: 10),
            Text(
              _molQuestion,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'PretendardSemiBold',
                color: Color(0xFF463EC6),
              ),
            ),
          ],
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
                      imagePath: 'assets/popup.png',
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
      child: Center(
        child: Container(
          height: 120,
          width: 212,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F5FF),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'PretendardMedium',
              color: Color(0xFF5D5D5D),
            ),
          ),
        ),
      ),
    );
  }
}
