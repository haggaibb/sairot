import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sairot/models/bur.dart';
import 'package:sairot/models/participant.dart';
import 'package:sairot/models/qualified_recruit.dart';
import 'package:sairot/models/system_settings.dart';
import 'models/types.dart';
import 'models/alonka_sprint.dart';
import 'models/event.dart';
import 'models/grade_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'models/instructor.dart';
import 'models/system.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'theme_controller.dart';
import 'utils/logger.dart';
import 'services/platform_service.dart';


class EventController extends GetxController {
  var loading = false.obs;
  var widgetLoading = false.obs;
  var unfinalizedLoading = false.obs;
  var pastEventsLoading = false.obs;
  GradeSettings gradesData = GradeSettings();
  final themeController = Get.put(ThemeController());
  final platformService = PlatformService.create();

  /// Event Days
  String currentEventName = '';
  List<Event> pastEvents = <Event>[].obs;
  // Removed unused late String instructorId - use currentInstructor.id instead
  var events = <String>[].obs; // List of Event Names
  var eventDays = <String, List<String>>{}.obs; // Map: Event -> Days with data
  var selectedEvent = RxnString();
  var selectedDay = RxnString();
  Rx<Event> currentEvent = Event(date: DateTime.now().toString(), instructorId: '', eventName: '').obs;
  List<Event> unfinalizedEvents = <Event>[].obs;
  /// Alonka
  RxInt currentAlonkaRound = 0.obs;
  /// Meshulash
  RxBool meshulashEditModeOn = true.obs;
  /// Sakim
  RxBool sakimEditModeOn = true.obs;
  /// Display
  int numberOfCols = 3;
  /// firebase
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  GradeSettings firestoreGradeSettings = GradeSettings();
  SystemSettings systemSettings = SystemSettings();
  List<Instructor> instructorList = [];
  //final FirebaseStorage _storage = FirebaseStorage.instance;
  /// login
  Rx<System> system = System().obs;
  RxBool loggedIn = false.obs;
  Instructor currentInstructor =
   Instructor(id: '', firstName: '', lastName: '', mobile: '');
  RxBool isConnected = false.obs;
  /// Hive
  var systemBox;
  /// Settings
  RxDouble userFontSize = 18.0.obs;
  RxDouble userChildAspectRatio = 3.0.obs;



  @override
  onInit() async {
    loading.value = true;
    // On web, Hive uses IndexedDB and doesn't need a file path
    // On mobile, we need to get the documents directory
    if (kIsWeb) {
      // Web: Hive uses IndexedDB automatically, no path needed
      if (!Hive.isAdapterRegistered(102)) Hive.registerAdapter(SystemAdapter());
      if (!Hive.isAdapterRegistered(200)) Hive.registerAdapter(AccessibilityAdapter());
      await Hive.initFlutter(); // No path needed on web
    } else {
      // Mobile: Get the documents directory for Hive file storage
      var dir = await getApplicationDocumentsDirectory();
      if (!Hive.isAdapterRegistered(102)) Hive.registerAdapter(SystemAdapter());
      if (!Hive.isAdapterRegistered(200)) Hive.registerAdapter(AccessibilityAdapter());
      await Hive.initFlutter(dir.path);
    }
    await initSystemHiveBox();
    await gradesUpdate();
    await getSystemSettings();
    await getCurrentEventName();
    await getUpdatedInstructorsList();
    await checkForLocalLogin();
    if (loggedIn.value) {
      await getUnfinalizedEvents();
      await fetchInstructorEvents();
    }
    super.onInit();
    loading.value = false;
  }

  /// 🚀 Automatically stops the timer when the controller is destroyed
  @override
  void onClose() {
    super.onClose();
  }
  /// Settings
  setUserAccessibility(Accessibility accessibility) {
    switch (accessibility) {
      case Accessibility.normal:
        userFontSize.value = systemSettings.accessibilitySettings['normal']['font_size'].toDouble() ?? 18;
        userChildAspectRatio.value = systemSettings.accessibilitySettings['normal']['child_aspect_ratio'].toDouble() ?? 3;
        system.value.userFontSize = userFontSize.value;
        system.value.save();
        break;
      case Accessibility.big:
        userFontSize.value = systemSettings.accessibilitySettings['big']['font_size'].toDouble() ?? 26;
        userChildAspectRatio.value = systemSettings.accessibilitySettings['big']['child_aspect_ratio'].toDouble() ?? 2.5;        system.value.userFontSize = userFontSize.value;
        system.value.save();
        break;
      case Accessibility.biggest:
        userFontSize.value = (systemSettings.accessibilitySettings['biggest']?['font_size'] as num?)?.toDouble() ?? 30.0;
        userChildAspectRatio.value = systemSettings.accessibilitySettings['biggest']['child_aspect_ratio'].toDouble() ?? 2;        system.value.userFontSize = userFontSize.value;
        system.value.save();
        break;
    }
    system.refresh(); // Ensure UI updates
    update(); // Notify GetX listeners
  }

  /// Hive
  initSystemHiveBox() async {
    systemBox = await Hive.openBox<System>('system');
    if (systemBox.length > 0) {
      system.value = systemBox.get('login') as System;
    } else {
      await systemBox.put('login', system.value);
      return false;
    }
  }
  deleteSystemHiveBox() async {
    await Hive.deleteBoxFromDisk('system');
    Get.offAllNamed('/front_door');
  }

  /// get the system settings from firebase
  getSystemSettings() async {
    try {
      DocumentSnapshot docSnapshot =
      await firestore.collection('System').doc('app_system_settings').get();
      if (docSnapshot.exists) {
        systemSettings =
            SystemSettings.fromJson(docSnapshot.data() as Map<String, dynamic>);
        setUserAccessibility(system.value.accessibility);
        // print(
        //     'Updated System Settings.');
        return true;
      } else {
        systemSettings = SystemSettings();
        print('Document does not exist');
        return null;
      }
    } catch (e) {
      systemSettings = SystemSettings();
      print('❌ System Settings Error fetching document: $e');
      return null;
    }
  }

  ///
  Instructor? getInstructor(String id) {
    return instructorList.firstWhereOrNull((i) => i.id == id);
  }
  
  /// 🔎 Get a List of Unfinalized Events for an Instructor in a Specific Event
  getUnfinalizedEvents() async {
    AppLogger.debug(" ➡️ get Unfinalized Events.");
    try {
      unfinalizedLoading.value=true;
      unfinalizedEvents.clear();
      QuerySnapshot unfinalizedSnapshot = await firestore.collection('Results')
          .doc(currentInstructor.id)
          .collection('events')
          .doc(currentEventName)
          .collection('days')
          .where('finalized', isEqualTo: false)
          .get();
      if (unfinalizedSnapshot.docs.isNotEmpty) {
        for (var doc in unfinalizedSnapshot.docs) {
          Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
          unfinalizedEvents.add(Event.fromJson(docData));
        }
      }
    } catch (e) {
      unfinalizedLoading.value=false;
      print("❌ Error fetching unfinalized events: $e");
    }
    unfinalizedLoading.value=false;
    return unfinalizedEvents;
  }

  /// 📂 Fetch Main Event list from firebase Where Current Instructor Has Data for dropdown
  Future<void> fetchInstructorEvents() async {
    pastEventsLoading.value=true;
    try {
      QuerySnapshot eventsSnapshot = await firestore.collection('Results').doc(currentInstructor.id).collection('events').get();
      if (eventsSnapshot.docs.isNotEmpty) {
        events.value = eventsSnapshot.docs.map((doc) => doc.id).toList();
        final monthMap = {
          'January': 1,
          'February': 2,
          'March': 3,
          'April': 4,
          'May': 5,
          'June': 6,
          'July': 7,
          'August': 8,
          'September': 9,
          'October': 10,
          'November': 11,
          'December': 12,
        };
        events.sort((a, b) {
          final aParts = a.split(' ');
          final bParts = b.split(' ');

          final aMonth = monthMap[aParts[0]] ?? 0;
          final aYear = int.tryParse(aParts[1]) ?? 0;

          final bMonth = monthMap[bParts[0]] ?? 0;
          final bYear = int.tryParse(bParts[1]) ?? 0;

          // Sort by year, then by month
          if (aYear != bYear) {
            return aYear.compareTo(bYear);
          } else {
            return aMonth.compareTo(bMonth);
          }
        });
        // for (QueryDocumentSnapshot element in eventsSnapshot.docs) {
        //   var data = element.data() as Map<String, dynamic>;
        //   pastEvents.add(Event.fromJson(data));
        // }
      } else {
        print('No Main Events Found');
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
      //events.assignAll(instructorEvents.toList());
      pastEventsLoading.value=false;
      AppLogger.debug("📂 Found events: ${events.toList()}");
  }

  /// 📅 Fetch Available Days for Selected Event
  Future<void> fetchEventDays(String eventName) async {
    pastEventsLoading.value = true;
    try {
      QuerySnapshot daysSnapshot = await firestore.collection('Results')
          .doc(currentInstructor.id)
          .collection('events')
          .doc(eventName)
          .collection('days')
          .where('finalized', isEqualTo: true)
          .get();
      if (daysSnapshot.docs.isNotEmpty) {
        eventDays[eventName] = daysSnapshot.docs.map((doc) => doc.id).toList();
      } else {
        print('No Main Events Found');
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
    pastEventsLoading.value = false;
  }

  /// 📥 Load Selected Event for the Instructor from firestore
  Future<void> loadInstructorEvent(String eventName, String day) async {
    pastEventsLoading.value = true;
    try {
      DocumentSnapshot eventSnapshot = await firestore.collection('Results')
          .doc(currentInstructor.id)
          .collection('events')
          .doc(eventName)
          .collection('days')
          .doc(day)
          .get();
      if (eventSnapshot.exists && eventSnapshot.data() != null) {
        Map<String, dynamic> eventData = eventSnapshot.data() as Map<String, dynamic>;
        currentEvent.value = Event.fromJson(eventData); // ✅ Convert Firestore data to Event object
      }
    } catch (e) {
      pastEventsLoading.value = false;
      print("❌ Error loading event: $e");
    } finally {
      pastEventsLoading.value = false;
    }
  }

  getCurrentEventName() async {
    DocumentSnapshot<Map<String, dynamic>> doc =
    await firestore.collection('System').doc('config').get();
    Map<String, dynamic>? docData = doc.data(); // Ensuring correct casting
    currentEventName = docData?['current_event'] ?? 'NA';
  }

  getCurrentEventDays() async {
      CollectionReference eventDaysRef =
      firestore.collection('Events/' + currentEventName + '/days');
      QuerySnapshot eventDaysQuery = await eventDaysRef.get();
      var _eventDays = [];
      eventDaysQuery.docs.forEach((element) {
        _eventDays.add(element.id);
      });
      return _eventDays;
  }

  createNewEvent(Event event) async {
    loading.value = true;
    for (var participant in event.participants) {
      participant.status = ParticipantStatus.Active;
    }
    currentEvent.value = event;
    await currentEvent.value.createFirestoreEvent();
    loading.value = false;
  }

  delEvent(Event event) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference eventRef = firestore.collection('Results')
          .doc(event.instructorId)
      .collection('events')
      .doc(event.eventName)
      .collection('days')
      .doc(event.date);
      // 🔥 Step 2: Delete event document
      await eventRef.delete();
      eventRef = firestore.collection('AdminIndex')
          .doc(event.eventName)
          .collection('days')
          .doc(event.date);
      // 🔥 Step 2: Delete event document
      // await eventRef.delete();
      await eventRef.update({
        "groups": FieldValue.arrayRemove([event.groupNumber.toString()]),
      });
      await eventRef.update({
        "instructors": FieldValue.arrayRemove([event.instructorId]),
      });
      // Get the document snapshot
      final snapshot = await eventRef.get();
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;
        List<dynamic> groupsArray = data?['groupsAndInstructors'] ?? [];
        // Remove any map where instructorId matches
        groupsArray.removeWhere((item) =>
        item is Map<String, dynamic> && item['instructorId'] == event.instructorId);
        await eventRef.update({'groupsAndInstructors': groupsArray});
      }
      print("✅ Event '${event.date}' deleted successfully.");
    } catch (e) {
      print("❌ Error deleting event: $e");
    }
  }

  /// participants
  updateParticipantStatus(int id, ParticipantStatus newStatus) {
    int index = currentEvent.value.participants
        .indexWhere((participant) => participant.number == id);
    currentEvent.value.participants[index].status = newStatus;
    currentEvent.value.saveToFirestore();
  }

  Participant getParticipant(int number) {
    // Removed debug print of participant AI report
    int index = currentEvent.value.participants
        .indexWhere((participant) => participant.number == number);
    if (index>-1)
     return currentEvent.value.participants[index];
    else return Participant(number: 0, name: 'לא נמצא');
  }

  /// Sakim
  setParticipantSakimPosition(int number, int pos) {
    int index = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    currentEvent.value.participants[index].sakimPositions.add(pos);
    //currentEvent.value.saveToFirestore();
  }
  void addSakimComments(List<String> comments, int participantNumber) {
    // Find the index of the participant by their number.
    int index = currentEvent.value.participants
        .indexWhere((participant) => participant.number == participantNumber);
    // ✅ Ensure participant exists.
    if (index != -1) {
      // Get the existing comments.
      List<String> existingComments = currentEvent.value.participants[index].sakimInstructorComments;
      // ✅ Merge new comments without duplicates.
      existingComments.addAll(comments.where((comment) => !existingComments.contains(comment)));
      // ✅ Update the participant's comment list.
      currentEvent.value.participants[index].sakimInstructorComments = existingComments;
      print("✅ Comments merged successfully: ${existingComments}");
      currentEvent.value.saveToFirestore();
    } else {
      print("❌ Participant not found with number: $participantNumber");
    }
  }

  /// Meshulash
  setParticipantMeshulashPosition(int number, int pos) {
    int index = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    currentEvent.value.participants[index].meshulashPositions.add(pos);
    //currentEvent.value.saveToFirestore();
  }
  void addMeshulashComments(List<String> comments, int participantNumber) {
    // Find the index of the participant by their number.
    int index = currentEvent.value.participants
        .indexWhere((participant) => participant.number == participantNumber);
    // ✅ Ensure participant exists.
    if (index != -1) {
      // Get the existing comments.
      //List<String> existingComments = currentEvent.value.participants[index].meshulashInstructorComments;
      // ✅ Merge new comments without duplicates.
      //existingComments.addAll(comments.where((comment) => !existingComments.contains(comment)));
      // ✅ Update the participant's comment list.
      currentEvent.value.participants[index].meshulashInstructorComments = comments;
      print("✅ Comments saved successfully: ${comments}");
      currentEvent.value.saveToFirestore();
    } else {
      print("❌ Participant not found with number: $participantNumber");
    }
  }

  /// Alonka
  void addAlonkaComments(List<String> comments, int participantNumber) {
    // Find the index of the participant by their number.
    int index = currentEvent.value.participants
        .indexWhere((participant) => participant.number == participantNumber);
    // ✅ Ensure participant exists.
    if (index != -1) {
      // Get the existing comments.
      //List<String> existingComments = currentEvent.value.participants[index].alonkaInstructorComments;
      // ✅ Merge new comments without duplicates.
      //existingComments.addAll(comments.where((comment) => !existingComments.contains(comment)));
      // ✅ Update the participant's comment list.
      currentEvent.value.participants[index].alonkaInstructorComments = comments;
      print("✅ Comments to save : ${comments}");
      currentEvent.value.saveToFirestore();
    } else {
      print("❌ Participant not found with number: $participantNumber");
    }
  }

  /// Leadership
  void addInterviewComments(List<String> comments, int participantNumber) {
    // Find the index of the participant by their number.
    int index = currentEvent.value.participants
        .indexWhere((participant) => participant.number == participantNumber);
    // ✅ Ensure participant exists.
    if (index != -1) {
      // Get the existing comments.
     // List<String> existingComments = currentEvent.value.participants[index].interviewInstructorComments;
      // ✅ Merge new comments without duplicates.
      //existingComments.addAll(comments.where((comment) => !existingComments.contains(comment)));

      // ✅ Update the participant's comment list.
      currentEvent.value.participants[index].interviewInstructorComments = comments;
      print("✅ Comments saved successfully: ${comments}");
      currentEvent.value.saveToFirestore();
      currentEvent.refresh();
    } else {
      print("❌ Participant not found with number: $participantNumber");
    }
  }
  Color getLeadershipStatus(){
    int count = 0;
    bool interviewsHaveStarted = false;
    var list = currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active);
    for (Participant p in list) {
      if (p.leadershipInstructorComments.isNotEmpty) count++;
      if (p.interviewInstructorComments.isNotEmpty) interviewsHaveStarted = true;
    }
    if (count==0) return Colors.black;
    if (count>0 && interviewsHaveStarted) {
      return Colors.green;
    } else {
      return Colors.red;
    }

  }

  /// Interview
  void addLeadershipComments(List<String> comments, int participantNumber) {
    // Find the index of the participant by their number.
    int index = currentEvent.value.participants
        .indexWhere((participant) => participant.number == participantNumber);
    // ✅ Ensure participant exists.
    if (index != -1) {
      // Get the existing comments.
      //List<String> existingComments = currentEvent.value.participants[index].leadershipInstructorComments;
      // ✅ Merge new comments without duplicates.
      //existingComments.addAll(comments.where((comment) => !existingComments.contains(comment)));
      // ✅ Update the participant's comment list.
      currentEvent.value.participants[index].leadershipInstructorComments = comments;
      print("✅ Comments to save: ${comments}");
      currentEvent.value.saveToFirestore();
      currentEvent.refresh();
    } else {
      print("❌ Participant not found with number: $participantNumber");
    }
  }

  /// Bur - Add a comment to a Bur's instructorComments list
  void addBurComment(String comment, int participantNumber) {
    // Find the Bur by participant number (bur.id == participantNumber)
    int burIndex = currentEvent.value.burGrades.indexWhere((Bur bur) => bur.id == participantNumber);
    
    if (burIndex != -1) {
      // Get the existing comments
      List<String> existingComments = currentEvent.value.burGrades[burIndex].instructorComments;
      
      // Add new comment if it doesn't already exist (merge, don't replace)
      if (!existingComments.contains(comment)) {
        existingComments.add(comment);
        currentEvent.value.burGrades[burIndex].instructorComments = existingComments;
        print("✅ Bur comment added successfully to participant $participantNumber: $comment");
        currentEvent.value.saveToFirestore();
        currentEvent.refresh();
      } else {
        print("⚠️ Bur comment already exists for participant $participantNumber: $comment");
      }
    } else {
      print("❌ Bur not found with participant number: $participantNumber");
    }
  }

  Color getInterviewStatus(){
    int count = 0;
    var list = currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active);
    for (Participant p in list) {
      if (p.interviewInstructorComments.isNotEmpty) count++;
    }
    if (count==0) return Colors.black;
    if (count==list.length) {
      return Colors.green;
    } else {
      return Colors.red;
    }

  }

  /// Grades
  gradesUpdate() async {
    try {
      DocumentSnapshot docSnapshot =
      await firestore.collection('System').doc('grades').get();
      if (docSnapshot.exists) {
        firestoreGradeSettings = GradeSettings.fromJson(docSnapshot.data() as Map<String, dynamic>);
        gradesData = firestoreGradeSettings;
        // print(
        //     'Grades Updated to version ${firestoreGradeSettings.version} !!!!');
        return true;
      } else {
        firestoreGradeSettings = GradeSettings();
        print('Document does not exist');
        return null;
      }
    } catch (e) {
      firestoreGradeSettings = GradeSettings();
      print('Error fetching document: $e');
      return null;
    }
  }

  /// Grades
  bool gradesCanBeFinalized() {
    List<Participant> activeList =
    currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active);
    for (Participant p in activeList) {
      if (p.instructorGrade <= 0) return false;
    }
    return true;
  }

  /// Get absolute position of a participant in meshulash exercise
  /// Returns position based on round and order of arrival within round
  /// Position 1 = best (first in highest round), higher numbers = worse
  int _getMeshulashAbsolutePosition(int participantNumber) {
    // Find which round participant is in
    int currentRound = -1;
    int indexInRound = -1;
    
    for (int i = 0; i < currentEvent.value.meshulashRounds.length; i++) {
      final round = currentEvent.value.meshulashRounds[i];
      final index = round.participantsInRound.indexOf(participantNumber);
      if (index != -1) {
        currentRound = round.round;
        indexInRound = index;
        break;
      }
    }
    
    if (currentRound == -1) return 0; // Not found
    
    // Count participants in higher rounds
    int participantsAhead = 0;
    for (var round in currentEvent.value.meshulashRounds) {
      if (round.round > currentRound) {
        participantsAhead += round.participantsInRound.length;
      }
    }
    
    return participantsAhead + indexInRound + 1;
  }

  /// Get total number of active participants in all meshulash rounds
  int _getTotalMeshulashParticipants() {
    int total = 0;
    for (var round in currentEvent.value.meshulashRounds) {
      total += round.participantsInRound.length;
    }
    return total;
  }

  double getMeshulashGrade(int number) {
    if (currentEvent.value.meshulashRounds.isEmpty) return 0;
    
    final absolutePosition = _getMeshulashAbsolutePosition(number);
    if (absolutePosition == 0) {
      return 1 * gradesData.systemGradeFactor; // Not found
    }
    
    final totalParticipants = _getTotalMeshulashParticipants();
    if (totalParticipants <= 1) {
      return 10 * gradesData.systemGradeFactor; // Single participant gets max
    }
    
    // Normalize: position 1 = 10, last position = 1
    // Formula: 1 + ((total - position) / (total - 1)) * (10 - 1)
    double meshulashGrade = 1 + ((totalParticipants - absolutePosition) / (totalParticipants - 1)) * (10 - 1);
    
    return meshulashGrade * gradesData.systemGradeFactor;
  }

  /// Calculate arrival bonus based on position
  /// Position 1 = 1.0, position 2 = 0.8, position 3 = 0.64, etc.
  /// Formula: 1.0 * (0.8)^(position - 1)
  double _getArrivalBonus(int position) {
    // position is 1-based (first = 1, second = 2, etc.)
    return 1.0 * pow(0.8, position - 1);
  }

  /// Get maximum possible credit for Alonka exercise
  /// Assumes picking up stretcher (ALONKA_CREDIT) and arriving first in every sprint
  double _getMaxAlonkaCredit() {
    if (currentEvent.value.alonkaSprints.isEmpty) return 0;
    // Max credit per sprint = ALONKA_CREDIT (1.0) + first place bonus (1.0) = 2.0
    return 2.0 * currentEvent.value.alonkaSprints.length;
  }

  double getAlonkaGrade(int number) {
    if (currentEvent.value.alonkaSprints.isEmpty) return 0;
    double credits = 0;
    for (int i = 0; i < currentEvent.value.alonkaSprints.length; i++) {
      credits = credits + getAlonkaSprintCredit(number, i);
    }
    
    // Max possible credit per sprint = ALONKA_CREDIT (1.0) + first place bonus (1.0) = 2.0
    double maxPossibleCredit = _getMaxAlonkaCredit();
    if (maxPossibleCredit == 0) return 0;
    
    // Normalize: (actual credits / max possible credits) * 10 * systemGradeFactor
    // This ensures grades are between 0 and 10 (before systemGradeFactor)
    double alonkaGrade = ((credits / maxPossibleCredit) * 10) * gradesData.systemGradeFactor;
    return alonkaGrade;
  }

  /// Get base credit only (without arrival bonus) for a participant in a specific sprint
  /// Used for chart display to show element credit separately from position
  double getAlonkaSprintBaseCredit(int number, int sprintNumber) {
    AlonkaSprint sprint = currentEvent.value.alonkaSprints[sprintNumber];
    
    // Check each element type and return base credit only
    if (sprint.alonkaCredits.contains(number)) {
      return gradesData.ALONKA_CREDIT;
    } else if (sprint.gerikanCredits.contains(number)) {
      return gradesData.GERIKAN_CREDIT;
    } else if (sprint.runCredits.contains(number)) {
      return gradesData.RUNNER_CREDIT;
    } else if (sprint.participationCredits.contains(number)) {
      return gradesData.PARTICIPATION_CREDIT;
    }
    
    return 0; // Not found
  }

  /// Get the absolute position (order of arrival) for a participant in a specific sprint
  /// This calculates position across ALL elements, not just within the element type
  /// Returns 0 if participant not found, otherwise returns 1-based absolute position
  int getAlonkaSprintPosition(int number, int sprintNumber) {
    AlonkaSprint sprint = currentEvent.value.alonkaSprints[sprintNumber];
    
    // Combine all element lists in order to get absolute order of arrival
    // Order: alonkaCredits (highest priority), then gerikanCredits, then runCredits, then participationCredits
    List<int> allParticipantsInOrder = [];
    allParticipantsInOrder.addAll(sprint.alonkaCredits);
    allParticipantsInOrder.addAll(sprint.gerikanCredits);
    allParticipantsInOrder.addAll(sprint.runCredits);
    allParticipantsInOrder.addAll(sprint.participationCredits);
    
    // Find participant's position in the combined list
    int absolutePosition = allParticipantsInOrder.indexOf(number);
    
    // Return 1-based position, or 0 if not found
    return absolutePosition >= 0 ? absolutePosition + 1 : 0;
  }

  double getAlonkaSprintCredit(int number, int sprintNumber) {
    AlonkaSprint sprint = currentEvent.value.alonkaSprints[sprintNumber];
    double baseCredit = 0;
    
    // Check if participant was automatically added to participationCredits
    // (i.e., instructor finished interval without inputting their order)
    if (sprint.participationCredits.contains(number)) {
      // Only give base participation credit, no arrival bonus
      return gradesData.PARTICIPATION_CREDIT;
    }
    
    // Determine base credit based on element type for explicitly input participants
    if (sprint.alonkaCredits.contains(number)) {
      baseCredit = gradesData.ALONKA_CREDIT;
    } else if (sprint.gerikanCredits.contains(number)) {
      baseCredit = gradesData.GERIKAN_CREDIT;
    } else if (sprint.runCredits.contains(number)) {
      baseCredit = gradesData.RUNNER_CREDIT;
    } else {
      return 0; // Not found
    }
    
    // Get absolute position (across all elements) for arrival bonus
    // Only calculate for participants explicitly input by instructor
    int absolutePosition = getAlonkaSprintPosition(number, sprintNumber);
    if (absolutePosition == 0) return 0;
    
    double arrivalBonus = _getArrivalBonus(absolutePosition);
    return baseCredit + arrivalBonus;
  }

  /// Get absolute position of a participant in sakim exercise
  /// Returns position based on round and order of arrival within round
  /// Position 1 = best (first in highest round), higher numbers = worse
  int _getSakimAbsolutePosition(int participantNumber) {
    // Find which round participant is in
    int currentRound = -1;
    int indexInRound = -1;
    
    for (int i = 0; i < currentEvent.value.sakimRounds.length; i++) {
      final round = currentEvent.value.sakimRounds[i];
      final index = round.participantsInRound.indexOf(participantNumber);
      if (index != -1) {
        currentRound = round.round;
        indexInRound = index;
        break;
      }
    }
    
    if (currentRound == -1) return 0; // Not found
    
    // Count participants in higher rounds
    int participantsAhead = 0;
    for (var round in currentEvent.value.sakimRounds) {
      if (round.round > currentRound) {
        participantsAhead += round.participantsInRound.length;
      }
    }
    
    return participantsAhead + indexInRound + 1;
  }

  /// Get total number of active participants in all sakim rounds
  int _getTotalSakimParticipants() {
    int total = 0;
    for (var round in currentEvent.value.sakimRounds) {
      total += round.participantsInRound.length;
    }
    return total;
  }

  double getSakimGrade(int number) {
    if (currentEvent.value.sakimRounds.isEmpty) return 0;
    
    final absolutePosition = _getSakimAbsolutePosition(number);
    if (absolutePosition == 0) {
      return 1 * gradesData.systemGradeFactor; // Not found
    }
    
    final totalParticipants = _getTotalSakimParticipants();
    if (totalParticipants <= 1) {
      return 10 * gradesData.systemGradeFactor; // Single participant gets max
    }
    
    // Normalize: position 1 = 10, last position = 1
    // Formula: 1 + ((total - position) / (total - 1)) * (10 - 1)
    double sakimGrade = 1 + ((totalParticipants - absolutePosition) / (totalParticipants - 1)) * (10 - 1);
    
    return sakimGrade * gradesData.systemGradeFactor;
  }

  double getBurGrade(int number) {
    if (currentEvent.value.burGrades.isEmpty) return 0;
    int participantBurIndex =
    currentEvent.value.burGrades.indexWhere((Bur bur) => bur.id == number);
    return currentEvent.value.burGrades[participantBurIndex].burGrade;
  }

  double calculateWeightedGrade({
    required double param1,
    required double param2,
    required double param3,
    required double param4,
    required double weight1,
    required double weight2,
    required double weight3,
    required double weight4,
  }) {
    // Validate that weights sum up to 1.0
    final totalWeight = weight1 + weight2 + weight3 + weight4;
    if (totalWeight != 1.0) {
      throw ArgumentError('Weights must sum up to 1.0');
    }
    return (param1 * weight1) + (param2 * weight2) + (param3 * weight3) + (param4 * weight4);
  }

  void dropParticipant(int number) {
    var participant = currentEvent.value
        .getParticipantsByStatus(
        ParticipantStatus.Active)
        .firstWhereOrNull(
            (p) => p.number == number);
    if (participant != null) {
      participant.status = ParticipantStatus.Droped;
      // // Ensure UI updates properly
      // currentEvent.update((val) {
      //   val?.participants = List.from(
      //       val.participants); // Force update
      // });
      update(); // Trigger GetX UI refresh
    }

  }

  /// Restore a participant to Active status and add them back to the appropriate round
  /// If they're not in any round, adds them to round 0
  void restoreParticipantToRound(int number, String exerciseType) {
    var participant = currentEvent.value.participants
        .firstWhereOrNull((p) => p.number == number);
    
    if (participant == null) return;
    
    participant.status = ParticipantStatus.Active;
    
    if (exerciseType == 'meshulash') {
      // Check if participant is already in any round
      bool isInAnyRound = currentEvent.value.meshulashRounds.any(
        (round) => round.participantsInRound.contains(number)
      );
      
      // If not in any round, add to round 0
      if (!isInAnyRound && currentEvent.value.meshulashRounds.isNotEmpty) {
        currentEvent.value.meshulashRounds[0].participantsInRound.add(number);
      }
    } else if (exerciseType == 'sakim') {
      // Check if participant is already in any round
      bool isInAnyRound = currentEvent.value.sakimRounds.any(
        (round) => round.participantsInRound.contains(number)
      );
      
      // If not in any round, add to round 0
      if (!isInAnyRound && currentEvent.value.sakimRounds.isNotEmpty) {
        currentEvent.value.sakimRounds[0].participantsInRound.add(number);
      }
    }
    
    update(); // Trigger GetX UI refresh
  }
  calculateGrades() {
    for (Participant p in currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active)) {
      p.alonkaGrade = getAlonkaGrade(p.number);
      p.sakimGrade = getSakimGrade(p.number);
      p.burGrade = getBurGrade(p.number);
      p.meshulashGrade = getMeshulashGrade(p.number);
      // p.systemGrade =
      //     (p.meshulashGrade + p.alonkaGrade + p.sakimGrade + p.burGrade) / 4;
      // Weighted average is implemented. TODO: Consider adding grades version control for backward compatibility
      p.systemGrade = calculateWeightedGrade(
        param1: p.meshulashGrade,
        param2: p.alonkaGrade,
        param3: p.sakimGrade,
        param4: p.burGrade,
        weight1: gradesData.weighted['meshulash'],
        weight2: gradesData.weighted['alonka'],
        weight3: gradesData.weighted['sakim'],
        weight4: gradesData.weighted['bur'],
      );
      if (!currentEvent.value.finalized) currentEvent.value.saveToFirestore();
    }
  }

  setParticipantsGrade(int number, int grade) {
    int participantIndex = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    currentEvent.value.participants[participantIndex].instructorGrade = grade;
    currentEvent.value.saveToFirestore();
  }

  /// Get rank information for a participant in a specific exercise
  /// Returns a map with 'rank' (1-based) and 'total' (total participants)
  Map<String, int> getExerciseRank(int participantNumber, String exerciseName) {
    List<Participant> activeParticipants = 
        currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active);
    
    // Sort participants by grade (descending - higher grade = better rank)
    List<Participant> sortedParticipants;
    switch (exerciseName) {
      case 'meshulash':
        sortedParticipants = List.from(activeParticipants)
          ..sort((a, b) => b.meshulashGrade.compareTo(a.meshulashGrade));
        break;
      case 'alonka':
        sortedParticipants = List.from(activeParticipants)
          ..sort((a, b) => b.alonkaGrade.compareTo(a.alonkaGrade));
        break;
      case 'bur':
        sortedParticipants = List.from(activeParticipants)
          ..sort((a, b) => b.burGrade.compareTo(a.burGrade));
        break;
      case 'sakim':
        sortedParticipants = List.from(activeParticipants)
          ..sort((a, b) => b.sakimGrade.compareTo(a.sakimGrade));
        break;
      default:
        return {'rank': 0, 'total': activeParticipants.length};
    }
    
    // Find participant's position (1-based)
    int rank = sortedParticipants.indexWhere((p) => p.number == participantNumber) + 1;
    if (rank == 0) rank = activeParticipants.length; // If not found, assume last
    
    return {
      'rank': rank,
      'total': activeParticipants.length,
    };
  }

  /// Get all exercise ranks for a participant (for system grade breakdown)
  /// Returns a map of exercise names to rank information
  Map<String, Map<String, int>> getAllExerciseRanks(int participantNumber) {
    return {
      'meshulash': getExerciseRank(participantNumber, 'meshulash'),
      'alonka': getExerciseRank(participantNumber, 'alonka'),
      'bur': getExerciseRank(participantNumber, 'bur'),
      'sakim': getExerciseRank(participantNumber, 'sakim'),
    };
  }
  saveParticipantsAIReport(int number, String report) {
    int participantIndex = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    currentEvent.value.participants[participantIndex].participantAIReport = report;
    currentEvent.value.saveToFirestore();
  }

  /// Cloud
  Future<void> connectionEnabled() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    // ✅ Check if there is no Wi-Fi or mobile data
    if (connectivityResult == ConnectivityResult.none) {
      print("⚠️ No network available.");
      isConnected.value = false;
      return;
    }

    // ✅ Check actual internet access using an HTTP request
    try {
      final response =
      await http.get(Uri.parse("https://www.google.com")).timeout(
        Duration(seconds: 3), // Timeout to avoid long waiting
        onTimeout: () {
          print("⚠️ Internet request timed out.");
          return http.Response('', 500); // Simulate no response
        },
      );

      if (response.statusCode == 200) {
        print("✅ Internet connection OK.");
        isConnected.value = true;
      } else {
        print("⚠️ No real internet access.");
        isConnected.value = false;
      }
    } catch (e) {
      print("❌ Internet check failed: $e");
      isConnected.value = false;
    }
  }

  /// Get device document from Firestore by Android ID
  Future<Map<String, dynamic>?> getDeviceDocument(String androidId) async {
    try {
      final doc = await firestore.collection('devices').doc(androidId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Error getting device document: $e');
      return null;
    }
  }

  /// Check if device number is already registered by another device
  Future<bool> isDeviceNumberRegistered(String deviceNumber) async {
    try {
      final query = await firestore
          .collection('devices')
          .where('deviceNumber', isEqualTo: deviceNumber)
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking device number: $e');
      return false;
    }
  }

  /// Register device number to Firestore
  Future<bool> registerDeviceNumber(String androidId, String deviceNumber) async {
    try {
      // Check if device number is already registered
      final isRegistered = await isDeviceNumberRegistered(deviceNumber);
      if (isRegistered) {
        return false; // Device number already in use
      }

      final deviceData = {
        'androidId': androidId,
        'deviceNumber': deviceNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await firestore
          .collection('devices')
          .doc(androidId)
          .set(deviceData, SetOptions(merge: true));

      print('✅ Device number registered: $deviceNumber for Android ID $androidId');
      return true;
    } catch (e) {
      print('❌ Error registering device number: $e');
      return false;
    }
  }

  /// Register device to Firestore
  Future<void> registerDevice() async {
    try {
      // Device registration is Android-only - skip on web
      if (kIsWeb || !platformService.requiresDeviceRegistration()) {
        return;
      }
      
      final androidId = await _getAndroidId();
      if (androidId == null || androidId.isEmpty) {
        print('⚠️ Could not get Android ID for device registration');
        return;
      }

      // Get existing device document to preserve deviceNumber
      final existingDevice = await getDeviceDocument(androidId);
      final deviceNumber = existingDevice?['deviceNumber'] as String?;

      final deviceData = {
        'androidId': androidId,
        'instructorId': currentInstructor.id,
        'instructorFullName': '${currentInstructor.firstName} ${currentInstructor.lastName}',
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Preserve deviceNumber if it exists
      if (deviceNumber != null && deviceNumber.isNotEmpty) {
        deviceData['deviceNumber'] = deviceNumber;
      }

      await firestore
          .collection('devices')
          .doc(androidId)
          .set(deviceData, SetOptions(merge: true));

      print('✅ Device registered: $androidId for instructor ${currentInstructor.id}');
    } catch (e) {
      print('❌ Error registering device: $e');
    }
  }

  /// Get Android ID using PlatformService
  Future<String?> _getAndroidId() async {
    try {
      return await platformService.getDeviceId();
    } catch (e) {
      print('❌ Error getting Android ID: $e');
      return null;
    }
  }

  /// Finalize event and update qualified recruits in Firestore
  Future<bool> finalizeEventAndUpdateQualifiedRecruits() async {
    try {
      // Filter qualified participants by final grade (instructorGrade >= 5) and Active status
      // Note: We use instructorGrade (final grade), NOT systemGrade
      List<Participant> qualifiedRecruits = currentEvent.value.participants
          .where((p) =>
              p.status == ParticipantStatus.Active &&
              p.instructorGrade >= 5) // Final grade comparison
          .toList();

      if (qualifiedRecruits.isEmpty) {
        print('ℹ️ No qualified recruits to save (instructorGrade >= 5)');
        return true; // Not an error, just no qualified recruits
      }

      final eventName = currentEvent.value.eventName;
      final date = currentEvent.value.date;
      final instructorId = currentEvent.value.instructorId;
      final instructorName = currentEvent.value.instructorName;
      final groupNumber = currentEvent.value.groupNumber;

      // Path: /AdminIndex/{eventName}/days/{day}/qualified_recruits/{participantNumber}
      final qualifiedRecruitsRef = firestore
          .collection('AdminIndex')
          .doc(eventName)
          .collection('days')
          .doc(date)
          .collection('qualified_recruits');

      // Save each qualified recruit with new unified structure
      for (Participant participant in qualifiedRecruits) {
        // New unified structure with nested participantData
        Map<String, dynamic> recruitData = {
          'participantNumber': participant.number,
          'participantData': participant.toJson(), // Full participant data nested
          'eventName': eventName,
          'day': date, // Use 'day' for consistency (renamed from 'date')
          'finalizedAt': FieldValue.serverTimestamp(), // When instructor finalized
          'finalizedBy': instructorId, // Instructor ID who finalized
          'finalizedByName': instructorName, // Instructor name who finalized
          'groupNumber': groupNumber,
          'instructorId': instructorId,
          'instructorName': instructorName,
        };

        // Use participant number as document ID (unique within event)
        // SetOptions(merge: true) will preserve finalStatus if admin app set it
        await qualifiedRecruitsRef
            .doc(participant.number.toString())
            .set(recruitData, SetOptions(merge: true));
      }

      print(
          '✅ Successfully saved ${qualifiedRecruits.length} qualified recruits to Firestore');
      return true;
    } catch (e) {
      print('❌ Error saving qualified recruits to Firestore: $e');
      return false;
    }
  }

  /// Update qualified recruit final classification
  /// @deprecated Final classification should only be done in sairot_admin app, not in sairot app
  /// This method is kept for backward compatibility but should not be used
  @Deprecated('Final classification should only be done in sairot_admin app')
  Future<bool> updateQualifiedRecruitClassification({
    required String eventName,
    required String date,
    required int participantNumber,
    required FinalClassification classification,
    String? classifiedBy,
  }) async {
    print('⚠️ WARNING: updateQualifiedRecruitClassification is deprecated. Final classification should only be done in sairot_admin app.');
    return false;
  }

  /// Get qualified recruit document from Firestore
  /// Reads from unified structure with participantData nested field
  Future<QualifiedRecruit?> getQualifiedRecruit({
    required String eventName,
    required String date,
    required int participantNumber,
  }) async {
    try {
      final docSnapshot = await firestore
          .collection('AdminIndex')
          .doc(eventName)
          .collection('days')
          .doc(date)
          .collection('qualified_recruits')
          .doc(participantNumber.toString())
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        // fromJson will handle both old and new structures
        return QualifiedRecruit.fromJson(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting qualified recruit: $e');
      return null;
    }
  }

  /// Show final classification dialog and update qualified recruit
  /// @deprecated Final classification should only be done in sairot_admin app, not in sairot app
  /// This method is kept for backward compatibility but should not be used
  @Deprecated('Final classification should only be done in sairot_admin app')
  Future<void> showFinalClassificationDialogAndUpdate({
    required BuildContext context,
    required String eventName,
    required String date,
    required int participantNumber,
  }) async {
    print('⚠️ WARNING: showFinalClassificationDialogAndUpdate is deprecated. Final classification should only be done in sairot_admin app.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('סיווג סופי יכול להיעשות רק באפליקציית המנהל'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// log in
  login(String id) async {
    loading.value = true;
    var i = getInstructor(id);
    if (i != null) {
      system.value.loggedIn = id;
      system.value.save();
      currentInstructor = i;
      
      // Register device to Firestore after successful login
      await registerDevice();
      
      loading.value = false;
      return true;
    } else {
      loading.value = false;
      return false;
    }
  }

  getUpdatedInstructorsList() async {
    try {
      QuerySnapshot querySnapshot =
      await firestore.collection('Instructors').get();
      if (querySnapshot.docs.isNotEmpty) {
        // Convert each document into a Map and store in a List
        // List<Map<String, dynamic>> instructors = querySnapshot.docs.map((doc) {
        //   return doc.data() as Map<String, dynamic>;
        // }).toList();
        instructorList = querySnapshot.docs.map((doc) {
          return Instructor.fromJson(
              doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
        return instructorList;
      } else {
        print('Document does not exist');
        return null;
      }
    } catch (e) {
      print('Error fetching document: $e');
      return null;
    }
  }

  checkForLocalLogin() async {
    systemBox = await Hive.openBox<System>('system');
    if (systemBox.length > 0) {
      if (system.value.loggedIn != '') {
        //print('logged in');
        loggedIn.value = true;
        toggleTheme(system.value.isDarkMode);
        currentInstructor = getInstructor(system.value.loggedIn)?? currentInstructor;
        
        // Register device if instructor is logged in
        if (currentInstructor.id.isNotEmpty) {
          await registerDevice();
        }
        
        return true;
      } else {
        print('Not logged in');
        return false;
      }
    }
  }

  void toggleTheme(bool isDark) {
    themeController.toggleTheme(isDark);
    Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
    system.value.isDarkMode = isDark;
    system.value.save();
  }

  /// 🔍 Get Full Name of an Instructor by `instructorId`
  String getInstructorName(String instructorId) {
    try {
      Instructor instructor = instructorList.firstWhere((i) => i.id == instructorId);
      return '${instructor.firstName} ${instructor.lastName}';
    } catch (e) {
      return "❌";
    }
  }

}
