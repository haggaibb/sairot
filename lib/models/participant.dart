import '../models/types.dart';

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
  List<int> meshulashPositions = [];
  List<int> sakimPositions = [];

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
      'meshulashPositions': meshulashPositions,
      'sakimPositions': sakimPositions,
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
      ..meshulashPositions =
      List<int>.from(json['meshulashPositions'] ?? [])
      ..sakimPositions = List<int>.from(json['sakimPositions'] ?? []);
  }
}

/// Extension to convert ParticipantStatus to a string
extension StatusX on ParticipantStatus {
  String get valueAsString => toString().split('.').last;
}