import 'package:hive/hive.dart';
import 'dart:convert';

part 'grade_settings.g.dart';

@HiveType(typeId: 200)
class GradeSettings extends HiveObject {
  GradeSettings();
  @HiveField(4)
  int version = 1;
  @HiveField(5)
  double ALONKA_CREDIT = 1.0;
  @HiveField(6)
  double GERIKAN_CREDIT = 0.5;
  @HiveField(7)
  double RUNNER_CREDIT = 0.2;
  @HiveField(8)
  double PARTICIPATION_CREDIT = 0.1;
  @HiveField(9)
  List<String> listOfCommentsBur = ['לא הבין את התרגיל','הבין את התרגיל','השקיע','לא השקיע','מתרץ','לוקח אחריות','בור יפה'];
  @HiveField(10)
  List<String> listOfCommentsPerformance = ['מרים אגן','מחפף','אגרסיבי','שומר כוח','זוחל יפה','משקיע'];
  @HiveField(11)
  List<String> listOfCommentsImpression= ['מכינה או שנת שרות','תלמיד רציני','מחובר לים','מראה מנהיגות','התאמן נעט','התאמן הרבה','ספורטאי'];
  @HiveField(12)
  double systemGradeFactor = 0.7;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      "ALONKA_CREDIT": ALONKA_CREDIT,
      "GERIKAN_CREDIT": GERIKAN_CREDIT,
      "RUNNER_CREDIT": RUNNER_CREDIT,
      "PARTICIPATION_CREDIT": PARTICIPATION_CREDIT,
      "listOfCommentsBur": listOfCommentsBur,
      "listOfCommentsPerformance": listOfCommentsPerformance,
      "listOfCommentsImpression": listOfCommentsImpression,
      "systemGradeFactor" : systemGradeFactor,
      "version" : version
    };
  }

  /// Convert from JSON
  factory GradeSettings.fromJson(Map<String, dynamic> json) {
    return GradeSettings()
      ..ALONKA_CREDIT = (json["ALONKA_CREDIT"] ?? 1.0).toDouble()
      ..GERIKAN_CREDIT = (json["GERIKAN_CREDIT"] ?? 0.5).toDouble()
      ..RUNNER_CREDIT = (json["RUNNER_CREDIT"] ?? 0.2).toDouble()
      ..PARTICIPATION_CREDIT = (json["PARTICIPATION_CREDIT"] ?? 0.1).toDouble()
      ..listOfCommentsBur = List<String>.from(json["listOfCommentsBur"] ?? [])
      ..listOfCommentsPerformance = List<String>.from(json["listOfCommentsPerformance"] ?? [])
      ..listOfCommentsImpression = List<String>.from(json["listOfCommentsImpression"] ?? [])
      ..systemGradeFactor = (json["system_grade_factor"] ?? 0.2).toDouble()
      ..version = (json["version"] ?? 0).toInt();
  }


  /// Convert object to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Convert JSON string to object
  static GradeSettings fromJsonString(String jsonString) {
    return GradeSettings.fromJson(jsonDecode(jsonString));
  }
}