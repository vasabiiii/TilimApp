import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../config/app_config.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  String _generateSignature(Map<String, String> params, String apiSecret) {
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    final paramString = sortedParams.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
    
    final stringToSign = '$paramString$apiSecret';
    
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  Future<String?> uploadImage(dynamic imageFile, {String? folder}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(AppConfig.cloudinaryUploadUrl));

      if (kIsWeb) {
        final xFile = imageFile as XFile;
        final bytes = await xFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: xFile.name,
        ));
      } else {
        final file = imageFile as File;
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      
      print('Generated timestamp for: ${DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toUtc()}');
      
      final params = <String, String>{'timestamp': timestamp.toString()};
      if (folder != null) params['folder'] = folder;

      final signature = _generateSignature(params, AppConfig.cloudinaryApiSecret);

      request.fields.addAll({
        'api_key': AppConfig.cloudinaryApiKey,
        ...params,
        'signature': signature,
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        return jsonDecode(responseBody)['secure_url'] as String?;
      } else {
        print('Cloudinary error: $responseBody');
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<String?> uploadImageForAvatar(dynamic imageFile) async {
    return await uploadImage(imageFile, folder: 'avatars');
  }
} 