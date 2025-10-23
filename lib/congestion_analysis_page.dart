import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:mu/scheduling.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mu/data/database.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class longbutton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const longbutton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: isEnabled ? Colors.indigo[600] : Colors.grey[400],
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text),
    );
  }
}

class CongestionAnalysisLayout extends StatefulWidget {
  @override
  _CongestionAnalysisLayoutState createState() =>
      _CongestionAnalysisLayoutState();
}

class _CongestionAnalysisLayoutState extends State<CongestionAnalysisLayout> {
  CameraController? _cameraController;
  Interpreter? _interpreter;
  final int _inputSize = 300;
  List<String>? _labels;
  String? _currentSection;
  bool _isCapturing = false;

  Future<void>? _initializationFuture;

  Map<String, String> _results = {};
  String _headerTitle = "";

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeAll();
  }

  Future<void> _initializeAll() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!status.isGranted) {
      throw Exception('카메라 권한이 거부되었습니다.');
    }

    final db = AppDatabase.instance;
    final userType = await db.getUserType(1) ?? '방치형';

    switch (userType) {
      case '감정형':
        _headerTitle = "옷장 속 물건이\n얼마나 많은지 볼까요?";
        break;
      case '몰라형':
        _headerTitle = "서랍장 속 물건이\n얼마나 많은지 볼까요?";
        break;
      case '방치형':
      default:
        _headerTitle = "냉장고 속 물건이\n얼마나 많은지 볼까요?";
        break;
    }

    List<String> defaultSections;
    switch (userType) {
      case '감정형':
        defaultSections = ["선반", "행거 구역", "옷장 바닥 공간", "서랍"];
        break;
      case '몰라형':
        defaultSections = ["1단", "2단", "3단"];
        break;
      case '방치형':
      default:
        defaultSections = ["냉장실 한 칸", "얼음/얼린 식재료 칸", "냉동식품 칸"];
        break;
    }

    final dbSections = await db.getSectionsForUser(1);

    bool needsReset = false;
    if (dbSections.isEmpty) {
      needsReset = true;
    } else {
      String firstDBSectionName = dbSections.first.name;
      if (!defaultSections.contains(firstDBSectionName)) {
        needsReset = true;
      }
    }
    if (needsReset) {
      print("사용자 유형이 변경되었거나 첫 실행입니다. 섹션을 리셋합니다.");
      await db.deleteAllSectionsForUser(1);
      await db.batchInsertSections(1, defaultSections);
      _results = {for (var section in defaultSections) section: "분석 전"};
    } else {
      _results = {for (var s in dbSections) s.name: s.clutterLevel};
    }
    await _initCamera();
    await _loadModel();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
    );
    await _cameraController!.initialize();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/detect.tflite');
      final labelsData = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/labelmap.txt');
      _labels = labelsData.split('\n');
      print("모델 로딩 완료");
    } catch (e) {
      print("모델 로딩 실패: $e");
    }
  }

  Future<void> _captureAndAnalyze(String section) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    try {
      setState(() {
        _currentSection = section;
        _results[section] = "분석 중...";
      });

      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);

      final result = await _analyzeImage(imageFile);

      setState(() => _results[section] = result);

      final db = AppDatabase.instance;
      await db.updateSectionClutterByName(1, section, result);
    } catch (e) {
      setState(() => _results[section] = "분석 오류");
    }
  }

  Future<String> _analyzeImage(File imageFile) async {
    if (_interpreter == null) {
      return "모델 준비 안됨";
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return "이미지 오류";

      img.Image resizedImage = img.copyResizeCropSquare(
        originalImage,
        _inputSize,
      );

      var input = List.generate(
        1,
        (_) => List.generate(
          _inputSize,
          (y) => List.generate(_inputSize, (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [
              img.getRed(pixel).toInt(),
              img.getGreen(pixel).toInt(),
              img.getBlue(pixel).toInt(),
            ];
          }),
        ),
      );

      final outputTensors = _interpreter!.getOutputTensors();
      final Map<int, Object> outputs = {};
      for (var i = 0; i < outputTensors.length; i++) {
        final tensor = outputTensors[i];
        outputs[i] = List.filled(
          tensor.shape.reduce((value, element) => value * element),
          0.0,
        ).reshape(tensor.shape);
      }

      _interpreter!.runForMultipleInputs([input], outputs);

      final int locationsIndex = outputTensors.indexWhere(
        (t) => t.name.contains('PostProcess') && t.shape.length == 3,
      );
      final int classesIndex = outputTensors.indexWhere(
        (t) => t.name.contains('PostProcess') && t.name.contains(':1'),
      );
      final int scoresIndex = outputTensors.indexWhere(
        (t) => t.name.contains('PostProcess') && t.name.contains(':2'),
      );
      final int detectionsIndex = outputTensors.indexWhere(
        (t) => t.name.contains('PostProcess') && t.name.contains(':3'),
      );

      if (locationsIndex == -1 ||
          classesIndex == -1 ||
          scoresIndex == -1 ||
          detectionsIndex == -1) {
        return "모델 출력 텐서를 찾을 수 없습니다.";
      }

      final outputLocations = outputs[locationsIndex] as List;
      final outputClasses = outputs[classesIndex] as List;
      final outputScores = outputs[scoresIndex] as List;
      final numDetections = outputs[detectionsIndex] as List;

      final imageWidth = originalImage.width;
      final imageHeight = originalImage.height;
      final imageArea = imageWidth * imageHeight;

      List<Rect> boxes = [];
      double totalBoxArea = 0;

      int detectedCount = 0;
      final threshold = 0.3;

      for (int i = 0; i < numDetections[0].toInt(); i++) {
        if (outputScores[0][i] < threshold) continue;

        final box = outputLocations[0][i];
        final ymin = box[0] * imageHeight;
        final xmin = box[1] * imageWidth;
        final ymax = box[2] * imageHeight;
        final xmax = box[3] * imageWidth;

        boxes.add(Rect.fromLTWH(xmin, ymin, xmax - xmin, ymax - ymin));
        totalBoxArea += (xmax - xmin) * (ymax - ymin);
        detectedCount++;
      }

      final areaRatio = totalBoxArea / imageArea;

      if (detectedCount > 10 && areaRatio > 0.4) {
        return "혼잡";
      } else if (detectedCount > 6 && areaRatio > 0.3) {
        return "보통";
      } else {
        return "여유";
      }
    } catch (e) {
      print("분석 오류: $e");
      return "분석 오류";
    }
  }

  void _addSection() {
    if (_results.length >= 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('칸은 최대 5개까지 추가할 수 있습니다.')));
      return;
    }

    TextEditingController controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '새로운 칸 추가',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: '칸 이름을 입력하세요',
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                longbutton(
                  text: "추가하기",
                  onPressed: () async {
                    if (controller.text.trim().isNotEmpty) {
                      final newName = controller.text.trim();

                      setState(() {
                        _results[controller.text.trim()] = "분석 전";
                      });
                      final db = AppDatabase.instance;
                      await db.addSection(1, newName);

                      Navigator.of(context).pop();
                    } else {
                      // 입력값이 없으면 경고 표시
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('칸 이름을 입력해주세요.')),
                      );
                    }
                  },
                  isEnabled: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteSection(String section) async {
    setState(() {
      _results.remove(section);
      if (_currentSection == section) {
        _currentSection = null;
      }
    });

    final db = AppDatabase.instance;
    await db.deleteSectionByName(1, section);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('\'$section\'이(가) 삭제되었습니다.')));
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthRatio = screenWidth / 1280;
    final heightRatio = screenHeight / 832;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("초기화 중 오류가 발생했습니다: ${snapshot.error}"));
          }

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 20),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 160 * widthRatio),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 25 * heightRatio),
                        Text(
                          _headerTitle,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 20 * heightRatio),
                        const Text(
                          "현재 상태를 촬영하면, 혼잡/보통/여유 중 하나로 알려드릴게요.\n불필요한 공간은 밀어서 삭제할 수 있어요.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF5D5D5D),
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 25 * heightRatio),

                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        _cameraController == null ||
                                                !_cameraController!
                                                    .value
                                                    .isInitialized
                                            ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                            : Align(
                                              alignment: Alignment.topCenter,
                                              child: AspectRatio(
                                                aspectRatio:
                                                    2.29 /
                                                    _cameraController!
                                                        .value
                                                        .aspectRatio,
                                                child: CameraPreview(
                                                  _cameraController!,
                                                ),
                                              ),
                                            ),
                                        // 코너 가이드 라인
                                        Positioned(
                                          top: 40 * heightRatio,
                                          left: 40 * widthRatio,
                                          child: Container(
                                            width: 30,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 40 * heightRatio,
                                          left: 40 * widthRatio,
                                          child: Container(
                                            width: 4,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 40 * heightRatio,
                                          right: 40 * widthRatio,
                                          child: Container(
                                            width: 30,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 40 * heightRatio,
                                          right: 40 * widthRatio,
                                          child: Container(
                                            width: 4,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 40 * heightRatio,
                                          left: 40 * widthRatio,
                                          child: Container(
                                            width: 30,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 40 * heightRatio,
                                          left: 40 * widthRatio,
                                          child: Container(
                                            width: 4,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 40 * heightRatio,
                                          right: 40 * widthRatio,
                                          child: Container(
                                            width: 30,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 40 * heightRatio,
                                          right: 40 * widthRatio,
                                          child: Container(
                                            width: 4,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        // 카메라 뷰의 텍스트 오버레이 (조건부)
                                        if (_currentSection != null)
                                          Positioned(
                                            bottom: 30 * heightRatio,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _currentSection!,
                                                style: const TextStyle(
                                                  color: Color(0xFf5D5D5D),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 20 * widthRatio),
                              Expanded(
                                flex: 2,
                                child: ListView(
                                  children: [
                                    ..._results.keys.map((section) {
                                      Color statusBackgroundColor =
                                          Colors.transparent;
                                      Color statusTextColor = Colors.black;
                                      bool showStatus =
                                          true; // "분석 전"일 때는 상태를 숨기기 위한 플래그

                                      switch (_results[section]!) {
                                        case '혼잡':
                                          statusBackgroundColor = const Color(
                                            0xFFF9C0C0,
                                          );
                                          statusTextColor = const Color(
                                            0xFFF16767,
                                          );
                                          break;
                                        case '보통':
                                          statusBackgroundColor = const Color(
                                            0xFFE9F0FC,
                                          );
                                          statusTextColor = const Color(
                                            0xFF678FF1,
                                          );
                                          break;
                                        case '여유':
                                          statusBackgroundColor = const Color(
                                            0xFFC6E9C6,
                                          );
                                          statusTextColor = const Color(
                                            0xFF63BB63,
                                          );
                                          break;
                                        default: // "분석 전" 또는 "분석 중..."
                                          showStatus = false;
                                          break;
                                      }

                                      return Slidable(
                                        key: ValueKey(section),

                                        endActionPane: ActionPane(
                                          motion: const ScrollMotion(),
                                          extentRatio: 0.25,
                                          children: [
                                            SlidableAction(
                                              onPressed: (context) {
                                                _deleteSection(section);
                                              },
                                              backgroundColor: Colors.redAccent,
                                              foregroundColor: Colors.white,
                                              icon: Icons.delete,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4.0,
                                            horizontal: 3,
                                          ),
                                          child: Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 0,
                                            color: Color(0xFFF5F5F5),
                                            // 카드 배경색을 연한 회색으로 변경
                                            child: ListTile(
                                              leading:
                                                  showStatus // "분석 전"이 아닐 때만 상태 박스 표시
                                                      ? Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              statusBackgroundColor,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                2,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          _results[section]!,
                                                          style: TextStyle(
                                                            color:
                                                                statusTextColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      )
                                                      : null,
                                              title: Text(
                                                section,
                                                style: const TextStyle(
                                                  color: Color(0xFF5D5D5D),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 4,
                                                  ),
                                              onTap:
                                                  () => _captureAndAnalyze(
                                                    section,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    // "추가" 버튼
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        elevation: 0,
                                        color: const Color(0xFFF3F5FF),
                                        // 추가 버튼 배경색 연하늘색
                                        child: ListTile(
                                          title: Text.rich(
                                            TextSpan(
                                              style: TextStyle(
                                                color: const Color(0xFF5D5D5D),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              children: [
                                                TextSpan(text: " 추가"),
                                                TextSpan(
                                                  text: "  +",
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFFB0B8C1,
                                                    ),
                                                    fontSize: 23,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 4.0,
                                              ),
                                          onTap: _addSection,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 100 * heightRatio),
                        longbutton(
                          text: "다음",
                          onPressed: () {
                            // 다음 페이지로 이동
                            final analyzedResults = Map<String, String>.from(
                              _results,
                            )..removeWhere(
                              (key, value) =>
                                  value == '분석 전' || value.contains('분석'),
                            );

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => EmptyingSchedulePage(
                                      analysisResults: analyzedResults,
                                    ),
                              ),
                            );
                          },
                          isEnabled: true,
                        ),
                        SizedBox(height: 100 * heightRatio),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
