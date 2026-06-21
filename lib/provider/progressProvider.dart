import 'package:flutter/material.dart';
import 'package:ksl/controller/progressController.dart';
import 'package:ksl/model/progress.dart';

class ProgressProvider extends ChangeNotifier {
  ProgressModel? userProgress;
  bool isLoading = true;
  String? errorMessage;

  Future<void> fetchUserProgress() async {
    isLoading = true;
    notifyListeners();

    final result = await ProgressController.getUserProgress();
    if (result['success'] == true) {
      userProgress = result['data'];
      errorMessage = null;
    } else {
      errorMessage = result['message'];
    }

    isLoading = false;
    notifyListeners();
  }
}
