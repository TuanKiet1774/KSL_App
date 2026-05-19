import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class PredictionResult {
  final String label;
  final double confidence;
  final int index;

  const PredictionResult({
    required this.label,
    required this.confidence,
    required this.index,
  });

  @override
  String toString() => '$label (${(confidence * 100).toStringAsFixed(1)}%)';
}

class VSLClassifier {
  Interpreter? _interpreter;
  List<String> _classes = [];
  bool _isLoaded = false;

  // Từ EDA: brightness_mean = 14/255 ≈ 0.055, contrast_mean/255 ≈ 0.21
  // static const double _mean = 0.055;
  // static const double _std  = 0.210;
  static const double _mean = 0.0;   // không normalize
static const double _std  = 1.0;   // không normalize
  static const int    _size = 224;

  bool get isLoaded => _isLoaded;
  int  get numClasses => _classes.length;

  /// Load model và label map từ assets
  Future<void> load() async {
    try {
      // Load label_map.json
      final jsonStr = await rootBundle.loadString('assets/label_map.json');
      final Map<String, dynamic> labelMap = json.decode(jsonStr);

      // Sắp xếp theo index để tạo mảng idx→class
      _classes = List<String>.filled(labelMap.length, '');
      labelMap.forEach((cls, idx) {
        _classes[idx as int] = cls;
      });

      // Load TFLite model
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        'assets/mobilenetv2_vsl.tflite',
        options: options,
      );

      print('[VSLClassifier] Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('[VSLClassifier] Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      print('[VSLClassifier] Input type: ${_interpreter!.getInputTensor(0).type}');

      _isLoaded = true;
      print('[VSLClassifier] Loaded — ${_classes.length} classes');
      print('[VSLClassifier] Classes: $_classes');

      // In tensor shapes để debug
      print('[VSLClassifier] Input shape:  ${_interpreter!.getInputTensor(0).shape}');
      print('[VSLClassifier] Output shape: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      _isLoaded = false;
      print('[VSLClassifier] Load error: $e');
      rethrow;
    }
  }

  /// Predict từ ảnh skeleton img.Image (224×224)
  /// Trả về top-k predictions, mặc định top-3
  List<PredictionResult> predict(img.Image skeletonImage, {int topK = 3}) {
    if (!_isLoaded || _interpreter == null) {
      throw StateError('Model chưa được load. Gọi load() trước.');
    }

    // ── Chuẩn bị input tensor [1, 224, 224, 3] ──────────────────────────
    // TFLite float16 vẫn nhận input float32
    final inputData = Float32List(_size * _size * 3);
    int idx = 0;

    final resized = img.copyResize(skeletonImage,
        width: _size, height: _size,
        interpolation: img.Interpolation.linear);

    for (int y = 0; y < _size; y++) {
      for (int x = 0; x < _size; x++) {
        final pixel = resized.getPixel(x, y);
        // Normalize: (value/255 - mean) / std
        inputData[idx++] = (pixel.r / 255.0 - _mean) / _std; // R
        inputData[idx++] = (pixel.g / 255.0 - _mean) / _std; // G
        inputData[idx++] = (pixel.b / 255.0 - _mean) / _std; // B
      }
    }

    print('[VSL] inputData sample: ${inputData.sublist(0, 10)}');
    print('[VSL] inputData min: ${inputData.reduce((a,b) => a < b ? a : b)}');
    print('[VSL] inputData max: ${inputData.reduce((a,b) => a > b ? a : b)}');
    print('[VSL] inputData mean: ${inputData.reduce((a,b) => a+b) / inputData.length}');
    // Reshape thành [1, 224, 224, 3]
    final input = inputData.reshape([1, _size, _size, 3]);

    // ── Output tensor [1, 25] ────────────────────────────────────────────
    final output = List.generate(1, (_) => List<double>.filled(_classes.length, 0.0));
    _interpreter!.run(input, output);
    final outputData = Float32List.fromList(output[0].map((e) => e.toDouble()).toList());

    _interpreter!.run(input, output);

    print('[VSL] Raw output: ${outputData.sublist(0, 10)}');
    print('[VSL] Output max: ${outputData.reduce((a,b) => a > b ? a : b)}');
    print('[VSL] Output min: ${outputData.reduce((a,b) => a < b ? a : b)}');

    // ── Softmax ──────────────────────────────────────────────────────────
    final logits = outputData;
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((v) => math.exp(v - maxLogit)).toList();
    final sumExp = exps.reduce((a, b) => a + b);
    final probs = exps.map((e) => e / sumExp).toList();

    // ── Top-K ────────────────────────────────────────────────────────────
    final results = List.generate(_classes.length, (i) => PredictionResult(
      label: _classes[i],
      confidence: probs[i],
      index: i,
    ));

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results.take(topK).toList();
  }

  void dispose() {
    _interpreter?.close();
    _isLoaded = false;
  }
}
