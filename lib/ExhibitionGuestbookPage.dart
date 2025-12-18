import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:camera/camera.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mu/user_theme_manager.dart';
import 'package:mu/widgets/longbutton.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

List<Map<String, String>> savedGuestbooks = [];

class ExhibitionGuestbookPage extends StatefulWidget {
  final UserType userType;
  const ExhibitionGuestbookPage({super.key, required this.userType});

  @override
  _ExhibitionGuestbookPageState createState() => _ExhibitionGuestbookPageState();
}

class _ExhibitionGuestbookPageState extends State<ExhibitionGuestbookPage> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  final TextEditingController _textController = TextEditingController();
  XFile? _capturedImage;
  final GlobalKey _storyTemplateKey = GlobalKey();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    CameraDescription? frontCamera;
    try {
      frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);
    } catch (e) {
      if (cameras.isNotEmpty) frontCamera = cameras.first;
      else return;
    }
    _cameraController = CameraController(frontCamera!, ResolutionPreset.medium, enableAudio: true);
    _initializeControllerFuture = _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textController.dispose();
    super.dispose();
  }

  // 💡 기록 저장만 수행하는 함수
  void _handleSaveOnly() {
    if (_textController.text.isEmpty || _capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사진과 메시지를 모두 입력해주세요.')));
      return;
    }
    setState(() {
      savedGuestbooks.add({
        'content': _textController.text,
        'date': DateFormat('yyyy. MM. dd').format(DateTime.now()),
        'imagePath': _capturedImage!.path,
      });
      _capturedImage = null;
      _textController.clear();
    });
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('소중한 기록이 저장되었습니다. 💜')));
  }

  // 📸 이미지 캡처 함수
  Future<XFile?> _capturePng() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      RenderRepaintBoundary boundary = _storyTemplateKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/mu_story_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(pngBytes);
      return XFile(file.path);
    } catch (e) {
      return null;
    }
  }

  // 📤 공유 함수
  Future<void> _shareImage(XFile imageFile) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles(
      [imageFile],
      text: 'MU 전시회에서 남긴 나의 기록 💜',
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor;
    final Color accentColor = const Color(0xFF463EC6);

    switch (widget.userType) {
      case UserType.bang: baseColor = const Color(0xFFF9F1FD); break;
      case UserType.gam: baseColor = const Color(0xFFFFF6EF); break;
      case UserType.mol: baseColor = const Color(0xFFF3FBF0); break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            // [계층 1] 캡처용 템플릿
            SingleChildScrollView(
              child: RepaintBoundary(
                key: _storyTemplateKey,
                child: InstagramStoryTemplate(
                  baseColor: baseColor,
                  imagePath: _capturedImage?.path,
                  message: _textController.text,
                ),
              ),
            ),
            // [계층 2] 메인 UI
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildModernHeader(baseColor, accentColor),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 100,
                        child: Row(
                          children: [
                            _buildPhotoSection(baseColor),
                            _buildInputSection(baseColor, accentColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isSharing)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      SizedBox(height: 20),
                      Text("MU RECORD 생성 중...", style: TextStyle(color: Colors.white, letterSpacing: 2)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(Color baseColor, Color accentColor) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05)))),
      child: Row(
        children: [
          GestureDetector(onTap: () => Navigator.pop(context), child: SvgPicture.asset('assets/left.svg', width: 28)),
          const Spacer(),
          const Text("MU RECORD", style: TextStyle(fontSize: 22, fontFamily: 'PretendardBold', letterSpacing: 6.0, color: Color(0xFF1A1A1A))),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GuestbookListPage(baseColor: baseColor))),
            child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.grid_view_rounded, size: 20, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(Color baseColor) {
    String formattedDate = DateFormat('yyyy. MM. dd').format(DateTime.now());
    return Expanded(
      flex: 1,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(50, 60, 30, 60),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 15))]),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFFF2F3F5), border: Border.all(color: const Color(0xFFEEEEEE))),
                    child: ClipRRect(
                      child: _capturedImage != null
                          ? Stack(
                        children: [
                          Positioned.fill(child: Transform.scale(scaleX: -1, child: Image.file(File(_capturedImage!.path), fit: BoxFit.cover))),
                          Positioned(
                            top: 15, right: 15,
                            child: GestureDetector(
                              onTap: () => setState(() => _capturedImage = null),
                              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white)),
                            ),
                          ),
                        ],
                      )
                          : FutureBuilder<void>(
                        future: _initializeControllerFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done) return CameraPreview(_cameraController!);
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                if (_capturedImage == null)
                  GestureDetector(
                    onTap: () async {
                      try {
                        await _initializeControllerFuture;
                        final image = await _cameraController!.takePicture();
                        setState(() => _capturedImage = image);
                      } catch (e) { print(e); }
                    },
                    child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF463EC6), width: 4)), child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF463EC6), size: 35)),
                  )
                else
                  Column(
                    children: [
                      Image.asset('assets/mu.png', height: 50, fit: BoxFit.contain),
                      const SizedBox(height: 10),
                      Text(formattedDate, style: const TextStyle(fontSize: 14, fontFamily: 'PretendardRegular', letterSpacing: 2, color: Color(0xFFB0B8C1))),
                    ],
                  ),
              ],
            ),
          ),
          Positioned(top: 45, child: Container(width: 120, height: 35, decoration: BoxDecoration(color: baseColor.withOpacity(0.6)))),
        ],
      ),
    );
  }

  Widget _buildInputSection(Color baseColor, Color accentColor) {
    return Expanded(
      flex: 1,
      child: Container(
        color: baseColor.withOpacity(0.2),
        padding: const EdgeInsets.fromLTRB(30, 60, 80, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("비워낸 자리에 네가 와줘서,\n비로소 이 공간이 완성됐어.", style: TextStyle(fontFamily: 'PretendardBold', fontSize: 34, color: Color(0xFF1A1A1A), height: 1.2)),
            const SizedBox(height: 40),
            Expanded(
              child: TextField(
                controller: _textController, maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 18, height: 1.6),
                decoration: InputDecoration(
                  hintText: "MU 전시에 방문해준 여러분 환영합니다!\nMU 전시 소감이나 치우개팀에게 응원의 메시지를 남겨주세요.", filled: true, fillColor: const Color(0xFFF2F3F5),
                  contentPadding: const EdgeInsets.all(30), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // 💡 버튼 2개 분리 레이아웃
            Row(
              children: [
                // 1. 저장 버튼 (세컨더리)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _handleSaveOnly,
                    style: OutlinedButton.styleFrom(
                      fixedSize: const Size.fromHeight(60),
                      side: BorderSide(color: accentColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.white,
                    ),
                    child: Text("기록 저장", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 15),
                // 2. 공유 버튼 (프라이머리)
                Expanded(
                  flex: 2,
                  child: LongButton(
                    text: "공유하기",
                    onPressed: () async {
                      if (_textController.text.isEmpty || _capturedImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사진과 메시지를 입력해주세요.')));
                        return;
                      }
                      setState(() => _isSharing = true);
                      try {
                        savedGuestbooks.add({'content': _textController.text, 'date': DateFormat('yyyy. MM. dd').format(DateTime.now()), 'imagePath': _capturedImage!.path});
                        final file = await _capturePng();
                        setState(() => _isSharing = false);
                        if (file != null) await _shareImage(file);
                        setState(() { _capturedImage = null; _textController.clear(); });
                      } catch (e) {
                        setState(() => _isSharing = false);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('공유 중 오류가 발생했습니다.')));
                      }
                    },
                    isEnabled: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────── ✨ 인스타그램 스토리 템플릿 (Typography 교정) ───────
class InstagramStoryTemplate extends StatelessWidget {
  final Color baseColor;
  final String? imagePath;
  final String message;

  const InstagramStoryTemplate({super.key, required this.baseColor, this.imagePath, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080, height: 1920,
      color: Colors.white,
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, right: 0, height: 800, child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [baseColor.withOpacity(0.4), Colors.white])))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 90),
            child: Column(
              children: [
                const SizedBox(height: 150),
                // 💡 상단 타이포그래피 날짜 수정
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("MU : EXHIBITION", style: TextStyle(fontSize: 40, fontFamily: 'PretendardBold', letterSpacing: 10)),
                    Text(DateFormat('2025. 12. 19').format(DateTime.now()), style: const TextStyle(fontSize: 24, letterSpacing: 2, color: Colors.black54)),
                  ],
                ),
                const Divider(height: 60, thickness: 2, color: Colors.black),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.fromLTRB(40, 40, 40, 120),
                  decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 60, offset: const Offset(0, 30))]),
                  child: Column(
                    children: [
                      if (imagePath != null) SizedBox(width: 750, height: 750, child: Transform.scale(scaleX: -1, child: Image.file(File(imagePath!), fit: BoxFit.cover))),
                      const SizedBox(height: 50),
                      Image.asset('assets/mu.png', height: 60),
                    ],
                  ),
                ),
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 450),
                  child: SingleChildScrollView(
                    child: Text(message.isEmpty ? "비움 뒤에 찾아오는\n채움의 기록." : message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 48, fontFamily: 'PretendardBold', height: 1.6, color: Color(0xFF1A1A1A))),
                  ),
                ),
                const SizedBox(height: 120),
                const Text("RECORDED BY MU", style: TextStyle(fontSize: 18, letterSpacing: 6, color: Colors.grey)),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────── 📁 리스트 페이지 ───────
class GuestbookListPage extends StatelessWidget {
  final Color baseColor;
  const GuestbookListPage({super.key, required this.baseColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("MU RECORDS", style: TextStyle(color: Color(0xFF1A1A1A), fontFamily: 'PretendardBold', letterSpacing: 2)), backgroundColor: Colors.white, centerTitle: true, elevation: 0, leading: IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1A1A)), onPressed: () => Navigator.pop(context))),
      body: savedGuestbooks.isEmpty
          ? const Center(child: Text("기록된 이야기가 없습니다."))
          : GridView.builder(
        padding: const EdgeInsets.all(30),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 25, mainAxisSpacing: 25),
        itemCount: savedGuestbooks.length,
        itemBuilder: (context, index) {
          final item = savedGuestbooks[savedGuestbooks.length - 1 - index];
          return Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), child: item['imagePath'] != null ? Transform.scale(scaleX: -1, child: Image.file(File(item['imagePath']!), fit: BoxFit.cover, width: double.infinity)) : Container(color: Colors.grey[200]))),
                Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(item['content']!, style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF333333)), maxLines: 3, overflow: TextOverflow.ellipsis)), const SizedBox(height: 5), Text(item['date']!, style: const TextStyle(fontSize: 11, color: Colors.grey))]))),
              ],
            ),
          );
        },
      ),
    );
  }
}