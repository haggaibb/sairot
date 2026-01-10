import 'package:sairot/models/grade_settings.dart';
import 'package:sairot/models/meshulash_round.dart';
import 'types.dart';
import 'alonka_sprint.dart';
import 'participant.dart';
import 'sakim_round.dart';
import 'bur.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/local_storage_service.dart';
import '../services/sync_queue_service.dart';

class Event {
  Event({
    required this.date,
    required this.instructorId,
    required this.eventName,
  });

  final String date;
  List<AlonkaSprint> alonkaSprints = [];
  List<SakimRound> sakimRounds = [];
  List<MeshulashRound> meshulashRounds = [];
  List<Participant> participants = [];
  double ALONKA_CREDIT = 1.0;
  double GERIKAN_CREDIT = 0.5;
  double RUNNER_CREDIT = 0.2;
  int groupNumber = 0;
  String instructorName = '';
  GroupStrength groupStrength = GroupStrength.normal; // Group strength: weak, normal, or strong
  List<Participant> activeParticipants = [];
  List<Bur> burGrades = [];
  GradeSettings gradeSettings = GradeSettings();
  DateTime? burStartTime;
  DateTime? burEndTime;
  DateTime? alonkaStartTime;
  DateTime? alonkaEndTime;
  DateTime? meshulashStartTime;
  DateTime? meshulashEndTime;
  DateTime? sakimStartTime;
  DateTime? sakimEndTime;
  final String instructorId;
  bool finalized = false;
  bool isBackedUp = false;
  final String eventName;
  DateTime? lastUpdate = DateTime.now();

  /// Converts Event object to JSON format for Firestore
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'instructorId': instructorId,
      'eventName': eventName,
      'alonkaSprints': alonkaSprints.map((e) => e.toJson()).toList(),
      'sakimRounds': sakimRounds.map((e) => e.toJson()).toList(),
      'meshulashRounds': meshulashRounds.map((e) => e.toJson()).toList(),
      'participants': participants.map((e) => e.toJson()).toList(),
      'ALONKA_CREDIT': ALONKA_CREDIT,
      'GERIKAN_CREDIT': GERIKAN_CREDIT,
      'RUNNER_CREDIT': RUNNER_CREDIT,
      'groupNumber': groupNumber,
      'instructorName': instructorName,
      'groupStrength': groupStrength.name,
      'activeParticipants': activeParticipants.map((e) => e.toJson()).toList(),
      'burGrades': burGrades.map((e) => e.toJson()).toList(),
      'gradeSettings': gradeSettings.toJson(),
      'burStartTime': burStartTime?.toIso8601String(),
      'burEndTime': burEndTime?.toIso8601String(),
      'alonkaStartTime': alonkaStartTime?.toIso8601String(),
      'alonkaEndTime': alonkaEndTime?.toIso8601String(),
      'meshulashStartTime': meshulashStartTime?.toIso8601String(),
      'meshulashEndTime': meshulashEndTime?.toIso8601String(),
      'sakimStartTime': sakimStartTime?.toIso8601String(),
      'sakimEndTime': sakimEndTime?.toIso8601String(),
      'finalized': finalized,
      'isBackedUp': isBackedUp,
      'lastUpdate' : lastUpdate?.toIso8601String()
    };
  }

  /// Converts JSON data from Firestore to an Event object
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      date: json['date'] ?? '',
      instructorId: json['instructorId'] ?? '',
      eventName: json['eventName'] ?? '',
    )
      ..alonkaSprints = (json['alonkaSprints'] as List<dynamic>?)
              ?.map((e) => AlonkaSprint.fromJson(e))
              .toList() ??
          []
      ..sakimRounds = (json['sakimRounds'] as List<dynamic>?)
              ?.map((e) => SakimRound.fromJson(e))
              .toList() ??
          []
      ..meshulashRounds = (json['meshulashRounds'] as List<dynamic>?)
              ?.map((e) => MeshulashRound.fromJson(e))
              .toList() ??
          []
      ..participants = (json['participants'] as List<dynamic>?)
              ?.map((e) => Participant.fromJson(e))
              .toList() ??
          []
      ..ALONKA_CREDIT = (json['ALONKA_CREDIT'] ?? 1.0).toDouble()
      ..GERIKAN_CREDIT = (json['GERIKAN_CREDIT'] ?? 0.5).toDouble()
      ..RUNNER_CREDIT = (json['RUNNER_CREDIT'] ?? 0.2).toDouble()
      ..groupNumber = json['groupNumber'] ?? 0
      ..instructorName = json['instructorName'] ?? ''
      ..groupStrength = json['groupStrength'] != null
          ? (json['groupStrength'] == 'weak' 
              ? GroupStrength.weak 
              : json['groupStrength'] == 'strong' 
                  ? GroupStrength.strong 
                  : GroupStrength.normal)
          : GroupStrength.normal
      ..activeParticipants = (json['activeParticipants'] as List<dynamic>?)
              ?.map((e) => Participant.fromJson(e))
              .toList() ??
          []
      ..burGrades = (json['burGrades'] as List<dynamic>?)
              ?.map((e) => Bur.fromJson(e))
              .toList() ??
          []
      ..gradeSettings = GradeSettings.fromJson(json['gradeSettings'] ?? {})
      ..burStartTime = json['burStartTime'] != null
          ? DateTime.parse(json['burStartTime'])
          : null
      ..burEndTime =
          json['burEndTime'] != null ? DateTime.parse(json['burEndTime']) : null
      ..alonkaStartTime = json['alonkaStartTime'] != null
          ? DateTime.parse(json['alonkaStartTime'])
          : null
      ..alonkaEndTime = json['alonkaEndTime'] != null
          ? DateTime.parse(json['alonkaEndTime'])
          : null
      ..meshulashStartTime = json['meshulashStartTime'] != null
          ? DateTime.parse(json['meshulashStartTime'])
          : null
      ..meshulashEndTime = json['meshulashEndTime'] != null
          ? DateTime.parse(json['meshulashEndTime'])
          : null
      ..sakimStartTime = json['sakimStartTime'] != null
          ? DateTime.parse(json['sakimStartTime'])
          : null
      ..sakimEndTime = json['sakimEndTime'] != null
          ? DateTime.parse(json['sakimEndTime'])
          : null
      ..finalized = json['finalized'] ?? false
      ..isBackedUp = json['isBackedUp'] ?? false
      ..lastUpdate = json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'])
          : null;
  }

  /// Save Event instance to local Hive storage
  Future<bool> saveToLocal() async {
    try {
      lastUpdate = DateTime.now();
      final success = await LocalStorageService.instance.saveEventLocally(this);
      if (success) {
        print('✅ Event saved locally: $eventName - $date');
      }
      return success;
    } catch (e) {
      print("❌ Error saving Event locally: $eventName - $date: $e");
      return false;
    }
  }

  /// Save Event instance to Firestore (always saves locally first)
  /// Note: This method should be called through EventController.saveEventWithOfflineSupport()
  /// for proper offline support, but can be called directly if needed
  Future<bool> saveToFirestore() async {
    try {
      lastUpdate = DateTime.now();
      
      // Always save locally first (immediate, works offline)
      await saveToLocal();
      
      // Debug: Verify instructorGrade values are present before saving
      if (finalized) {
        print('🔍 Saving finalized event - verifying instructorGrade values:');
        int activeCount = 0;
        int gradesSetCount = 0;
        for (var p in participants) {
          if (p.status == ParticipantStatus.Active) {
            activeCount++;
            if (p.instructorGrade > 0) {
              gradesSetCount++;
            }
            print('  Participant ${p.number}: instructorGrade = ${p.instructorGrade}');
          }
        }
        print('  Summary: $gradesSetCount/$activeCount active participants have instructorGrade set');
        
        if (gradesSetCount == 0 && activeCount > 0) {
          print('⚠️ WARNING: No instructorGrade values found for active participants!');
        }
      }
      
      final eventJson = toJson();
      
      // Debug: Verify instructorGrade in JSON
      if (finalized) {
        final participantsJson = eventJson['participants'] as List<dynamic>?;
        if (participantsJson != null) {
          print('🔍 Verifying instructorGrade in JSON:');
          int jsonGradesSetCount = 0;
          for (var pJson in participantsJson) {
            final pMap = pJson as Map<String, dynamic>;
            if (pMap['status'] == 'Active') {
              final grade = pMap['instructorGrade'] ?? 0;
              if (grade > 0) {
                jsonGradesSetCount++;
              }
              print('  Participant ${pMap['number']}: instructorGrade = $grade');
            }
          }
          print('  JSON Summary: $jsonGradesSetCount active participants have instructorGrade in JSON');
        }
      }
      
      // Add timeout to prevent hanging when offline
      try {
        await FirebaseFirestore.instance
            .collection('Results')
            .doc(instructorId)
            .collection('events')
            .doc(eventName)
            .collection('days')
            .doc(date)
            .set(eventJson)
            .timeout(
              Duration(seconds: 10),
              onTimeout: () {
                print('⚠️ Firestore save timed out after 10 seconds');
                throw TimeoutException('Firestore save operation timed out');
              },
            );
      } on TimeoutException {
        print('⚠️ Firestore save timed out - will queue for sync');
        rethrow;
      }
      
      print('✅ Event saved successfully: $eventName - $date (finalized: $finalized)');
      return true;
    } catch (e) {
      print("❌ Error saving Event to Firestore: $eventName - $date: $e");
      // Queue for retry when online (local save already succeeded)
      try {
        await SyncQueueService.instance.queueFirestoreOperation('saveEvent', toJson());
        print('📴 Event queued for sync when online');
      } catch (queueError) {
        print('⚠️ Failed to queue event for sync: $queueError');
      }
      return false;
    }
  }

  /// Save Event instance to Firestore (always saves locally first)
  Future<bool> createFirestoreEvent() async {
    try {
      // Always save locally first
      await saveToLocal();
      
      // Add timeouts to prevent hanging when offline
      try {
        await FirebaseFirestore.instance
            .collection('Results')
            .doc(instructorId)
            .collection('events')
            .doc(eventName)
            .collection('days')
            .doc(date)
            .set(toJson())
            .timeout(
              Duration(seconds: 10),
              onTimeout: () {
                print('⚠️ Firestore create timed out after 10 seconds');
                throw TimeoutException('Firestore create operation timed out');
              },
            );
      } on TimeoutException {
        print('⚠️ Firestore create timed out - will queue for sync');
        rethrow;
      }
      
      // These operations are less critical, use shorter timeout and don't fail if they timeout
      try {
        await FirebaseFirestore.instance.collection('Results')
            .doc(instructorId)
            .set({'exists': true}, SetOptions(merge: true))
            .timeout(Duration(seconds: 5));
      } catch (e) {
        print('⚠️ Failed to update Results doc (non-critical): $e');
      }
      
      try {
        await FirebaseFirestore.instance.collection('Results')
            .doc(instructorId)
            .collection('events')
            .doc(eventName)
            .set({'exists': true}, SetOptions(merge: true))
            .timeout(Duration(seconds: 5));
      } catch (e) {
        print('⚠️ Failed to update events doc (non-critical): $e');
      }

      // Skip AdminIndex updates for playground events
      if (eventName != 'playground') {
        try {
          await FirebaseFirestore.instance
              .collection('AdminIndex')
              .doc(eventName)
              .collection('days')
              .doc(date)
              .set({
            "instructors": FieldValue.arrayUnion([instructorId]),
            "groups": FieldValue.arrayUnion([groupNumber.toString()]),
            "groupsAndInstructors": FieldValue.arrayUnion([{
              'groupNumber': groupNumber.toString(),
              'instructorId': instructorId.toString()
            }])
          }, SetOptions(merge: true))
              .timeout(Duration(seconds: 5));
        } catch (e) {
          print('⚠️ Failed to update AdminIndex (non-critical): $e');
        }
        
        try {
          await FirebaseFirestore.instance.collection('AdminIndex')
              .doc(eventName)
              .set({'exists': true}, SetOptions(merge: true))
              .timeout(Duration(seconds: 5));
        } catch (e) {
          print('⚠️ Failed to update AdminIndex doc (non-critical): $e');
        }
      }
      print("✅ Event created successfully: $eventName - $date");
      return true;
    } catch (e) {
      print("❌ Error creating Event to Firestore: $e");
      // Queue for retry when online (local save already succeeded)
      try {
        await SyncQueueService.instance.queueFirestoreOperation('createEvent', toJson());
        print('📴 Event creation queued for sync when online');
      } catch (queueError) {
        print('⚠️ Failed to queue event creation for sync: $queueError');
      }
      return false;
    }
  }


  /// Run times
  int getBurRunTime() {
    if (burStartTime != null) {
      DateTime now = burEndTime ?? DateTime.now();
      Duration difference = now.difference(burStartTime!);
      return difference.inMinutes;
    }
    return 0;
  }

  int getAlonkaRunTime() {
    if (alonkaStartTime != null) {
      DateTime now = alonkaEndTime ?? DateTime.now();
      Duration difference = now.difference(alonkaStartTime!);
      return difference.inMinutes;
    }
    return 0;
  }

  int getMeshulashRunTime() {
    if (meshulashStartTime != null) {
      DateTime now = meshulashEndTime ?? DateTime.now();
      Duration difference = now.difference(meshulashStartTime!);
      return difference.inMinutes;
    }
    return 0;
  }

  int getSakimRunTime() {
    if (sakimStartTime != null) {
      DateTime now = sakimEndTime ?? DateTime.now();
      Duration difference = now.difference(sakimStartTime!);
      return difference.inMinutes;
    }
    return 0;
  }

  int getLeadershipStatus(){
    int count = 0;
    bool interviewsHaveStarted = false;
    var list = getParticipantsByStatus(ParticipantStatus.Active);
    for (Participant p in list) {
      if (p.leadershipInstructorComments.isNotEmpty) count++;
      if (p.interviewInstructorComments.isNotEmpty) interviewsHaveStarted = true;
    }
    if (count==0) return 0;
    if (count>0 && interviewsHaveStarted) {
      return -1;
    } else if (count>0)  {
      return 1;
    } else {
      return 0;
    }

  }
  int getInterviewStatus(){
    int count = 0;
    var list = getParticipantsByStatus(ParticipantStatus.Active);
    for (Participant p in list) {
      if (p.interviewInstructorComments.isNotEmpty) count++;
    }
    if (count==0) return 0;
    if (count == list.length) return -1;
        else return 1;
  }


  List<Participant> getParticipantsByStatus(ParticipantStatus status) {
    print(participants
        .where((participant) => participant.status == status)
        .toList()
        .length);
    return participants
        .where((participant) => participant.status == status)
        .toList();
  }

  /// Participants management
  List<Participant> getParticipantsPassedDay() {
    return participants
        .where((p) =>
            p.status == ParticipantStatus.Active && p.instructorGrade >= 5)
        .toList();
  }

  List<Participant> getParticipantsFinishedDay() {
    return participants
        .where((p) => p.status == ParticipantStatus.Active)
        .toList();
  }

  void addParticipant(String name, int number) {
    if (!participants.any((p) => p.number == number)) {
      participants.add(Participant(name: name, number: number));
    }
  }


}
