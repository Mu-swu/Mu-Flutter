import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class CongestionAnalysisPage extends StatefulWidget {
  @override
  _CongestionAnalysisPageState createState() => _CongestionAnalysisPageState();
}

class _CongestionAnalysisPageState extends State<CongestionAnalysisPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  bool _isLoading = false;
  String _resultText = '';

  Interpreter? _interpreter;
  List<String>? _labels;
  final int _inputSize = 300;


  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('detect.tflite');
      print("Interpreter 로딩 성공");

      final labelsData = await DefaultAssetBundle.of(context).loadString('assets/labelmap.txt');
      _labels = labelsData.split('\n');
      print("라벨 로딩 성공");

    } catch (e) {
      print("모델 또는 라벨 로딩 실패: $e");
    }
  }

  Future<void> _pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() {
        _image = pickedFile;
        _isLoading = true;
        _resultText = '';
      });

      await _analyzeImage(File(pickedFile.path));
    } catch (e) {
      print("이미지 선택 오류: $e");
      setState(() {
        _isLoading = false;
        _resultText = '이미지 선택 중 오류 발생';
      });
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    if (_interpreter == null || _labels == null) {
      print("모델 또는 라벨이 로드되지 않았습니다.");
      return;
    }

    try {
      var imageBytes = imageFile.readAsBytesSync();
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return;

      img.Image resizedImage = img.copyResize(originalImage, width: _inputSize, height: _inputSize);

      var inputBytes = resizedImage.getBytes();
      var input = inputBytes.buffer.asUint8List();

      var inputArray = input.reshape([1, _inputSize, _inputSize, 3]);

      final outputLocations = List.generate(1, (_) => List.filled(10, List.filled(4, 0.0))).reshape([1, 10, 4]);
      final outputClasses = List.generate(1, (_) => List.filled(10, 0.0)).reshape([1, 10]);
      final outputScores = List.generate(1, (_) => List.filled(10, 0.0)).reshape([1, 10]);
      final numDetections = List.filled(1, 0.0).reshape([1]);

      Map<int, Object> outputs = {
        0: outputLocations,
        1: outputClasses,
        2: outputScores,
        3: numDetections,
      };

      _interpreter!.runForMultipleInputs([inputArray], outputs);

      int objectCount = numDetections[0].toInt();
      double threshold = 0.5;

      final imageWidth = originalImage.width;
      final imageHeight = originalImage.height;
      final imageArea = imageWidth * imageHeight;

      double totalBoxArea = 0;
      List<Rect> boxes = [];

      for (int i = 0; i < objectCount; i++) {
        if (outputScores[0][i] < threshold) continue;

        final box = outputLocations[0][i];
        final ymin = box[0] * imageHeight;
        final xmin = box[1] * imageWidth;
        final ymax = box[2] * imageHeight;
        final xmax = box[3] * imageWidth;

        final w = xmax - xmin;
        final h = ymax - ymin;

        totalBoxArea += w * h;
        boxes.add(Rect.fromLTWH(xmin, ymin, w, h));
      }

      if (boxes.isEmpty) {
        setState(() {
          _isLoading = false;
          _resultText = '혼잡도 낮음 (감지된 객체 없음)';
        });
        return;
      }

      double overlapArea = 0;
      for (int i = 0; i < boxes.length; i++) {
        for (int j = i + 1; j < boxes.length; j++) {
          final intersect = boxes[i].intersect(boxes[j]);
          if (intersect.width > 0 && intersect.height > 0) {
            overlapArea += intersect.width * intersect.height;
          }
        }
      }

      final detectedCount = boxes.length;
      final areaRatio = totalBoxArea / imageArea;
      final overlapRatio = overlapArea / imageArea;

      String result;
      if (detectedCount > 6 && areaRatio > 0.3 && overlapRatio > 0.05) {
        result = "혼잡도가 높음 (물건 많고 겹쳐 있음)";
      } else if (detectedCount >= 3 && areaRatio > 0.15) {
        result = "혼잡도가 중간 (보통)";
      } else {
        result = "혼잡도가 낮음 (정리 쉬움)";
      }

      setState(() {
        _isLoading = false;
        _resultText =
        "$result\n- 감지 수: $detectedCount개\n- 면적 비율: ${(areaRatio * 100).toStringAsFixed(1)}%\n- 겹침 비율: ${(overlapRatio * 100).toStringAsFixed(1)}%";
      });

    } catch (e) {
      print("이미지 분석 오류: $e");
      setState(() {
        _isLoading = false;
        _resultText = '이미지 분석 중 오류 발생';
      });
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("혼잡도 분석")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Wrap(
                spacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(source: ImageSource.camera),
                    icon: Icon(Icons.camera_alt),
                    label: Text("카메라로 촬영"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(source: ImageSource.gallery),
                    icon: Icon(Icons.photo),
                    label: Text("갤러리에서 선택"),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (_image != null)
                InteractiveViewer(
                  child: Image.file(
                    File(_image!.path),
                    height: MediaQuery.of(context).size.height * 0.6,
                  ),
                ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              if (_resultText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _resultText,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}