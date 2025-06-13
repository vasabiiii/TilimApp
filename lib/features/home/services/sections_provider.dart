import 'package:flutter/material.dart';
import '../models/section_model.dart';
import 'module_service.dart';

class SectionsProvider extends ChangeNotifier {
  final ModuleService _moduleService = ModuleService();
  List<SectionModel> _sections = [];
  bool _isLoading = false;
  String? _error;

  List<SectionModel> get sections => _sections;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSections(int moduleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final module = await _moduleService.getModule(moduleId);
      if (module != null) {
        _sections = module.sections.map((section) => SectionModel(
          id: section.id,
          title: section.title,
          lessons: section.lessons,
          moduleTitle: module.title,
          moduleId: module.id,
        )).toList();
      } else {
        _error = 'Не удалось загрузить разделы';
      }
    } catch (e) {
      _error = 'Ошибка загрузки разделов: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
} 