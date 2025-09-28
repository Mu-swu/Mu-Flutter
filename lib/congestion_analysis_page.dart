import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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

  Map<String, String> _results = {
    "냉장실 한 칸": "분석 전", // 초기 상태는 "분석 전"으로 변경
    "얼음/얼린 식재료 칸": "분석 전",
    "냉동식품 칸": "분석 전",
  };

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadModel();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/detect.tflite');
      final labelsData =
      await DefaultAssetBundle.of(context).loadString('assets/labelmap.txt');
      _labels = labelsData.split('\n');
      print("모델 로딩 완료");
    } catch (e) {
      print("모델 로딩 실패: $e");
    }
  }

  Future<void> _captureAndAnalyze(String section) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      setState(() {
        _currentSection = section;
        _results[section] = "분석 중...";
      });

      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);

      final result = await _analyzeImage(imageFile);

      setState(() => _results[section] = result);
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

      img.Image resizedImage = img.copyResizeCropSquare(originalImage, _inputSize);

      var input = List.generate(
        1,
            (_) => List.generate(_inputSize, (y) => List.generate(_inputSize, (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [
            img.getRed(pixel).toInt(),
            img.getGreen(pixel).toInt(),
            img.getBlue(pixel).toInt(),
          ];
        })),
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

      final int locationsIndex = outputTensors.indexWhere((t) => t.name.contains('PostProcess') && t.shape.length == 3);
      final int classesIndex = outputTensors.indexWhere((t) => t.name.contains('PostProcess') && t.name.contains(':1'));
      final int scoresIndex = outputTensors.indexWhere((t) => t.name.contains('PostProcess') && t.name.contains(':2'));
      final int detectionsIndex = outputTensors.indexWhere((t) => t.name.contains('PostProcess') && t.name.contains(':3'));

      if (locationsIndex == -1 || classesIndex == -1 || scoresIndex == -1 || detectionsIndex == -1) {
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

      if (detectedCount > 6 && areaRatio > 0.3) {
        return "혼잡";
      } else if (detectedCount >= 3 && areaRatio > 0.15) {
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
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        // 다이얼로그의 너비와 높이를 조정하기 위해 LayoutBuilder 사용
        return LayoutBuilder(
          builder: (context, constraints) {
            final double dialogWidth = constraints.maxWidth < 600 ? constraints.maxWidth * 0.9 : 450;
            final double dialogHeight = constraints.maxHeight < 400 ? constraints.maxHeight * 0.8 : 250;

            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: dialogWidth,
                  height: dialogHeight,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const Spacer(),
                      longbutton(
                        text: "추가하기",
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            setState(() {
                              _results[controller.text.trim()] = "분석 전";
                            });
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
              ),
            );
          },
        );
      },
    );
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 150 * widthRatio,
            vertical: 40 * heightRatio,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 뒤로가기 버튼과 제목
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(height: 20 * heightRatio),
              const Text(
                "냉장고 속 물건이\n얼마나 많은지 볼까요?",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 20 * heightRatio),
              const Text(
                "현재 상태를 촬영하면, 혼잡/보통/여유 중 하나로 알려드릴게요.\n불필요한 공간은 밀어서 삭제할 수 있어요.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 40 * heightRatio),

              // 메인 콘텐츠: 카메라와 목록
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _cameraController == null || !_cameraController!.value.isInitialized
                                  ? const Center(child: CircularProgressIndicator())
                                  : CameraPreview(_cameraController!),
                              // 코너 가이드 라인
                              Positioned(
                                top: 20 * heightRatio,
                                left: 20 * widthRatio,
                                child: Container(width: 50, height: 2, color: Colors.white),
                              ),
                              Positioned(
                                top: 20 * heightRatio,
                                left: 20 * widthRatio,
                                child: Container(width: 2, height: 50, color: Colors.white),
                              ),
                              Positioned(
                                top: 20 * heightRatio,
                                right: 20 * widthRatio,
                                child: Container(width: 50, height: 2, color: Colors.white),
                              ),
                              Positioned(
                                top: 20 * heightRatio,
                                right: 20 * widthRatio,
                                child: Container(width: 2, height: 50, color: Colors.white),
                              ),
                              Positioned(
                                bottom: 20 * heightRatio,
                                left: 20 * widthRatio,
                                child: Container(width: 50, height: 2, color: Colors.white),
                              ),
                              Positioned(
                                bottom: 20 * heightRatio,
                                left: 20 * widthRatio,
                                child: Container(width: 2, height: 50, color: Colors.white),
                              ),
                              Positioned(
                                bottom: 20 * heightRatio,
                                right: 20 * widthRatio,
                                child: Container(width: 50, height: 2, color: Colors.white),
                              ),
                              Positioned(
                                bottom: 20 * heightRatio,
                                right: 20 * widthRatio,
                                child: Container(width: 2, height: 50, color: Colors.white),
                              ),
                              // 카메라 뷰의 텍스트 오버레이 (조건부)
                              if (_currentSection != null)
                                Positioned(
                                  bottom: 40 * heightRatio,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _currentSection!,
                                      style: const TextStyle(color: Colors.white, fontSize: 16),
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
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ..._results.keys.map((section) {
                            Color statusBackgroundColor = Colors.transparent;
                            Color statusTextColor = Colors.black;
                            bool showStatus = true; // "분석 전"일 때는 상태를 숨기기 위한 플래그

                            switch (_results[section]!) {
                              case '혼잡':
                                statusBackgroundColor = const Color(0xFFF9C0C0);
                                statusTextColor = const Color(0xFFF16767);
                                break;
                              case '보통':
                                statusBackgroundColor = const Color(0xFFE9F0FC);
                                statusTextColor = const Color(0xFF678FF1);
                                break;
                              case '여유':
                                statusBackgroundColor = const Color(0xFFC6E9C6);
                                statusTextColor = const Color(0xFF63BB63);
                                break;
                              default: // "분석 전" 또는 "분석 중..."
                                showStatus = false;
                                break;
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                                elevation: 0,
                                color: Colors.grey[100], // 카드 배경색을 연한 회색으로 변경
                                child: ListTile(
                                  leading: showStatus // "분석 전"이 아닐 때만 상태 박스 표시
                                      ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusBackgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _results[section]!,
                                      style: TextStyle(color: statusTextColor, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  )
                                      : null,
                                  title: Text(
                                    section,
                                    style: const TextStyle(color: Colors.black, fontSize: 16),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  onTap: () => _captureAndAnalyze(section),
                                ),
                              ),
                            );
                          }).toList(),
                          // "추가" 버튼
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                              elevation: 0,
                              color: const Color(0xFFF0F5FD), // 추가 버튼 배경색 연하늘색
                              child: ListTile(
                                title: Text(
                                  "추가 +",
                                  style: TextStyle(color: const Color(0xFF678FF1), fontWeight: FontWeight.bold, fontSize: 16), // 추가 버튼 글자색 파란색
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
              SizedBox(height: 40 * heightRatio),
              longbutton(
                text: "다음",
                onPressed: () {},
                isEnabled: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}