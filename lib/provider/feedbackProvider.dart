import 'package:flutter/material.dart';
import 'package:ksl/controller/feedbackController.dart';
import 'package:ksl/model/feedback.dart';

class FeedbackProvider extends ChangeNotifier {
  List<FeedbackModel> history = [];
  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;

  Future<Map<String, dynamic>> sendFeedback({
    required int rating,
    required String comment,
  }) async {
    isSubmitting = true;
    notifyListeners();

    final result = await FeedbackController.sendFeedback(rating: rating, comment: comment);

    isSubmitting = false;
    notifyListeners();
    return result;
  }

  Future<void> fetchHistory() async {
    isLoading = true;
    notifyListeners();

    final result = await FeedbackController.getFeedbackHistory();
    if (result['success'] == true) {
      history = result['data'];
      errorMessage = null;
    } else {
      errorMessage = result['message'];
    }

    isLoading = false;
    notifyListeners();
  }
}
