import 'dart:convert';
import '../../../config/app_config.dart';
import '../../../core/services/http_service.dart';
import '../models/module_model.dart';

class ModuleService {
  final HttpService _httpService = HttpService();

  Future<ModuleModel?> getModule(int moduleId) async {
    try {
      final response = await _httpService.get('${AppConfig.baseUrl}/main-page/module/$moduleId');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ModuleModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
} 