import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;
import 'package:mu/widgets/shortbutton.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:mu/scheduling.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mu/data/database.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mu/widgets/longbutton.dart';
import 'package:flutter/foundation.dart';

class CongestionAnalysisLayout extends StatefulWidget {
  final String spaceName;

  const CongestionAnalysisLayout({super.key, required this.spaceName});

  @override
  _CongestionAnalysisLayoutState createState() =>
      _CongestionAnalysisLayoutState();
}

class _CongestionAnalysisLayoutState extends State<CongestionAnalysisLayout>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  Interpreter? _interpreter;
  final int _inputSize = 300;
  List<String>? _labels;
  String? _currentSection;
  String? _selectedSection;

  Future<void>? _initializationFuture;

  Future<void> showDeleteConfirmationDialog({
    required BuildContext context,
    required String sectionName,
    required VoidCallback onDelete,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final double dialogWidth = 543;
        final double dialogHeight = 384;

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: dialogWidth,
              height: dialogHeight,
              padding: const EdgeInsets.all(50),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '정말로 삭제하시겠습니까?',
                    style: TextStyle(
                      fontSize: 32,
                      fontFamily: 'PretendardBold',
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "삭제 시 세부 공간이 목록에서 제거돼요!\n삭제된 공간은 다시 추가할 수 있어요.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'PretendardRegular',
                      color: Color(0xFF5D5D5D),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ShortButton(
                        text: "아니요",
                        isYes: false,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        width: 185,
                        height: 52,
                        fontSize: 16,
                      ),
                      ShortButton(
                        text: "네",
                        isYes: true,
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          onDelete();
                        },
                        width: 185,
                        height: 52,
                        fontSize: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, Map<String, dynamic>> _results = {};
  String _headerTitle = "";
  String? _currentlyOpenSection;

  final Map<String, SlidableController> _slidableControllers = {};

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeAll();
  }

  @override
  SlidableController _getControllerFor(String section) {
    var controller = _slidableControllers[section];
    if (controller == null) {
      controller = SlidableController(this as TickerProvider);

      controller.animation.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _currentlyOpenSection = section;
          });
        } else if (status == AnimationStatus.dismissed) {
          if (_currentlyOpenSection == section) {
            setState(() {
              _currentlyOpenSection = null;
            });
          }
        }
      });
      _slidableControllers[section] = controller;
    }
    return controller;
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
    final String currentSpace = widget.spaceName;
    List<String> defaultSections;

    switch (currentSpace) {
      case '옷장':
        _headerTitle = "옷장 속 물건이\n얼마나 많은지 볼까요?";
        defaultSections = ["선반", "행거 구역", "옷장 바닥 공간", "서랍"];
        break;
      case '서랍장':
        _headerTitle = "서랍장 속 물건이\n얼마나 많은지 볼까요?";
        defaultSections = ["1단", "2단", "3단"];
        break;
      case '냉장고':
      default:
        _headerTitle = "냉장고 속 물건이\n얼마나 많은지 볼까요?";
        defaultSections = ["냉장실 한 칸", "얼음/얼린 식재료 칸", "냉동식품 칸"];
        break;
    }

    final allDbSections = await db.getSectionsForUser(1);

    final int currentMissionIndex = await db.getUserMissionIndex(1);
    final List<Section> orderedMissions = await db.getOrderedMissions(1);
    final Set<String> completedMissionNames;
    if (currentMissionIndex > 0 &&
        currentMissionIndex <= orderedMissions.length) {
      completedMissionNames =
          orderedMissions
              .sublist(0, currentMissionIndex)
              .map((s) => s.name)
              .toSet();
    } else {
      completedMissionNames = {};
    }
    Map<String, Map<String, dynamic>> tempResults = {};

    for (var s in allDbSections) {
      if (defaultSections.contains(s.name)) {
        tempResults[s.name] = {
          "clutter": s.clutterLevel,
          "completed": completedMissionNames.contains(s.name),
        };
      }
    }

    for (String defaultName in defaultSections) {
      if (!tempResults.containsKey(defaultName)) {
        tempResults[defaultName] = {"clutter": "분석 전", "completed": false};
      }
    }

    _results = tempResults;

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
        _results[section]!["clutter"] = "분석 중...";
      });

      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);

      final result = await _analyzeImage(imageFile);

      setState(() => _results[section]!["clutter"] = result);

      final db = AppDatabase.instance;
      final allDbSections = await db.getSectionsForUser(1);
      final bool exists = allDbSections.any((s) => s.name == section);

      if (!exists) {
        await db.addSection(1, section);
      }

      await db.updateSectionClutterByName(1, section, result);
    } catch (e) {
      setState(() => _results[section]!["clutter"] = "분석 오류");
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
        size: _inputSize,
      );

      var input = List.generate(
        1,
        (_) => List.generate(
          _inputSize,
          (y) => List.generate(_inputSize, (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
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
      final outputScores = outputs[scoresIndex] as List;
      final numDetections = outputs[detectionsIndex] as List;

      final imageWidth = originalImage.width.toDouble();
      final imageHeight = originalImage.height.toDouble();
      final imageArea = imageWidth * imageHeight;

      List<Rect> boxes = [];
      double totalBoxArea = 0;
      int detectedCount = 0;
      const threshold = 0.3;

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

      double overlapArea = 0;
      for (int i = 0; i < boxes.length; i++) {
        for (int j = i + 1; j < boxes.length; j++) {
          final Rect intersect = boxes[i].intersect(boxes[j]);
          if (intersect.width > 0 && intersect.height > 0) {
            overlapArea += intersect.width * intersect.height;
          }
        }
      }
      double overlapRatio = totalBoxArea > 0 ? overlapArea / totalBoxArea : 0;

      double areaRatio = totalBoxArea / imageArea;

      if (detectedCount > 9 && areaRatio > 0.5 && overlapRatio > 0.05) {
        return "혼잡";
      } else if (detectedCount > 6 && areaRatio > 0.3 && overlapRatio > 0.05) {
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

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 543,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            '취소',
                            style: TextStyle(
                              color: Color(0xFF5D5D5D),
                              fontSize: 16,
                              fontFamily: 'PretendardRegular',
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        '세부 공간 추가',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'PretendardMedium',
                          color: Color(0xFF5D5D5D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              '이름',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'PretendardMedium',
                                color: Color(0xFF5D5D5D),
                              ),
                            ),
                          ),
                        ),
                        TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF2F3F5),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),

                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (controller.text.trim().isNotEmpty) {
                                final newName = controller.text.trim();
                                setState(() {
                                  _results[newName] = {
                                    "clutter": "분석 전",
                                    "completed": false,
                                  };
                                });
                                final db = AppDatabase.instance;
                                await db.addSection(1, newName);
                                Navigator.of(context).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF463EC6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '저장하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'PretendardMedium',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
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
    super.dispose();
    // 🎯 TFLite 인터프리터 이중 해제 방지 로직 추가
    if (_interpreter != null) {
      // _interpreter가 null이거나 유효한 상태인지 확인
      try {
        _interpreter?.close();
      } catch (e) {
        // 이미 닫혔거나 오류 발생 시 무시
        if (kDebugMode) {
          print('TFLite Interpreter disposal error: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthRatio = screenWidth / 1280;
    final heightRatio = screenHeight / 832;
    bool isAnyAnalyzed = _results.values.any((result) {
      final clutter = result["clutter"];
      return clutter != "분석 전" && clutter != "분석 중..." && clutter != "분석 오류";
    });

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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: SvgPicture.asset('assets/left.svg'),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 180 * widthRatio),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 25 * heightRatio),
                        Text(
                          _headerTitle,
                          style: TextStyle(
                            fontFamily: 'PretendardBold',
                            fontSize: 32 * widthRatio,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 30 * heightRatio),
                        Text(
                          "현재 상태를 촬영하면, 혼잡/보통/여유 중 하나로 알려드릴게요.\n불필요한 공간은 밀어서 삭제할 수 있어요.",
                          style: TextStyle(
                            fontFamily: 'PretendardRegular',
                            fontSize: 20 * widthRatio,
                            color: const Color(0xFF5D5D5D),
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 30 * heightRatio),

                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
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
                                            : Positioned.fill(
                                              child: FittedBox(
                                                fit: BoxFit.cover,
                                                child: SizedBox(
                                                  width:
                                                      _cameraController!
                                                          .value
                                                          .previewSize!
                                                          .height,
                                                  height:
                                                      _cameraController!
                                                          .value
                                                          .previewSize!
                                                          .width,
                                                  child: CameraPreview(
                                                    _cameraController!,
                                                  ),
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
                                                style: TextStyle(
                                                  fontFamily:
                                                      'PretendardMedium',
                                                  color: const Color(
                                                    0xFf5D5D5D,
                                                  ),
                                                  fontSize: 14 * widthRatio,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 40 * widthRatio),
                              Expanded(
                                flex: 2,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: ListView(
                                    children: [
                                      ..._results.keys.map((section) {
                                        final sectionData = _results[section]!;
                                        final String clutterStatus =
                                            sectionData["clutter"] as String;
                                        final bool isCompleted =
                                            sectionData["completed"] as bool;

                                        Color statusBackgroundColor;
                                        Color statusTextColor;
                                        Color titleColor;
                                        Color tileBackgroundColor;
                                        bool showStatus = true;

                                        final bool isSliding =
                                            (_currentlyOpenSection == section);
                                        final controller = _getControllerFor(
                                          section,
                                        );

                                        if (isCompleted) {
                                          statusBackgroundColor = const Color(
                                            0xFFDBDEE7,
                                          );
                                          statusTextColor = const Color(
                                            0xFFB0B8C1,
                                          );
                                          titleColor = const Color(0xFFB0B8C1);
                                          tileBackgroundColor = const Color(
                                            0xFFF5F5F5,
                                          );
                                        } else {
                                          titleColor = const Color(0xFF5D5D5D);
                                          if (clutterStatus == "분석 전" ||
                                              clutterStatus == "분석 중...") {
                                            tileBackgroundColor = const Color(
                                              0xFFF5F5F5,
                                            );
                                          } else {
                                            tileBackgroundColor =
                                                isSliding
                                                    ? const Color(0xFFFFF3F3)
                                                    : const Color(0xFFF3F5FF);
                                          }
                                          switch (clutterStatus) {
                                            case '혼잡':
                                              statusBackgroundColor =
                                                  const Color(0xFFFFD7D7);
                                              statusTextColor = const Color(
                                                0xFFEC5353,
                                              );
                                              break;
                                            case '보통':
                                              statusBackgroundColor =
                                                  const Color(0xFFC0F1D0);
                                              statusTextColor = const Color(
                                                0xFF30AE65,
                                              );
                                              break;
                                            case '여유':
                                              statusBackgroundColor =
                                                  const Color(0xFFC6DEFF);
                                              statusTextColor = const Color(
                                                0xFF1B73EC,
                                              );
                                              break;
                                            default:
                                              showStatus = false;
                                              statusBackgroundColor =
                                                  Colors.transparent;
                                              statusTextColor = Color(
                                                0XFF5D5D5D,
                                              );
                                              break;
                                          }
                                        }
                                        final bool isSelected =
                                            _selectedSection == section;
                                        return Slidable(
                                          key: ValueKey(section),
                                          controller: controller,
                                          endActionPane: ActionPane(
                                            motion: const ScrollMotion(),
                                            extentRatio: 0.34,
                                            children: [
                                              CustomSlidableAction(
                                                onPressed: (context) {
                                                  showDeleteConfirmationDialog(
                                                    context: context,
                                                    sectionName: section,
                                                    onDelete: () {
                                                      _deleteSection(section);
                                                    },
                                                  );
                                                },
                                                flex: 1,
                                                child: Transform.translate(
                                                  offset: const Offset(
                                                    -5.5,
                                                    0.0,
                                                  ),
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.fromLTRB(
                                                          0.0,
                                                          7.0,
                                                          0.0,
                                                          4.0,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFFEC5353),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: SvgPicture.asset(
                                                        'assets/mission/delete.svg',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              3.0,
                                              7.0,
                                              0.0,
                                              4.0,
                                            ),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              decoration: BoxDecoration(
                                                color: tileBackgroundColor,
                                                borderRadius:
                                                    isSliding
                                                        ? const BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                8,
                                                              ),
                                                          bottomLeft:
                                                              Radius.circular(
                                                                8,
                                                              ),
                                                        )
                                                        : BorderRadius.circular(
                                                          8,
                                                        ),
                                                border: Border.all(
                                                  color:
                                                      isSelected
                                                          ? const Color(
                                                            0xFF7F91FF,
                                                          )
                                                          : Colors.transparent,
                                                  width: 4.0,
                                                ),
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: ListTile(
                                                  onTap:
                                                      isCompleted
                                                          ? null
                                                          : () {
                                                            setState(() {
                                                              _selectedSection =
                                                                  section;
                                                              _currentSection =
                                                                  section;
                                                            });
                                                          },
                                                  leading:
                                                      showStatus
                                                          ? Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      10,
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
                                                              clutterStatus,
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'PretendardMedium',
                                                                color:
                                                                    statusTextColor,

                                                                fontSize:
                                                                    14 *
                                                                    widthRatio,
                                                              ),
                                                            ),
                                                          )
                                                          : null,
                                                  title: Text(
                                                    section,
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'PretendardMedium',
                                                      color: titleColor,
                                                      fontSize: 18 * widthRatio,
                                                    ),
                                                  ),
                                                  trailing: GestureDetector(
                                                    onTap: () {
                                                      _captureAndAnalyze(
                                                        section,
                                                      );
                                                    },
                                                    child: SvgPicture.asset(
                                                      'assets/mission/camera.svg',
                                                    ),
                                                  ),
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
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                            vertical: 3,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          elevation: 0,
                                          color: const Color(0xFFF5F5F5),
                                          child: ListTile(
                                            title: Text.rich(
                                              TextSpan(
                                                style: TextStyle(
                                                  fontFamily:
                                                      'PretendardMedium',
                                                  color: const Color(
                                                    0xFF5D5D5D,
                                                  ),
                                                  fontSize: 18 * widthRatio,
                                                ),
                                                children: [
                                                  TextSpan(text: "  추가"),
                                                  WidgetSpan(
                                                    alignment:
                                                        PlaceholderAlignment
                                                            .middle,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 8.0,
                                                          ),
                                                      child: SvgPicture.asset(
                                                        'assets/mission/plus.svg',
                                                        colorFilter:
                                                            ColorFilter.mode(
                                                              const Color(
                                                                0xFFB0B8C1,
                                                              ),
                                                              BlendMode.srcIn,
                                                            ),
                                                      ),
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
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 80 * heightRatio),
                        LongButton(
                          text: "다음",
                          isEnabled: isAnyAnalyzed,
                          onPressed: () {
                            final analyzedResults = <String, String>{};
                            _results.forEach((key, valueMap) {
                              analyzedResults[key] =
                                  valueMap["clutter"] as String;
                            });
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => EmptyingSchedulePage(
                                      analysisResults: analyzedResults,
                                    ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 90 * heightRatio),
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
