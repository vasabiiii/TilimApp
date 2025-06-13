import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String baseUrl = 'http://localhost:8080';

  static String get cloudinaryCloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get cloudinaryApiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get cloudinaryApiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
  
  static String get cloudinaryUploadUrl => 'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';
  
  static String getCloudinaryImageUrl(String publicId, {int? width, int? height, String? format}) {
    String url = 'https://res.cloudinary.com/$cloudinaryCloudName/image/upload';
    
    List<String> transformations = [];
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    if (format != null) transformations.add('f_$format');
    
    if (transformations.isNotEmpty) {
      url += '/${transformations.join(',')}';
    }
    
    return '$url/$publicId';
  }
} 