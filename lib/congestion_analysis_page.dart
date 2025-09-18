import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class CongestionAnalysisLayout extends StatefulWidget {
  @override
  _CongestionAnalysisLayoutState createState() =>
      _CongestionAnalysisLayoutState();
}

class _CongestionAnalysisLayoutState extends State<CongestionAnalysisLayout> {
  CameraController? _cameraController;
  Interpreter? _interpreter;
  final int _inputSize = 300; // 모델 입력 크기
  List<String>? _labels;

  Map<String, String> _results = {
    "냉장고 상단": "분석 전",
    "냉장고 중간": "분석 전",
    "냉장고 하단": "분석 전",
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
      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);

      setState(() => _results[section] = "분석 중...");

      final result = await _analyzeImage(imageFile);

      setState(() => _results[section] = result);
    } catch (e) {
      setState(() => _results[section] = "촬영/분석 오류: $e");
    }
  }

  Future<String> _analyzeImage(File imageFile) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return "카메라가 준비되지 않았습니다.";
    }

    if (_interpreter == null) {
      return "모델 준비 안됨";
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return "이미지 오류";

      // 1️⃣ 모델 입력 크기로 리사이즈
      img.Image resizedImage = img.copyResizeCropSquare(originalImage, _inputSize);

      // 2️⃣ 정규화 대신 픽셀 값을 0-255 범위로 유지하고 4차원 배열 변환 [1, 300, 300, 3]
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

      // 3️⃣ 동적으로 출력 배열 준비
      final outputTensors = _interpreter!.getOutputTensors();
      final Map<int, Object> outputs = {};
      for (var i = 0; i < outputTensors.length; i++) {
        final tensor = outputTensors[i];
        outputs[i] = List.filled(
          tensor.shape.reduce((value, element) => value * element),
          0.0,
        ).reshape(tensor.shape);
      }

      // 4️⃣ 모델 실행
      _interpreter!.runForMultipleInputs([input], outputs);

      // 5️⃣ 감지 결과 계산 (인덱스로 접근)
      final int locationsIndex = outputTensors.indexWhere((t) => t.name.contains('PostProcess') && t.shape.length == 3);
      final int classesIndex = outputTensors.indexWhere((t) => t.name.contains('PostProcess') && t.name.contains(':1'));
      final int scoresIndex = outputTensors.indexWhere((t) => t.name.contains('PostProcess') && t.name.contains(':2'));
      final int detectionsIndex = outputTensors.indexWhere((t) => t.name.contains('PostProcess') && t.name.contains(':3'));

      if (locationsIndex == -1 || classesIndex == -1 || scoresIndex == -1 || detectionsIndex == -1) {
        return "모델 출력 텐서를 찾을 수 없습니다. 콘솔 로그를 확인하세요.";
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

      if (boxes.isEmpty) return "여유 (감지 없음)";

      double overlapArea = 0;
      for (int i = 0; i < boxes.length; i++) {
        for (int j = i + 1; j < boxes.length; j++) {
          final intersect = boxes[i].intersect(boxes[j]);
          if (intersect.width > 0 && intersect.height > 0) {
            overlapArea += intersect.width * intersect.height;
          }
        }
      }

      final areaRatio = totalBoxArea / imageArea;
      final overlapRatio = totalBoxArea > 0 ? overlapArea / totalBoxArea : 0.0;

      if (detectedCount > 6 && areaRatio > 0.3 && overlapRatio > 0.05) {
        return "혼잡도가 높음 (물건 많고 겹침)";
      } else if (detectedCount >= 3 && areaRatio > 0.15) {
        return "혼잡도가 중간 (보통)";
      } else {
        return "혼잡도가 낮음 (정리 쉬움)";
      }
    } catch (e) {
      print("분석 오류: $e");
      return "분석 오류";
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("냉장고 혼잡도 분석")),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: _cameraController == null || !_cameraController!.value.isInitialized
                ? Center(child: CircularProgressIndicator())
                : CameraPreview(_cameraController!),
          ),
          Expanded(
            flex: 1,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: _results.keys.map((section) {
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    title: Text(section),
                    subtitle: Text(_results[section]!),
                    onTap: () => _captureAndAnalyze(section),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
