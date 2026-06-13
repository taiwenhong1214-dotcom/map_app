import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ImageUploadService {
  /// Uploads an image to catbox.moe (free, no registration, 200MB limit)
  /// Returns the direct image URL upon success, or null upon failure.
  static Future<String?> uploadImage(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://catbox.moe/user/api.php'),
      );
      
      request.fields['reqtype'] = 'fileupload';
      request.files.add(
        await http.MultipartFile.fromPath('fileToUpload', file.path),
      );

      final response = await request.send();
      
      if (response.statusCode == 200) {
        final url = await response.stream.bytesToString();
        debugPrint('Catbox upload success: $url');
        return url.trim();
      } else {
        debugPrint('Catbox upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading image to Catbox: $e');
      return null;
    }
  }
}
