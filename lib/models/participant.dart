
import 'package:hive/hive.dart';
import '../models/types.dart';
part 'participant.g.dart';

@HiveType(typeId: 1)
class Participant extends HiveObject {
  Participant({required this.number, required this.name});

  @HiveField(0)
  int number;
  @HiveField(1)
  double sakimGrade=0;
  @HiveField(2)
  double alonkaGrade=0;
  @HiveField(3)
  double meshulashGrade=0;
  @HiveField(4)
  double burGrade=0;
  @HiveField(5)
  ParticipantStatus status = ParticipantStatus.Active;
  @HiveField(6)
  String fullName='';
  @HiveField(7)
  int instructorGrade=0;
  @HiveField(8)
  double systemGrade=0;
  @HiveField(9)
  String name = '';
  @HiveField(10)
  int groupNumber = 0;
  @HiveField(11)
  List<int> meshulashPositions = [];
  @HiveField(12)
  List<int> sakimPositions = [];


  setFinalGrade (int grade) {
    instructorGrade = grade;
  }

}

extension StatusX on ParticipantStatus {
  String get valueAsString => toString().split('.').last;

}
