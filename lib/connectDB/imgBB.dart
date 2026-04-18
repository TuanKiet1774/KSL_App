import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

final String imgBB_Token = "703790f2ae91a72e116c63e9dc5cff6f";

class ImgBBService {
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$imgBB_Token'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final decodedData = json.decode(responseData);

      if (response.statusCode == 200 && decodedData['success'] == true) {
        return decodedData['data']['url'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error uploading to ImgBB: $e');
      return null;
    }
  }
}