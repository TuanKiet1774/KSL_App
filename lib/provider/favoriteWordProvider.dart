import 'package:flutter/material.dart';
import 'package:ksl/controller/favoriteWordController.dart';
import 'package:ksl/model/favoriteWord.dart';

class FavoriteWordProvider extends ChangeNotifier {
  List<FavoriteWordModel> favorites = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  String? errorMessage;
  static const int _limit = 50;

  Future<void> fetchFavorites({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isFetchingMore || !hasMore) return;
      isFetchingMore = true;
    } else {
      isLoading = true;
      currentPage = 1;
      hasMore = true;
    }
    notifyListeners();

    final result = await FavoriteWordController.getMyFavorites(page: currentPage, limit: _limit);

    if (result['success'] == true) {
      final List<FavoriteWordModel> newItems = result['data'];
      hasMore = newItems.length >= _limit;
      if (hasMore) currentPage++;
      favorites = isLoadMore ? [...favorites, ...newItems] : newItems;
      errorMessage = null;
    } else {
      hasMore = false;
      errorMessage = result['message'];
    }

    isLoading = false;
    isFetchingMore = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> addToFavorite({
    required String wordId,
    required String topicId,
    String note = '',
  }) {
    return FavoriteWordController.addToFavorite(wordId: wordId, topicId: topicId, note: note);
  }

  Future<Map<String, dynamic>> removeFromFavorite(String wordId) async {
    final result = await FavoriteWordController.removeFromFavorite(wordId);
    if (result['success'] == true) {
      favorites.removeWhere((f) => f.wordId?.id == wordId);
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>> updateFavoriteNote(String favoriteId, String note) async {
    final result = await FavoriteWordController.updateFavoriteNote(favoriteId, note);
    if (result['success'] == true) {
      final updated = result['data'] as FavoriteWordModel;
      final index = favorites.indexWhere((f) => f.id == favoriteId);
      if (index != -1) favorites[index] = updated;
      notifyListeners();
    }
    return result;
  }
}
