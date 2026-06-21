import 'package:flutter/material.dart';
import 'package:ksl/controller/learnedWordController.dart';
import 'package:ksl/model/learnedWord.dart';

class LearnedWordProvider extends ChangeNotifier {
  List<LearnedWordModel> learnedWords = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  String? errorMessage;
  static const int _limit = 20;

  Future<void> fetchLearnedWords({String? topicId, bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isFetchingMore || !hasMore) return;
      isFetchingMore = true;
    } else {
      isLoading = true;
      currentPage = 1;
      hasMore = true;
    }
    notifyListeners();

    final result = await LearnedWordController.getMyLearnedWords(
      topicId: topicId,
      page: currentPage,
      limit: _limit,
    );

    if (result['success'] == true) {
      final List<LearnedWordModel> newItems = result['data'];
      hasMore = newItems.length >= _limit;
      if (hasMore) currentPage++;
      learnedWords = isLoadMore ? [...learnedWords, ...newItems] : newItems;
      errorMessage = null;
    } else {
      hasMore = false;
      errorMessage = result['message'];
    }

    isLoading = false;
    isFetchingMore = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> markAsLearned({
    required String wordId,
    required String topicId,
    required int expGained,
  }) {
    return LearnedWordController.markAsLearned(
      wordId: wordId,
      topicId: topicId,
      expGained: expGained,
    );
  }

  Future<Map<String, dynamic>> deleteLearnedWord(String id) async {
    final result = await LearnedWordController.deleteLearnedWord(id);
    if (result['success'] == true) {
      learnedWords.removeWhere((w) => w.id == id);
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>> deleteMultipleLearnedWords(List<String> ids) async {
    final result = await LearnedWordController.deleteMultipleLearnedWords(ids);
    if (result['success'] == true) {
      learnedWords.removeWhere((w) => ids.contains(w.id));
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>> syncExp() {
    return LearnedWordController.syncExp();
  }
}
