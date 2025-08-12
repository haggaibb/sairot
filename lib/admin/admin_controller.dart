import 'package:get/get.dart';
import '../models/instructor.dart';
import '../models/event.dart';
import '../models/admin_event.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../event_controller.dart';
import '../models/types.dart';
import 'package:sairot/models/participant.dart';

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
  AdminEvent adminEvent = AdminEvent(name: 'NA');
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  var isInstructorMode = true.obs; // 👈 New toggle switch state
  Event pastEvent = Event(date: '', instructorId: '', eventName: '');
  final eventController = Get.put(EventController());

  /// live event
  var liveEvents = <Event>[].obs; // 🔥 Stores downloaded live events
  var isDownloadingLiveEvents =
      false.obs; // Tracks live event download progress
  var activeLiveDayEvent = '';
  var currentEventName;
  List<Instructor> instructorList = [];
  var instructorIdToTimestamp =
      <String, DateTime>{}.obs; // Map: groupNumber -> InstructorIs
  var instructorIsDownloading =
      <String, bool>{}.obs; // Map: groupNumber -> InstructorIs
  Timer? periodicTimer; // Timer for periodic internet checks
  StreamSubscription? _eventSubscription;
  Rx<DateTime> now = DateTime.now().obs;

  @override
  void onInit() async {
    //isDownloading.value = true;
    await fetchEventsNames();
    await getUpdatedInstructorsList();
    print('done init admin');
    //isDownloading.value = false;
    super.onInit();
  }

  /// 🚀 Automatically stops the timer when the controller is destroyed
  @override
  void onClose() {
    stopLiveListener();
    super.onClose();
  }

  /// go over all , it is a mess, function names and duplicate work?

  void toggleDropdownMode(bool value) {
    isInstructorMode.value = value;
    selectedInstructor.value = null; // Reset selection when switching modes
    selectedGroup.value = null;
  }

  getCurrentEventName() async {
    DocumentSnapshot<Map<String, dynamic>> doc =
        await firestore.collection('System').doc('config').get();
    Map<String, dynamic>? docData = doc.data(); // Ensuring correct casting
    currentEventName = docData?['current_event'] ?? 'NA';
  }

  /// Past Events
  ///
  /// 📂 Fetch Main Event list from firebase Where Current Instructor Has Data for dropdown
  Future<void> fetchEventsNames() async {
    isDownloading.value = true;
    try {
      QuerySnapshot eventsSnapshot =
          await firestore.collection('AdminIndex').get();
      if (eventsSnapshot.docs.isNotEmpty) {
        events.value = eventsSnapshot.docs.map((doc) => doc.id).toList();
        print("📂 Got events");
      } else {
        print('No Main Events Found');
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
    //events.assignAll(instructorEvents.toList());
    isDownloading.value = false;
  }

  /// 📅 Fetch Available Days for Selected Event
  Future<void> fetchEventDays(String eventName) async {
    isDownloading.value = true;
    try {
      QuerySnapshot daysSnapshot = await firestore
          .collection('AdminIndex')
          .doc(eventName)
          .collection('days')
          .get();
      if (daysSnapshot.docs.isNotEmpty) {
        eventDays[eventName] = daysSnapshot.docs.map((doc) => doc.id).toList();
      } else {
        print('No Days for Event Found');
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
    isDownloading.value = false;
  }

  /// 📅 Fetch Instructors for an Event
  Future<void> fetchInstructorsForEvent(String eventName, String day) async {
    isDownloading.value = true;
    try {
      DocumentSnapshot daySnapshot = await firestore
          .collection('AdminIndex')
          .doc(eventName)
          .collection('days')
          .doc(day)
          .get();
      if (daySnapshot.exists) {
        Map<String, dynamic> dayData =
            daySnapshot.data() as Map<String, dynamic>;
        instructorFiles[day] = List<String>.from(dayData['instructors'] ?? []);
      } else {
        print('No Days for Event Found');
      }
    } catch (e) {
      print('Error fetching instructors for day: $e');
    }
    isDownloading.value = false;
  }

  /// 📅 Fetch Instructors for an Event
  Future<void> fetchGroupsForEvent(String eventName, String day) async {
    isDownloading.value = true;
    try {
      DocumentSnapshot daySnapshot = await firestore
          .collection('AdminIndex')
          .doc(eventName)
          .collection('days')
          .doc(day)
          .get();
      if (daySnapshot.exists) {
        Map<String, dynamic> dayData =
            daySnapshot.data() as Map<String, dynamic>;
        instructorFiles[day] = List<String>.from(dayData['instructors'] ?? []);
        groupNumbers[day] = List<String>.from(dayData['groups'] ?? []);
        if (dayData['groupsAndInstructors'] != null) {
          List<dynamic> groups = dayData['groupsAndInstructors'];
          // 🌟 Transform into Map<String, String>
          groupNumberToInstructor
              .clear(); // Clear existing entries before update
          for (var group in groups) {
            if (group is Map<String, dynamic> &&
                group.containsKey('groupNumber') &&
                group.containsKey('instructorId')) {
              String groupNumber = group['groupNumber'].toString();
              String instructorId = group['instructorId'].toString();
              groupNumberToInstructor[groupNumber] = instructorId;
            }
          }

          print("✅ Updated Map: $groupNumberToInstructor");
        }
      } else {
        print('No Days for Event Found');
      }
    } catch (e) {
      print('Error fetching groups for day $e');
    }
    isDownloading.value = false;
  }

  /// 📅 Fetch Instructors for an Event
  Future<void> loadEvent(
      String eventName, String day, String instructorId) async {
    isDownloading.value = true;
    try {
      DocumentSnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('Results')
          .doc(instructorId)
          .collection('events')
          .doc(eventName)
          .collection('days')
          .doc(day)
          .get();
      if (eventSnapshot.exists) {
        Map<String, dynamic> eventData =
            eventSnapshot.data() as Map<String, dynamic>;
        pastEvent = Event.fromJson(eventData);
        eventController.currentEvent.value = pastEvent;
      } else {
        print('No Event Found');
      }
    } catch (e) {
      print('Error fetching event for instructor: $e');
    }
    isDownloading.value = false;
  }

  ///
  /// General Event Report
  Future<void> LoadGeneralEventReport() async {
    if (selectedEvent.value != null) {
      isDownloadingGeneralReport.value = true;
      try {
        List<String>? days = eventDays[selectedEvent.value];
        if (days != null) {
          for (String day in days) {
            await fetchInstructorsForEvent(selectedEvent.value!, day);
            if (instructorFiles[day] != null) {
              for (String i in instructorFiles[day]!) {
                DocumentSnapshot eventSnapshot = await FirebaseFirestore
                    .instance
                    .collection('Results')
                    .doc(i)
                    .collection('events')
                    .doc(selectedEvent.value)
                    .collection('days')
                    .doc(day)
                    .get();
                if (eventSnapshot.exists) {
                  Map<String, dynamic> eventData =
                      eventSnapshot.data() as Map<String, dynamic>;
                  adminEvent.eventDays.add(Event.fromJson(eventData));
                  print('Added an event day to Admin Events');
                } else {
                  print('No Event Found');
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error fetching event for instructor: $e');
      }
      isDownloadingGeneralReport.value = false;
    }
  }

  /// Live
  ///
  void startLiveListener(String day) async {
    await getCurrentEventName(); // Ensure we have the correct event name
    liveEvents.clear();
    _eventSubscription = FirebaseFirestore.instance
        .collection('Results')
        .snapshots()
        .listen((snapshot) {
      print('######### update ########');
      for (var doc in snapshot.docs) {
        print('${doc.id} -> $currentEventName -> $day');
        String instructorId = doc.id; // ✅ Get instructor ID from Firestore
        FirebaseFirestore.instance
            .collection('Results')
            .doc(instructorId)
            .collection('events')
            .doc(currentEventName)
            .collection('days')
            .doc(day)
            .snapshots() // ✅ LISTEN for real-time updates on this specific day
            .listen((eventSnapshot) {
          if (eventSnapshot.exists) {
            try {
              Map<String, dynamic> eventData = eventSnapshot.data()!;
              Event updatedEvent = Event.fromJson(eventData);
              int index =
                  liveEvents.indexWhere((e) => e.instructorId == instructorId);
              if (index != -1) {
                // ✅ Update existing event in the list
                liveEvents[index] = updatedEvent;
                print("✅ Updated Event for ${updatedEvent.instructorId}");
              } else {
                // 🆕 Add new event if it doesn't exist
                liveEvents.add(updatedEvent);
                print("➕ Added New Event for ${updatedEvent.instructorId}");
              }
            } catch (e) {
              print("❌ Error parsing event: $e");
            }
          }
        }, onError: (e) {
          print("❌ Error listening to event: $e");
        });
      }
    }, onError: (e) {
      print("❌ Error listening to Results collection: $e");
    });
    periodicTimer = Timer.periodic(Duration(seconds: 30), (Timer timer) {
      now.value = DateTime.now();
    });
  }

  // 🔴 Stop Listening
  void stopLiveListener() {
    if (_eventSubscription != null) {
      _eventSubscription!.cancel();
      print("🛑 Firestore listener stopped.");
    }
    periodicTimer?.cancel();
  }

  ///
  logout() async {
    eventController.loading.value = true;
    eventController.system.value.loggedIn = '';
    await eventController.system.value.save();
  }

  /// misc
  getGroupStatus(String groupNumber) {
    int meshulashStatus = 0;
    int alonkaStatus = 0;
    int burStatus = 0;
    int sakimStatus = 0;
    int leadership =0;
    int interview = 0;

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
        return ' משולש -${groupEvent.meshulashRounds.length - 1} ';
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
        return ' שקים -${(groupEvent.sakimRounds.length - 1).toString()}';
      }
    }
    ///
    var list = groupEvent.getParticipantsByStatus(ParticipantStatus.Active);
    int interviewsCount = 0;
    /// interviews
    for (Participant p in list) {
      if (p.interviewInstructorComments.isNotEmpty) interviewsCount++;
    }
    if (interviewsCount > 0) {
      if (interviewsCount == list.length) {
        interview = -1;
      } else {
        interview = 0;
        return ' ראיונות -${(interviewsCount).toString()}/${list.length.toString()}';
      }
    }
    /// Leadership
    int leaderShipCount =0;
    for (Participant p in list) {
      if (p.leadershipInstructorComments.isNotEmpty) leaderShipCount++;
    }
    if (leaderShipCount==list.length || interviewsCount>0) {
      leadership = -1;
    } else if (leaderShipCount > 0 && interviewsCount==0) {
      return 'מנהיגות';
    }
    /// check finished
    if (meshulashStatus + alonkaStatus + burStatus + sakimStatus + leadership + interview ==
        -6) {
      return 'הסתיים';
    } else if (meshulashStatus + alonkaStatus + burStatus + sakimStatus == 0) {
      return 'לא התחיל';
    }
    return 'מנוחה';
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
