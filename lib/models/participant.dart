import 'package:sairot/pages/performance_page.dart';
import '../models/types.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'alonka_sprint.dart';
import 'bur.dart';

class Participant {
  Participant({required this.number, required this.name});

  int number;
  double sakimGrade = 0;
  double alonkaGrade = 0;
  double meshulashGrade = 0;
  double burGrade = 0;
  ParticipantStatus status = ParticipantStatus.Active;
  String fullName = '';
  double instructorGrade = 0.0;
  double instructorMeshulashGrade = 0.0; // Instructor's grade for Meshulash exercise
  double instructorAlonkaGrade = 0.0; // Instructor's grade for Alonka exercise
  double instructorSakimGrade = 0.0; // Instructor's grade for Sakim exercise
  int instructorBurGrade = 0; // Instructor's grade for Bur exercise (deprecated - use burGrades collection)
  double systemGrade = 0;
  String name = '';
  int groupNumber = 0;
  String participantAIReport ='';
  String? commentsSummary; // Cached summary of instructor comments
  List<int> meshulashPositions = [];
  List<int> sakimPositions = [];
  List<int> lastMeshulashIndexStack = []; // Stack of indices for undo (most recent last)
  List<int> lastSakimIndexStack = []; // Stack of indices for undo (most recent last)
  List<String> meshulashInstructorComments = [];
  List<String> alonkaInstructorComments = [];
  List<String> sakimInstructorComments = [];
  List<String> leadershipInstructorComments = [];
  List<String> interviewInstructorComments = [];
  List<String> genericInstructorComments = []; // Generic comments (from event home page)

  /// Set final instructor grade
  setFinalGrade(double grade) {
    instructorGrade = grade;
  }

  /// Convert Participant to JSON format for Firestore
  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'sakimGrade': sakimGrade,
      'alonkaGrade': alonkaGrade,
      'meshulashGrade': meshulashGrade,
      'burGrade': burGrade,
      'status': status.valueAsString,
      'fullName': fullName,
      'instructorGrade': instructorGrade,
      'instructorMeshulashGrade': instructorMeshulashGrade,
      'instructorAlonkaGrade': instructorAlonkaGrade,
      'instructorSakimGrade': instructorSakimGrade,
      'instructorBurGrade': instructorBurGrade,
      'systemGrade': systemGrade,
      'name': name,
      'groupNumber': groupNumber,
      'participantAIReport' : participantAIReport,
      'commentsSummary': commentsSummary,
      'meshulashPositions': meshulashPositions,
      'sakimPositions': sakimPositions,
      'lastMeshulashIndexStack': lastMeshulashIndexStack,
      'lastSakimIndexStack': lastSakimIndexStack,
      'meshulashInstructorComments': meshulashInstructorComments,
      'alonkaInstructorComments': alonkaInstructorComments,
      'sakimInstructorComments': sakimInstructorComments,
      'leadershipInstructorComments': leadershipInstructorComments,
      'interviewInstructorComments': interviewInstructorComments,
      'genericInstructorComments': genericInstructorComments,
    };
  }

  /// Helper method to parse index stack with backward compatibility
  /// If new stack format exists, use it; otherwise convert old int? to list
  static List<int> _parseIndexStack(dynamic stackValue, dynamic oldIndexValue) {
    if (stackValue != null && stackValue is List) {
      return List<int>.from(stackValue);
    }
    // Backward compatibility: convert old int? to list
    if (oldIndexValue != null && oldIndexValue is int) {
      return [oldIndexValue];
    }
    return [];
  }

  /// Create an instance of Participant from JSON
  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      number: json['number'] ?? 0,
      name: json['name'] ?? '',
    )
      ..sakimGrade = (json['sakimGrade'] ?? 0).toDouble()
      ..alonkaGrade = (json['alonkaGrade'] ?? 0).toDouble()
      ..meshulashGrade = (json['meshulashGrade'] ?? 0).toDouble()
      ..burGrade = (json['burGrade'] ?? 0).toDouble()
      ..status = ParticipantStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['status'],
          orElse: () => ParticipantStatus.Active)
      ..fullName = json['fullName'] ?? ''
      ..instructorGrade = (json['instructorGrade'] ?? 0).toDouble()
      ..instructorMeshulashGrade = (json['instructorMeshulashGrade'] ?? 0).toDouble()
      ..instructorAlonkaGrade = (json['instructorAlonkaGrade'] ?? 0).toDouble()
      ..instructorSakimGrade = (json['instructorSakimGrade'] ?? 0).toDouble()
      ..instructorBurGrade = json['instructorBurGrade'] ?? 0
      ..systemGrade = (json['systemGrade'] ?? 0).toDouble()
      ..groupNumber = json['groupNumber'] ?? 0
      ..participantAIReport = json['participantAIReport'] ?? json['participateAIReport'] ?? ''
      ..commentsSummary = json['commentsSummary']
      ..meshulashPositions = List<int>.from(json['meshulashPositions'] ?? [])
      ..sakimPositions = List<int>.from(json['sakimPositions'] ?? [])
      ..lastMeshulashIndexStack = _parseIndexStack(json['lastMeshulashIndexStack'], json['lastMeshulashIndex'])
      ..lastSakimIndexStack = _parseIndexStack(json['lastSakimIndexStack'], json['lastSakimIndex'])
      ..meshulashInstructorComments =
          List<String>.from(json['meshulashInstructorComments'] ?? [])
      ..alonkaInstructorComments =
          List<String>.from(json['alonkaInstructorComments'] ?? [])
      ..sakimInstructorComments =
          List<String>.from(json['sakimInstructorComments'] ?? [])
      ..leadershipInstructorComments =
          List<String>.from(json['leadershipInstructorComments'] ?? [])
      ..interviewInstructorComments =
          List<String>.from(json['interviewInstructorComments'] ?? [])
      ..genericInstructorComments =
          List<String>.from(json['genericInstructorComments'] ?? []);
  }

  /// tests
  /// Vertex AI
  Map<String, dynamic>fetchParticipantData(participantId) {
    Participant p = eventController.getParticipant(int.parse(participantId));
    return p.toJson();
  }

  Future<String> fetchAndGenerateSummary(String participantId) async {
    var participantData = fetchParticipantData(participantId);
    /// get bur comments. for id eventController.get
    int participantBurIndex = eventController.currentEvent.value.burGrades.indexWhere((Bur bur) => bur.id == number);
    participantData["burInstructorComments"] = eventController.currentEvent.value.burGrades[participantBurIndex].instructorComments;
    participantData["date"] = eventController.currentEvent.value.date;
    participantData["allParticipants"] = eventController.currentEvent.value.participants;
    String prompt = generatePrompt(participantData);
    String res = await getVertexAISummary(prompt);
    participantAIReport = res;
    //print(res);
    return res;
  }
  String generatePrompt(Map<String, dynamic> participantData) {
    final List<int> rounds = eventController.currentEvent.value.alonkaSprints
        .map((AlonkaSprint sprint) => sprint.round)
        .toList();
    final List<double> participantsSprintCredit =
    rounds.map((round) => eventController.getAlonkaSprintCredit(number, round)).toList();
    return """
Analyze the following performance of participant number $number in the following events:
Date of when these tests were taken : ${participantData["date"]}
Score Logic - range  1 to 7, 1 being bad 7 being best
Analyze his endurance during the events, you can see that by his positions during the event.


Event name is Triangle - Event Overview is to crawl, carry a sandbag up hill and back.
the target is to do as many rounds as you can, and finish first.  
  Score : ${participantData["meshulashGrade"]}
  Positions :  ${participantData["meshulashPositions"]}
  Instructor comments : ${participantData["meshulashInstructorComments"]}
  Score Logic - range  1 to 7, 1 being bad 7 being best


Event name is Stretcher Sprints - Event Overview is to sprint up hill and back, pick up stretcher for full point or a Jerrycan for a half a point, the target is to get as much credit as possible in each round :
  Score : ${participantData["alonkaGrade"]}
  Credits per Round:  ${participantsSprintCredit}
  Instructor comments : ${participantData["alonkaInstructorComments"]}
  Score Logic - range  1 to 7, 1 being bad 7 being best


 Event name is Bur - Event Overview is to to dig a hole in the sand according to the instructions given, grade is given and  ranges  1 to 7, 1 being bad 7 being best
  Score : ${participantData["burGrade"]},
  Instructor comments : ${participantData["burInstructorComments"]}



Event name is Sandbags - Event Overview is to carry a sandbag up hill and back, the target is to do as many rounds as you can, and finish as first.
The possitions array shows what position the participant was in each round, value of 1 in the array represents first place  
  Score : ${participantData["sakimGrade"]}
  Positions :  ${participantData["sakimPositions"]}
  Instructor comments : ${participantData["sakimInstructorComments"]}
  Score Logic - range  1 to 7, 1 being bad 7 being best

  
  
 Instructor interview - comments given by the instructor about the participant show comments and create a short summary using these comments
  Instructor comments : ${participantData["interviewInstructorComments"]} , ${participantData["leadershipInstructorComments"]}

Overall Participant Score - ${participantData["systemGrade"]}

Group Results - this the results of all participants in these tests.
Group Results :  ${participantData["allParticipants"] }


Provide a detailed **performance summary** do not include any future recommendations, include a competitive analysis of this participant vs the others, provide it in a professional tone, scores should be presented with only two place after the dot, provide the summary in hebrew in a nice text format.
""";
  }
  Future<String> getVertexAISummary(String prompt) async {
    try {
      // Get the model instance
      final model = FirebaseVertexAI.instance.generativeModel(
        model: "gemini-2.5-pro", // Use "gemini-1" or another available model
      );

      // Create a content list as required by generateContent()
      final contentList = [Content.text(prompt)];

      // Generate the AI response
      final response = await model.generateContent(contentList);

      // Return the response if available
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        print("❌ Vertex AI returned an empty response.");
        return "No summary available.";
      }
    } catch (e) {
      print("❌ Error in Vertex AI API: $e");
      return "Error generating summary.";
    }
  }

  /// Generate a one-paragraph summary based on all instructor comments
  /// Returns cached summary if available, otherwise generates new one
  /// Only generates if sakim grade is available (indicates sufficient data)
  Future<String> generateCommentsSummary() async {
    // Only generate summary if sakim grade is available (indicates sufficient data)
    if (sakimGrade <= 0) {
      return "סיכום הערות יופיע לאחר השלמת תרגיל השקים.";
    }
    
    // Collect all instructor comments from all exercises
    List<String> meshulashComments = meshulashInstructorComments;
    List<String> alonkaComments = alonkaInstructorComments;
    List<String> sakimComments = sakimInstructorComments;
    List<String> leadershipComments = leadershipInstructorComments;
    List<String> interviewComments = interviewInstructorComments;
    List<String> genericComments = genericInstructorComments;
    
    // Get Bur comments from Bur model
    List<String> burComments = [];
    try {
      int participantBurIndex = eventController.currentEvent.value.burGrades
          .indexWhere((Bur bur) => bur.id == number);
      if (participantBurIndex >= 0) {
        burComments = eventController.currentEvent.value.burGrades[participantBurIndex].instructorComments;
      }
    } catch (e) {
      print("⚠️ Error getting Bur comments: $e");
    }
    
    // Count comments (excluding bur comments)
    int commentCount = meshulashComments.length +
        alonkaComments.length +
        sakimComments.length +
        leadershipComments.length +
        interviewComments.length +
        genericComments.length;
    
    // Need at least 3 comments (excluding bur) to generate summary
    if (commentCount < 3) {
      return "נדרשות לפחות 3 הערות (מלבד בור) ליצירת סיכום.";
    }
    
    // Create focused prompt for comments-only summary
    String prompt = _generateCommentsPrompt(
      meshulashComments,
      alonkaComments,
      sakimComments,
      burComments,
      leadershipComments,
      interviewComments,
      genericComments,
    );
    
    // Generate summary using VertexAI
    String summary = await getVertexAISummary(prompt);
    
    // Cache the result
    commentsSummary = summary;
    
    // Save to Firestore (async, don't wait)
    try {
      eventController.currentEvent.value.saveToFirestore();
    } catch (e) {
      print("⚠️ Error saving comments summary to Firestore: $e");
    }
    
    return summary;
  }
  
  /// Generate prompt for comments-only summary
  String _generateCommentsPrompt(
    List<String> meshulashComments,
    List<String> alonkaComments,
    List<String> sakimComments,
    List<String> burComments,
    List<String> leadershipComments,
    List<String> interviewComments,
    List<String> genericComments,
  ) {
    return """
תבסס על ההערות הבאות של המדריך מתרגילים שונים, צור סיכום קצר של פסקה אחת בעברית שמתמצת את התובנות המרכזיות על משתתף זה. התמקד בנושאים, נקודות חוזק ואזורים שהוזכרו בהערות.

הערות מתרגיל המשולש: ${meshulashComments.isEmpty ? 'אין הערות' : meshulashComments.join(', ')}
הערות מתרגיל האלונקה: ${alonkaComments.isEmpty ? 'אין הערות' : alonkaComments.join(', ')}
הערות מתרגיל השקים: ${sakimComments.isEmpty ? 'אין הערות' : sakimComments.join(', ')}
הערות מתרגיל הבור: ${burComments.isEmpty ? 'אין הערות' : burComments.join(', ')}
הערות ממנהיגות: ${leadershipComments.isEmpty ? 'אין הערות' : leadershipComments.join(', ')}
הערות מראיון: ${interviewComments.isEmpty ? 'אין הערות' : interviewComments.join(', ')}
הערות כלליות: ${genericComments.isEmpty ? 'אין הערות' : genericComments.join(', ')}

צור סיכום של פסקה אחת בעברית (2-4 משפטים) שמסנתז את ההערות הללו. התמקד בנושאים המרכזיים, נקודות חוזק, ואזורים שדורשים תשומת לב שהוזכרו בהערות. כתוב בטון מקצועי ותמציתי.
""";
  }

}

/// Extension to convert ParticipantStatus to a string
extension StatusX on ParticipantStatus {
  String get valueAsString => toString().split('.').last;
}

