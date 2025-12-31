class SakimRound {
  SakimRound({required this.round, required this.participantsInRound});

  final int round;
  List<int> participantsInRound;

  /// Convert SakimRound to JSON format for Firestore
  Map<String, dynamic> toJson() {
    return {
      'round': round,
      'participantsInRound': participantsInRound,
    };
  }

  /// Create an instance of SakimRound from JSON
  factory SakimRound.fromJson(Map<String, dynamic> json) {
    return SakimRound(
      round: json['round'] ?? 0,
      participantsInRound: List<int>.from(json['participantsInRound'] ?? []),
    );
  }

  @override
  String toString() {
    return '$round';
  }
}