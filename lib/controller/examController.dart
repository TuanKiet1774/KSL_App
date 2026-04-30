import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ksl/connectDB/api.dart';
import 'package:ksl/controller/authController.dart';
import 'package:ksl/model/exam.dart';
import 'package:ksl/model/examResult.dart';

class ExamController {
  /// Lấy danh sách tất cả các bài thi
  static Future<Map<String, dynamic>> getAllExams() async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.get(
        Uri.parse('$urlAPI/api/exams'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> examJson = data['data'];
        final List<ExamModel> exams = examJson.map((json) => ExamModel.fromJson(json)).toList();
        
        return {
          'success': true,
          'data': exams
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể lấy danh sách bài thi'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối server: $e'
      };
    }
  }

  /// Lấy chi tiết bài thi theo ID
  static Future<Map<String, dynamic>> getExamById(String id) async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.get(
        Uri.parse('$urlAPI/api/exams/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final ExamModel exam = ExamModel.fromJson(data['data']);
        return {
          'success': true,
          'data': exam
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể lấy chi tiết bài thi'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối server: $e'
      };
    }
  }

  /// Gửi kết quả bài thi lên server
  static Future<Map<String, dynamic>> submitExamResult({
    required String userId,
    required String examId,
    required List<Map<String, dynamic>> results,
    required int totalScore,
    required int maxScore,
    required int timeSpent,
  }) async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.post(
        Uri.parse('$urlAPI/api/exams/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'examId': examId,
          'results': results,
          'totalScore': totalScore,
          'maxScore': maxScore,
          'timeSpent': timeSpent,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể lưu kết quả bài thi'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối server: $e'
      };
    }
  }

  // Lấy lịch sử bài thi của người dùng
  static Future<Map<String, dynamic>> getUserResults(String userId) async {
    try {
      final token = await AuthController.getAccessToken();
      final response = await http.get(
        Uri.parse('$urlAPI/api/exams/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List resultsJson = data['data'] ?? [];
        final List<ExamResultModel> results = resultsJson
            .map((item) => ExamResultModel.fromJson(item))
            .toList();
        return {
          'success': true,
          'data': results,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Lỗi không xác định khi lấy lịch sử bài thi',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  // Xóa một kết quả bài thi
  static Future<Map<String, dynamic>> deleteResult(String resultId) async {
    try {
      final token = await AuthController.getAccessToken();
      final response = await http.delete(
        Uri.parse('$urlAPI/api/exams/results/$resultId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Không thể xóa kết quả'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Xóa toàn bộ lịch sử bài thi của người dùng
  static Future<Map<String, dynamic>> clearHistory(String userId) async {
    try {
      final token = await AuthController.getAccessToken();
      final response = await http.delete(
        Uri.parse('$urlAPI/api/exams/user/$userId/clear'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Không thể xóa lịch sử'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
