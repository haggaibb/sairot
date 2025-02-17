
import 'package:hive/hive.dart';
import 'package:sairot/models/grade_settings.dart';
import 'package:sairot/models/meshulash_round.dart';
import 'types.dart';
import 'alonka_sprint.dart';
import 'participant.dart';
import 'sakim_round.dart';
import 'bur.dart';
part 'event.g.dart';

@HiveType(typeId: 0)
class Event extends HiveObject {
  Event({required this.date, required this.instructorId, required this.eventName});

  @HiveField(0)
  final String date;
  @HiveField(1)
  List<AlonkaSprint> alonkaSprints=[];
  @HiveField(2)
  List<SakimRound> sakimRounds=[];
  @HiveField(3)
  List<MeshulashRound> meshulashRounds=[];
  @HiveField(4)
  List<Participant> participants=[];
  @HiveField(5)
  double ALONKA_CREDIT = 1.0;
  @HiveField(6)
  double GERIKAN_CREDIT = 0.5;
  @HiveField(7)
  double RUNNER_CREDIT = 0.2;
  @HiveField(8)
  int groupNumber =0;
  @HiveField(9)
  String instructorName='';
  @HiveField(10)
  List<Participant> activeParticipants=[];
  @HiveField(11)
  List<Bur> burGrades=[];
  @HiveField(20)
  GradeSettings gradeSettings = GradeSettings();
  @HiveField(21)
  DateTime? burStartTime;
  @HiveField(22)
  DateTime? burEndTime;
  @HiveField(23)
  DateTime? alonkaStartTime;
  @HiveField(24)
  DateTime? alonkaEndTime;
  @HiveField(25)
  DateTime? meshulashStartTime;
  @HiveField(26)
  DateTime? meshulashEndTime;
  @HiveField(27)
  DateTime? sakimStartTime;
  @HiveField(28)
  DateTime? sakimEndTime;
  @HiveField(29)
  final String instructorId;
  @HiveField(30)
  bool finalized = false;
  @HiveField(31)
  bool isBackedUp= false;
  @HiveField(32)
  final String eventName;


  /// Run times
  getBurRunTime(){
    if (burStartTime!=null) {
      DateTime now = burEndTime??DateTime.now();
      Duration difference =now.difference(burStartTime!);
      return difference.inMinutes;
    } else {
      return 0;
    }
  }

  getAlonkaRunTime(){
    if (alonkaStartTime!=null) {
      DateTime now = alonkaEndTime??DateTime.now();
      Duration difference = now.difference(alonkaStartTime!);
      return difference.inMinutes;
    } else {
      return 0;
    }
  }

  getMeshulashRunTime(){
    if (meshulashStartTime!=null) {
      DateTime now = meshulashEndTime??DateTime.now();
      Duration difference = now.difference(meshulashStartTime!);
      return difference.inMinutes;
    } else {
      return 0;
    }
  }

  getSakimRunTime(){
    if (sakimStartTime!=null) {
      DateTime now = sakimEndTime??DateTime.now();
      Duration difference = now.difference(sakimStartTime!);
      return difference.inMinutes;
    } else {
      return 0;
    }
  }

  /// get participants data
  ///
  List <Participant> getParticipantsPassedDay(){
    List<Participant> finishedDay =[];
    for (Participant participant in participants) {
      if (participant.status==ParticipantStatus.Active && participant.instructorGrade>=5) finishedDay.add(participant);
    }
    return finishedDay;
  }

  List <Participant> getParticipantsFinishedDay(){
    List<Participant> finishedDay =[];
    for (Participant participant in participants) {
      if (participant.status==ParticipantStatus.Active) finishedDay.add(participant);
    }
    return finishedDay;
  }

  ////

  List<Participant> getParticipantsByStatus(ParticipantStatus status) {
    print(participants
        .where((participant) => participant.status==status)
        .toList().length);
    return participants
        .where((participant) => participant.status==status)
        .toList();
  }

  addParticipant(String name,int number) {
    print('ad participant $name');
    var participantIndex = participants.indexWhere((element) => element.number==name);
    /// check if new Participant Number
    if ( participantIndex < 0) {
      Participant participantToAdd = Participant(name: name, number:number);
      participantToAdd.fullName = name;
      participants.add(participantToAdd);
      print('participant added $name');
    }
    else {
      print('participant already in $name');
    }


  }

  updateParticipant(String name,int oldValue, colIndex) {


  }


  getNumberOfParticipantsFinishedDay(){
    int count = 0;
    for (Participant participant in participants) {
      if (participant.status!='Folded') count++;
    }
    return count;
  }

  getNumberOfParticipantsPassedDay(){
    int count = 0;
    for (Participant participant in participants) {
      if (participant.instructorGrade>=5) count++;
    }
    return count;
  }

}