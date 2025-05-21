// mission_step_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'widgets/tts_text_box.dart';
import 'widgets/step_navigation.dart';

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

  final List<StepData> missionSteps = [
    StepData(title: "냉장고 안 내용물 전부 꺼내기", lines: [
      "생각만 하지 말고 지금 당장 시작해.",
      "냉장고 문 열고, 안에 있는 음료수, 야채, 반찬, 찌개 통, 소스병까지 전부 꺼내.",
      "깊숙한 칸, 구석, 문 쪽 포켓까지 다 꺼내.",
      "‘잠깐만’은 없어. 미루면 끝도 없어. 당장 행동해."
    ]),
    StepData(title: "유통기한 확인하기", lines: [
      "유통기한 지난 건 무조건 버려.",
      "눈 감고 버려. 아깝다는 말, 지금 금지야.",
      "이미 버린 돈이야. 몸에 안 좋은 거 먹겠다고?",
      "왜? 누구 위해서?",
      "지금 버리면 그게 건강 챙기는 첫 걸음이야."
    ]),
    StepData(title: "안 먹는 식재료 과감히 버리기", lines: [
      "쓴 적 없는 소스, 이상한 향신료, 다 버려.",
      "‘언젠가’ 안 와. 그 ‘언젠가’ 3년째 아니야?",
      "한 번도 안 썼으면 앞으로도 안 써.",
      "남겨둘수록 냉장고는 쓰레기통이 돼. 지금 버려."
    ]),
    StepData(title: "애매한 식재료 잠시 보류하기", lines: [
      "애매한 건 딱 10초 고민하고, ‘버릴까 말까 상자’에 넣어.",
      "미련과 혼란은 그 상자 안에 다 넣고, 냉장고 안은 깔끔하게.",
      "나중에 다시 판단하면 돼.",
      "지금 냉장고는 ‘정리 공간’이지, ‘보관 창고’ 아니야."
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _startTimer();
    _loadStepData(_currentStepIndex);
  }

  void _initTts() {
    _flutterTts.setSpeechRate(0.45);
    _flutterTts.setPitch(1.0);
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

  void _loadStepData(int index) {
    _currentLines = missionSteps[index].lines;
    _currentLineIndex = -1;
    if (_isTtsEnabled) {
      _startTtsSequence();
    }
  }

  Future<void> _startTtsSequence() async {
    for (int i = 0; i < _currentLines.length; i++) {
      if (_isPaused) break;
      setState(() => _currentLineIndex = i);
      await _flutterTts.speak(_currentLines[i]);
      await Future.delayed(Duration(seconds: 2));
    }
  }

  void _onStepFinished() {
    if (_currentStepIndex < missionSteps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _loadStepData(_currentStepIndex);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("모든 단계를 완료했어요!")),
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
    });
  }

  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "${(duration.inHours).toString().padLeft(2, '0')}:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단바
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 28),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          missionSteps[_currentStepIndex].title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleTts,
                      icon: Icon(
                        _isTtsEnabled ? Icons.volume_up : Icons.volume_off,
                        size: 28,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StepNavigation(
                        currentIndex: _currentStepIndex,
                        totalSteps: missionSteps.length,
                        onStepSelected: (step) {
                          setState(() {
                            _currentStepIndex = step - 1;
                            _loadStepData(_currentStepIndex);
                          });
                        },
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '남은 시간',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 타이머
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _togglePause,
                                  icon: Icon(
                                    _isPaused ? Icons.play_arrow : Icons.pause,
                                    size: 80,
                                    color: _isPaused ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _formatDuration(_remainingTime),
                                  style: const TextStyle(
                                    fontSize: 80,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),

                            Container(
                              width: 1600, // 원하는 고정 너비
                              height: 400, // 원하는 고정 높이
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F5FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: tts_text_box(
                                lines: _currentLines,
                                currentLineIndex: _currentLineIndex,
                              ),
                            ),

                            const Spacer(),

                            // 버튼
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.black),
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text("아직 안 끝났어요", style: TextStyle(color: Colors.black, fontSize: 18)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _onStepFinished,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text("끝났어요", style: TextStyle(color: Colors.white, fontSize: 18)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
    );
  }
}