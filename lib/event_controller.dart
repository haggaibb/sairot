import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sairot/models/bur.dart';
import 'package:sairot/models/meshulash_round.dart';
import 'package:sairot/models/participant.dart';
import 'package:sairot/models/system_settings.dart';
import 'models/types.dart';
import 'models/alonka_sprint.dart';
import 'models/event.dart';
import 'models/sakim_round.dart';
import 'models/grade_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'models/instructor.dart';
import 'models/system.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/material.dart';
import 'theme_controller.dart';


class EventController extends GetxController {
  var loading = false.obs;
  var unfinalizedLoading = false.obs;
  var pastEventsLoading = false.obs;
  GradeSettings gradesData = GradeSettings();
  final themeController = Get.put(ThemeController());

  /// Event Days
  String currentEventName = '';
  List<Event> pastEvents = <Event>[].obs;
  late String instructorId;
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
  final FirebaseStorage _storage = FirebaseStorage.instance;
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
    var dir = await getApplicationDocumentsDirectory();
    if (!Hive.isAdapterRegistered(102)) Hive.registerAdapter(SystemAdapter());
    if (!Hive.isAdapterRegistered(200)) Hive.registerAdapter(AccessibilityAdapter());
    await Hive.initFlutter(dir.path);
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
    print('done ctx init');
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
        print("🔹 Setting to NORMAL mode.");
        userFontSize.value = systemSettings.accessibilitySettings['normal']['font_size'].toDouble() ?? 18;
        userChildAspectRatio.value = systemSettings.accessibilitySettings['normal']['child_aspect_ratio'].toDouble() ?? 3;
        system.value.userFontSize = userFontSize.value;
        system.value.save();
        break;
      case Accessibility.big:
        print("🔹 Setting to BIG mode.");
        userFontSize.value = systemSettings.accessibilitySettings['big']['font_size'].toDouble() ?? 26;
        userChildAspectRatio.value = systemSettings.accessibilitySettings['big']['child_aspect_ratio'].toDouble() ?? 2.5;        system.value.userFontSize = userFontSize.value;
        system.value.save();
        break;
      case Accessibility.biggest:
        print("🔹 Setting BIGGEST mode.");
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
    print('Delete System Hive Box');
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
    print(currentInstructor.id);
    print(" ➡️ get Unfinalized Events.");
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
        print(events);
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
      print("📂 Found events for instructor ${currentInstructor.id}: ${events.toList()}");
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
      await eventRef.delete();

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
    int index = currentEvent.value.participants
        .indexWhere((participant) => participant.number == number);
    return currentEvent.value.participants[index];
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
    print('Add Leadership Comments');
    // Find the index of the participant by their number.
    int index = currentEvent.value.participants
        .indexWhere((participant) => participant.number == participantNumber);
    // ✅ Ensure participant exists.
    if (index != -1) {
      // Get the existing comments.
      print('######');
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

  double getMeshulashGrade(int number) {
    if (currentEvent.value.meshulashRounds.isEmpty) return 0;

    int maxRound = currentEvent.value.meshulashRounds.length - 1;

    // Find the first occupied round (ignoring empty ones)
    int minRound = currentEvent.value.meshulashRounds.indexWhere(
            (MeshulashRound round) => round.participantsInRound.isNotEmpty);

    // Find the participant's position
    int participantPosition = currentEvent.value.meshulashRounds.indexWhere(
            (MeshulashRound round) => round.participantsInRound.contains(number));

    // Ensure valid position
    if (participantPosition == -1 || minRound == -1 || maxRound == minRound) {
      return 1 * gradesData.systemGradeFactor; // Default to lowest score if invalid
    }

    // Normalize the grade between 10 (maxRound) and 1 (minRound)
    double meshulashGrade = 1 + ((participantPosition - minRound) / (maxRound - minRound)) * (10 - 1);

    return meshulashGrade * gradesData.systemGradeFactor;
  }

  double getAlonkaGrade(int number) {
    if (currentEvent.value.alonkaSprints.isEmpty) return 0;
    double credits = 0;
    for (AlonkaSprint sprint in currentEvent.value.alonkaSprints) {
      if (sprint.alonkaCredits.contains(number)) {
        credits = credits + gradesData.ALONKA_CREDIT;
      } else if (sprint.gerikanCredits.contains(number)) {
        credits = credits + gradesData.GERIKAN_CREDIT;
      } else if (sprint.runCredits.contains(number)) {
        credits = credits + gradesData.RUNNER_CREDIT;
      } else if (sprint.participationCredits.contains(number)) {
        credits = credits + gradesData.PARTICIPATION_CREDIT;
      }
    }
    double alonkaGrade =
        ((credits / currentEvent.value.alonkaSprints.length) * 10) *
            gradesData.systemGradeFactor;
    return alonkaGrade;
  }

  double getAlonkaSprintCredit(int number, int sprintNumber) {
    double credits = 0;
    AlonkaSprint sprint = currentEvent.value.alonkaSprints[sprintNumber];
    if (sprint.alonkaCredits.contains(number)) {
      credits = credits + gradesData.ALONKA_CREDIT;
    } else if (sprint.gerikanCredits.contains(number)) {
      credits = credits + gradesData.GERIKAN_CREDIT;
    } else if (sprint.runCredits.contains(number)) {
      credits = credits + gradesData.RUNNER_CREDIT;
    } else if (sprint.participationCredits.contains(number)) {
      credits = credits + gradesData.PARTICIPATION_CREDIT;
    }
    return credits;
  }

  double getSakimGrade(int number) {
    if (currentEvent.value.sakimRounds.isEmpty) return 0;

    int maxRound = currentEvent.value.sakimRounds.length - 1;

    // Find the first occupied round (ignoring empty ones)
    int minRound = currentEvent.value.sakimRounds.indexWhere(
            (SakimRound round) => round.participantsInRound.isNotEmpty);

    // Find the participant's position
    int participantPosition = currentEvent.value.sakimRounds.indexWhere(
            (SakimRound round) => round.participantsInRound.contains(number));

    // Ensure valid position
    if (participantPosition == -1 || minRound == -1 || maxRound == minRound) {
      return 1 * gradesData.systemGradeFactor; // Default to lowest score if invalid
    }

    // Normalize the grade between 10 (maxRound) and 1 (minRound)
    double sakimGrade = 1 + ((participantPosition - minRound) / (maxRound - minRound)) * (10 - 1);

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
    double weight1 = 0.25,
    double weight2 = 0.25,
    double weight3 = 0.25,
    double weight4 = 0.25,
  }) {
    // Validate that weights sum up to 1.0
    final totalWeight = weight1 + weight2 + weight3 + weight4;
    if (totalWeight != 1.0) {
      throw ArgumentError('Weights must sum up to 1.0');
    }
    return (param1 * weight1) +
        (param2 * weight2) +
        (param3 * weight3) +
        (param4 * weight4);
  }

  calculateGrades() {
    for (Participant p in currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active)) {
      p.alonkaGrade = getAlonkaGrade(p.number);
      p.sakimGrade = getSakimGrade(p.number);
      p.burGrade = getBurGrade(p.number);
      p.meshulashGrade = getMeshulashGrade(p.number);
      // p.systemGrade =
      //     (p.meshulashGrade + p.alonkaGrade + p.sakimGrade + p.burGrade) / 4;
      /// TODO - add weighted avg, add grades version control
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

  /// log in
  login(String id) async {
    loading.value = true;
    var i = getInstructor(id);
    if (i != null) {
      system.value.loggedIn = id;
      system.value.save();
      currentInstructor = i;
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
        List<Map<String, dynamic>> instructors = querySnapshot.docs.map((doc) {
          return doc.data() as Map<String, dynamic>;
        }).toList();
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
