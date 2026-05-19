import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image/image.dart' as img;
import 'package:percent_indicator/percent_indicator.dart';
import 'vsl_classifier.dart';

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({super.key});
  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {

  static const _channel = MethodChannel('com.ksl.ksl/hand_landmark');

  CameraController? _cameraCtrl;
  final VSLClassifier _classifier = VSLClassifier();

  bool _isCameraReady  = false;
  bool _isModelLoaded  = false;
  bool _isProcessing   = false;
  bool _isFrontCamera  = true;

  List<PredictionResult> _predictions = [];
  Uint8List? _skeletonPreview;
  String _statusMsg = 'Đang khởi tạo...';
  DateTime _lastProcess = DateTime.now();
  static const _interval = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _classifier.load();
    setState(() => _isModelLoaded = true);
    await _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (!mounted) return;                    // ← thêm dòng này

    final cam = cameras.firstWhere(
          (c) => c.lensDirection == (_isFrontCamera
          ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => cameras.first,
    );
    _cameraCtrl = CameraController(cam, ResolutionPreset.medium,
        enableAudio: false);
    await _cameraCtrl!.initialize();
    if (!mounted) return;                    // ← thêm dòng này

    _cameraCtrl!.startImageStream(_onFrame);
    setState(() {
      _isCameraReady = true;
      _statusMsg = 'Giơ bàn tay vào camera';
    });
  }

  void _onFrame(CameraImage frame) {
    if (!_isModelLoaded || _isProcessing) return;
    if (DateTime.now().difference(_lastProcess) < _interval) return;
    _lastProcess = DateTime.now();
    _processFrame();
  }

  Future<void> _processFrame() async {
    _isProcessing = true;
    try {
      // THÊM kiểm tra mounted trước mọi thao tác
      if (!mounted) return;
      if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) return;

      final xfile = await _cameraCtrl!.takePicture();

      // THÊM kiểm tra mounted sau mỗi await
      if (!mounted) return;

      final bytes = await xfile.readAsBytes();
      if (!mounted) return;

      final skeletonBytes = await _channel.invokeMethod<Uint8List>(
        'processFrame', {'bytes': bytes},
      );
      if (!mounted) return;

      if (skeletonBytes == null) {
        setState(() {                    // mounted đã check ở trên
          _predictions = [];
          _statusMsg = 'Không thấy bàn tay';
          _skeletonPreview = null;
        });
        return;
      }

      final img.Image? skeletonImage = img.decodeImage(skeletonBytes);
      if (!mounted || skeletonImage == null) return;

      final preds = _classifier.predict(skeletonImage, topK: 3);
      if (!mounted) return;

      setState(() {
        _predictions     = preds;
        _skeletonPreview = skeletonBytes;
        _statusMsg       = 'Đang nhận dạng...';
      });

    } catch (e) {
      if (mounted) setState(() => _statusMsg = 'Lỗi: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _flipCamera() async {
    await _cameraCtrl?.stopImageStream();
    await _cameraCtrl?.dispose();
    _isFrontCamera = !_isFrontCamera;
    await _initCamera();
  }

  @override
  void dispose() {
    _cameraCtrl?.dispose();
    _classifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(child: Column(children: [
        _buildHeader(),
        Expanded(child: _buildCamera()),
        _buildResultPanel(),
      ])),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF2E75B6).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2E75B6)),
          ),
          child: const Icon(Icons.sign_language,
              color: Color(0xFF2E75B6), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('VSL Recognition',
              style: TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(_statusMsg,
              style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ])),
        // Model status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (_isModelLoaded ? const Color(0xFF1D7A45)
                : const Color(0xFFC55A11)).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _isModelLoaded
                ? const Color(0xFF1D7A45) : const Color(0xFFC55A11)),
          ),
          child: Text(_isModelLoaded ? 'Ready' : 'Loading',
              style: TextStyle(
                  color: _isModelLoaded
                      ? const Color(0xFF1D7A45) : const Color(0xFFC55A11),
                  fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        IconButton(
          icon: const Icon(Icons.flip_camera_ios, color: Colors.grey),
          onPressed: _flipCamera,
        ),
      ]),
    );
  }

  Widget _buildCamera() {
    if (!_isCameraReady || _cameraCtrl == null) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E75B6)));
    }
    return Stack(children: [
      Positioned.fill(child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CameraPreview(_cameraCtrl!),
      )),
      // Skeleton preview góc trên phải
      if (_skeletonPreview != null)
        Positioned(top: 12, right: 12,
          child: Container(
            width: 224, height: 224,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2E75B6), width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(_skeletonPreview!, fit: BoxFit.cover),
            ),
          ).animate().fadeIn(),
        ),
      // LIVE badge
      Positioned(top: 12, left: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.85),
              borderRadius: BorderRadius.circular(6)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.circle, size: 7, color: Colors.white),
            SizedBox(width: 4),
            Text('LIVE', style: TextStyle(color: Colors.white,
                fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildResultPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF12121C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _predictions.isEmpty ? _buildEmpty() : _buildPredictions(),
    );
  }

  Widget _buildEmpty() {
    return SizedBox(height: 150, child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.pan_tool_outlined, size: 36, color: Colors.grey[700]),
        const SizedBox(height: 10),
        Text('Giơ bàn tay vào camera',
            style: TextStyle(color: Colors.grey[600])),
      ]),
    ));
  }

  Widget _buildPredictions() {
    final top = _predictions.first;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(top.label,
          style: const TextStyle(color: Colors.white, fontSize: 80,
              fontWeight: FontWeight.bold),
        ).animate(key: ValueKey(top.label))
            .scale(begin: const Offset(0.8, 0.8), duration: 200.ms),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _confColor(top.confidence).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _confColor(top.confidence)),
            ),
            child: Text('${(top.confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: _confColor(top.confidence),
                    fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 6),
          SizedBox(width: 80, child: LinearPercentIndicator(
            lineHeight: 5,
            percent: top.confidence.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[800]!,
            progressColor: _confColor(top.confidence),
            barRadius: const Radius.circular(3),
            padding: EdgeInsets.zero,
          )),
        ]),
      ]),
      const SizedBox(height: 12),
      const Divider(color: Color(0xFF2A2A3A)),
      const SizedBox(height: 8),
      Row(children: _predictions.skip(1).map((p) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A3A)),
          ),
          child: Column(children: [
            Text(p.label, style: const TextStyle(color: Colors.white70,
                fontSize: 28, fontWeight: FontWeight.bold)),
            Text('${(p.confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ]),
        ),
      )).toList()),
    ]);
  }

  Color _confColor(double c) {
    if (c >= 0.9) return const Color(0xFF1D7A45);
    if (c >= 0.7) return const Color(0xFFC55A11);
    return const Color(0xFFC00000);
  }
}