import 'package:hive/hive.dart';
import '../models/event.dart';
import '../models/types.dart'; // Assuming ParticipantStatus is defined here


class AdminEvent extends HiveObject {
  final String name;
  List<Event> eventDays = [];

  AdminEvent({required this.name});

  /// Returns the number of event days in this object
  int getEventDaysCount() {
    return eventDays.length;
  }

  int getUniqueEventDaysCount() {
    if (eventDays.isEmpty) return 0;

    // Extract unique dates from eventDays using a Set
    Set<String> uniqueDates = eventDays.map((event) => event.date).toSet();

    return uniqueDates.length;
  }
  /// Returns the total accumulated count of Active Participants across all eventDays
  int getTotalActiveParticipantsCount() {
    int total = 0;
    for (var event in eventDays) {
      total += event.participants
          .where((p) => p.status == ParticipantStatus.Active)
          .length;
    }
    return total;
  }

  /// Returns an array where the index represents the InstructorGrade,
  /// and the value at each index represents the count of participants with that grade.
  List<int> getInstructorGradeDistribution() {
    // Assuming InstructorGrades range from 0 to 10
    List<int> gradeDistribution =
        List.filled(11, 0); // Grades 0-10 (Array Size 11)

    for (var event in eventDays) {
      for (var participant in event.participants) {
        int grade = participant.instructorGrade.round(); // Convert to integer
        if (grade >= 0 && grade <= 10) {
          // Ensure within range
          gradeDistribution[grade]++;
        }
      }
    }
    return gradeDistribution;
  }

  double getAverageGroupsPerDay() {
    if (eventDays.isEmpty) return 0.0; // Avoid division by zero
    int totalGroups = eventDays.fold(0, (sum, event) => sum + event.groupNumber);
    return totalGroups / eventDays.length;
  }

  int getQualifiedParticipantsCount() {
    int total = 0;
    for (var event in eventDays) {
      total += event.participants
          .where((p) => p.instructorGrade >= 5)
          .length;
    }
    return total;
  }

  @override
  String toString() {
    return '$name';
  }
}
