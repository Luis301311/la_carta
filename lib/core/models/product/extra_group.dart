import 'package:lacarta/core/models/product/extra_option.dart';

class ExtraGroup {
  final String? id;
  final String title;
  final bool isRequired;
  final int minSelection;
  final int maxSelection;
  final List<ExtraOption> options;

  ExtraGroup({
    this.id,
    required this.title,
    required this.isRequired,
    required this.minSelection,
    required this.maxSelection,
    required this.options,
  });

  factory ExtraGroup.fromJson(Map<String, dynamic> json) {
    return ExtraGroup(
      id: json['id'],
      title: json['title'] ?? '',
      isRequired: json['isRequired'] ?? false,
      minSelection: (json['minSelection'] as num?)?.toInt() ?? 0,
      maxSelection: (json['maxSelection'] as num?)?.toInt() ?? 1,
      options: ((json['options'] as List?) ?? [])
          .map((e) => ExtraOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isRequired': isRequired,
      'minSelection': minSelection,
      'maxSelection': maxSelection,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }
}
