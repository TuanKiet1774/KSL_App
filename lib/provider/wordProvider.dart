import 'package:flutter/material.dart';
import 'package:ksl/controller/wordController.dart';
import 'package:ksl/model/word.dart';

class WordProvider extends ChangeNotifier {
  List<WordModel> words = [];
  bool isLoading = true;
  String? errorMessage;

  List<WordModel> searchResults = [];
  bool isSearching = false;
  String? searchErrorMessage;

  Map<String, dynamic>? analyzeResult;
  bool isAnalyzing = false;

  // Học từ vựng theo topic: tải theo batch, đồng bộ với PageView trong WordListScreen
  List<WordModel> topicWords = [];
  bool isLoadingTopicWords = true;
  String topicWordsError = '';
  int topicWordsPage = 0;
  bool hasMoreTopicWords = true;
  bool isFetchingMoreTopicWords = false;
  static const int _topicBatchSize = 10;

  /// Tải các batch cho đến khi đủ tới [targetIndex] hoặc hết dữ liệu
  Future<void> loadTopicWordsUntilIndex(String topicId, int targetIndex) async {
    isLoadingTopicWords = true;
    topicWordsError = '';
    topicWords = [];
    topicWordsPage = 0;
    hasMoreTopicWords = true;
    notifyListeners();

    while (topicWords.length <= targetIndex && hasMoreTopicWords) {
      final result = await WordController.getWordsByTopic(
        topicId,
        page: topicWordsPage + 1,
        limit: _topicBatchSize,
      );

      if (result['success'] != true) {
        topicWordsError = result['message'];
        break;
      }

      final List<WordModel> newWords = result['data'];
      if (newWords.isEmpty) {
        hasMoreTopicWords = false;
        break;
      }

      topicWords.addAll(newWords);
      if (newWords.length < _topicBatchSize) {
        hasMoreTopicWords = false;
      } else {
        topicWordsPage++;
      }
    }

    isLoadingTopicWords = false;
    notifyListeners();
  }

  Future<void> loadNextTopicWordBatch(String topicId) async {
    if (!hasMoreTopicWords || isFetchingMoreTopicWords) return;
    isFetchingMoreTopicWords = true;
    notifyListeners();

    final nextPage = topicWordsPage + 1;
    final result = await WordController.getWordsByTopic(topicId, page: nextPage, limit: _topicBatchSize);

    if (result['success'] == true) {
      final List<WordModel> nextWords = result['data'];
      if (nextWords.isNotEmpty) {
        topicWords.addAll(nextWords);
        topicWordsPage = nextPage;
        if (nextWords.length < _topicBatchSize) hasMoreTopicWords = false;
      } else {
        hasMoreTopicWords = false;
      }
    }

    isFetchingMoreTopicWords = false;
    notifyListeners();
  }

  void setTopicWordFavorite(String wordId, bool value) {
    final index = topicWords.indexWhere((w) => w.id == wordId);
    if (index != -1) {
      topicWords[index].isFavorite = value;
      notifyListeners();
    }
  }

  Future<void> fetchWordsByTopic(String topicId) async {
    isLoading = true;
    notifyListeners();

    final result = await WordController.getWordsByTopic(topicId);
    if (result['success'] == true) {
      words = result['data'];
      errorMessage = null;
    } else {
      words = [];
      errorMessage = result['message'];
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> searchWords(String query) async {
    isSearching = true;
    notifyListeners();

    final result = await WordController.searchWords(query);
    if (result['success'] == true) {
      searchResults = result['data'];
      searchErrorMessage = null;
    } else {
      searchResults = [];
      searchErrorMessage = result['message'];
    }

    isSearching = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> analyzeSign(String sentence) async {
    isAnalyzing = true;
    notifyListeners();

    final result = await WordController.analyzeSign(sentence);
    analyzeResult = result['success'] == true ? result['data'] : null;

    isAnalyzing = false;
    notifyListeners();
    return result;
  }
}
