import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sairot/performance_page.dart';
import 'dart:io';
import '../models/instructor.dart';
import '../models/event.dart';
import '../models/admin_event.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';


class AdminController extends GetxController {
  var isLoading = false.obs; // Tracks live event download progress
  var events = <String>[].obs; // List of Event Names
  var eventDays = <String, List<String>>{}.obs; // Map: Event -> Days
  var instructorFiles =
      <String, List<String>>{}.obs; // Map: Day -> Instructor Files
  var groupNumbers = <String, List<String>>{}.obs; // Map: Day -> Group Numbers
  var groupNumberToInstructor =
      <String, String>{}.obs; // Map: groupNumber -> InstructorIs
  var selectedEvent = RxnString();
  var selectedDay = RxnString();
  var selectedGroup = RxnString();
  var selectedInstructor = RxnString();
  var isDownloading = false.obs;
  var isDownloadingGeneralReport = false.obs;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Instructor> allInstructors = [];
  Box<AdminEvent>? adminEventsBox;
  AdminEvent adminEvent = AdminEvent(name: 'NA');
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  var isInstructorMode = true.obs; // 👈 New toggle switch state


  /// live event
  var liveEvents = <Event>[].obs; // 🔥 Stores downloaded live events
  var isDownloadingLiveEvents =
      false.obs; // Tracks live event download progress
  var activeLiveDayEvent = '';
  var currentEventName;
  List<Instructor> instructorList = [];
  var instructorIdToTimestamp = <String, DateTime>{}.obs; // Map: groupNumber -> InstructorIs
  var instructorIsDownloading = <String, bool>{}.obs; // Map: groupNumber -> InstructorIs
  Timer? periodicTimer; // Timer for periodic internet checks

  @override
  void onInit() async {
    //isDownloading.value = true;
    await fetchEventData();
    await getUpdatedInstructorsList();
    print('done init admin');
    //isDownloading.value = false;
    super.onInit();
  }
  /// 🚀 Automatically stops the timer when the controller is destroyed
  @override
  void onClose() {
    periodicTimer?.cancel();
    super.onClose();
  }
  /// go over all , it is a mess, function names and duplicate work?

  void toggleDropdownMode(bool value) {
    isInstructorMode.value = value;
    selectedInstructor.value = null; // Reset selection when switching modes
    selectedGroup.value = null;
  }

  /// 📂 Fetch Events from Firebase Storage
  Future<void> fetchEventData() async {
    isDownloading.value = true;
    try {
      ListResult eventList = await _storage.ref('hive').listAll();
      for (var eventRef in eventList.prefixes) {
        String eventName = eventRef.name;
        events.add(eventName);
        // Fetch Days inside each event folder
        ListResult dayList = await _storage.ref('hive/$eventName').listAll();
        List<String> dayFolders =
            dayList.prefixes.map((dayRef) => dayRef.name).toList();
        eventDays[eventName] = dayFolders;
      }
      print('done with list of events');
      isDownloading.value = false;
    } catch (e) {
      print("❌ Error fetching event data: $e");
      isDownloading.value = false;
    }
    isDownloading.value = false;
  }

  /// 📅 Fetch Instructor Files for a Specific Event & Day
  Future<void> fetchInstructorFiles(String eventName, String day) async {
    try {
      ListResult instructorList =
          await _storage.ref('hive/$eventName/$day').listAll();
      List<String> instructorFileIds = instructorList.items
          .map((item) => item.name.split('.').first)
          .toList();
      instructorFiles[day] = instructorFileIds;
    } catch (e) {
      print("❌ Error fetching instructor files: $e");
    }
  }

  /// 📥 Download Hive Box from Firebase Storage
  Future<void> fetchInstructorDays(
      String eventName, String day, String instructorId) async {
    try {
      isDownloading.value = true;
      final dir = await getApplicationDocumentsDirectory();
      final eventDir = Directory(
          '${dir.path}/hive/admin/$eventName/$day'); // 📂 Correct full path
      final localFilePath = '${eventDir.path}/$instructorId.hive';
// ✅ Ensure directory exists before downloading
      if (!eventDir.existsSync()) {
        eventDir.createSync(recursive: true);
      }
      File localFile = File(localFilePath);
      // ✅ Download only if it doesn't exist
      if (!localFile.existsSync()) {
        print("📥 Downloading Hive Box for Instructor: $instructorId...");
        print('hive/$eventName/$day/$instructorId.hive');
        await _storage
            .ref('hive/$eventName/$day/$instructorId.hive')
            .writeToFile(localFile);
        print("✅ Download completedd: $localFilePath");
      } else {
        print("📂 Hive file already exists: $localFilePath");
      }

      // ✅ Open Hive Box and extract event
      Box<Event> instructorBox = await Hive.openBox<Event>(instructorId,
          path: '${dir.path}/hive/admin/$eventName/$day');
      Event? event = instructorBox.get(day);
      if (event != null) {
        eventController.currentEvent.value = event;
        adminEvent.eventDays.add(event);
        print("📅 Extracted Event for $instructorId on $day: ${event.date}");
      }
      await instructorBox.close();
    } catch (e) {
      print("❌ Error fetching instructor days: $e");
    } finally {
      isDownloading.value = false;
    }
  }

  /// 📅 Fetch Group Numbers for a Specific Event & Day by Reading Hive Files
  Future<void> fetchGroupNumbers(String eventName, String day) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dayDir = Directory('${dir.path}/hive/admin/$eventName/$day');

      print("📂 Checking Group Numbers in: ${dayDir.path}");

      if (!dayDir.existsSync()) {
        print("❌ No directory found for $eventName on $day.");
        return;
      }

      List<String> groupNumbersList = [];
      for (var file in dayDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.hive'))) {
        try {
          String instructorId = file.uri.pathSegments.last.split('.').first;

          // ✅ Open the Hive Box
          Box<Event> instructorBox =
              await Hive.openBox<Event>(instructorId, path: dayDir.path);

          // 🔍 Retrieve event using `day` as the key
          Event? event = instructorBox.get(day);
          await instructorBox.close(); // Close box after reading

          if (event != null) {
            groupNumbersList.add(event.groupNumber.toString());
            groupNumberToInstructor[event.groupNumber.toString()] =
                instructorId;
          }
        } catch (e) {
          print("❌ Error reading Hive file: ${file.path}, Error: $e");
        }
      }
      // ✅ Remove duplicates and update the controller
      groupNumbers[day] = groupNumbersList.toSet().toList();
      print('groupNumbers[day]');
      print(groupNumbers[day]);
      print(
          "✅ Fetched Group Numbers for $eventName on $day: ${groupNumbers[day]}");
    } catch (e) {
      print("❌ Error fetching group numbers: $e");
    }
  }

  /// 🔄 Generate Full Report for an Event
  Future<void> getAllAdminEventData() async {
    if (selectedEvent.value != null) {
      isDownloadingGeneralReport.value = true;
      String eventName = selectedEvent.value!;
      List<String>? days = eventDays[eventName];

      if (days != null) {
        for (var day in days) {
          await fetchInstructorFiles(eventName, day);
          List<String>? instructors = instructorFiles[day];
          if (instructors != null) {
            for (var instructorId in instructors) {
              await fetchInstructorDays(eventName, day, instructorId);
            }
          }
        }
      }
      isDownloadingGeneralReport.value = false;
    }
  }



  /// Live Event /////
  ///
  ///
  /// 📥 Fetch & Download Only Updated Live Events for a Given Day in `hive/admin/live/$eventName/$day`
  Future<void> fetchAndDownloadLiveEvents(String eventName, String day) async {
/// for debug!!!!
    day = '17-02-2025';
    if (liveEvents.isEmpty) isDownloadingLiveEvents.value =true;
    try {
      //isDownloadingLiveEvents.value = true;
      print("🔄 Fetching live events for $eventName on $day from Firebase...");

      // 🔍 Get list of all instructor event files in `hive/admin/live/$eventName/$day/`
      ListResult result =
          await _storage.ref('admin/live/$eventName/$day').listAll();
      print('admin/live/$eventName/$day');
      if (result.items.isEmpty) {
        print("⚠️ No live event files found for $eventName on $day.");
        //isDownloadingLiveEvents.value = false;
        return;
      }

      // 📂 Get local storage directory
      final dir = await getApplicationDocumentsDirectory();
      final localLiveDir =
          Directory('${dir.path}/hive/admin/live/$eventName/$day');

      // ✅ Ensure directory exists
      if (!localLiveDir.existsSync()) {
        localLiveDir.createSync(recursive: true);
      }

      // 🔄 Iterate over each instructor event file and check timestamp before downloading
      for (var fileRef in result.items) {
        String instructorId = fileRef.name
            .split('.')
            .first; // Extract Instructor ID from filename
        String localFilePath = '${localLiveDir.path}/$instructorId.hive';
        File localFile = File(localFilePath);

        // 🕒 Get last modified timestamp from Firebase Storage
        FullMetadata metadata = await fileRef.getMetadata();
        DateTime? firebaseTimestamp =
            metadata.updated; // Get the last modified timestamp

        if (firebaseTimestamp == null) {
          print("❌ No timestamp found for $instructorId.hive, skipping.");
          continue;
        }
        instructorIdToTimestamp[instructorId] = firebaseTimestamp;
        // 🖥️ Check local file modification date
        bool shouldDownload = false;
        DateTime? localFileTimestamp;

        if (localFile.existsSync()) {
          localFileTimestamp = localFile.lastModifiedSync();
          print("📂 Local file exists, last modified: $localFileTimestamp");
          shouldDownload = firebaseTimestamp.isAfter(localFileTimestamp);
          //print();

        } else {
          print("📥 No local file found, downloading...");
          shouldDownload = true;
        }

        // ⏳ Only download if Firebase file is newer or no file exists
        if (shouldDownload) {
          instructorIsDownloading[instructorId] = true;
          print("📥 Newer file found for Instructor $instructorId! Downloading...");
          await fileRef.writeToFile(localFile);
          print("✅ Downloaded: $localFilePath");

          // 🗂️ Open Hive Box, extract event, and update `liveEvents`
          await processDownloadedEvent(localFilePath, instructorId);
          instructorIsDownloading[instructorId] = false;
        } else {
          print("⏩ Skipping Download of $instructorId.hive, local file is up to date.");
          bool exists = liveEvents.any((i) => i.instructorId.toString() == instructorId);
          print('file exists $exists');
          if (!exists) await processDownloadedEvent(localFilePath, instructorId);
        }
      }
      print(
          "🎉 All eligible live events for $eventName on $day have been downloaded!");
    } catch (e) {
      print("❌ Error fetching live events: $e");
    } finally {
      isDownloadingLiveEvents.value = false;
    }
  }

  /// 📂 Process Downloaded Event File, Extract Data & **Update `liveEvents`**
  Future<void> processDownloadedEvent(
      String filePath, String instructorId) async {
    try {
      // 🗂️ Open Hive Box
      Box<Event> instructorBox = await Hive.openBox<Event>(instructorId,
          path: File(filePath).parent.path);

      if (instructorBox.isNotEmpty) {
        Event? event = instructorBox.get(
            instructorBox.keys.first); // Assuming the first key holds the event
        if (event != null) {
          print(
              "📅 Extracted event for Instructor $instructorId: ${event.eventName} on ${event.date}");

          // 🔄 Check if the event already exists in `liveEvents`
          int index =
              liveEvents.indexWhere((e) => e.instructorId == instructorId);

          if (index != -1) {
            // ✅ Update the existing event
            liveEvents[index] = event;
            print("♻️ Updated existing event for Instructor $instructorId.");
          } else {
            // 🔥 Insert new event if not found
            liveEvents.add(event);
            print("✅ Added new event for Instructor $instructorId.");
          }
        }
      }

      // 🔄 Close Hive Box
      await instructorBox.close();
    } catch (e) {
      print("❌ Error processing event file: $e");
    }
  }

  /// start live event
  Future<void> startLiveDayEvent() async {
    isDownloadingLiveEvents.value = true;
    DateTime today = DateTime.now();
    await getCurrentEventName();
    String formattedToday =
        "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";
    await fetchAndDownloadLiveEvents(currentEventName, formattedToday);
    startLiveEventUpdateTimer(10);
    isDownloadingLiveEvents.value = false;
  }

  startLiveEventUpdateTimer(int seconds) {
    print("🕞 Start Live Update Timer...");
    periodicTimer = Timer.periodic(Duration(seconds: seconds), (Timer timer) async {
      for (var entry in instructorIdToTimestamp.entries) {
        print("🕖 Instructor ID: ${entry.key} - 📅 Last Updated: ${entry.value}");
        Event instructorEvent = liveEvents.firstWhere((i) => i.instructorId.toString() == entry.key);
        fetchAndDownloadLiveEvents(instructorEvent.eventName, instructorEvent.date);
      }
    });
  }

  stopLiveEventUpdateTimer() {
    periodicTimer?.cancel();
  }
  getGroupStatus(String groupNumber) {
    int meshulashStatus = 0;
    int alonkaStatus = 0;
    int burStatus = 0;
    int sakimStatus = 0;

    Event groupEvent =
        liveEvents.firstWhere((i) => i.groupNumber.toString() == groupNumber);

    /// check meshulash status
    if (groupEvent.meshulashStartTime != null) {
      if (groupEvent.meshulashEndTime != null) {
        /// its done
        meshulashStatus = -1;
      } else {
        /// not done yet return also calc duration?
        meshulashStatus = 0;
        return ' משולש -${groupEvent.meshulashRounds.length-1} ';

      }
    }
    if (groupEvent.alonkaStartTime != null) {
      if (groupEvent.alonkaEndTime != null) {
        /// its done
        alonkaStatus = -1;
      } else {
        /// not done yet return also calc duration?
        alonkaStatus = 0;
        return ' אלונקה -${groupEvent.alonkaSprints.length} ';
      }
    }
    if (groupEvent.burStartTime != null) {
      if (groupEvent.burEndTime != null) {
        /// its done
        burStatus = -1;
      } else {
        /// not done yet return also calc duration?
        alonkaStatus = 0;
        DateTime now = DateTime.now();
        Duration? difference = now.difference(groupEvent.burStartTime!);
        return ' בור -${difference.inMinutes.toString()} דקות ';
      }
    }
    if (groupEvent.sakimStartTime != null) {
      if (groupEvent.sakimEndTime != null) {
        /// its done
        sakimStatus = -1;
      } else {
        /// not done yet return also calc duration?
        sakimStatus = 0;
        DateTime now = DateTime.now();
        Duration? difference = now.difference(groupEvent.sakimStartTime!);
        return ' שקים -${(groupEvent.sakimRounds.length-1).toString()}';
      }
    }
    /// check finished
    if (meshulashStatus+alonkaStatus+burStatus+sakimStatus==-4) {
      return 'הסתיים';
    } else if(meshulashStatus+alonkaStatus+burStatus+sakimStatus==0) {
      return 'לא התחיל';
    }
    return 'מנוחה';

  }

  /// get last update time
  int getMinutesPassedSinceUpdate(String instructorId) {
    DateTime now = DateTime.now();
    DateTime? pastTime = instructorIdToTimestamp[instructorId];
    if (pastTime != null) {
      Duration difference = now.difference(pastTime);
      return difference.inMinutes;
    } else {
      return 0;
    }
  }




  /// firestore functions
  ///
  getCurrentEventName() async {
    DocumentSnapshot<Map<String, dynamic>> doc =
        await firestore.collection('System').doc('config').get();
    Map<String, dynamic>? docData = doc.data(); // Ensuring correct casting
    currentEventName = docData?['current_event'] ?? 'NA';
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
  /// 🔍 Get Full Name of an Instructor by `instructorId`
  String getInstructorName(String instructorId) {
    try {
      Instructor instructor =
          instructorList.firstWhere((i) => i.id == instructorId);
      return '${instructor.firstName} ${instructor.lastName}';
    } catch (e) {
      return "❌";
    }
  }
}
