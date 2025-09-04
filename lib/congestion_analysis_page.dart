import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:image_picker/image_picker.dart';

class CongestionAnalysisPage extends StatefulWidget {
  @override
  _CongestionAnalysisPageState createState() => _CongestionAnalysisPageState();
}

class _CongestionAnalysisPageState extends State<CongestionAnalysisPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  bool _isLoading = false;
  String _resultText = '';

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      String? res = await Tflite.loadModel(
        model: "assets/detect.tflite",
        labels: "assets/labelmap.txt",
      );
      print("모델 로딩 결과: $res");
    } catch (e) {
      print("모델 로딩 실패: $e");
    }
  }

  // 이미지 선택
  Future<void> _pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() {
        _image = pickedFile;
        _isLoading = true;
        _resultText = '';
      });

      await _analyzeImage(_image!.path);
    } catch (e) {
      print("이미지 선택 오류: $e");
      setState(() {
        _isLoading = false;
        _resultText = '이미지 선택 중 오류 발생';
      });
    }
  }

  Future<void> _analyzeImage(String imagePath) async {
    try {
      final recognitions = await Tflite.detectObjectOnImage(
        path: imagePath,
        model: "SSDMobileNet",
        threshold: 0.3,
        imageMean: 127.5,
        imageStd: 127.5,
        numResultsPerClass: 10,
      );

      if (recognitions == null || recognitions.isEmpty) {
        setState(() {
          _isLoading = false;
          _resultText = '혼잡도 낮음 (감지된 객체 없음)';
        });
        return;
      }

      final image = File(imagePath);
      final decodedImage = await decodeImageFromList(image.readAsBytesSync());
      final imageWidth = decodedImage.width;
      final imageHeight = decodedImage.height;
      final imageArea = imageWidth * imageHeight;

      double totalBoxArea = 0;
      List<Rect> boxes = [];

      for (var obj in recognitions) {
        final rect = obj['rect'];
        final x = rect['x'] * imageWidth;
        final y = rect['y'] * imageHeight;
        final w = rect['w'] * imageWidth;
        final h = rect['h'] * imageHeight;

        totalBoxArea += w * h;
        boxes.add(Rect.fromLTWH(x, y, w, h));
      }

      // 겹치는 면적 계산
      double overlapArea = 0;
      for (int i = 0; i < boxes.length; i++) {
        for (int j = i + 1; j < boxes.length; j++) {
          final intersect = boxes[i].intersect(boxes[j]);
          if (intersect.width > 0 && intersect.height > 0) {
            overlapArea += intersect.width * intersect.height;
          }
        }
      }

      final objectCount = recognitions.length;
      final areaRatio = totalBoxArea / imageArea;
      final overlapRatio = overlapArea / imageArea;

      String result;
      if (objectCount > 6 && areaRatio > 0.3 && overlapRatio > 0.05) {
        result = "혼잡도가 높음 (물건 많고 겹쳐 있음)";
      } else if (objectCount >= 3 && areaRatio > 0.15) {
        result = "혼잡도가 중간 (보통)";
      } else {
        result = "혼잡도가 낮음 (정리 쉬움)";
      }

      setState(() {
        _isLoading = false;
        _resultText =
        "$result\n- 감지 수: $objectCount개\n- 면적 비율: ${(areaRatio * 100).toStringAsFixed(1)}%\n- 겹침 비율: ${(overlapRatio * 100).toStringAsFixed(1)}%";
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
    Tflite.close();
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