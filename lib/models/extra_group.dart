import 'package:lacarta/models/extra_option.dart';

class ExtraGroup {
  final String id;
  final String title;
  final bool isRequired;
  final int minSelection;
  final int maxSelection;
  final List<ExtraOption> options;

  ExtraGroup({
    required this.id,
    required this.title,
    required this.isRequired,
    required this.minSelection,
    required this.maxSelection,
    required this.options,
  });

  factory ExtraGroup.fromMap(Map<String, dynamic> map) {
    return ExtraGroup(
      id: map['id'],
      title: map['title'],
      isRequired: map['isRequired'],
      minSelection: map['minSelection'],
      maxSelection: map['maxSelection'],
      options: (map['options'] as List)
          .map((e) => ExtraOption.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isRequired': isRequired,
      'minSelection': minSelection,
      'maxSelection': maxSelection,
      'options': options.map((e) => e.toMap()).toList(),
    };
  }
}