import '../models/types.dart';

class MeshulashRound {
  MeshulashRound({required this.round, required this.participantsInRound});

  final int round;
  List<int> participantsInRound;

  /// Convert MeshulashRound to JSON format for Firestore
  Map<String, dynamic> toJson() {
    return {
      'round': round,
      'participantsInRound': participantsInRound,
    };
  }

  /// Create an instance of MeshulashRound from JSON
  factory MeshulashRound.fromJson(Map<String, dynamic> json) {
    return MeshulashRound(
      round: json['round'] ?? 0,
      participantsInRound: List<int>.from(json['participantsInRound'] ?? []),
    );
  }

  @override
  String toString() {
    return '$round';
  }
}