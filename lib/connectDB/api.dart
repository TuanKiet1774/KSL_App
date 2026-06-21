import 'package:http/http.dart' as http;

final String urlAPI = 'https://ksl-be.onrender.com';

extension HttpTimeout on Future<http.Response> {
  Future<http.Response> withTimeout() => timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Kết nối quá hạn. Vui lòng kiểm tra mạng và thử lại.'),
      );
}