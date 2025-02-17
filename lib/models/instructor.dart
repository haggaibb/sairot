import 'package:hive/hive.dart';
part 'instructor.g.dart';

@HiveType(typeId: 103)
class Instructor {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String firstName;
  @HiveField(2)
  final String lastName;
  @HiveField(3)
  final String mobile;

  Instructor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.mobile,
  });

  // Factory constructor to create an Instructor object from Firestore document
  factory Instructor.fromJson(String id, Map<String, dynamic> json) {
    return Instructor(
      id: id,
      firstName: json['first_name'] ?? '', // Default to empty string if null
      lastName: json['last_name'] ?? '',
      mobile: json['mobile'] ?? '',
    );
  }
}