import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:mu/widgets/category_edit_popup.dart';
import 'package:mu/widgets/keepdialogs.dart';
import 'package:mu/widgets/longbutton.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'widgets/ItemSaveSection.dart';
import 'package:mu/data/sampledata.dart';
import 'user_theme_manager.dart'; // Import the user theme manager
import 'package:mu/data/database.dart';
import 'package:drift/drift.dart' show Value;

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
  List<Map<String, dynamic>> categories = [];
  int? selectedIndex;
  String _currentItemName = "새 항목";

  GenerativeModel? _model;
  bool _isGeminiInitialized = false;

  final AppDatabase _database = AppDatabase.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initGemini();
    _initSpeech();
    _loadData();
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
    final List<KeepBoxesCompanion> itemsToSave = [];
    final DateFormat formatter = DateFormat("yyyy.MM.dd");

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
        } catch (e) {
          print("날짜 파싱 오류 : $e, 항목 : ${itemMap['name']}");
        }
      }
    }
    await _database.replaceAllKeepBoxes(itemsToSave);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장되었습니다!')));
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
      body: Row(
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
          // 오른쪽 90% 영역
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
                longbutton(text: '저장', onPressed: _saveData),
                SizedBox(height: 24 * heightRatio),
              ],
            ),
          ),
        ],
      ),
    );
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
