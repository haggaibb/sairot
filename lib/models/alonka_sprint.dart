import '../models/types.dart';

class AlonkaSprint {
  AlonkaSprint({required this.round, required this.activeParticipants});

  final int round;
  List<int> alonkaCredits = [];
  List<int> gerikanCredits = [];
  List<int> runCredits = [];
  List<int> participationCredits = [];
  List<int> activeParticipants = [];

  /// Check if participant has Alonka Credit
  bool participantHasAlonkaCredit(int number) {
    return alonkaCredits.contains(number);
  }

  /// Add Alonka Credit based on type
  void addAlonkaCredit(int id, AlonkaCreditTypes type) {
    switch (type) {
      case AlonkaCreditTypes.Alonka:
        alonkaCredits.add(id);
        break;
      case AlonkaCreditTypes.Gerikan:
        gerikanCredits.add(id);
        break;
      case AlonkaCreditTypes.Runner:
        runCredits.add(id);
        break;
      default:
        participationCredits.add(id);
        break;
    }
  }

  /// Convert AlonkaSprint to JSON format for Firestore
  Map<String, dynamic> toJson() {
    return {
      'round': round,
      'alonkaCredits': alonkaCredits,
      'gerikanCredits': gerikanCredits,
      'runCredits': runCredits,
      'participationCredits': participationCredits,
      'activeParticipants': activeParticipants,
    };
  }

  /// Create an instance of AlonkaSprint from JSON
  factory AlonkaSprint.fromJson(Map<String, dynamic> json) {
    return AlonkaSprint(
      round: json['round'] ?? 0,
      activeParticipants: List<int>.from(json['activeParticipants'] ?? []),
    )
      ..alonkaCredits = List<int>.from(json['alonkaCredits'] ?? [])
      ..gerikanCredits = List<int>.from(json['gerikanCredits'] ?? [])
      ..runCredits = List<int>.from(json['runCredits'] ?? [])
      ..participationCredits = List<int>.from(json['participationCredits'] ?? []);
  }

  @override
  String toString() {
    return '$round';
  }
}