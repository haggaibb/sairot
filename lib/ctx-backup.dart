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
import 'dart:io';
import 'models/instructor.dart';
import 'models/system.dart';
import 'package:http/http.dart' as http;
import 'models/admin_event.dart';
import 'dart:async';


class Controller extends GetxController {
  var loading = false.obs;
  var unfinalizedLoading = false.obs;
  var pastEventsLoading = false.obs;

  GradeSettings gradesData = GradeSettings();

  /// Event Days
  String currentEventName = '';
  List<Event> pastEvents = <Event>[].obs;
  late String instructorId;
  var events = <String>[].obs; // List of Event Names
  var eventDays = <String, List<String>>{}.obs; // Map: Event -> Days with data
  var selectedEvent = RxnString();
  var selectedDay = RxnString();
  Rx<Event> currentEvent =
      Event(date: DateTime.now().toString(), instructorId: '', eventName: '')
          .obs;
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
  HiveStorageService hiveStorage = HiveStorageService();
  var eventBox;
  var systemBox;


  @override
  onInit() async {
    loading.value = true;
    await connectionEnabled();
    var dir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(dir.path);
    /// for debug;
    //await deleteAllHiveBoxes();
    // await Hive.close();
    // await Hive.deleteBoxFromDisk('system');
    // print('del hive');
    // return;
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(EventAdapter());
    if (!Hive.isAdapterRegistered(1))
      Hive.registerAdapter(ParticipantAdapter());
    if (!Hive.isAdapterRegistered(3))
      Hive.registerAdapter(AlonkaSprintAdapter());
    if (!Hive.isAdapterRegistered(100))
      Hive.registerAdapter(ParticipantStatusAdapter());
    if (!Hive.isAdapterRegistered(4))
      Hive.registerAdapter(MeshulashRoundAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(SakimRoundAdapter());
    if (!Hive.isAdapterRegistered(200))
      Hive.registerAdapter(GradeSettingsAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(BurAdapter());
    if (!Hive.isAdapterRegistered(102)) Hive.registerAdapter(SystemAdapter());
    if (!Hive.isAdapterRegistered(103))
      Hive.registerAdapter(InstructorAdapter());
    if (!Hive.isAdapterRegistered(50))
      Hive.registerAdapter(AdminEventAdapter());
    if (!Hive.isAdapterRegistered(104))
      Hive.registerAdapter(SystemSettingsAdapter());
    await initSystemHiveBox();
    if (isConnected.value) {
      await gradesUpdate();
      await getSystemSettings();
      await getCurrentEventName();
      system.value.instructors = await getUpdatedInstructorsList() ?? [];
    }
    await checkForLocalLogin();
    if (loggedIn.value) {
      currentInstructor =
          system.value.getLoggedInInstructorData() ?? currentInstructor;
      //if (currentInstructor.id != '') await loadTodayEvent();
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

  /// get the system settings from firebase
  getSystemSettings() async {
    try {
      DocumentSnapshot docSnapshot =
      await firestore.collection('System').doc('app_system_settings').get();
      if (docSnapshot.exists) {
        systemSettings =
            SystemSettings.fromJson(docSnapshot.data() as Map<String, dynamic>);
        system.value.systemSettings = systemSettings;
        //await system.value.save();
        print(
            'Updated System Settings.');
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

  Future<void> deleteAllHiveBoxes() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory('${dir.path}/hive');

      if (!hiveDir.existsSync()) {
        print("❌ Hive directory not found.");
        return;
      }

      // 📂 Loop through all event folders
      for (var eventDir in hiveDir.listSync().whereType<Directory>()) {
        for (var dayDir in eventDir.listSync().whereType<Directory>()) {
          for (var file in dayDir.listSync().whereType<File>()) {
            if (file.path.endsWith('.hive')) {
              try {
                // Close Hive Box before deleting
                String boxName = file.uri.pathSegments.last.split('.').first;
                if (Hive.isBoxOpen(boxName)) {
                  await Hive.box(boxName).close();
                }

                // 🗑️ Delete Hive file
                file.deleteSync();
                print("✅ Deleted: ${file.path}");
              } catch (e) {
                print("❌ Error deleting ${file.path}: $e");
              }
            }
          }

          // 🗑️ Remove day directory if empty
          if (dayDir.listSync().isEmpty) {
            dayDir.deleteSync();
          }
        }

        // 🗑️ Remove event directory if empty
        if (eventDir.listSync().isEmpty) {
          eventDir.deleteSync();
        }
      }

      print("🎉 All Hive boxes deleted successfully!");
    } catch (e) {
      print("❌ Error deleting Hive boxes: $e");
    }
  }

  // ///
  // /// event and hive functions
  // loadTodayEvent() async {
  //   loading.value = true;
  //   DateTime today = DateTime.now();
  //   String formattedDate =
  //       "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";
  //   Event? foundTodayEvent =
  //       await hiveStorage.tryOpenLocalOrRemoteInstructorBox(
  //           currentEventName, formattedDate, currentInstructor.id);
  //   if (foundTodayEvent != null && !foundTodayEvent.finalized) {
  //     currentEvent.value = foundTodayEvent;
  //   }
  //   loading.value = false;
  // }

  /// open Hive box and load the event
  openHiveBoxAndLoadEvent(Event event) async {
    /// Get Hivebox
    eventBox = await hiveStorage.openInstructorBoxIfExists(event);
    /// 📦 Extract `Event` from an Already Open Hive Box Using `event.date` as the Key
    if (!eventBox.isOpen) {
      print("❌ Error: Hive box is not open!");
      return null;
    }

    print("🔍 Extracting Event for Key: ${event.date}");
    Event? loadedEvent = eventBox.get(event.date);

    if (loadedEvent != null) {
      currentEvent.value = loadedEvent;
      print("✅ Event Loaded: ${loadedEvent.eventName} on ${loadedEvent.date}");
    } else {
      print("❌ No event found in the box for key: ${event.date}");
    }
    return true;
  }


  /// 📦 Close `eventBox` Hive Box if Open
  Future<void> closeEventBox() async {
    if (eventBox != null && eventBox!.isOpen) {
      try {
        await eventBox.close();
        eventBox = null; // Reset reference
        print("✅ Closed Hive Box: eventBox");
      } catch (e) {
        print("❌ Error closing Hive Box: $e");
      }
    } else {
      print("⚠️ Hive Box is already closed or was never opened.");
    }
  }

  /// 🔎 Get a List of Unfinalized Events for an Instructor in a Specific Event
  getUnfinalizedEvents() async {
    instructorId = currentInstructor.id;
    print(" ➡️ get Unfinalized Events.");
    try {
      unfinalizedLoading.value=true;
      final dir = await getApplicationDocumentsDirectory();
      final eventDir = Directory('${dir.path}/hive/$currentEventName');
      if (await !eventDir.existsSync()) {
        print(" event dir: ${eventDir.toString()}");
      }
      unfinalizedEvents.clear();
      print('days in hibe event -> /${eventDir.listSync().whereType<Directory>().toString()}');
      // 📂 Iterate over all day folders inside the event directory
      for (var dayDir in await eventDir.listSync().whereType<Directory>()) {
        String day = dayDir.path.split('/').last;
        print('check day  ${day}');
        final localFilePath = '${eventDir.path}/${day}/$instructorId.hive';
        File localFile = File(localFilePath);
        print('file exists  ${await localFile.existsSync()}');
        if (await localFile.existsSync()) {
          // ✅ Open Hive Box and Check Finalized Status
          print(' ✅ Open Hive Box and Check Finalized Status');
          Box<Event> instructorBox =
              await Hive.openBox<Event>(instructorId, path: dayDir.path);
          //print(instructorBox.length);
          for (var key in instructorBox.keys) {
            print("🔑 Key: $key");
          }
          print('try and fetch $day event');
          Event? event = await instructorBox.get(day);
          //print
          await instructorBox.close();
          if (event != null && !event.finalized) {
            unfinalizedEvents.add(event);
            print(
                "🚨 Unfinalized Event Found: ${event.eventName} on ${event.date}");
          } else if (event != null && !event.isBackedUp) {
                unfinalizedEvents.add(event);
          } else {
            print(
                "event null (${event == null}) or finalized (${event?.finalized})");
          }
        } else {
          print("No File Found: ${localFile.path}");
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
    instructorId = currentInstructor.id;
    try {
      pastEventsLoading.value=true;
      ListResult eventList = await _storage.ref('hive').listAll();

      Set<String> instructorEvents = {};

      for (var eventRef in eventList.prefixes) {
        String eventName = eventRef.name;
        ListResult dayList = await _storage.ref('hive/$eventName').listAll();

        for (var dayRef in dayList.prefixes) {
          String day = dayRef.name;
          String filePath = 'hive/$eventName/$day/$instructorId.hive';

          try {
            await _storage.ref(filePath).getMetadata(); // ✅ File exists
            instructorEvents.add(eventName);
          } catch (e) {
            print('// File does not exist, ignore');
            // File does not exist, ignore
          }
        }
      }

      events.assignAll(instructorEvents.toList());
      pastEventsLoading.value=false;
      print("📂 Found events for instructor $instructorId: ${events.toList()}");
    } catch (e) {
      print("❌ Error fetching instructor events: $e");
      pastEventsLoading.value=false;
    }
  }

  /// 📅 Fetch Available Days for Selected Event
  Future<void> fetchEventDays(String eventName) async {
    pastEventsLoading.value = true;
    try {
      ListResult dayList = await _storage.ref('hive/$eventName').listAll();
      List<String> availableDays = [];

      for (var dayRef in dayList.prefixes) {
        String day = dayRef.name;
        String filePath = 'hive/$eventName/$day/$instructorId.hive';

        try {
          await _storage.ref(filePath).getMetadata(); // ✅ File exists
          availableDays.add(day);
        } catch (e) {
          pastEventsLoading.value = false;
          // File does not exist, ignore
        }
      }
      eventDays[eventName] = availableDays;
      print("📅 Found days for $instructorId in $eventName: $availableDays");
    } catch (e) {
      pastEventsLoading.value = false;
      print("❌ Error fetching event days: $e");
    }
    pastEventsLoading.value = false;
  }

  /// 📥 Load Selected Event for the Instructor
  Future<void> loadInstructorEvent(String eventName, String day) async {
    pastEventsLoading.value = true;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final eventDir = Directory('${dir.path}/hive/$eventName/$day');
      if (!eventDir.existsSync()) {
        eventDir.createSync(recursive: true);
      }
      final localFilePath = '${eventDir.path}/$instructorId.hive';
      File localFile = File(localFilePath);
      // ✅ Download only if it doesn't exist
      if (await !localFile.existsSync()) {
        print("📥 Downloading Hive Box for Instructor: $instructorId...");
        await _storage
            .ref('hive/$eventName/$day/$instructorId.hive')
            .writeToFile(localFile);
        print("✅ Download completed: $localFilePath");
      } else {
        print("📂 Hive file already exists: $localFilePath");
      }

      // ✅ Open Hive Box and extract event
      print(
          '✅ Open Hive Box and extract event for $instructorId at ${eventDir.path}');
      Box<Event> instructorBox =
          await Hive.openBox<Event>(instructorId, path: eventDir.path);
      print('✅ Get event by $day');
      Event? event = await instructorBox.get(day);

      if (event != null) {
        currentEvent.value = event;
        print('current event ${event.date}');
        currentEvent.refresh();
        print("📅 Loaded Event for $instructorId on $day: ${event.date}");
      } else {
        print("!!!! Event is null !!!");
      }
      await instructorBox.close();
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

  createNewEvent(Event event) async {
    loading.value = true;
    for (var participant in event.participants) {
      participant.status = ParticipantStatus.Active;
    }
    print(event.date);
    print(event.eventName);
    print(event.instructorId);
    currentEvent.value = await hiveStorage.createNewInstructorBox(event);
    loading.value = false;
  }

  delEvent(Event event) async {
    loading.value = true;
    print('TODO delkte function');
    //await eventsBox.delete(event.date);
    loading.value = false;
  }

  /// participants
  updateParticipantStatus(int id, ParticipantStatus newStatus) async {
    int index = currentEvent.value.participants
        .indexWhere((participant) => participant.number == id);
    currentEvent.value.participants[index].status = newStatus;
    await currentEvent.value.save();
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
    currentEvent.value.save();
  }

  /// Meshulash
  setParticipantMeshulashPosition(int number, int pos) {
    int index = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    currentEvent.value.participants[index].meshulashPositions.add(pos);
    currentEvent.value.save();
  }

  /// Grades
  gradesUpdate() async {
    try {
      DocumentSnapshot docSnapshot =
          await firestore.collection('System').doc('grades').get();
      if (docSnapshot.exists) {
        firestoreGradeSettings =
            GradeSettings.fromJson(docSnapshot.data() as Map<String, dynamic>);
        system.value.gradeSettings = firestoreGradeSettings;
        await system.value.save();
        print(
            'Grades Updated to version ${firestoreGradeSettings.version} !!!!');
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
    int maxRound = currentEvent.value.meshulashRounds.length;
    int participantPosition = currentEvent.value.meshulashRounds.indexWhere(
        (MeshulashRound round) => round.participantsInRound.contains(number));
    double meshulashGrade = (((participantPosition + 1) / maxRound) * 10) *
        gradesData.systemGradeFactor;
    return meshulashGrade;
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
    int maxRound = currentEvent.value.sakimRounds.length;
    int participantPosition = currentEvent.value.sakimRounds.indexWhere(
        (SakimRound round) => round.participantsInRound.contains(number));
    double sakimGrade = (((participantPosition + 1) / maxRound) * 10) *
        gradesData.systemGradeFactor;
    return sakimGrade;
  }

  double getBurGrade(int number) {
    if (currentEvent.value.burGrades.isEmpty) return 0;
    int participantBurIndex =
        currentEvent.value.burGrades.indexWhere((Bur bur) => bur.id == number);
    return currentEvent.value.burGrades[participantBurIndex].burGrade;
  }

  calculateGrades() {
    for (Participant p in currentEvent.value.participants) {
      p.alonkaGrade = getAlonkaGrade(p.number);
      p.sakimGrade = getSakimGrade(p.number);
      p.burGrade = getBurGrade(p.number);
      p.meshulashGrade = getMeshulashGrade(p.number);
      p.systemGrade =
          (p.meshulashGrade + p.alonkaGrade + p.sakimGrade + p.burGrade) / 4;
      currentEvent.value.save();
    }
  }

  setParticipantsGrade(int number, int grade) {
    int participantIndex = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    currentEvent.value.participants[participantIndex].instructorGrade = grade;
    print(currentEvent.value.participants[participantIndex].number);
    print(currentEvent.value.participants[participantIndex].instructorGrade);
    currentEvent.value.save();
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
    var i = system.value.instructors.indexWhere((Instructor i) => i.id == id);
    if (i != -1) {
      currentInstructor = system.value.instructors[i];
      system.value.loggedIn = currentInstructor.id;
      await system.value.save();
      //await initHiveBox(currentEventName,id);
      //hiveStorage.tryOpenLocalOrRemoteInstructorBox(currentEventName, day, instructorId)
      //await loadTodayEvent();
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
    print('system > 0?');
    print(systemBox.length);
    if (systemBox.length > 0) {
      print(system.value.loggedIn);
      if (system.value.loggedIn != '') {
        print('logged in');
        loggedIn.value = true;
        return true;
      } else {
        print('NOT logged in');
        return false;
      }
    }
  }

  initSystemHiveBox() async {
    systemBox = await Hive.openBox<System>('system');
    print('system > 0?');
    print(systemBox.length);
    if (systemBox.length > 0) {
      system.value = systemBox.get('login') as System;
    } else {
      /// one time event to create System
      print('NO system');
      await gradesUpdate();
      system.value.gradeSettings = firestoreGradeSettings;
      system.value.systemSettings = systemSettings;
      system.value.instructors = await getUpdatedInstructorsList();
      await systemBox.put('login', system.value);
      return false;
    }
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

///
///
///  Hive Storage
class HiveStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: "yemey-siarot.appspot.com",
  );
  var instructorBox;

  /// 📦 Open an Instructor's Hive Box ONLY IF IT EXISTS (Returns `null` if missing)
  Future<Box<Event>?> openInstructorBoxIfExists(Event event) async {
    final dir = await getApplicationDocumentsDirectory();
    final eventDir =
        Directory('${dir.path}/hive/${event.eventName}/${event.date}');

    print('📂 Checking Event Directory Path: ${eventDir.path}');

    final boxPath = '${eventDir.path}/${event.instructorId}.hive';
    File boxFile = File(boxPath);

    // 🛑 Check if the file exists before opening the box
    if (!boxFile.existsSync()) {
      print("⚠️ Hive box does not exist: $boxPath");
      return null; // Do NOT open a new box if it doesn't exist
    }

    // ✅ Open the Hive Box (Since it exists)
    Box<Event> instructorBox =
        await Hive.openBox<Event>(event.instructorId, path: eventDir.path);
    print("📦 Opened Existing Instructor Hive Box at: ${instructorBox.path}");

    return instructorBox; // Keep the box open for later use
  }

  /// 📜 Delete Event from loacal storage
  Future<void> delEventFromHive(Event event) async {
    var eventName = event.eventName;
    var day = event.date;
    var instructorId = event.instructorId;

    try {
      final dir = await getApplicationDocumentsDirectory();
      Hive.deleteBoxFromDisk(instructorId,
          path: '${dir.path}/hive/$eventName/$day');
    } catch (e) {
      print("❌ Error deleting Hive Box: $e");
      return null;
    }
  }

  // /// 🌟 Try Opening Instructor Hive Box (Local First, then Firebase)
  // /// Returns `true` if successful, `false` if the file is missing everywhere.
  // Future<Event?> tryOpenLocalOrRemoteInstructorBox(
  //     String eventName, String day, String instructorId) async {
  //   final dir = await getApplicationDocumentsDirectory();
  //   final localFilePath = '${dir.path}/hive/$eventName/$day/$instructorId.hive';
  //   final localFile = File(localFilePath);
  //
  //   // ✅ Step 1: Try opening the local Hive box
  //   if (localFile.existsSync()) {
  //     print("📂 Found local Hive file for $instructorId. Loading...");
  //     return await _loadEventFromHive(eventName, day, instructorId);
  //   }
  //
  //   // ✅ Step 2: Try downloading from Firebase Storage if local file is missing
  //   final ref = _storage.ref('hive/$eventName/$day/$instructorId.hive');
  //   try {
  //     await ref.getMetadata(); // If this succeeds, file exists
  //     print("☁️ File found in Firebase. Downloading...");
  //
  //     // Download and save locally
  //     await ref.writeToFile(localFile);
  //     print("✅ Download completed: $localFilePath");
  //
  //     // Open and return event
  //     return await _loadEventFromHive(eventName, day, instructorId);
  //   } catch (e) {
  //     print("⚠️ File not found in Firebase for in $day $instructorId.");
  //     return null; // File does not exist anywhere
  //   }
  // }
  //
  // /// 📜 Load Event from Hive Box (Called by `tryOpenLocalOrRemoteInstructorBox`)
  // Future<Event?> _loadEventFromHive(
  //     String eventName, String day, String instructorId) async {
  //   try {
  //     final dir = await getApplicationDocumentsDirectory();
  //     instructorBox = await Hive.openBox<Event>(instructorId,
  //         path: '${dir.path}/hive/$eventName/$day');
  //     Event? event = instructorBox.get(day);
  //     await instructorBox.close();
  //     if (event != null) {
  //       print("📜 Loaded Event: ${event.eventName} on ${event.date}");
  //       return event;
  //     } else {
  //       print("⚠️ No event found in Hive box.");
  //       return null;
  //     }
  //   } catch (e) {
  //     print("❌ Error opening Hive Box: $e");
  //     return null;
  //   }
  // }

  /// ✨ Create a New Instructor Hive Box with a Default Event (Only Called via UI Button)
  Future<Event> createNewInstructorBox(Event event) async {
    final dir = await getApplicationDocumentsDirectory();
    final eventDir =
        Directory('${dir.path}/hive/${event.eventName}/${event.date}');

    print('eventDir path:');
    print(eventDir.path);

    // Ensure directory exists
    if (!eventDir.existsSync()) {
      eventDir.createSync(recursive: true);
    }

    // ✅ First, check if the box is open and properly close it
    if (Hive.isBoxOpen(event.instructorId)) {
      var openBox = Hive.box<Event>(event.instructorId);
      await openBox.close(); // Ensure it's fully closed before proceeding
      print("✅ Closed existing box: ${event.instructorId}");
    }

    print('########## Open box at path: ${eventDir.path}');
    instructorBox =
        await Hive.openBox<Event>(event.instructorId, path: eventDir.path);

    print('+++++++++ Instructor Box Path After Opening:');
    print(instructorBox.path);

    // ✅ Ensure old data is cleared before adding new event
    print('########## Put in box, key is ${event.date}');
    await instructorBox.clear();
    await instructorBox.put(event.date, event);
    //await instructorBox.close();

    print("✨ Created new event: ${event.eventName} on ${event.date}");
    return event;
  }

  /// 💾 Save or Update an Instructor's Event in Hive
  Future<void> saveInstructorEvent(Event updatedEvent) async {
    print('start save instructor event');
    var eventName = updatedEvent.eventName;
    var day = updatedEvent.date;
    var instructorId = updatedEvent.instructorId;
    final dir = await getApplicationDocumentsDirectory();
    final eventDir = Directory('${dir.path}/hive/$eventName/$day');

    // Ensure the directory exists
    if (!eventDir.existsSync()) {
      eventDir.createSync(recursive: true);
    }
    try {
      // Open Hive Box in the correct directory
      Box<Event> instructorBox =
      await Hive.openBox<Event>(instructorId, path: eventDir.path);
      // Save or update the event inside the Hive Box
      print('put updated event in box');
      await instructorBox.put(day, updatedEvent);
      await instructorBox.close();

      print(
          "✅ Saved updated event: ${updatedEvent.eventName} on ${updatedEvent.date}");
    } catch (e) {
      print("❌ Error saving Hive: $e");
    }
  }

  /// ✅ Open Hive Box, Set `finalized = true`, Save, and Close
  Future<void> updateEvent(Event event) async {
    final dir = await getApplicationDocumentsDirectory();
    final eventDir = Directory('${dir.path}/hive/${event.eventName}/${event.date}');

    print('📂 Event Directory Path: ${eventDir.path}');

    final boxPath = '${eventDir.path}/${event.instructorId}.hive';
    File boxFile = File(boxPath);

    // 🛑 Check if the Hive file exists before proceeding
    if (!boxFile.existsSync()) {
      print("❌ Hive file does not exist: $boxPath");
      return;
    }

    try {
      // ✅ Open Hive Box
      Box<Event> instructorBox = await Hive.openBox<Event>(event.instructorId, path: eventDir.path);

      // 🔍 Get the event from the box
      Event? storedEvent = instructorBox.get(event.date);

      if (storedEvent != null) {
        print("🔄 Updating Event: ${storedEvent.eventName} on ${storedEvent.date}");

        // ✅ Update `finalized` field to `true`
        storedEvent.isBackedUp = true;

        // ✅ Save the updated event
        await instructorBox.put(event.date, storedEvent);
        print("✅ Event Finalized: ${storedEvent.eventName} on ${storedEvent.date}");
      } else {
        print("❌ No event found for key: ${event.date}");
      }

      // ✅ Close Hive Box
      await instructorBox.close();
      print("📦 Closed Hive Box: ${event.instructorId}");
    } catch (e) {
      print("❌ Error finalizing event: $e");
    }
  }

  /// 🔥 Backup Hive Box to Firebase Storage
  Future<bool> backupHiveToFirebase(String eventName, String day, String instructorId) async {
    try {
      // 📂 Get the app's document directory
      Directory appDir = await getApplicationDocumentsDirectory();
      String hiveFilePath =
          '${appDir.path}/hive/$eventName/$day/$instructorId.hive';

      // 🔎 Check if the Hive file exists
      File hiveFile = File(hiveFilePath);
      if (!hiveFile.existsSync()) {
        print("❌ Hive box file not found for $instructorId on $day!");
        return false;
      }

      // 🔥 Upload to Firebase Storage in the correct structure
      Reference storageRef =
          _storage.ref('hive/$eventName/$day/$instructorId.hive');
      UploadTask uploadTask = storageRef.putFile(hiveFile);
      // ✅ Listen for Upload Progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print("📤 Upload Progress: ${progress.toStringAsFixed(2)}%");
      });

      // ⏳ **Wait for the Upload to Complete**
      print("📤 Upload Progress waiting");
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print("✅ Backup completed! File uploaded to: $downloadUrl");
      storageRef =
          _storage.ref('admin/live/$eventName/$day/$instructorId.hive');
      uploadTask = storageRef.putFile(hiveFile);

      // ✅ Listen for Upload Progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print("📤 Upload Progress: ${progress.toStringAsFixed(2)}%");
      });

      // ⏳ **Wait for the Upload to Complete**
      snapshot = await uploadTask.whenComplete(() {});
      downloadUrl = await snapshot.ref.getDownloadURL();

      print("✅ Backup completed! File uploaded to: $downloadUrl");
      /// do the same for live


      return true;
    } catch (e) {
      print("❌ Error backing up Hive: $e");
      return false;
    }
  }
}
