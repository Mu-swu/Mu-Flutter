import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class ElevenLabsTTS {
  final String apiKey;
  final String voiceId = 'HGa3AcTzIsetvM211K1o';
  //i9Zv36vHIRPyb4KMdMDQ
  final String modelId = 'eleven_multilingual_v2';

  final AudioPlayer _audioPlayer = AudioPlayer();

  ElevenLabsTTS({required this.apiKey});

  Future<void> speak(String text) async {
    final url = Uri.parse(
      'https://api.elevenlabs.io/v1/text-to-speech/$voiceId',
    );

    final headers = {
      'xi-api-key': apiKey,
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "text": text,
      "model_id": modelId,
      "voice_settings": {"stability": 0.7, "similarity_boost": 0.75},
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      Uint8List audioBytes = response.bodyBytes;

      final tempDir=await getTemporaryDirectory();
      final file=File('${tempDir.path}/tts_audio.mp3');

      await file.writeAsBytes(audioBytes);

      await _audioPlayer.stop();
      await _audioPlayer.setFilePath(file.path);
      await _audioPlayer.play();
    } else {
      print("TTS 실패 응답: ${response.body}");
    }
  }

  void stop() {
    _audioPlayer.stop();
  }
}
