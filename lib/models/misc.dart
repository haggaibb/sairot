
// class AdminController extends GetxController {
//   var events = <String>[].obs; // List of Event Names
//   var eventInstructors = <String, List<String>>{}.obs; // Map: Event -> Instructors
//   var instructorDays = <String, List<String>>{}.obs; // Map: Instructor -> Days
//   var selectedEvent = RxnString(); // Stores the selected event
//   var selectedInstructor = RxnString(); // Stores the selected instructor
//   var selectedDay = RxnString(); // Stores the selected day
//   var isDownloading = false.obs; // Tracks Hive download progress
//   var isDownloadingGeneralReport = false.obs;
//   List<Event> pastEvents = <Event>[].obs;
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   List<Instructor> instructors =[];
//   Box<AdminEvent>? adminEventsBox;
//   AdminEvent adminEvent = AdminEvent(name: 'NA');
//
//   @override
//   void onInit() async {
//     fetchEventData();// Load event and instructor data
//     super.onInit();
//
//   }
//
//   /// Fetch Events and Instructors from Firebase Storage
//   Future<void> fetchEventData() async {
//     try {
//       ListResult eventList = await _storage.ref('hive').listAll();
//
//       for (var eventRef in eventList.prefixes) {
//         String eventName = eventRef.name;
//         events.add(eventName);
//
//         // Fetch Instructor Files inside each event folder
//         ListResult instructorList = await _storage.ref('hive/$eventName').listAll();
//         List<String> instructorFileIds = instructorList.items.map((item) => item.name).toList();
//         eventInstructors[eventName] = instructorFileIds;
//         instructors = await eventController.getUpdatedInstructorsList();
//       }
//     } catch (e) {
//       print("❌ Error fetching event data: $e");
//     }
//   }
//
//   /// Download Hive Box from Firebase Storage & Extract Days
//   Future<void> fetchInstructorDays(String eventName, String instructorId) async {
//     try {
//       isDownloading.value = true; // Show loading indicator
//       // Get app's document directory
//       final dir = await getApplicationDocumentsDirectory();
//       final localFilePath = '${dir.path}/$instructorId.hive';
//       // Check if file exists locally
//       File localFile = File(localFilePath);
//       /// TODO put it smart logic to see if this is the last version of file
//       //if (!await localFile.exists()) {
//       if (true) {
//         print("📥 Downloading Hive Box for Instructor: $instructorId...");
//         // Download Hive file from Firebase Storage
//         await _storage.ref('hive/$eventName/$instructorId').writeToFile(localFile);
//         print("✅ Download completed: $localFilePath");
//       } else {
//         print("📂 Hive file already exists: $localFilePath");
//       }
//       // Open the Hive box from local storage
//       Box<dynamic> instructorBox = await Hive.openBox(instructorId, path: dir.path);
//       List<String> days = [];
//       if (instructorBox.length>0) {
//         pastEvents =[];
//         instructorBox.keys.forEach((e) {
//           Event? tmpEvent = instructorBox.get(e);
//           days.add(tmpEvent!.date);
//           pastEvents.add(tmpEvent);
//         });
//       }
//
//       // Store the days for the instructor
//       instructorDays[instructorId] = days;
//       await instructorBox.close();
//       print("📅 Extracted Days for $instructorId: $days");
//
//     } catch (e) {
//       print("❌ Error fetching instructor days: $e");
//     } finally {
//       isDownloading.value = false; // Hide loading indicator
//     }
//   }
//
//   String getInstructorName(String id) {
//     Instructor instructor = instructors.firstWhere((Instructor i) => i.id == id);
//     return '${instructor.firstName} ${instructor.lastName}';
//   }
//
//   /// full event report
//   getAllAdminEventData() async {
//     if (selectedEvent.value!=null) {
//       isDownloadingGeneralReport.value = true;
//       String name = selectedEvent.value!;
//       List<String>? instructorFileIds = eventInstructors[name];
//       // await Hive.close();
//       // await Hive.deleteBoxFromDisk(name);
//       // print('del hive');
//       // return;
//       adminEventsBox = await Hive.openBox<AdminEvent>(name);
//       adminEvent = AdminEvent(name: name);
//       /// TODO put it smart logic to see if this is the last version of file
//       if (false) {
//         print('no need to update event from storage');
//         adminEventsBox?.keys.forEach((e) {
//           //print(e);
//           AdminEvent? adminEvent = adminEventsBox?.get(e);
//         });
//         adminEvent = adminEventsBox?.get(name)??AdminEvent(name: name);
//       } else {
//         if (instructorFileIds!=null) {
//           for ( var i in instructorFileIds){
//             /// todo optimize to load only ids not present
//             await getInstructorDays(name,i);
//           }
//         }
//       }
//       isDownloadingGeneralReport.value = false;
//     }
//
//
//   }
//   Future<void> getInstructorDays(String eventName, String instructorId) async {
//     try {
//       final dir = await getApplicationDocumentsDirectory();
//       final localFilePath = '${dir.path}/$instructorId.hive';
//       // Check if file exists locally
//       File localFile = File(localFilePath);
//       //if (!await localFile.exists()) {
//       if (true) {
//         print("📥 Downloading Hive Box for Instructor: $instructorId...");
//         // Download Hive file from Firebase Storage
//         await _storage.ref('hive/$eventName/$instructorId').writeToFile(localFile);
//         print("✅ Download completed: $localFilePath");
//         // Open the Hive box from local storage
//       } else {
//         print("📂 Hive file already exists: $localFilePath");
//       }
//       Box<dynamic> instructorBox = await Hive.openBox(instructorId, path: dir.path);
//       List<Event> eventDays = [];
//       if (instructorBox.length>0) {
//         instructorBox.keys.forEach((e) {
//           Event? tmpEvent = instructorBox.get(e);
//           if (tmpEvent!=null) {
//             //eventDays.add(tmpEvent);
//             adminEvent.eventDays.add(tmpEvent);
//             print('added ${tmpEvent.date}');
//             print(adminEvent.eventDays.length);
//             //adminEvent.save();
//           }
//         });
//         print("📅 Extracted Days");
//       }
//       print('added to admin Events ${adminEvent.eventDays.length}');
//       await instructorBox.close();
//     } catch (e) {
//       print("❌ Error fetching instructor days: $e");
//     } finally {
//       //isDownloading.value = false; // Hide loading indicator
//     }
//   }
//
//
// }
