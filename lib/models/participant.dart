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
  int instructorGrade = 0;
  double systemGrade = 0;
  String name = '';
  int groupNumber = 0;
  String participantAIReport ='';
  List<int> meshulashPositions = [];
  List<int> sakimPositions = [];
  List<String> meshulashInstructorComments = [];
  List<String> alonkaInstructorComments = [];
  List<String> sakimInstructorComments = [];
  List<String> leadershipInstructorComments = [];
  List<String> interviewInstructorComments = [];

  /// Set final instructor grade
  setFinalGrade(int grade) {
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
      'systemGrade': systemGrade,
      'name': name,
      'groupNumber': groupNumber,
      'participateAIReport' : participantAIReport,
      'meshulashPositions': meshulashPositions,
      'sakimPositions': sakimPositions,
      'meshulashInstructorComments': meshulashInstructorComments,
      'alonkaInstructorComments': alonkaInstructorComments,
      'sakimInstructorComments': sakimInstructorComments,
      'leadershipInstructorComments': leadershipInstructorComments,
      'interviewInstructorComments': interviewInstructorComments,
    };
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
      ..instructorGrade = json['instructorGrade'] ?? 0
      ..systemGrade = (json['systemGrade'] ?? 0).toDouble()
      ..groupNumber = json['groupNumber'] ?? 0
      ..participantAIReport = json['fullName'] ?? ''
      ..meshulashPositions = List<int>.from(json['meshulashPositions'] ?? [])
      ..sakimPositions = List<int>.from(json['sakimPositions'] ?? [])
      ..meshulashInstructorComments =
          List<String>.from(json['meshulashInstructorComments'] ?? [])
      ..alonkaInstructorComments =
          List<String>.from(json['alonkaInstructorComments'] ?? [])
      ..sakimInstructorComments =
          List<String>.from(json['sakimInstructorComments'] ?? [])
      ..leadershipInstructorComments =
          List<String>.from(json['leadershipInstructorComments'] ?? [])
      ..interviewInstructorComments =
          List<String>.from(json['interviewInstructorComments'] ?? []);
  }

  /// tests
  /// Vertex AI
  Map<String, dynamic>fetchParticipantData(participantId) {
    Participant p = eventController.getParticipant(int.parse(participantId));
    print(p.toJson());
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
    print(prompt);
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

}

/// Extension to convert ParticipantStatus to a string
extension StatusX on ParticipantStatus {
  String get valueAsString => toString().split('.').last;
}

