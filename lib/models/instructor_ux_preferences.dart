import 'package:hive/hive.dart';
part 'instructor_ux_preferences.g.dart';

@HiveType(typeId: 104)
class InstructorUxPreferences {
  @HiveField(0)
  final double fontSize;

  @HiveField(1)
  final String theme; // 'light', 'dark'

  @HiveField(2)
  final bool inOrderOfArrival;

  @HiveField(3)
  final bool floatingPttEnabled;

  @HiveField(4)
  final bool volumeButtonPttEnabled;

  InstructorUxPreferences({
    this.fontSize = 18.0,
    this.theme = 'dark',
    this.inOrderOfArrival = true,
    this.floatingPttEnabled = false,
    this.volumeButtonPttEnabled = false,
  });

  factory InstructorUxPreferences.fromJson(Map<String, dynamic> json) {
    return InstructorUxPreferences(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18.0,
      theme: json['theme'] ?? 'dark',
      inOrderOfArrival: json['inOrderOfArrival'] ?? true,
      floatingPttEnabled: json['floatingPttEnabled'] ?? false,
      volumeButtonPttEnabled: json['volumeButtonPttEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'fontSize': fontSize,
        'theme': theme,
        'inOrderOfArrival': inOrderOfArrival,
        'floatingPttEnabled': floatingPttEnabled,
        'volumeButtonPttEnabled': volumeButtonPttEnabled,
      };

  InstructorUxPreferences copyWith({
    double? fontSize,
    String? theme,
    bool? inOrderOfArrival,
    bool? floatingPttEnabled,
    bool? volumeButtonPttEnabled,
  }) {
    return InstructorUxPreferences(
      fontSize: fontSize ?? this.fontSize,
      theme: theme ?? this.theme,
      inOrderOfArrival: inOrderOfArrival ?? this.inOrderOfArrival,
      floatingPttEnabled: floatingPttEnabled ?? this.floatingPttEnabled,
      volumeButtonPttEnabled:
          volumeButtonPttEnabled ?? this.volumeButtonPttEnabled,
    );
  }
}
