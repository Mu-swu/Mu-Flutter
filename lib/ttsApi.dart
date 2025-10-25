import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class ElevenLabsTTS {
  final FlutterTts _flutterTts = FlutterTts();
  Completer<void>? _speechCompleter;

  // ElevenLabsTTS({required this.apiKey}); // API 키가 더 이상 필요 없습니다.
  ElevenLabsTTS() {
    _initTts();
  }

  void _initTts() async {
    // 한국어 설정
    await _flutterTts.setLanguage("ko-KR");
    // 음성 속도를 0.5로 설정 (기본값 1.0은 너무 빠를 수 있습니다)
    await _flutterTts.setSpeechRate(0.5);

    // 말하기가 완료되었을 때 호출됩니다.
    _flutterTts.setCompletionHandler(() {
      _speechCompleter?.complete();
    });

    // 에러가 발생했을 때 호출됩니다.
    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
      _speechCompleter?.completeError(Exception(msg));
    });
  }

  /// 기존 speak 함수를 대체합니다.
  /// 이제 API 호출 대신 기기의 TTS 엔진을 사용합니다.
  Future<void> speak(String text) async {
    // speak 함수가 끝날 때까지 기다릴 수 있도록 Completer를 사용합니다.
    // (mission_step_page의 _startTtsSequence 루프에 꼭 필요합니다)
    _speechCompleter = Completer<void>();

    await _flutterTts.stop(); // 혹시 말하는 중이면 중지
    final result = await _flutterTts.speak(text);

    if (result == 1) {
      // 1 (성공)이면, completer가 완료될 때까지 기다립니다.
      return _speechCompleter!.future;
    } else {
      // 0 (실패)이면, 에러를 발생시킵니다.
      throw Exception("flutter_tts: Failed to start speaking.");
    }
  }

  /// 기존 stop 함수를 대체합니다.
  void stop() {
    _flutterTts.stop();
    // 수동으로 중지할 때도 completer를 완료시켜서
    // _startTtsSequence의 await가 멈추지 않도록 합니다.
    if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
      _speechCompleter!.complete();
    }
  }
}

// import 'dart:convert';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:just_audio/just_audio.dart';
// import 'package:path_provider/path_provider.dart';
//
// class ElevenLabsTTS {
//   final String apiKey;
//   final String voiceId = 'HGa3AcTzIsetvM211K1o';
//   //i9Zv36vHIRPyb4KMdMDQ
//   final String modelId = 'eleven_multilingual_v2';
//
//   final AudioPlayer _audioPlayer = AudioPlayer();
//
//   ElevenLabsTTS({required this.apiKey});
//
//   Future<void> speak(String text) async {
//     final url = Uri.parse(
//       'https://api.elevenlabs.io/v1/text-to-speech/$voiceId',
//     );
//
//     final headers = {
//       'xi-api-key': apiKey,
//       'Content-Type': 'application/json',
//     };
//
//     final body = jsonEncode({
//       "text": text,
//       "model_id": modelId,
//       "voice_settings": {"stability": 0.7, "similarity_boost": 0.75},
//     });
//
//     final response = await http.post(url, headers: headers, body: body);
//
//     if (response.statusCode == 200) {
//       Uint8List audioBytes = response.bodyBytes;
//
//       final tempDir=await getTemporaryDirectory();
//       final file=File('${tempDir.path}/tts_audio.mp3');
//
//       await file.writeAsBytes(audioBytes);
//
//       await _audioPlayer.stop();
//       await _audioPlayer.setFilePath(file.path);
//       await _audioPlayer.play();
//     } else {
//       print("TTS 실패 응답: ${response.body}");
//     }
//   }
//
//   void stop() {
//     _audioPlayer.stop();
//   }
// }
