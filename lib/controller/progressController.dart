import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:ksl/connectDB/api.dart';
import 'package:ksl/controller/authController.dart';
import 'package:ksl/model/progress.dart';

class ProgressController {
  static DateTime? _sessionStartTime;
  static Timer? _heartbeatTimer;
  static int _secondsSent = 0;

  /// Bắt đầu phiên làm việc mới
  static void startSession() {
    if (_sessionStartTime != null) return;
    
    _sessionStartTime = DateTime.now();
    _secondsSent = 0;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final now = DateTime.now();
      final totalSecondsSoFar = now.difference(_sessionStartTime!).inSeconds;
      final incrementSeconds = totalSecondsSoFar - _secondsSent;
      
      if (incrementSeconds >= 30) {
        updateLearningTime(incrementSeconds);
        _secondsSent = totalSecondsSoFar;
      }
    });
    
    debugPrint('[ProgressController] Session started at $_sessionStartTime');
  }

  /// Kết thúc phiên làm việc và gửi thời gian còn lại lên server
  static Future<void> endSession() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (_sessionStartTime != null) {
      final now = DateTime.now();
      final totalSeconds = now.difference(_sessionStartTime!).inSeconds;
      final remainingSeconds = totalSeconds - _secondsSent;
      
      if (remainingSeconds > 5) {
        debugPrint('[ProgressController] Session ending. Sending remaining $remainingSeconds seconds');
        await updateLearningTime(remainingSeconds);
      }
      
      _sessionStartTime = null;
      _secondsSent = 0;
    }
  }

  /// Lấy thông tin tiến độ và thống kê của người dùng
  static Future<Map<String, dynamic>> getUserProgress() async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.get(
        Uri.parse('$urlAPI/api/progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': ProgressModel.fromJson(data['data'])
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể lấy thông tin thống kê'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối server'
      };
    }
  }

  /// Cập nhật thời gian học tập (hỗ trợ cả giây và phút)
  static Future<Map<String, dynamic>> updateLearningTime(int durationSeconds) async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) return {'success': false, 'message': 'Chưa đăng nhập'};

      final response = await http.post(
        Uri.parse('$urlAPI/api/progress/update-learning-time'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'duration': durationSeconds,          // Đơn vị giây
          'durationMinutes': durationSeconds / 60.0, // Đơn vị phút (cho phép số thập phân)
          'timeSpent': durationSeconds,         // Đồng bộ với logic của bài thi
          'sessionStart': _sessionStartTime?.toIso8601String(),
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      // Nếu token không hợp lệ (hết hạn hoặc bị logout từ thiết bị khác)
      if (response.statusCode == 401) {
        final data = jsonDecode(response.body);
        AuthController.handleSessionExpired(data['message'] ?? 'Phiên đăng nhập đã kết thúc do tài khoản được đăng nhập ở thiết bị khác.');
        return {'success': false, 'message': 'Session expired'};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': 'Đã cập nhật thời gian học'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể cập nhật thời gian học'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối server'
      };
    }
  }
}
