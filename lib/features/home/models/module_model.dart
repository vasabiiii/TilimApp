import 'section_model.dart';

class ModuleModel {
  final int id;
  final String title;
  final List<SectionModel> sections;

  const ModuleModel({
    required this.id,
    required this.title,
    required this.sections,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      id: json['id'] as int,
      title: json['title'] as String,
      sections: (json['sections'] as List)
          .map((section) => SectionModel.fromJson(section))
          .toList(),
    );
  }
} 