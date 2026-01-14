import 'dart:convert';


class GradeSettings {
  GradeSettings();
  int version = 1;
  double ALONKA_CREDIT = 1.0;
  double GERIKAN_CREDIT = 0.5;
  double RUNNER_CREDIT = 0.2;
  double PARTICIPATION_CREDIT = 0.1;
  Map<String, dynamic> weighted = {};
  List<String> listOfCommentsBur = ['לא הבין את התרגיל','הבין את התרגיל','השקיע','לא השקיע','מתרץ','לוקח אחריות','בור יפה'];
  List<String> listOfCommentsMeshulash = ['מרים אגן','מחפף','אגרסיבי','שומר כוח','זוחל יפה','משקיע'];
  List<String> listOfCommentsAlonka = ['אגרסיבי','שומר כוח','משקיע','מחפף'];
  List<String> listOfCommentsSakim = ['מחפף','אגרסיבי','שומר כוח','משקיע'];
  List<String> listOfCommentsLeadership= ['מכינה או שנת שרות','תלמיד רציני','מחובר לים','מראה מנהיגות','התאמן מעט','התאמן הרבה','ספורטאי'];
  List<String> listOfCommentsInterview= ['מכינה או שנת שרות','תלמיד רציני','מחובר לים','מראה מנהיגות','התאמן מעט','התאמן הרבה','ספורטאי'];
  double systemGradeFactor = 0.7;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      "ALONKA_CREDIT": ALONKA_CREDIT,
      "GERIKAN_CREDIT": GERIKAN_CREDIT,
      "RUNNER_CREDIT": RUNNER_CREDIT,
      "PARTICIPATION_CREDIT": PARTICIPATION_CREDIT,
      "weighted" : weighted,
      "listOfCommentsBur": listOfCommentsBur,
      "listOfCommentsMeshulash": listOfCommentsMeshulash,
      "listOfCommentsAlonka": listOfCommentsAlonka,
      "listOfCommentsSakim": listOfCommentsSakim,
      "listOfCommentsLeadership": listOfCommentsLeadership,
      "listOfCommentsInterview": listOfCommentsInterview,
      "systemGradeFactor" : systemGradeFactor,
      "version" : version
    };
  }

  /// Convert from JSON
  factory GradeSettings.fromJson(Map<String, dynamic> json) {
    //print(json['weighted']);
    return GradeSettings()
      ..ALONKA_CREDIT = (json["ALONKA_CREDIT"] ?? 1.0).toDouble()
      ..GERIKAN_CREDIT = (json["GERIKAN_CREDIT"] ?? 0.5).toDouble()
      ..RUNNER_CREDIT = (json["RUNNER_CREDIT"] ?? 0.2).toDouble()
      ..PARTICIPATION_CREDIT = (json["PARTICIPATION_CREDIT"] ?? 0.1).toDouble()
      ..weighted = (json['weighted']) ?? {}
      ..listOfCommentsBur = List<String>.from(json["listOfCommentsBur"] ?? [])
      ..listOfCommentsMeshulash = List<String>.from(json["listOfCommentsMeshulash"] ?? [])
      ..listOfCommentsAlonka = List<String>.from(json["listOfCommentsAlonka"] ?? [])
      ..listOfCommentsSakim = List<String>.from(json["listOfCommentsSakim"] ?? [])
      ..listOfCommentsLeadership = List<String>.from(json["listOfCommentsLeadership"] ?? [])
      ..listOfCommentsInterview = List<String>.from(json["listOfCommentsInterview"] ?? [])
      ..systemGradeFactor = (json["systemGradeFactor"] ?? 1).toDouble()
      ..version = (json["version"] ?? 0).toInt();
  }


  /// Convert object to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Convert JSON string to object
  static GradeSettings fromJsonString(String jsonString) {
    return GradeSettings.fromJson(jsonDecode(jsonString));
  }
}