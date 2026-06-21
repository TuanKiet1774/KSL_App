import 'package:flutter/material.dart';
import 'package:ksl/controller/topicController.dart';
import 'package:ksl/model/topic.dart';

class TopicProvider extends ChangeNotifier {
  List<TopicModel> topics = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  String? errorMessage;
  static const int _limit = 10;

  Future<void> fetchTopics({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isFetchingMore || !hasMore) return;
      isFetchingMore = true;
    } else {
      isLoading = true;
      currentPage = 1;
      hasMore = true;
    }
    notifyListeners();

    final result = await TopicController.getAllTopics(page: currentPage, limit: _limit);

    if (result['success'] == true) {
      final List<TopicModel> newTopics = result['data'];
      hasMore = newTopics.length >= _limit;
      if (hasMore) currentPage++;
      topics = isLoadMore ? [...topics, ...newTopics] : newTopics;
      errorMessage = null;
    } else {
      hasMore = false;
      errorMessage = result['message'];
    }

    isLoading = false;
    isFetchingMore = false;
    notifyListeners();
  }
}
