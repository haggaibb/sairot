import 'package:cloud_firestore/cloud_firestore.dart';

class Bur {
  Bur({required this.id});

  final int id;
  double burGrade = 0;
  List<String> instructorComments = [];

  /// Convert Bur to JSON format for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'burGrade': burGrade,
      'instructorComments': instructorComments,
    };
  }

  /// Create an instance of Bur from JSON
  factory Bur.fromJson(Map<String, dynamic> json) {
    return Bur(id: json['id'] ?? 0)
      ..burGrade = (json['burGrade'] ?? 0).toDouble()
      ..instructorComments = List<String>.from(json['instructorComments'] ?? []);
  }

  /// Save Bur instance to Firestore
  Future<void> saveToFirestore(String eventName, String day, String instructorId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Events')
          .doc(eventName)
          .collection('days')
          .doc(day)
          .collection('instructors_data')
          .doc(instructorId)
          .collection('burGrades') // Nested collection for Bur grades
          .doc(id.toString()) // Using ID as document name
          .set(toJson());
    } catch (e) {
      print("❌ Error saving Bur to Firestore: $id: $e");
    }
  }


  @override
  String toString() {
    return '$id';
  }
}