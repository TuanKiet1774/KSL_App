import 'package:flutter/material.dart';
import 'package:ksl/controller/examController.dart';
import 'package:ksl/model/exam.dart';
import 'package:ksl/model/examResult.dart';

class ExamProvider extends ChangeNotifier {
  List<ExamModel> exams = [];
  bool isLoading = true;
  String? errorMessage;

  ExamModel? currentExam;
  bool isLoadingExam = false;

  List<ExamResultModel> results = [];
  bool isLoadingResults = true;
  String? resultsErrorMessage;

  bool isSubmitting = false;

  Future<void> fetchExams() async {
    isLoading = true;
    notifyListeners();

    final result = await ExamController.getAllExams();
    if (result['success'] == true) {
      exams = result['data'];
      errorMessage = null;
    } else {
      exams = [];
      errorMessage = result['message'];
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchExamById(String id) async {
    isLoadingExam = true;
    notifyListeners();

    final result = await ExamController.getExamById(id);
    currentExam = result['success'] == true ? result['data'] : null;

    isLoadingExam = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> submitExamResult({
    required String userId,
    required String examId,
    required List<Map<String, dynamic>> results,
    required int totalScore,
    required int maxScore,
    required int timeSpent,
  }) async {
    isSubmitting = true;
    notifyListeners();

    final result = await ExamController.submitExamResult(
      userId: userId,
      examId: examId,
      results: results,
      totalScore: totalScore,
      maxScore: maxScore,
      timeSpent: timeSpent,
    );

    isSubmitting = false;
    notifyListeners();
    return result;
  }

  Future<void> fetchUserResults(String userId) async {
    isLoadingResults = true;
    notifyListeners();

    final result = await ExamController.getUserResults(userId);
    if (result['success'] == true) {
      results = result['data'];
      results.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      resultsErrorMessage = null;
    } else {
      results = [];
      resultsErrorMessage = result['message'];
    }

    isLoadingResults = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> deleteResult(String resultId) async {
    final result = await ExamController.deleteResult(resultId);
    if (result['success'] == true) {
      results.removeWhere((r) => r.id == resultId);
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>> clearHistory(String userId) async {
    final result = await ExamController.clearHistory(userId);
    if (result['success'] == true) {
      results = [];
      notifyListeners();
    }
    return result;
  }
}
