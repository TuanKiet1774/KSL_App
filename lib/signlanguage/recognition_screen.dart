import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image/image.dart' as img;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/component/youtubeFrame.dart';
import 'package:ksl/controller/wordController.dart';
import 'package:ksl/model/word.dart';
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

  bool _isCameraReady   = false;
  bool _isModelLoaded   = false;
  bool _isProcessing    = false;
  bool _isFrontCamera   = true;
  bool _isCameraStarted = false;
  bool _isInitializing  = false;

  Timer? _frameTimer;
  Timer? _idleTimer;
  static const _idleTimeout = Duration(minutes: 1);

  List<PredictionResult> _predictions = [];
  Uint8List? _skeletonPreview;
  String _statusMsg = 'Sẵn sàng';
  static const _interval = Duration(milliseconds: 350);

  int _currentMode = 0;
  final TextEditingController _inputController = TextEditingController();

  bool _isAnalyzing = false;
  Map<String, dynamic>? _analyzeResult;
  String _analyzeError = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _classifier.load();
    if (mounted) {
      setState(() {
        _isModelLoaded = true;
        _statusMsg = 'Sẵn sàng';
      });
    }
  }

  Future<void> _stopCamera() async {
    _frameTimer?.cancel();
    _frameTimer = null;
    _idleTimer?.cancel();
    _idleTimer = null;
    WakelockPlus.disable();

    final ctrl = _cameraCtrl;
    if (ctrl == null) return;

    // Null out state BEFORE disposing so no widget rebuild calls CameraPreview on a disposed controller
    if (mounted) {
      setState(() {
        _cameraCtrl = null;
        _isCameraReady = false;
        _isCameraStarted = false;
        _predictions = [];
        _skeletonPreview = null;
        _statusMsg = 'Sẵn sàng';
      });
    } else {
      _cameraCtrl = null;
      _isCameraReady = false;
      _isCameraStarted = false;
    }

    try {
      await ctrl.dispose();
    } catch (e) {
      debugPrint('[RecognitionScreen] Camera dispose error: $e');
    }
  }

  Future<void> _initCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;
    CameraController? ctrl;
    try {
      final cameras = await availableCameras();
      if (!mounted || !_isCameraStarted) return;

      final cam = cameras.firstWhere(
        (c) => c.lensDirection == (_isFrontCamera
            ? CameraLensDirection.front : CameraLensDirection.back),
        orElse: () => cameras.first,
      );
      ctrl = CameraController(cam, ResolutionPreset.medium, enableAudio: false);
      await ctrl.initialize();

      if (!mounted || !_isCameraStarted) {
        await ctrl.dispose();
        return;
      }

      _cameraCtrl = ctrl;
      _frameTimer = Timer.periodic(_interval, (_) {
        if (_currentMode == 1 && _isModelLoaded && !_isProcessing &&
            mounted && _cameraCtrl != null) {
          _processFrame();
        }
      });
      WakelockPlus.enable();
      _resetIdleTimer();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _statusMsg = 'Giơ bàn tay vào camera';
        });
      }
    } catch (e) {
      await ctrl?.dispose();
      if (mounted) {
        setState(() {
          _statusMsg = 'Lỗi camera: $e';
          _isCameraStarted = false;
        });
      }
    } finally {
      _isInitializing = false;
    }
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, () {
      if (mounted && _isCameraStarted) _stopCamera();
    });
  }

  Future<void> _processFrame() async {
    _isProcessing = true;
    try {
      if (!mounted) return;
      final ctrl = _cameraCtrl;
      if (ctrl == null || !ctrl.value.isInitialized) return;

      final xfile = await ctrl.takePicture();
      if (!mounted || _cameraCtrl == null) return;

      final bytes = await xfile.readAsBytes();
      if (!mounted || _cameraCtrl == null) return;

      final skeletonBytes = await _channel.invokeMethod<Uint8List>(
        'processFrame', {'bytes': bytes},
      );
      if (!mounted || _cameraCtrl == null) return;

      if (skeletonBytes == null) {
        setState(() {
          _predictions = [];
          _statusMsg = 'Không thấy bàn tay';
          _skeletonPreview = null;
        });
        return;
      }

      final img.Image? skeletonImage = img.decodeImage(skeletonBytes);
      if (!mounted || skeletonImage == null || _cameraCtrl == null) return;

      final preds = _classifier.predict(skeletonImage, topK: 3);
      if (!mounted || _cameraCtrl == null) return;

      _resetIdleTimer();
      setState(() {
        _predictions     = preds;
        _skeletonPreview = skeletonBytes;
        _statusMsg       = 'Đang nhận dạng...';
      });

    } catch (e) {
      // Ignore errors caused by camera being stopped/disposed mid-frame
      if (mounted && _cameraCtrl != null) {
        setState(() => _statusMsg = 'Lỗi: $e');
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _flipCamera() async {
    _frameTimer?.cancel();
    _frameTimer = null;
    _idleTimer?.cancel();
    _idleTimer = null;

    final ctrl = _cameraCtrl;
    if (ctrl == null) return;

    _isFrontCamera = !_isFrontCamera;

    if (mounted) {
      setState(() {
        _cameraCtrl = null;
        _isCameraReady = false;
      });
    } else {
      _cameraCtrl = null;
      _isCameraReady = false;
    }

    try {
      await ctrl.dispose();
    } catch (e) {
      debugPrint('[RecognitionScreen] Camera dispose error: $e');
    }

    if (mounted && _isCameraStarted) {
      await _initCamera();
    }
  }

  Future<void> _analyzeSignLanguage() async {
    FocusScope.of(context).unfocus();
    final sentence = _inputController.text.trim();
    if (sentence.isEmpty) {
      setState(() => _analyzeError = 'Vui lòng nhập câu cần phân tích');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analyzeResult = null;
      _analyzeError = '';
    });

    final result = await WordController.analyzeSign(sentence);

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        if (result['success'] == true) {
          _analyzeResult = result['data'] as Map<String, dynamic>;
        } else {
          _analyzeError = result['message'] ?? 'Đã xảy ra lỗi';
        }
      });
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _idleTimer?.cancel();
    WakelockPlus.disable();
    _cameraCtrl?.dispose();
    _classifier.dispose();
    _inputController.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryTeal, Color(0xFF236B65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x3A1A4D49),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            title: const Text(
              'Dịch ký hiệu',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            actions: [
              if (_currentMode == 1 && _isCameraStarted)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 22),
                      tooltip: 'Lật camera',
                      onPressed: _flipCamera,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                child: _buildModeSwitcher(),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _currentMode == 1
                  ? Padding(
                      key: const ValueKey('recognition'),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: child,
                        ),
                        child: _isCameraStarted
                            ? KeyedSubtree(key: const ValueKey('cam'), child: _buildCamera())
                            : KeyedSubtree(key: const ValueKey('placeholder'), child: _buildCameraPlaceholder()),
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('guide'),
                      child: _buildGuideView(),
                    ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            ),
            child: (_currentMode == 1 && _isCameraStarted)
                ? KeyedSubtree(key: const ValueKey('panel'), child: _buildResultPanel())
                : const SizedBox.shrink(key: ValueKey('nopanel')),
          ),
        ],
      ),
    );
  }

  // ─── Mode Switcher (inside AppBar) ────────────────────────────────────────

  Widget _buildModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildModeTab(0, Icons.sign_language_rounded, 'Hướng dẫn ký hiệu'),
          _buildModeTab(1, Icons.camera_alt_rounded, 'Nhận diện cử chỉ'),
        ],
      ),
    );
  }

  Widget _buildModeTab(int index, IconData icon, String label) {
    final isActive = _currentMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 0) {
            setState(() { _currentMode = 0; _statusMsg = 'Sẵn sàng'; });
            _stopCamera();
          } else {
            setState(() { _currentMode = 1; _statusMsg = 'Sẵn sàng'; });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? AppColors.primaryTeal : Colors.white.withOpacity(0.85),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.primaryTeal : Colors.white.withOpacity(0.85),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Guide View ───────────────────────────────────────────────────────────

  Widget _buildGuideView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primaryTeal),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Nhập nội dung',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryTeal.withOpacity(0.15)),
                  ),
                  child: TextField(
                    controller: _inputController,
                    maxLines: 3,
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: Xin chào, bạn khỏe không?',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildGradientButton(
                  label: _isAnalyzing ? 'Đang phân tích...' : 'Hướng dẫn ký hiệu',
                  icon: _isAnalyzing ? Icons.hourglass_empty_rounded : Icons.play_circle_outline_rounded,
                  onTap: _isAnalyzing ? () {} : _analyzeSignLanguage,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isAnalyzing)
            _buildAnalyzingLoader()
          else if (_analyzeError.isNotEmpty)
            _buildAnalyzeError()
          else if (_analyzeResult != null)
            _buildAnalyzeResults(_analyzeResult!)
          else
            _buildGuidePlaceholder(),
        ],
      ),
    );
  }

  Widget _buildGuidePlaceholder() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/huongdankyhieu.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Hướng dẫn ký hiệu của bạn',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Nhập nội dung ở trên và nhấn nút để xem video hoặc ảnh động hướng dẫn thực hiện ký hiệu thủ ngữ tương ứng.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingLoader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: AppColors.primaryTeal,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang phân tích câu...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _analyzeError,
              style: TextStyle(color: Colors.red.shade600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeResults(Map<String, dynamic> result) {
    final List<dynamic> words = result['words'] ?? [];
    final List<dynamic> removedWords = result['removedWords'] ?? [];
    final List<dynamic> signSequence = result['signSequence'] ?? [];
    final String originalSentence = result['originalSentence'] ?? '';

    final List<WordModel> foundWords = [];
    final List<int> foundIndices = [];
    for (final w in words) {
      final wMap = w as Map<String, dynamic>;
      if (wMap['found'] == true && wMap['data'] != null) {
        foundWords.add(WordModel.fromJson(wMap['data'] as Map<String, dynamic>));
        foundIndices.add(foundWords.length - 1);
      } else {
        foundIndices.add(-1);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Phần 1: Câu gốc → Câu rút gọn ──────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.compare_arrows_rounded,
                        size: 18, color: AppColors.primaryTeal),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Câu rút gọn',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Câu gốc
              Text(
                'Câu gốc',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  originalSentence,
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Mũi tên xuống
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 28, color: AppColors.primaryTeal.withOpacity(0.5)),
                ),
              ),

              // Câu rút gọn dạng chip
              Text(
                'Trình tự ký hiệu',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(signSequence.length, (index) {
                  final word = signSequence[index].toString();
                  final wordData = words.firstWhere(
                        (w) => w['word'].toString().toLowerCase() == word.toLowerCase(),
                    orElse: () => <String, dynamic>{'displayWord': word, 'found': false},
                  );
                  final displayWord = (wordData['displayWord'] ?? word).toString();
                  final isFound = wordData['found'] == true;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isFound
                              ? AppColors.primaryTeal.withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isFound
                                ? AppColors.primaryTeal.withOpacity(0.3)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isFound ? AppColors.primaryTeal : Colors.grey.shade400,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              displayWord.toUpperCase(),
                              style: TextStyle(
                                color: isFound ? AppColors.primaryTeal : Colors.grey.shade500,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < signSequence.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(Icons.arrow_forward_ios_rounded,
                              size: 10, color: Colors.grey.shade400),
                        ),
                    ],
                  );
                }),
              ),

              // Từ bị lọc bỏ
              if (removedWords.isNotEmpty) ...[
                const SizedBox(height: 14),
                Divider(color: Colors.grey.shade100),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.remove_circle_outline_rounded,
                        size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      'Từ lược bỏ: ',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        removedWords.join(', '),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // ── Phần 2: Gợi ý ký hiệu ────────────────────────────────────────
        if (words.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.sign_language_rounded,
                              size: 18, color: AppColors.primaryTeal),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Gợi ý ký hiệu',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${words.where((w) => w['found'] == true).length}/${words.length} từ',
                        style: const TextStyle(
                          color: AppColors.primaryTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 4),
                    itemCount: words.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _buildWordCard(words[i] as Map<String, dynamic>, foundWords, foundIndices[i]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWordCard(Map<String, dynamic> wordResult, List<WordModel> foundWords, int foundIndex) {
    final String rawWord = wordResult['word'] ?? '';
    final String displayWord = wordResult['displayWord'] ?? rawWord;
    final bool found = wordResult['found'] == true;
    final Map<String, dynamic>? data = wordResult['data'] as Map<String, dynamic>?;

    WordModel? wordModel;
    if (found && data != null) {
      wordModel = WordModel.fromJson(data);
    }

    return GestureDetector(
      onTap: found && wordModel != null ? () => _showWordDetailSheet(foundWords, foundIndex) : null,
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: found ? AppColors.primaryTeal.withOpacity(0.25) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: _buildCardThumbnail(wordModel, rawWord),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              decoration: BoxDecoration(
                color: found ? AppColors.primaryTeal.withOpacity(0.04) : Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: Text(
                wordModel?.name ?? displayWord,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: found ? AppColors.primaryBlue : Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardThumbnail(WordModel? wordModel, [String rawWord = '']) {
    if (wordModel == null) {
      final isSingleLetter = rawWord.length == 1 &&
          RegExp(r'^[A-ZĂÂÊÔƠƯĐa-zăâêôơưđ]$').hasMatch(rawWord);
      if (isSingleLetter) {
        return Container(
          color: AppColors.primaryTeal.withOpacity(0.06),
          child: Center(
            child: Text(
              rawWord.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryTeal,
                fontSize: 38,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      }
      return Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Icon(Icons.sign_language_rounded, size: 32, color: Colors.grey.shade300),
        ),
      );
    }

    final media = wordModel.media;
    final youtubeLink = wordModel.youtubeLink;

    if (media.url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: media.url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: AppColors.primaryTeal.withOpacity(0.05),
          child: const Center(
            child: SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: Colors.grey.shade100,
          child: Icon(Icons.broken_image_rounded, color: Colors.grey.shade300, size: 24),
        ),
      );
    }

    if (youtubeLink.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(youtubeLink);
      if (videoId != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: 'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: Colors.grey.shade100),
            ),
            Container(color: Colors.black26),
            const Center(
              child: Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 28),
            ),
          ],
        );
      }
    }

    return Container(
      color: AppColors.primaryTeal.withOpacity(0.05),
      child: const Center(
        child: Icon(Icons.sign_language_rounded, size: 32, color: AppColors.primaryTeal),
      ),
    );
  }

  void _showWordDetailSheet(List<WordModel> words, int initialIndex) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WordDetailSheet(words: words, initialIndex: initialIndex),
    ).then((_) {
      if (mounted) FocusScope.of(context).unfocus();
    });
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryTeal, Color(0xFF236B65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Camera Placeholder ───────────────────────────────────────────────────

  Widget _buildCameraPlaceholder() {
    return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/mayanh.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nhận dạng bằng Camera',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Khởi động camera và đưa bàn tay trước camera để nhận diện ký hiệu',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.6),
                ),
              ),
              const SizedBox(height: 28),
              _buildGradientButton(
                label: 'Khởi động Camera',
                icon: Icons.videocam_rounded,
                onTap: () {
                  setState(() => _isCameraStarted = true);
                  _initCamera();
                },
              ),
            ],
          ),
        ),
    );
  }

  // ─── Camera View ──────────────────────────────────────────────────────────

  Widget _buildCamera() {
    if (!_isCameraReady || _cameraCtrl == null) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: AppColors.primaryTeal,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Đang khởi tạo camera...',
              style: TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraCtrl!.value.previewSize?.height ?? 480,
                  height: _cameraCtrl!.value.previewSize?.width ?? 640,
                  child: CameraPreview(_cameraCtrl!),
                ),
              ),
            ),
          ),
        ),
        // Corner frame overlay
        Positioned.fill(child: _buildCameraFrame()),
        // LIVE badge – top left
        Positioned(
          top: 14,
          left: 14,
          child: _buildLiveBadge(),
        ),
        // Skeleton preview – below stop button
        if (_skeletonPreview != null)
          Positioned(
            top: 58,
            right: 14,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accentOrange, width: 2),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_skeletonPreview!, fit: BoxFit.cover),
              ),
            ).animate().fadeIn(duration: 200.ms),
          ),
        // Stop camera button – top right
        Positioned(
          top: 14,
          right: 14,
          child: GestureDetector(
            onTap: _stopCamera,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.red.shade600.withOpacity(0.88),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_off_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Tắt camera',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Status badge – bottom center
        Positioned(
          bottom: 14,
          left: 0,
          right: 0,
          child: Center(child: _buildStatusBadge()),
        ),
      ],
        ),
      ),
    );
  }

  Widget _buildCameraFrame() {
    const double arm = 26;
    const double thick = 3;
    const c = Colors.white54;

    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // top-left
            Positioned(top: 0, left: 0, child: Container(width: arm, height: thick, color: c)),
            Positioned(top: 0, left: 0, child: Container(width: thick, height: arm, color: c)),
            // top-right
            Positioned(top: 0, right: 0, child: Container(width: arm, height: thick, color: c)),
            Positioned(top: 0, right: 0, child: Container(width: thick, height: arm, color: c)),
            // bottom-left
            Positioned(bottom: 0, left: 0, child: Container(width: arm, height: thick, color: c)),
            Positioned(bottom: 0, left: 0, child: Container(width: thick, height: arm, color: c)),
            // bottom-right
            Positioned(bottom: 0, right: 0, child: Container(width: arm, height: thick, color: c)),
            Positioned(bottom: 0, right: 0, child: Container(width: thick, height: arm, color: c)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.88),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: Colors.white),
          SizedBox(width: 5),
          Text(
            'TRỰC TIẾP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _isModelLoaded ? const Color(0xFF4CAF50) : AppColors.accentOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            _statusMsg,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Result Panel ─────────────────────────────────────────────────────────

  Widget _buildResultPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _buildPredictions(),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictions() {
    final bool hasResult = _predictions.isNotEmpty;
    final top = hasResult ? _predictions.first : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kết quả nhận dạng',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hasResult
                    ? _confColor(top!.confidence).withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: hasResult ? _confColor(top!.confidence) : Colors.grey.shade400,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasResult
                        ? '${(top!.confidence * 100).toStringAsFixed(0)}% tin cậy'
                        : 'Chờ nhận dạng',
                    style: TextStyle(
                      color: hasResult ? _confColor(top!.confidence) : Colors.grey.shade400,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryTeal.withOpacity(hasResult ? 0.07 : 0.03),
                AppColors.primaryTeal.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasResult
                  ? AppColors.primaryTeal.withOpacity(0.12)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: hasResult
                      ? Text(
                          top!.label,
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ).animate(key: ValueKey(top.label))
                            .scale(
                              begin: const Offset(0.85, 0.85),
                              duration: 180.ms,
                              curve: Curves.easeOutBack,
                            )
                      : Icon(
                          Icons.back_hand_rounded,
                          size: 52,
                          color: AppColors.primaryTeal.withOpacity(0.35),
                        ),
                ),
              ),
              Container(
                width: 1.5,
                height: 75,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: AppColors.primaryTeal.withOpacity(0.15),
              ),
              hasResult
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${(top!.confidence * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _confColor(top.confidence),
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 100,
                          child: LinearPercentIndicator(
                            lineHeight: 7,
                            percent: top.confidence.clamp(0.0, 1.0),
                            backgroundColor: Colors.grey.shade200,
                            progressColor: _confColor(top.confidence),
                            barRadius: const Radius.circular(4),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '--',
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearPercentIndicator(
                            lineHeight: 7,
                            percent: 0,
                            backgroundColor: Colors.grey.shade200,
                            progressColor: Colors.grey.shade300,
                            barRadius: const Radius.circular(4),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Các kết quả khác',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: hasResult && _predictions.length > 1
              ? _predictions.skip(1).map((p) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            p.label,
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _confColor(p.confidence).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(p.confidence * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: _confColor(p.confidence),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList()
              : List.generate(2, (_) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '--',
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '0.0%',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
        ),
      ],
    );
  }

  Color _confColor(double c) {
    if (c >= 0.85) return const Color(0xFF2E7D32);
    if (c >= 0.65) return AppColors.accentOrange;
    return Colors.redAccent;
  }
}

// ─── Word Detail Bottom Sheet ─────────────────────────────────────────────────

class _WordDetailSheet extends StatefulWidget {
  final List<WordModel> words;
  final int initialIndex;
  const _WordDetailSheet({required this.words, required this.initialIndex});

  @override
  State<_WordDetailSheet> createState() => _WordDetailSheetState();
}

class _WordDetailSheetState extends State<_WordDetailSheet> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.words[_currentIndex];
    final bool hasPrev = _currentIndex > 0;
    final bool hasNext = _currentIndex < widget.words.length - 1;
    final bool hasNav = widget.words.length > 1;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.93,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasNav)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              _NavButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: hasPrev ? () => setState(() => _currentIndex--) : null,
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    '${_currentIndex + 1} / ${widget.words.length}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              _NavButton(
                                icon: Icons.arrow_forward_ios_rounded,
                                onTap: hasNext ? () => setState(() => _currentIndex++) : null,
                              ),
                            ],
                          ),
                        ),
                      if (word.media.url.isNotEmpty || word.youtubeLink.isNotEmpty)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryTeal.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: word.youtubeLink.isNotEmpty &&
                                    YoutubePlayer.convertUrlToId(word.youtubeLink) != null
                                ? YoutubeFrame(
                                    key: ValueKey(word.id),
                                    videoUrl: word.youtubeLink,
                                    aspectRatio: 1,
                                  )
                                : AspectRatio(
                                    aspectRatio: 1,
                                    child: CachedNetworkImage(
                                      key: ValueKey(word.id),
                                      imageUrl: word.media.url,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryTeal.withOpacity(0.5),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => const Icon(
                                        Icons.image_not_supported_rounded,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        word.name,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (word.description.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'ĐỊNH NGHĨA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          word.description,
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.grey.shade800,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primaryTeal.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? AppColors.primaryTeal.withOpacity(0.25) : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.primaryTeal : Colors.grey.shade300,
        ),
      ),
    );
  }
}
