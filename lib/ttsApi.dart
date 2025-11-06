import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

import 'user_theme_manager.dart';

class ElevenLabsTTS {
  final String apiKey;
  final UserType userType;
  final String modelId = 'eleven_multilingual_v2';

  final AudioPlayer _audioPlayer = AudioPlayer();
  Completer<void>? _speechCompleter;

  ElevenLabsTTS({required this.apiKey, required this.userType}) {
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
          _speechCompleter!.complete();
        }
      }
    });
  }

  String _getVoiceId() {
    switch (userType) {
      case UserType.bang:
        return 'O06mWxUIqkxtwRmi6Klv';
      case UserType.gam:
        return 'i9Zv36vHIRPyb4KMdMDQ';
      case UserType.mol:
        return 'HGa3AcTzIsetvM211K1o';
      default:
        return 'O06mWxUIqkxtwRmi6Klv';
    }
  }

  Future<void> speak(String text) async {
    _speechCompleter = Completer<void>();
    final voiceId = _getVoiceId();
    final url = Uri.parse(
      'https://api.elevenlabs.io/v1/text-to-speech/$voiceId',
    );

    final headers = {'xi-api-key': apiKey, 'Content-Type': 'application/json'};

    final body = jsonEncode({
      "text": text,
      "model_id": modelId,
      "voice_settings": {"stability": 0.7, "similarity_boost": 0.75},
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        Uint8List audioBytes = response.bodyBytes;

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/tts_audio.mp3');

        await file.writeAsBytes(audioBytes);

        await _audioPlayer.stop();
        await _audioPlayer.setAudioSource(AudioSource.file(file.path));
        await _audioPlayer.play();
        return _speechCompleter!.future;
      } else {
        print("TTS 실패 응답: ${response.body}");
        throw Exception('TTS API Error:${response.body}');
      }
    } catch (e) {
      print('TTS speck 오류 : $e');
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.completeError(e);
      }
      rethrow;
    }
  }

  void stop() {
    _audioPlayer.stop();
    if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
      _speechCompleter!.complete();
    }
  }
}
