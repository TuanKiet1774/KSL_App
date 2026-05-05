
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  try {
    final modelPath = 'assets/models/vsl_model_sim_float16.tflite';
    final file = File(modelPath);
    if (!file.existsSync()) {
      print('Model file not found at $modelPath');
      return;
    }
    final interpreter = Interpreter.fromFile(file);
    print('INPUTS:');
    for (var i = 0; i < interpreter.getInputTensors().length; i++) {
      print('Input $i: ${interpreter.getInputTensor(i).shape}');
    }
    print('OUTPUTS:');
    for (var i = 0; i < interpreter.getOutputTensors().length; i++) {
      print('Output $i: ${interpreter.getOutputTensor(i).shape}');
    }
    interpreter.close();
  } catch (e) {
    print('Error: $e');
  }
}
