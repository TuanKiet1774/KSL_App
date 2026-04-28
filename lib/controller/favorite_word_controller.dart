import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ksl/connectDB/api.dart';
import 'package:ksl/controller/auth_controller.dart';
import 'package:ksl/model/favorite_word.dart';

class FavoriteWordController {
  /// Thêm từ vựng vào danh sách yêu thích
  static Future<Map<String, dynamic>> addToFavorite({
    required String wordId,
    required String topicId,
    String note = '',
  }) async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.post(
        Uri.parse('$urlAPI/api/favorite-words'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'wordId': wordId,
          'topicId': topicId,
          'note': note,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đã thêm vào yêu thích',
          'data': FavoriteWordModel.fromJson(data['data'])
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể thêm vào yêu thích'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối server: $e'
      };
    }
  }

  /// Lấy danh sách từ yêu thích
  static Future<Map<String, dynamic>> getMyFavorites({int page = 1, int limit = 10}) async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.get(
        Uri.parse('$urlAPI/api/favorite-words?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> listJson = data['data'];
        final List<FavoriteWordModel> list = listJson.map((json) => FavoriteWordModel.fromJson(json)).toList();
        return {
          'success': true,
          'data': list
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể lấy danh sách yêu thích'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối server: $e'
      };
    }
  }

  /// Xóa khỏi danh sách yêu thích
  static Future<Map<String, dynamic>> removeFromFavorite(String wordId) async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.delete(
        Uri.parse('$urlAPI/api/favorite-words/word/$wordId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đã xóa khỏi yêu thích'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể xóa khỏi yêu thích'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối server: $e'
      };
    }
  }

  /// Cập nhật ghi chú cho từ yêu thích
  static Future<Map<String, dynamic>> updateFavoriteNote(String favoriteId, String note) async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.put(
        Uri.parse('$urlAPI/api/favorite-words/$favoriteId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'note': note,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đã cập nhật ghi chú',
          'data': FavoriteWordModel.fromJson(data['data'])
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể cập nhật ghi chú'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối server: $e'
      };
    }
  }
}
