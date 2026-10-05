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
import 'services/local_storage_service.dart';
import 'services/sync_queue_service.dart';
import 'services/instructor_profile_service.dart';
import 'connectivity_controller.dart';
import 'models/instructor_ux_preferences.dart';
import 'utils/instructor_grade.dart';

class EventController extends GetxController {
  var loading = false.obs;
  var widgetLoading = false.obs;
  var unfinalizedLoading =
      true.obs; // Start as true to show loading message initially
  var backgroundLoading = false.obs; // Track background cache/network loading
  GradeSettings gradesData = GradeSettings();
  final themeController = Get.put(ThemeController());
  final platformService = PlatformService.create();

  /// Event Days
  String currentEventName = '';
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
  //final FirebaseStorage _storage = FirebaseStorage.instance;
  /// login
  Rx<System> system = System().obs;
  RxBool loggedIn = false.obs;
  Instructor currentInstructor =
      Instructor(id: '', firstName: '', lastName: '', mobile: '');
  RxBool isConnected = false.obs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Hive
  var systemBox;

  /// Settings
  RxDouble userFontSize = 18.0.obs;
  RxDouble userChildAspectRatio = 3.0.obs;

  /// Grades table sort state (shared with performance page)
  Rx<SortColumn?> sortColumn = SortColumn.systemGrade.obs;
  Rx<SortDirection> sortDirection = SortDirection.descending.obs;

  /// Progress bar state
  RxBool showProgressBar = false.obs;

  /// Instructor custom comments (exercise type -> list of comments)
  RxMap<String, List<String>> instructorCustomComments =
      <String, List<String>>{}.obs;

  /// Instructor UX preferences
  Rx<InstructorUxPreferences> uxPreferences = InstructorUxPreferences().obs;

  /// Get sorted list of active participants based on current sort settings
  List<Participant> getSortedActiveParticipants() {
    final participants = List<Participant>.from(
      currentEvent.value.participants
          .where((p) => p.status == ParticipantStatus.Active),
    );

    if (sortColumn.value == null || sortDirection.value == SortDirection.none) {
      return participants;
    }

    participants.sort((a, b) {
      int comparison = 0;
      switch (sortColumn.value!) {
        case SortColumn.number:
          comparison = a.number.compareTo(b.number);
          break;
        case SortColumn.finalGrade:
          // Use instructor grade if set (> 0), otherwise use calculated/hint value
          final gradeA = a.instructorGrade > 0.0
              ? a.instructorGrade
              : getCalculatedInstructorGrade(a);
          final gradeB = b.instructorGrade > 0.0
              ? b.instructorGrade
              : getCalculatedInstructorGrade(b);
          comparison = gradeA.compareTo(gradeB);
          break;
        case SortColumn.systemGrade:
          comparison = a.systemGrade.compareTo(b.systemGrade);
          break;
        case SortColumn.meshulash:
          comparison = a.meshulashGrade.compareTo(b.meshulashGrade);
          break;
        case SortColumn.alonka:
          comparison = a.alonkaGrade.compareTo(b.alonkaGrade);
          break;
        case SortColumn.bur:
          comparison = a.burGrade.compareTo(b.burGrade);
          break;
        case SortColumn.sakim:
          comparison = a.sakimGrade.compareTo(b.sakimGrade);
          break;
        case SortColumn.instructorGrade:
          // In the general context, sort by final instructor grade
          // Exercise-specific instructor grade sorting is handled in exercise_grading_page.dart
          comparison = a.instructorGrade.compareTo(b.instructorGrade);
          break;
        case SortColumn.instructorMeshulash:
          comparison =
              a.instructorMeshulashGrade.compareTo(b.instructorMeshulashGrade);
          break;
        case SortColumn.instructorAlonka:
          comparison =
              a.instructorAlonkaGrade.compareTo(b.instructorAlonkaGrade);
          break;
        case SortColumn.instructorSakim:
          comparison = a.instructorSakimGrade.compareTo(b.instructorSakimGrade);
          break;
      }

      return sortDirection.value == SortDirection.ascending
          ? comparison
          : -comparison;
    });

    return participants;
  }

  @override
  onInit() async {
    loading.value = true;

    // Step 1: Initialize storage (fast, local operations)
    if (kIsWeb) {
      // Web: Hive uses IndexedDB automatically, no path needed
      if (!Hive.isAdapterRegistered(102)) Hive.registerAdapter(SystemAdapter());
      if (!Hive.isAdapterRegistered(200))
        Hive.registerAdapter(AccessibilityAdapter());
      // Instructor adapter (103) is generated in instructor.g.dart (part of instructor.dart)
      // It should be accessible, but if registration fails, LocalStorageService will handle it
      try {
        if (!Hive.isAdapterRegistered(103)) {
          // Try to register - this will work if instructor.g.dart is properly generated
          Hive.registerAdapter(InstructorAdapter());
        }
      } catch (e) {
        print('⚠️ Could not register Instructor adapter: $e');
        print('⚠️ Make sure to run: flutter pub run build_runner build');
      }
      await Hive.initFlutter(); // No path needed on web
    } else {
      // Mobile: Get the documents directory for Hive file storage
      var dir = await getApplicationDocumentsDirectory();
      if (!Hive.isAdapterRegistered(102)) Hive.registerAdapter(SystemAdapter());
      if (!Hive.isAdapterRegistered(200))
        Hive.registerAdapter(AccessibilityAdapter());
      // Instructor adapter (103) is generated in instructor.g.dart (part of instructor.dart)
      // It should be accessible, but if registration fails, LocalStorageService will handle it
      try {
        if (!Hive.isAdapterRegistered(103)) {
          // Try to register - this will work if instructor.g.dart is properly generated
          Hive.registerAdapter(InstructorAdapter());
        }
      } catch (e) {
        print('⚠️ Could not register Instructor adapter: $e');
        print('⚠️ Make sure to run: flutter pub run build_runner build');
      }
      await Hive.initFlutter(dir.path);
    }

    // Step 2: Initialize services (fast, local operations)
    await LocalStorageService.instance.initialize();
    await SyncQueueService.instance.initialize();

    // Step 3: Load critical cached data first (fast, works offline)
    await initSystemHiveBox();
    await checkForLocalLogin(); // Works offline with cached instructors

    // Step 4: Show UI immediately if logged in (don't wait for network)
    if (loggedIn.value) {
      // The open event is loaded after the connectivity check.
    }

    // Step 5: Set loading to false to show UI
    super.onInit();
    loading.value = false;

    // Step 6: Do network operations in background (non-blocking)
    backgroundLoading.value = true; // Show background loading indicator
    _connectivitySubscription ??=
        Connectivity().onConnectivityChanged.listen((_) {
      connectionEnabled();
    });
    _initializeInBackground();
  }

  /// Initialize non-critical network operations in the background
  /// This runs after UI is shown, so it doesn't block the splash screen
  Future<void> _initializeInBackground() async {
    try {
      // Non-blocking connectivity check with timeout
      try {
        await connectionEnabled().timeout(
          Duration(seconds: 3),
          onTimeout: () {
            print('⚠️ Connectivity check timed out, assuming offline');
            isConnected.value = false;
          },
        );
        print(
            '🔍 Connectivity check completed. isConnected: ${isConnected.value}');
      } catch (e) {
        print('⚠️ Connectivity check error (non-critical): $e');
        isConnected.value = false;
      }

      // Load network-dependent data in background (non-blocking when offline)
      // Only do Firestore operations if online to avoid blocking
      if (isConnected.value) {
        gradesUpdate().catchError((e) {
          print('⚠️ Error updating grades (non-critical): $e');
          return false;
        });
        getSystemSettings().catchError((e) {
          print('⚠️ Error getting system settings (non-critical): $e');
        });
        getCurrentEventName().catchError((e) {
          print('⚠️ Error getting current event name (non-critical): $e');
        });
        getUpdatedInstructorsList().catchError((e) {
          print('⚠️ Error getting instructors list (non-critical): $e');
        });
      } else {
        // If offline, load from local cache only (fast, non-blocking)
        gradesUpdate(); // Loads from local cache
        getSystemSettings(); // Loads from local cache
        getCurrentEventName(); // Loads from local cache
        getUpdatedInstructorsList(); // Loads from local cache
      }

      if (loggedIn.value) {
        // Load instructor's custom comments (non-blocking - fire and forget)
        loadInstructorCustomComments().catchError((e) {
          print('⚠️ Error loading custom comments (non-critical): $e');
        });

        // Load instructor's UX preferences (non-blocking - fire and forget)
        loadUxPreferences().catchError((e) {
          print('⚠️ Error loading UX preferences (non-critical): $e');
        });

        // Load the single open event after connectivity is known.
        getUnfinalizedEvents();

        // Process sync queue in background (non-blocking)
        if (isConnected.value) {
          final connectivityController = Get.put(ConnectivityController());
          connectivityController.isConnected.value = isConnected.value;
          connectivityController.processSyncQueue().catchError((e) {
            print('⚠️ Error processing sync queue (non-critical): $e');
          });
        }
      }
    } catch (e) {
      print('⚠️ Background initialization error (non-critical): $e');
    } finally {
      // Hide background loading indicator when done
      backgroundLoading.value = false;
    }
  }

  /// 🚀 Automatically stops the timer when the controller is destroyed
  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  /// Settings
  setUserAccessibility(Accessibility accessibility) {
    switch (accessibility) {
      case Accessibility.normal:
        userFontSize.value = systemSettings.accessibilitySettings['normal']
                    ['font_size']
                .toDouble() ??
            18;
        userChildAspectRatio.value = systemSettings
                .accessibilitySettings['normal']['child_aspect_ratio']
                .toDouble() ??
            3;
        system.value.userFontSize = userFontSize.value;
        system.value.save();
        break;
      case Accessibility.big:
        userFontSize.value = systemSettings.accessibilitySettings['big']
                    ['font_size']
                .toDouble() ??
            26;
        userChildAspectRatio.value = systemSettings.accessibilitySettings['big']
                    ['child_aspect_ratio']
                .toDouble() ??
            2.5;
        system.value.userFontSize = userFontSize.value;
        system.value.save();
        break;
      case Accessibility.biggest:
        userFontSize.value = (systemSettings.accessibilitySettings['biggest']
                    ?['font_size'] as num?)
                ?.toDouble() ??
            30.0;
        userChildAspectRatio.value = systemSettings
                .accessibilitySettings['biggest']['child_aspect_ratio']
                .toDouble() ??
            2;
        system.value.userFontSize = userFontSize.value;
        system.value.save();
        break;
    }
    system.refresh(); // Ensure UI updates
    update(); // Notify GetX listeners

    // Save font size to UX preferences
    if (loggedIn.value && currentInstructor.id.isNotEmpty) {
      final updatedPrefs = uxPreferences.value.copyWith(
        fontSize: userFontSize.value,
      );
      updateUxPreferences(updatedPrefs);
    }
  }

  /// Hive
  initSystemHiveBox() async {
    // Use untyped box to allow storing different types (System, Map, String, etc.)
    // Check if box is already open to avoid "box already open" error
    if (systemBox == null || !systemBox!.isOpen) {
      systemBox = await Hive.openBox('system');
    }
    if (systemBox.length > 0) {
      final loginData = systemBox.get('login');
      // Handle web's stricter typing - ensure it's a System
      if (loginData is System) {
        system.value = loginData;
      } else if (loginData != null) {
        // Try to cast it - on web Hive might return it in a different wrapper
        try {
          system.value = loginData as System;
        } catch (e) {
          print('⚠️ Error loading login data from cache: $e');
          // If casting fails, create a new System object
          system.value = System();
        }
      }
    } else {
      await systemBox.put('login', system.value);
      return false;
    }
  }

  deleteSystemHiveBox() async {
    await Hive.deleteBoxFromDisk('system');
    Get.offAllNamed('/front_door');
  }

  /// get the system settings from firebase (with local cache fallback)
  getSystemSettings() async {
    bool hasCachedSettings = false;
    try {
      // First, try to load from local cache (System Hive box)
      if (systemBox != null && systemBox!.containsKey('systemSettings')) {
        try {
          final cachedSettingsData = systemBox!.get('systemSettings');
          // Handle web's stricter typing - convert to Map if needed
          // Hive on web may return LinkedMap<dynamic, dynamic> instead of Map<String, dynamic>
          Map<String, dynamic>? cachedSettingsJson;
          if (cachedSettingsData != null) {
            try {
              // Convert any Map type (including LinkedMap) to Map<String, dynamic>
              // Recursively convert nested maps as well
              if (cachedSettingsData is Map) {
                // Helper function to recursively convert LinkedMap to Map<String, dynamic>
                dynamic convertValue(dynamic value) {
                  if (value is Map) {
                    final converted = <String, dynamic>{};
                    for (var entry in value.entries) {
                      converted[entry.key.toString()] =
                          convertValue(entry.value);
                    }
                    return converted;
                  } else if (value is List) {
                    return value.map((item) => convertValue(item)).toList();
                  }
                  return value;
                }

                // Create a new Map and copy all entries, converting keys to String
                final tempMap = <String, dynamic>{};
                for (var entry in cachedSettingsData.entries) {
                  tempMap[entry.key.toString()] = convertValue(entry.value);
                }
                cachedSettingsJson = tempMap;
              } else {
                // If it's not a Map, skip it
                cachedSettingsJson = null;
              }
            } catch (e) {
              print('⚠️ Could not convert cached settings data: $e');
              cachedSettingsJson = null;
            }
          }

          if (cachedSettingsJson != null) {
            systemSettings = SystemSettings.fromJson(cachedSettingsJson);
            setUserAccessibility(system.value.accessibility);
            hasCachedSettings = true;
            print('✅ Loaded system settings from local cache');
          }
        } catch (e) {
          print('⚠️ Error loading cached system settings: $e');
        }
      }

      // If online, try to fetch from Firestore and update cache
      if (isConnected.value) {
        try {
          DocumentSnapshot docSnapshot = await firestore
              .collection('System')
              .doc('app_system_settings')
              .get();
          if (docSnapshot.exists) {
            // Handle web's IdentityMap type - convert to regular Map
            final data = docSnapshot.data();
            Map<String, dynamic> settingsMap;
            if (data is Map) {
              settingsMap = Map<String, dynamic>.from(data);
            } else {
              settingsMap = Map<String, dynamic>.from(data as Map);
            }

            systemSettings = SystemSettings.fromJson(settingsMap);
            setUserAccessibility(system.value.accessibility);

            // Update local cache
            if (systemBox != null) {
              await systemBox!.put('systemSettings', systemSettings.toJson());
              print('✅ Updated system settings cache from Firestore');
            }
            return true;
          } else {
            if (!hasCachedSettings) {
              systemSettings = SystemSettings();
            }
            print('⚠️ Document does not exist in Firestore');
            // Keep using cached settings if available
            return hasCachedSettings;
          }
        } catch (e) {
          print('⚠️ Error fetching system settings from Firestore: $e');
          // Keep using cached settings if available
          return hasCachedSettings;
        }
      } else {
        // Offline: use cached settings
        if (hasCachedSettings) {
          print('📴 Using cached system settings (offline mode)');
          return true;
        } else {
          systemSettings = SystemSettings();
          print('⚠️ No cached system settings available, using defaults');
          return false;
        }
      }
    } catch (e) {
      systemSettings = SystemSettings();
      print('❌ System Settings Error: $e');
      return null;
    }
  }

  ///
  Instructor? getInstructor(String id) {
    return instructorList.firstWhereOrNull((i) => i.id == id);
  }

  getCurrentEventName() async {
    try {
      // First, try to load from local cache (System Hive box)
      if (systemBox != null && systemBox!.containsKey('currentEventName')) {
        try {
          final cachedEventNameData = systemBox!.get('currentEventName');
          // Handle web's stricter typing - ensure it's a String
          String? cachedEventName;
          if (cachedEventNameData is String) {
            cachedEventName = cachedEventNameData;
          } else if (cachedEventNameData != null) {
            // Try to convert to String if it's a different type
            cachedEventName = cachedEventNameData.toString();
          }

          if (cachedEventName != null &&
              cachedEventName.isNotEmpty &&
              cachedEventName != 'NA') {
            currentEventName = cachedEventName;
            print(
                '✅ Loaded current event name from local cache: $currentEventName');
          }
        } catch (e) {
          print('⚠️ Error loading cached event name: $e');
        }
      }

      // If online, try to fetch from Firestore and update cache
      if (isConnected.value) {
        try {
          DocumentSnapshot<Map<String, dynamic>> doc =
              await firestore.collection('System').doc('config').get();
          Map<String, dynamic>? docData = doc.data();
          final firestoreEventName = docData?['current_event'] ?? 'NA';

          if (firestoreEventName != 'NA' && firestoreEventName.isNotEmpty) {
            currentEventName = firestoreEventName;

            // Update local cache
            if (systemBox != null) {
              await systemBox!.put('currentEventName', currentEventName);
              print(
                  '✅ Updated current event name cache from Firestore: $currentEventName');
            }
          } else if (currentEventName.isEmpty || currentEventName == 'NA') {
            // If Firestore doesn't have it and we don't have cache, use default
            currentEventName = 'NA';
          }
        } catch (e) {
          print('⚠️ Error fetching current event name from Firestore: $e');
          // Keep using cached value if available
          if (currentEventName.isEmpty || currentEventName == 'NA') {
            currentEventName = 'NA';
          }
        }
      } else {
        // Offline: use cached event name
        if (currentEventName.isEmpty || currentEventName == 'NA') {
          currentEventName = 'NA';
          print('📴 No cached event name available (offline mode)');
        } else {
          print('📴 Using cached event name (offline mode): $currentEventName');
        }
      }
    } catch (e) {
      print('❌ Error in getCurrentEventName: $e');
      if (currentEventName.isEmpty) {
        currentEventName = 'NA';
      }
    }
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

  /// Time used to choose the single open event. lastUpdate wins over the day date.
  DateTime? _eventSortTime(Event event) {
    if (event.lastUpdate != null) return event.lastUpdate;
    final parts = event.date.split('-');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  bool _isNewerEvent(Event candidate, Event current) {
    final candidateTime = _eventSortTime(candidate);
    final currentTime = _eventSortTime(current);
    if (candidateTime == null) return false;
    if (currentTime == null) return true;
    return candidateTime.isAfter(currentTime);
  }

  /// True only when Firestore has this day and it is already closed.
  /// A missing document or a failed read leaves the local day open.
  Future<bool> _isOpenEventClosedOnServer(Event event) async {
    try {
      final snapshot = await firestore
          .collection('Results')
          .doc(event.instructorId)
          .collection('events')
          .doc(event.eventName)
          .collection('days')
          .doc(event.date)
          .get()
          .timeout(const Duration(seconds: 8));
      if (!snapshot.exists || snapshot.data() == null) return false;
      return snapshot.data()!['finalized'] == true;
    } catch (e) {
      print('⚠️ Could not verify open event on Firestore: $e');
      return false;
    }
  }

  Future<List<Event>> _remoteOpenDaysForCurrentEvent() async {
    if (currentEventName.isEmpty ||
        currentEventName == 'NA' ||
        currentEventName == 'playground') {
      return [];
    }
    final snapshot = await firestore
        .collection('Results')
        .doc(currentInstructor.id)
        .collection('events')
        .doc(currentEventName)
        .collection('days')
        .where('finalized', isEqualTo: false)
        .get()
        .timeout(const Duration(seconds: 8));
    final openDays = <Event>[];
    for (final doc in snapshot.docs) {
      final event = Event.fromJson(doc.data());
      if (event.eventName == 'playground' || event.eventName.isEmpty) {
        continue;
      }
      final deleted = await LocalStorageService.instance.isEventDeleted(
          event.eventName, event.date, currentInstructor.id);
      if (deleted) continue;
      openDays.add(event);
    }
    return openDays;
  }

  /// Remember extra open days so the app does not bring them back after this one is closed.
  /// Firestore copies stay where they are. A null [keep] hides every open day of the current event.
  Future<void> _hideOtherRemoteOpenDays(Event? keep) async {
    if (keep != null && keep.eventName != currentEventName) return;
    try {
      final openDays = await _remoteOpenDaysForCurrentEvent();
      for (final event in openDays) {
        if (keep != null &&
            event.date == keep.date &&
            event.eventName == keep.eventName) {
          continue;
        }
        await LocalStorageService.instance.markEventAsDeleted(
            event.eventName, event.date, currentInstructor.id);
        print(
            '⚠️ Leaving extra open day on the server, hidden in the app: ${event.eventName} / ${event.date}');
      }
    } catch (e) {
      print('⚠️ Could not hide extra open days: $e');
    }
  }

  /// Newest unfinalized day of the current event name.
  Future<Event?> _newestRemoteOpenEvent() async {
    try {
      final openDays = await _remoteOpenDaysForCurrentEvent();
      Event? newest;
      for (final event in openDays) {
        if (newest == null || _isNewerEvent(event, newest)) {
          newest = event;
        }
      }
      if (newest != null) {
        await _hideOtherRemoteOpenDays(newest);
      }
      return newest;
    } catch (e) {
      print('⚠️ Could not load the open event from Firestore: $e');
      return null;
    }
  }

  /// The instructor has one open event until it is closed or deleted.
  /// Local finalized:false does not override a day Firestore already closed.
  getUnfinalizedEvents() async {
    AppLogger.debug(" ➡️ get open event.");
    try {
      unfinalizedLoading.value = true;
      unfinalizedEvents.clear();

      await getCurrentEventName();
      await _uploadClosedEventsStillOnDevice();

      final localEvents = await LocalStorageService.instance
          .getLocalUnfinalizedEvents(currentInstructor.id);
      final candidates = localEvents
          .where((event) => event.eventName != 'playground')
          .toList();

      Event? openEvent;
      for (final event in candidates) {
        if (openEvent == null || _isNewerEvent(event, openEvent)) {
          openEvent = event;
        }
      }

      var skipRemoteAdopt = false;
      if (openEvent != null && isConnected.value) {
        final closedOnServer = await _isOpenEventClosedOnServer(openEvent);
        if (closedOnServer) {
          final droppedCurrentEvent = openEvent.eventName == currentEventName;
          print(
              '🗑️ Local event is closed on the server, dropping cache: ${openEvent.eventName} / ${openEvent.date}');
          await LocalStorageService.instance.deleteEventLocally(
              openEvent.eventName, openEvent.date, openEvent.instructorId);
          openEvent = null;
          // The cached day was already closed. Do not replace it with an older open day.
          if (droppedCurrentEvent) {
            await _hideOtherRemoteOpenDays(null);
            skipRemoteAdopt = true;
          }
        } else {
          await _hideOtherRemoteOpenDays(openEvent);
        }
      }

      if (openEvent == null && isConnected.value && !skipRemoteAdopt) {
        final remoteEvent = await _newestRemoteOpenEvent();
        if (remoteEvent != null) {
          await LocalStorageService.instance.saveEventLocally(remoteEvent);
          openEvent = remoteEvent;
          print(
              '✅ Loaded the open event from Firestore: ${openEvent.eventName} / ${openEvent.date}');
        }
      }

      await LocalStorageService.instance.pruneLocalEvents(
        instructorId: currentInstructor.id,
        keep: openEvent,
      );

      if (openEvent != null) {
        unfinalizedEvents.add(openEvent);
      }
    } catch (e) {
      print("❌ Error in getUnfinalizedEvents: $e");
    }
    unfinalizedLoading.value = false;
    return unfinalizedEvents;
  }

  /// Upload a close that was saved on the device and then remove that copy.
  Future<void> _uploadClosedEventsStillOnDevice() async {
    if (!isConnected.value) return;
    final localEvents = await LocalStorageService.instance
        .getLocalEvents(currentInstructor.id);
    for (final event in localEvents) {
      if (event.eventName == 'playground') continue;
      if (!event.finalized || event.isBackedUp) continue;
      final saved = await event.saveToFirestore(
        skipLocalSave: true,
        queueOnFailure: true,
      );
      if (!saved) continue;
      await LocalStorageService.instance.deleteEventLocally(
          event.eventName, event.date, event.instructorId);
    }
  }

  /// Close the working event. The local copy is removed only after Firestore accepts it.
  Future<bool> closeCurrentEvent() async {
    final event = currentEvent.value;
    event.finalized = true;
    currentEvent.refresh();
    final saved = await event.saveToFirestore(queueOnFailure: false);
    if (!saved) {
      event.finalized = false;
      event.isBackedUp = false;
      currentEvent.refresh();
      await event.saveToLocal();
      return false;
    }
    await LocalStorageService.instance.deleteEventLocally(
        event.eventName, event.date, event.instructorId);
    unfinalizedEvents.removeWhere((open) =>
        open.eventName == event.eventName && open.date == event.date);
    return true;
  }


  /// Helper method to save event with offline support
  /// Always saves locally first, then syncs to Firestore if online (non-blocking)
  Future<bool> saveEventWithOfflineSupport(Event event,
      {bool isCreate = false}) async {
    try {
      // Always save locally first (immediate)
      final localSuccess = await event.saveToLocal();
      if (!localSuccess) {
        print('⚠️ Failed to save event locally');
        return false;
      }

      print('✅ Event saved locally successfully');

      // Try Firestore save in background (non-blocking) - don't wait for it
      // This prevents the UI from hanging when offline
      _saveToFirestoreInBackground(event, isCreate: isCreate);

      // Return immediately after local save succeeds
      return true;
    } catch (e) {
      print('❌ Error in saveEventWithOfflineSupport: $e');
      return false;
    }
  }

  /// Save to Firestore in background (non-blocking)
  /// This method runs asynchronously and doesn't block the UI
  void _saveToFirestoreInBackground(Event event,
      {bool isCreate = false}) async {
    try {
      // Check connectivity before attempting Firestore save
      if (!isConnected.value) {
        // Offline: queue for sync when internet becomes available
        await SyncQueueService.instance.queueFirestoreOperation(
            isCreate ? 'createEvent' : 'saveEvent', event.toJson());
        print('📴 Event saved locally, queued for sync when online');
        // Note: Playground is NOT deleted here - it persists like a real event
        return;
      }

      // Online: try to save to Firestore (with timeout)
      try {
        if (isCreate) {
          final firestoreSuccess = await event.createFirestoreEvent();
          if (firestoreSuccess) {
            print('✅ Event created and saved to Firestore');
            // Note: isBackedUp flag is set in createFirestoreEvent() method
          } else {
            // Queue for retry
            await SyncQueueService.instance
                .queueFirestoreOperation('createEvent', event.toJson());
            print('⚠️ Firestore create failed, queued for retry');
          }
        } else {
          final firestoreSuccess = await event.saveToFirestore();
          if (firestoreSuccess) {
            print('✅ Event saved to Firestore');
            // Note: isBackedUp flag is set in saveToFirestore() method
          } else {
            // Queue for retry
            await SyncQueueService.instance
                .queueFirestoreOperation('saveEvent', event.toJson());
            print('⚠️ Firestore save failed, queued for retry');
          }
        }
        // Note: Playground is NOT deleted here - it persists like a real event
        // It will only be deleted when user explicitly saves/closes it
      } catch (e) {
        print('⚠️ Error saving to Firestore: $e, queuing for retry');
        // Queue for retry
        await SyncQueueService.instance.queueFirestoreOperation(
            isCreate ? 'createEvent' : 'saveEvent', event.toJson());
      }
    } catch (e) {
      print('❌ Error in _saveToFirestoreInBackground: $e');
      // Even if background save fails, queue it for later
      try {
        await SyncQueueService.instance.queueFirestoreOperation(
            isCreate ? 'createEvent' : 'saveEvent', event.toJson());
      } catch (queueError) {
        print('⚠️ Failed to queue operation: $queueError');
      }
    }
  }

  createNewEvent(Event event) async {
    loading.value = true;
    for (var participant in event.participants) {
      participant.status = ParticipantStatus.Active;
    }
    currentEvent.value = event;
    final saved = await saveEventWithOfflineSupport(event, isCreate: true);
    if (saved) {
      unfinalizedEvents
        ..clear()
        ..add(event);
      await LocalStorageService.instance.pruneLocalEvents(
        instructorId: currentInstructor.id,
        keep: event,
      );
    }
    loading.value = false;
  }

  delEvent(Event event) async {
    try {
      // 🔒 Safety check: If this is the currently loaded event, clear it first
      final isCurrentEvent = currentEvent.value.eventName == event.eventName &&
          currentEvent.value.date == event.date;
      if (isCurrentEvent) {
        print(
            '⚠️ Deleting currently loaded event - clearing currentEvent first');
        currentEvent.value = Event(date: '', instructorId: '', eventName: '');
        currentEvent.refresh();
      }

      // 🔥 Step 1: Delete from local storage first (immediate, works offline)
      await LocalStorageService.instance.deleteEventLocally(
          event.eventName, event.date, currentInstructor.id);


      // 🔥 Step 3: Delete from Firestore (queue if offline, execute if online)
      if (isConnected.value) {
        // Online: Delete from Firestore immediately
        Future(() async {
          try {
            await deleteEventFromFirestore(event);
            // Unmark as deleted after successful Firebase deletion
            await LocalStorageService.instance.unmarkEventAsDeleted(
                event.eventName, event.date, currentInstructor.id);
            print(
                "✅ Event '${event.date}' deleted successfully from Firestore.");
          } catch (e) {
            print("❌ Error deleting event from Firestore: $e");
            // If Firestore delete fails, queue it for retry
            await SyncQueueService.instance
                .queueFirestoreOperation('deleteEvent', {
              'eventName': event.eventName,
              'date': event.date,
              'instructorId': event.instructorId,
              'groupNumber': event.groupNumber,
            });
            // Keep it marked as deleted until Firebase deletion succeeds
          }
        }).catchError((e) {
          print('❌ Error in background Firestore delete: $e');
        });
      } else {
        // Offline: Queue deletion for sync when online
        print(
            '📴 Offline: Event deleted locally, queuing Firestore delete for sync');
        await SyncQueueService.instance.queueFirestoreOperation('deleteEvent', {
          'eventName': event.eventName,
          'date': event.date,
          'instructorId': event.instructorId,
          'groupNumber': event.groupNumber,
        });

        // Track deleted event locally to prevent restoration from Firebase
        await LocalStorageService.instance.markEventAsDeleted(
            event.eventName, event.date, currentInstructor.id);
      }

      print("✅ Event '${event.date}' deleted successfully from local storage.");
    } catch (e) {
      print("❌ Error deleting event: $e");
      rethrow; // Re-throw to let caller know deletion failed
    }
  }

  /// Delete event from Firestore (extracted for reuse)
  Future<void> deleteEventFromFirestore(Event event) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Delete from Results collection (with timeout)
    try {
      DocumentReference eventRef = firestore
          .collection('Results')
          .doc(event.instructorId)
          .collection('events')
          .doc(event.eventName)
          .collection('days')
          .doc(event.date);
      await eventRef.delete().timeout(
        Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Firestore delete timed out for Results collection');
          throw TimeoutException('Firestore delete operation timed out');
        },
      );
    } catch (e) {
      print('⚠️ Error deleting from Results collection: $e');
      rethrow;
    }

    // ❌ NOTE: We do NOT delete from Events collection
    // The Events collection is read-only and managed by admin system/Cloud Functions
    // It may contain data from other instructors and shouldn't be deleted by instructors
    // getCurrentEventDays() reads from Events collection for reference only

    // Update AdminIndex (remove instructor/group references) - non-critical
    try {
      DocumentReference adminRef = firestore
          .collection('AdminIndex')
          .doc(event.eventName)
          .collection('days')
          .doc(event.date);
      await adminRef.update({
        "groups": FieldValue.arrayRemove([event.groupNumber.toString()]),
      }).timeout(Duration(seconds: 3));
      await adminRef.update({
        "instructors": FieldValue.arrayRemove([event.instructorId]),
      }).timeout(Duration(seconds: 3));

      // Get the document snapshot and update groupsAndInstructors
      final snapshot = await adminRef.get().timeout(Duration(seconds: 3));
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;
        List<dynamic> groupsArray = data?['groupsAndInstructors'] ?? [];
        // Remove any map where instructorId matches
        groupsArray.removeWhere((item) =>
            item is Map<String, dynamic> &&
            item['instructorId'] == event.instructorId);
        await adminRef.update({'groupsAndInstructors': groupsArray}).timeout(
            Duration(seconds: 3));
      }
    } catch (e) {
      print('⚠️ Error updating AdminIndex (non-critical): $e');
      // Don't rethrow - AdminIndex update is non-critical
    }
  }

  /// participants
  updateParticipantStatus(int id, ParticipantStatus newStatus) {
    int index = currentEvent.value.participants
        .indexWhere((participant) => participant.number == id);
    currentEvent.value.participants[index].status = newStatus;
    // Use non-blocking save to prevent delays when offline
    saveEventWithOfflineSupport(currentEvent.value);
  }

  Participant getParticipant(int number) {
    // Removed debug print of participant AI report
    int index = currentEvent.value.participants
        .indexWhere((participant) => participant.number == number);
    if (index > -1)
      return currentEvent.value.participants[index];
    else
      return Participant(number: 0, name: 'לא נמצא');
  }

  /// Sakim
  setParticipantSakimPosition(int number, int pos) {
    int index = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    currentEvent.value.participants[index].sakimPositions.add(pos);
    //currentEvent.value.saveToFirestore();
  }

  /// Remove the last position from sakimPositions array (for undo)
  void removeLastSakimPosition(int number) {
    int participantIndex = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    if (participantIndex != -1 &&
        currentEvent
            .value.participants[participantIndex].sakimPositions.isNotEmpty) {
      currentEvent.value.participants[participantIndex].sakimPositions
          .removeLast();
    }
  }

  /// Push index to sakim stack (for undo tracking)
  /// If index is null, clears the stack
  void setLastSakimIndex(int number, int? index) {
    int participantIndex = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    if (participantIndex != -1) {
      if (index == null) {
        // Clear the stack
        currentEvent.value.participants[participantIndex].lastSakimIndexStack
            .clear();
      } else {
        // Push index to stack
        currentEvent.value.participants[participantIndex].lastSakimIndexStack
            .add(index);
      }
    }
  }

  /// Pop and return the last sakim index from stack (for undo tracking)
  /// Returns null if stack is empty
  int? getLastSakimIndex(int number) {
    int participantIndex = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    if (participantIndex != -1) {
      final stack =
          currentEvent.value.participants[participantIndex].lastSakimIndexStack;
      if (stack.isNotEmpty) {
        return stack.removeLast(); // Pop from stack
      }
    }
    return null;
  }

  /// Clear the entire sakim index stack for a participant
  void clearSakimIndexStack(int number) {
    int participantIndex = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    if (participantIndex != -1) {
      currentEvent.value.participants[participantIndex].lastSakimIndexStack
          .clear();
    }
  }

  void addSakimComments(List<String> comments, int participantNumber) {
    // Find the index of the participant by their number.
    int index = currentEvent.value.participants
        .indexWhere((participant) => participant.number == participantNumber);
    // ✅ Ensure participant exists.
    if (index != -1) {
      // Get the existing comments.
      List<String> existingComments =
          currentEvent.value.participants[index].sakimInstructorComments;
      // ✅ Merge new comments without duplicates.
      existingComments.addAll(
          comments.where((comment) => !existingComments.contains(comment)));
      // ✅ Update the participant's comment list.
      currentEvent.value.participants[index].sakimInstructorComments =
          existingComments;
      print("✅ Comments merged successfully: ${existingComments}");
      // Use non-blocking save to prevent delays when offline
      saveEventWithOfflineSupport(currentEvent.value);
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

  /// Remove the last position from meshulashPositions array (for undo)
  void removeLastMeshulashPosition(int number) {
    int participantIndex = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    if (participantIndex != -1 &&
        currentEvent.value.participants[participantIndex].meshulashPositions
            .isNotEmpty) {
      currentEvent.value.participants[participantIndex].meshulashPositions
          .removeLast();
    }
  }

  /// Push index to meshulash stack (for undo tracking)
  /// If index is null, clears the stack
  void setLastMeshulashIndex(int number, int? index) {
    int participantIndex = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    if (participantIndex != -1) {
      if (index == null) {
        // Clear the stack
        currentEvent
            .value.participants[participantIndex].lastMeshulashIndexStack
            .clear();
      } else {
        // Push index to stack
        currentEvent
            .value.participants[participantIndex].lastMeshulashIndexStack
            .add(index);
      }
    }
  }

  /// Pop and return the last meshulash index from stack (for undo tracking)
  /// Returns null if stack is empty
  int? getLastMeshulashIndex(int number) {
    int participantIndex = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    if (participantIndex != -1) {
      final stack = currentEvent
          .value.participants[participantIndex].lastMeshulashIndexStack;
      if (stack.isNotEmpty) {
        return stack.removeLast(); // Pop from stack
      }
    }
    return null;
  }

  /// Clear the entire meshulash index stack for a participant
  void clearMeshulashIndexStack(int number) {
    int participantIndex = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    if (participantIndex != -1) {
      currentEvent.value.participants[participantIndex].lastMeshulashIndexStack
          .clear();
    }
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
      currentEvent.value.participants[index].meshulashInstructorComments =
          comments;
      print("✅ Comments saved successfully: ${comments}");
      // Use non-blocking save to prevent delays when offline
      saveEventWithOfflineSupport(currentEvent.value);
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
      currentEvent.value.participants[index].alonkaInstructorComments =
          comments;
      print("✅ Comments to save : ${comments}");
      // Use non-blocking save to prevent delays when offline
      saveEventWithOfflineSupport(currentEvent.value);
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
      currentEvent.value.participants[index].interviewInstructorComments =
          comments;
      print("✅ Comments saved successfully: ${comments}");
      // Use non-blocking save to prevent delays when offline
      saveEventWithOfflineSupport(currentEvent.value);
      currentEvent.refresh();
    } else {
      print("❌ Participant not found with number: $participantNumber");
    }
  }

  /// Generic Comments (from event home page)
  void addGenericComments(List<String> comments, int participantNumber) {
    // Find the index of the participant by their number.
    int index = currentEvent.value.participants
        .indexWhere((participant) => participant.number == participantNumber);
    // ✅ Ensure participant exists.
    if (index != -1) {
      // ✅ Update the participant's generic comment list.
      currentEvent.value.participants[index].genericInstructorComments =
          comments;
      print("✅ Generic comments saved successfully: ${comments}");
      // Use non-blocking save to prevent delays when offline
      saveEventWithOfflineSupport(currentEvent.value);
      currentEvent.refresh();
    } else {
      print("❌ Participant not found with number: $participantNumber");
    }
  }

  Color getLeadershipStatus() {
    int count = 0;
    bool interviewsHaveStarted = false;
    var list =
        currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active);
    for (Participant p in list) {
      if (p.leadershipInstructorComments.isNotEmpty) count++;
      if (p.interviewInstructorComments.isNotEmpty)
        interviewsHaveStarted = true;
    }
    if (count == 0) return Colors.black;
    if (count > 0 && interviewsHaveStarted) {
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
      currentEvent.value.participants[index].leadershipInstructorComments =
          comments;
      print("✅ Comments to save: ${comments}");
      // Use non-blocking save to prevent delays when offline
      saveEventWithOfflineSupport(currentEvent.value);
      currentEvent.refresh();
    } else {
      print("❌ Participant not found with number: $participantNumber");
    }
  }

  /// Bur - Add a comment to a Bur's instructorComments list
  void addBurComment(String comment, int participantNumber) {
    // Find the Bur by participant number (bur.id == participantNumber)
    int burIndex = currentEvent.value.burGrades
        .indexWhere((Bur bur) => bur.id == participantNumber);

    if (burIndex != -1) {
      // Get the existing comments
      List<String> existingComments =
          currentEvent.value.burGrades[burIndex].instructorComments;

      // Add new comment if it doesn't already exist (merge, don't replace)
      if (!existingComments.contains(comment)) {
        existingComments.add(comment);
        currentEvent.value.burGrades[burIndex].instructorComments =
            existingComments;
        print(
            "✅ Bur comment added successfully to participant $participantNumber: $comment");
        // Use non-blocking save to prevent delays when offline
        saveEventWithOfflineSupport(currentEvent.value);
        currentEvent.refresh();
      } else {
        print(
            "⚠️ Bur comment already exists for participant $participantNumber: $comment");
      }
    } else {
      print("❌ Bur not found with participant number: $participantNumber");
    }
  }

  Color getInterviewStatus() {
    int count = 0;
    var list =
        currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active);
    for (Participant p in list) {
      if (p.interviewInstructorComments.isNotEmpty) count++;
    }
    if (count == 0) return Colors.black;
    if (count == list.length) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  /// Grades
  /// Grades - Get the grades settings from firebase (with local cache fallback)
  Future<bool?> gradesUpdate() async {
    bool hasCachedSettings = false;
    try {
      // First, try to load from local cache (System Hive box)
      if (systemBox != null && systemBox!.containsKey('grades')) {
        try {
          final cachedGradesData = systemBox!.get('grades');
          // Handle web's stricter typing - convert to Map if needed
          Map<String, dynamic>? cachedGradesJson;

          if (cachedGradesData != null) {
            try {
              // Same map conversion logic as getSystemSettings
              if (cachedGradesData is Map) {
                dynamic convertValue(dynamic value) {
                  if (value is Map) {
                    final converted = <String, dynamic>{};
                    for (var entry in value.entries) {
                      converted[entry.key.toString()] =
                          convertValue(entry.value);
                    }
                    return converted;
                  } else if (value is List) {
                    return value.map((item) => convertValue(item)).toList();
                  }
                  return value;
                }

                final tempMap = <String, dynamic>{};
                for (var entry in cachedGradesData.entries) {
                  tempMap[entry.key.toString()] = convertValue(entry.value);
                }
                cachedGradesJson = tempMap;
              }
            } catch (e) {
              print('⚠️ Could not convert cached grades data: $e');
              cachedGradesJson = null;
            }
          }

          if (cachedGradesJson != null) {
            firestoreGradeSettings = GradeSettings.fromJson(cachedGradesJson);
            gradesData = firestoreGradeSettings;
            hasCachedSettings = true;
            print('✅ Loaded grades settings from local cache');
          }
        } catch (e) {
          print('⚠️ Error loading cached grades settings: $e');
        }
      }

      // If online, try to fetch from Firestore and update cache
      if (isConnected.value) {
        try {
          DocumentSnapshot docSnapshot =
              await firestore.collection('System').doc('grades').get();
          if (docSnapshot.exists) {
            final data = docSnapshot.data();
            Map<String, dynamic> gradesMap;
            if (data is Map) {
              gradesMap = Map<String, dynamic>.from(data);
            } else {
              gradesMap = Map<String, dynamic>.from(data as Map);
            }

            firestoreGradeSettings = GradeSettings.fromJson(gradesMap);
            gradesData = firestoreGradeSettings;

            // Update local cache
            if (systemBox != null) {
              await systemBox!.put('grades', firestoreGradeSettings.toJson());
              print('✅ Updated grades settings cache from Firestore');
            }
            return true;
          } else {
            if (!hasCachedSettings) {
              firestoreGradeSettings = GradeSettings();
              gradesData = firestoreGradeSettings;
            }
            print('⚠️ Document does not exist in Firestore');
            return hasCachedSettings;
          }
        } catch (e) {
          print('⚠️ Error fetching grades from Firestore: $e');
          // Keep using cached settings if available
          return hasCachedSettings;
        }
      } else {
        // Offline: use cached settings
        if (hasCachedSettings) {
          print('📴 Using cached grades settings (offline mode)');
          return true;
        } else {
          firestoreGradeSettings = GradeSettings();
          gradesData = firestoreGradeSettings;
          print('⚠️ No cached grades settings available, using defaults');
          return false;
        }
      }
    } catch (e) {
      firestoreGradeSettings = GradeSettings();
      gradesData = firestoreGradeSettings;
      print('❌ Grades Settings Error: $e');
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
    double meshulashGrade = 1 +
        ((totalParticipants - absolutePosition) / (totalParticipants - 1)) *
            (10 - 1);

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
    double alonkaGrade =
        ((credits / maxPossibleCredit) * 10) * gradesData.systemGradeFactor;
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
    double sakimGrade = 1 +
        ((totalParticipants - absolutePosition) / (totalParticipants - 1)) *
            (10 - 1);

    return sakimGrade * gradesData.systemGradeFactor;
  }

  double getBurGrade(int number) {
    if (currentEvent.value.burGrades.isEmpty) return 0;
    int participantBurIndex =
        currentEvent.value.burGrades.indexWhere((Bur bur) => bur.id == number);
    if (participantBurIndex == -1)
      return 0; // Participant not found in burGrades
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

    // Only include exercises with grades > 0
    // Build lists of valid (grade > 0) exercises with their weights
    double validTotalWeight = 0.0;
    double weightedSum = 0.0;

    if (param1 > 0) {
      validTotalWeight += weight1;
      weightedSum += param1 * weight1;
    }
    if (param2 > 0) {
      validTotalWeight += weight2;
      weightedSum += param2 * weight2;
    }
    if (param3 > 0) {
      validTotalWeight += weight3;
      weightedSum += param3 * weight3;
    }
    if (param4 > 0) {
      validTotalWeight += weight4;
      weightedSum += param4 * weight4;
    }

    // If no valid grades, return 0
    if (validTotalWeight == 0) {
      return 0.0;
    }

    // Normalize the weighted sum by the total of valid weights
    // This ensures the result is still a weighted average, but only of exercises with grades
    return weightedSum / validTotalWeight;
  }

  void dropParticipant(int number) {
    var participant = currentEvent.value
        .getParticipantsByStatus(ParticipantStatus.Active)
        .firstWhereOrNull((p) => p.number == number);
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
      bool isInAnyRound = currentEvent.value.meshulashRounds
          .any((round) => round.participantsInRound.contains(number));

      // If not in any round, add to round 0
      if (!isInAnyRound && currentEvent.value.meshulashRounds.isNotEmpty) {
        currentEvent.value.meshulashRounds[0].participantsInRound.add(number);
      }
    } else if (exerciseType == 'sakim') {
      // Check if participant is already in any round
      bool isInAnyRound = currentEvent.value.sakimRounds
          .any((round) => round.participantsInRound.contains(number));

      // If not in any round, add to round 0
      if (!isInAnyRound && currentEvent.value.sakimRounds.isNotEmpty) {
        currentEvent.value.sakimRounds[0].participantsInRound.add(number);
      }
    }

    update(); // Trigger GetX UI refresh
  }

  /// Adds active participants who joined after an exercise started into that
  /// exercise, then saves when the roster changed.
  void syncLateArrivalsIntoOpenExercises() {
    final event = currentEvent.value;
    final numbers = event
        .getParticipantsByStatus(ParticipantStatus.Active)
        .map((participant) => participant.number);
    if (!event.enrollLateArrivals(numbers)) return;
    currentEvent.refresh();
    update();
    if (!event.finalized) {
      saveEventWithOfflineSupport(event);
    }
  }

  calculateGrades() {
    for (Participant p in currentEvent.value
        .getParticipantsByStatus(ParticipantStatus.Active)) {
      // Calculate system grades (from performance data)
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
        weight1: (gradesData.weighted['meshulash'] as num?)?.toDouble() ?? 0.25,
        weight2: (gradesData.weighted['alonka'] as num?)?.toDouble() ?? 0.25,
        weight3: (gradesData.weighted['sakim'] as num?)?.toDouble() ?? 0.25,
        weight4: (gradesData.weighted['bur'] as num?)?.toDouble() ?? 0.25,
      );

      // Note: Final instructor grade is always manual - we don't auto-calculate it
      // The calculated value is only shown as a hint in the UI
      // Trigger refresh so UI can update hints
      currentEvent.refresh();
      update();

      // Use non-blocking save to prevent delays when offline
      if (!currentEvent.value.finalized)
        saveEventWithOfflineSupport(currentEvent.value);
    }
  }

  /// Calculate final instructor grade from weighted average of instructor exercise grades
  /// Only includes exercises with grades > 0
  /// Returns the calculated value without modifying instructorGrade (used as hint/placeholder)
  double getCalculatedInstructorGrade(Participant p) {
    // Get instructor grades for each exercise
    double instructorMeshulash = p.instructorMeshulashGrade.toDouble();
    double instructorAlonka = p.instructorAlonkaGrade.toDouble();
    double instructorSakim = p.instructorSakimGrade.toDouble();

    // Get bur instructor grade from burGrades collection
    double instructorBur = 0.0;
    int burIndex = currentEvent.value.burGrades
        .indexWhere((Bur bur) => bur.id == p.number);
    if (burIndex != -1) {
      instructorBur = currentEvent.value.burGrades[burIndex].burGrade;
    }

    // Calculate weighted average of instructor exercise grades
    // Only include exercises with grades > 0
    double calculatedGrade = calculateWeightedGrade(
      param1: instructorMeshulash,
      param2: instructorAlonka,
      param3: instructorSakim,
      param4: instructorBur,
      weight1: (gradesData.weighted['meshulash'] as num?)?.toDouble() ?? 0.25,
      weight2: (gradesData.weighted['alonka'] as num?)?.toDouble() ?? 0.25,
      weight3: (gradesData.weighted['sakim'] as num?)?.toDouble() ?? 0.25,
      weight4: (gradesData.weighted['bur'] as num?)?.toDouble() ?? 0.25,
    );

    // Return calculated value (keep 2 decimal places)
    return double.parse(calculatedGrade.toStringAsFixed(2));
  }

  /// Calculate instructor grade (for hint display only)
  /// This is called when exercise grades change to update the hint
  /// Does NOT modify instructorGrade - it's only used for displaying the hint
  void calculateInstructorGrade(Participant p) {
    // Just trigger refresh so UI can update the hint
    // The actual instructorGrade value is never auto-updated - it's always manual
    currentEvent.refresh();
    update();
  }

  setParticipantsGrade(int number, dynamic grade) {
    int participantIndex = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    final gradeValue = grade is num
        ? normalizeInstructorGrade(grade)
        : parseInstructorGrade(grade.toString());
    currentEvent.value.participants[participantIndex].instructorGrade =
        gradeValue;
    // Use non-blocking save to prevent delays when offline
    saveEventWithOfflineSupport(currentEvent.value);
    // Trigger refresh to update UI
    currentEvent.refresh();
    update();
  }

  setParticipantExerciseGrade(int number, String exercise, dynamic grade) {
    int participantIndex = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    if (participantIndex == -1) return;

    bool shouldRecalculateSystemGrade = false;

    switch (exercise) {
      case 'meshulash':
        currentEvent
                .value.participants[participantIndex].instructorMeshulashGrade =
            grade is num
                ? normalizeInstructorGrade(grade)
                : parseInstructorGrade(grade.toString());
        // Instructor grade for meshulash doesn't affect system grade (system uses system-calculated grade)
        // But it affects final instructor grade, so recalculate
        calculateInstructorGrade(
            currentEvent.value.participants[participantIndex]);
        break;
      case 'alonka':
        currentEvent
                .value.participants[participantIndex].instructorAlonkaGrade =
            grade is num
                ? normalizeInstructorGrade(grade)
                : parseInstructorGrade(grade.toString());
        // Instructor grade for alonka doesn't affect system grade (system uses system-calculated grade)
        // But it affects final instructor grade, so recalculate
        calculateInstructorGrade(
            currentEvent.value.participants[participantIndex]);
        break;
      case 'sakim':
        currentEvent.value.participants[participantIndex].instructorSakimGrade =
            grade is num
                ? normalizeInstructorGrade(grade)
                : parseInstructorGrade(grade.toString());
        // Instructor grade for sakim doesn't affect system grade (system uses system-calculated grade)
        // But it affects final instructor grade, so recalculate
        calculateInstructorGrade(
            currentEvent.value.participants[participantIndex]);
        break;
      case 'bur':
        // Bur grades are stored only in burGrades collection (single source of truth)
        final burGradeValue = grade is num
            ? normalizeInstructorGrade(grade)
            : parseInstructorGrade(grade.toString());
        int burIndex = currentEvent.value.burGrades
            .indexWhere((Bur bur) => bur.id == number);
        if (burIndex != -1) {
          // Update existing Bur entry
          currentEvent.value.burGrades[burIndex].burGrade = burGradeValue;
        } else {
          // If Bur entry doesn't exist, create it
          Bur newBur = Bur(id: number)..burGrade = burGradeValue;
          currentEvent.value.burGrades.add(newBur);
        }
        // Trigger refresh so UI updates (especially bur page grid)
        currentEvent.refresh();
        update();
        // Bur grade affects both system grade and final instructor grade, so recalculate both
        shouldRecalculateSystemGrade = true;
        calculateInstructorGrade(
            currentEvent.value.participants[participantIndex]);
        break;
    }

    // Only recalculate system grade for bur (since it uses instructor grade)
    // For meshulash/alonka/sakim, system grade uses system-calculated grades, not instructor grades
    if (shouldRecalculateSystemGrade) {
      calculateGrades();
    }

    // Use non-blocking save to prevent delays when offline
    saveEventWithOfflineSupport(currentEvent.value);
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
    int rank =
        sortedParticipants.indexWhere((p) => p.number == participantNumber) + 1;
    if (rank == 0)
      rank = activeParticipants.length; // If not found, assume last

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
    currentEvent.value.participants[participantIndex].participantAIReport =
        report;
    // Use non-blocking save to prevent delays when offline
    saveEventWithOfflineSupport(currentEvent.value);
  }

  /// Cloud
  Future<void> connectionEnabled() async {
    try {
      print("🔍 Starting connectivity check...");

      // Quick connectivity check first (no HTTP)
      var connectivityResult = await Connectivity()
          .checkConnectivity()
          .timeout(Duration(seconds: 2));
      print("🔍 Connectivity result: $connectivityResult");

      // ✅ Check if there is no Wi-Fi or mobile data
      if (connectivityResult == ConnectivityResult.none) {
        print("⚠️ No network available.");
        isConnected.value = false;
        return;
      }

      // On web, skip HTTP check to avoid CORS errors
      // The connectivity_plus check is sufficient for web
      if (kIsWeb) {
        print(
            "🌐 Web platform detected - skipping HTTP check (CORS restrictions).");
        print("✅ Internet connection assumed OK based on connectivity check.");
        isConnected.value = true;
        return;
      }

      // ✅ Check actual internet access using an HTTP request (mobile/desktop only)
      // Single attempt with shorter timeout for faster response
      try {
        print("🔍 Attempting HTTP request to google.com...");
        final response =
            await http.get(Uri.parse("https://www.google.com")).timeout(
          Duration(seconds: 2), // Reduced timeout for faster response
          onTimeout: () {
            print("⚠️ Internet request timed out after 2 seconds.");
            return http.Response('', 500); // Simulate no response
          },
        );

        print("🔍 HTTP response status code: ${response.statusCode}");
        if (response.statusCode == 200) {
          print("✅ Internet connection confirmed.");
          isConnected.value = true;
          return;
        } else {
          print("⚠️ HTTP check returned status code: ${response.statusCode}");
        }
      } catch (e) {
        print("⚠️ HTTP check failed: $e");
      }

      // If HTTP check failed, we're actually offline - don't allow Firestore operations
      // This prevents blocking operations when offline
      print("⚠️ HTTP check failed - device is offline.");
      print("⚠️ Skipping Firestore operations to prevent blocking.");
      isConnected.value =
          false; // Mark as offline to prevent blocking operations
    } catch (e) {
      print("❌ Connectivity check error: $e");
      // Default to offline if check fails
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
  Future<bool> registerDeviceNumber(
      String androidId, String deviceNumber) async {
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

      print(
          '✅ Device number registered: $deviceNumber for Android ID $androidId');
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
        'instructorFullName':
            '${currentInstructor.firstName} ${currentInstructor.lastName}',
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

      print(
          '✅ Device registered: $androidId for instructor ${currentInstructor.id}');
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
          'participantData':
              participant.toJson(), // Full participant data nested
          'eventName': eventName,
          'day': date, // Use 'day' for consistency (renamed from 'date')
          'finalizedAt':
              FieldValue.serverTimestamp(), // When instructor finalized
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

  /// log in (works offline with cached instructors)
  login(String id) async {
    loading.value = true;

    // First check local instructor cache
    var i = getInstructor(id);

    // If not found locally, try loading from local storage
    if (i == null) {
      final localInstructor =
          LocalStorageService.instance.getInstructorLocally(id);
      if (localInstructor != null) {
        // Add to instructorList if not already there
        if (!instructorList.any((inst) => inst.id == id)) {
          instructorList.add(localInstructor);
        }
        i = localInstructor;
      }
    }

    if (i != null) {
      system.value.loggedIn = id;
      system.value.save();
      loggedIn.value = true;
      currentInstructor = i;

      // Register device to Firestore after successful login (non-blocking, background)
      // Don't block login if this fails
      if (isConnected.value) {
        registerDevice().catchError((e) {
          print('⚠️ Device registration failed (non-critical): $e');
        });
      }

      // Load instructor's custom comments after login
      loadInstructorCustomComments().catchError((e) {
        print(
            '⚠️ Failed to load instructor custom comments (non-critical): $e');
      });

      // Load instructor's UX preferences after login
      loadUxPreferences().catchError((e) {
        print('⚠️ Failed to load instructor UX preferences (non-critical): $e');
      });

      loading.value = false;
      return true;
    } else {
      loading.value = false;
      return false;
    }
  }

  getUpdatedInstructorsList() async {
    try {
      // First, try to load from local cache
      final localInstructors =
          await LocalStorageService.instance.loadInstructorsLocally();
      if (localInstructors.isNotEmpty) {
        instructorList = localInstructors;
        print('✅ Loaded ${instructorList.length} instructors from local cache');
      }

      // If online, try to fetch from Firestore and update cache
      if (isConnected.value) {
        try {
          QuerySnapshot querySnapshot =
              await firestore.collection('Instructors').get();
          if (querySnapshot.docs.isNotEmpty) {
            instructorList = querySnapshot.docs.map((doc) {
              return Instructor.fromJson(
                  doc.id, doc.data() as Map<String, dynamic>);
            }).toList();

            // Update local cache
            await LocalStorageService.instance
                .saveInstructorsLocally(instructorList);
            print(
                '✅ Updated instructors cache with ${instructorList.length} instructors from Firestore');
            return instructorList;
          } else {
            print('⚠️ No instructors found in Firestore');
            // Return cached instructors if available
            return localInstructors.isNotEmpty ? instructorList : null;
          }
        } catch (e) {
          print('⚠️ Error fetching instructors from Firestore: $e');
          // Return cached instructors if available
          if (localInstructors.isNotEmpty) {
            return instructorList;
          }
          return null;
        }
      } else {
        // Offline: use cached instructors
        if (localInstructors.isNotEmpty) {
          print('📴 Using cached instructors (offline mode)');
          return instructorList;
        } else {
          print('❌ No cached instructors available and offline');
          return null;
        }
      }
    } catch (e) {
      print('❌ Error in getUpdatedInstructorsList: $e');
      // Try to return cached instructors as fallback
      final localInstructors =
          await LocalStorageService.instance.loadInstructorsLocally();
      if (localInstructors.isNotEmpty) {
        instructorList = localInstructors;
        return instructorList;
      }
      return null;
    }
  }

  checkForLocalLogin() async {
    // Use existing systemBox if already open, otherwise open it
    if (systemBox == null || !systemBox!.isOpen) {
      systemBox = await Hive.openBox('system');
    }
    if (systemBox.length > 0) {
      if (system.value.loggedIn != '') {
        loggedIn.value = true;
        toggleTheme(system.value.isDarkMode);

        // Try to get instructor from local cache first
        var instructor = getInstructor(system.value.loggedIn);

        // If not in instructorList, try loading from local storage
        if (instructor == null) {
          final localInstructor = LocalStorageService.instance
              .getInstructorLocally(system.value.loggedIn);
          if (localInstructor != null) {
            // Add to instructorList if not already there
            if (!instructorList
                .any((inst) => inst.id == system.value.loggedIn)) {
              instructorList.add(localInstructor);
            }
            instructor = localInstructor;
          }
        }

        currentInstructor = instructor ?? currentInstructor;

        // Register device if instructor is logged in (non-blocking, background)
        // Don't block login if this fails or if offline
        if (currentInstructor.id.isNotEmpty && isConnected.value) {
          registerDevice().catchError((e) {
            print('⚠️ Device registration failed (non-critical): $e');
          });
        }

        // Load instructor's custom comments after local login check
        if (currentInstructor.id.isNotEmpty) {
          loadInstructorCustomComments().catchError((e) {
            print(
                '⚠️ Failed to load instructor custom comments (non-critical): $e');
          });
        }

        return true;
      } else {
        print('Not logged in');
        return false;
      }
    }
    return false;
  }

  void toggleTheme(bool isDark) {
    themeController.toggleTheme(isDark);
    Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
    system.value.isDarkMode = isDark;
    system.value.save();
  }

  /// 🎮 Create a playground event with 16 generic participants
  Event _createPlaygroundEvent() {
    final random = Random();
    final Set<int> usedNumbers = {};
    final List<Participant> participants = [];

    // Generate 16 unique random numbers between 85-350
    while (usedNumbers.length < 16) {
      final number = 85 + random.nextInt(350 - 85 + 1); // 85 to 350 inclusive
      if (!usedNumbers.contains(number)) {
        usedNumbers.add(number);
        participants.add(Participant(
          number: number,
          name: 'טירון ${usedNumbers.length}',
        )..status = ParticipantStatus.Active);
      }
    }

    // Sort participants by number
    participants.sort((a, b) => a.number.compareTo(b.number));

    final event = Event(
      date: '01-01-2026',
      instructorId: currentInstructor.id,
      eventName: 'playground',
    )
      ..participants = participants
      ..activeParticipants = List<Participant>.from(participants)
      ..instructorName =
          '${currentInstructor.firstName} ${currentInstructor.lastName}'
      ..groupNumber = 1 // Set groupNumber to pass validation (non-zero)
      ..finalized = false
      ..alonkaSprints = []
      ..sakimRounds = []
      ..meshulashRounds = []
      ..burGrades = []
      ..burStartTime = null
      ..burEndTime = null
      ..alonkaStartTime = null
      ..alonkaEndTime = null
      ..meshulashStartTime = null
      ..meshulashEndTime = null
      ..sakimStartTime = null
      ..sakimEndTime = null;

    return event;
  }

  /// 🎮 Load playground event (loads existing if available, creates new only if needed)
  Future<void> loadPlaygroundEvent() async {
    try {
      currentEventName = 'playground';

      // Try to load existing playground from local storage first
      final existingPlayground = await LocalStorageService.instance
          .loadEventLocally('playground', '01-01-2026', currentInstructor.id);

      if (existingPlayground != null &&
          existingPlayground.participants.isNotEmpty) {
        // Load existing playground
        // Ensure the loaded event has the correct instructor ID (in case instructor changed)
        // Note: eventName, date, and instructorId are final, so they should already be correct from JSON
        currentEvent.value = existingPlayground;

        // Explicitly save to ensure it's persisted (in case of any issues)
        await existingPlayground.saveToLocal();

        print(
            '✅ Loaded existing playground event: ${existingPlayground.participants.length} participants, first participant: ${existingPlayground.participants.first.number}, eventName: ${existingPlayground.eventName}');
        print(
            '   Participants: ${existingPlayground.participants.map((p) => p.number).join(", ")}');
      } else {
        // Create new playground event only if it doesn't exist or is empty
        print(
            '🆕 No existing playground found (or empty), creating new one...');
        if (existingPlayground != null) {
          print(
              '   Existing playground was empty (${existingPlayground.participants.length} participants)');
        }
        final playgroundEvent = _createPlaygroundEvent();
        currentEvent.value = playgroundEvent;

        // Save the new playground to local storage so it persists
        await playgroundEvent.saveToLocal();
        print(
            '✅ Created new playground event: ${playgroundEvent.participants.length} participants, groupNumber: ${playgroundEvent.groupNumber}, first participant: ${playgroundEvent.participants.first.number}');
        print(
            '   Participants: ${playgroundEvent.participants.map((p) => p.number).join(", ")}');
      }

      // Calculate grades synchronously before navigation
      // This ensures the event is fully ready and avoids build phase issues
      calculateGrades();
    } catch (e) {
      print('❌ Error loading playground event: $e');
      // If loading fails, create a new playground as fallback
      try {
        final playgroundEvent = _createPlaygroundEvent();
        currentEvent.value = playgroundEvent;
        await playgroundEvent.saveToLocal();
        calculateGrades();
        print('✅ Created fallback playground event after error');
      } catch (fallbackError) {
        print('❌ Error creating fallback playground: $fallbackError');
      }
    }
  }

  /// 🎮 Delete playground event from Firestore and local storage
  /// This is called when the user saves and closes the playground to reset it
  Future<void> deletePlaygroundEvent() async {
    try {
      // Delete from Firestore
      if (isConnected.value) {
        try {
          await firestore
              .collection('Results')
              .doc(currentInstructor.id)
              .collection('events')
              .doc('playground')
              .collection('days')
              .doc('01-01-2026')
              .delete();
          print('✅ Deleted playground from Firestore');
        } catch (e) {
          print('⚠️ Error deleting playground from Firestore: $e');
        }
      }

      // Delete from local storage
      try {
        await LocalStorageService.instance.deleteEventLocally(
            'playground', '01-01-2026', currentInstructor.id);
        print('✅ Deleted playground from local storage');
      } catch (e) {
        print('⚠️ Error deleting playground from local storage: $e');
      }
    } catch (e) {
      print('❌ Error in deletePlaygroundEvent: $e');
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

  /// 📝 Load instructor's custom comments from Firebase/local storage
  Future<void> loadInstructorCustomComments() async {
    try {
      if (!loggedIn.value || currentInstructor.id.isEmpty) {
        return;
      }

      final comments =
          await InstructorProfileService.loadInstructorCustomComments(
              currentInstructor.id);
      instructorCustomComments.value = comments;
      instructorCustomComments.refresh();
      print(
          '✅ Loaded ${comments.length} custom comment categories for instructor');
    } catch (e) {
      print('❌ Error loading instructor custom comments: $e');
    }
  }

  /// 🎨 Load instructor's UX preferences from Firebase/local storage
  Future<void> loadUxPreferences() async {
    try {
      if (!loggedIn.value || currentInstructor.id.isEmpty) {
        return;
      }

      final prefs = await InstructorProfileService.loadUxPreferences(
          currentInstructor.id);
      uxPreferences.value = prefs;

      // Apply preferences to current state
      userFontSize.value = prefs.fontSize;
      themeController.toggleTheme(prefs.theme == 'dark');

      themeController.toggleTheme(prefs.theme == 'dark');
    } catch (e) {
      print('❌ Error loading instructor UX preferences: $e');
    }
  }

  /// 💾 Update and save instructor's UX preferences
  Future<bool> updateUxPreferences(InstructorUxPreferences newPrefs) async {
    if (!loggedIn.value || currentInstructor.id.isEmpty) {
      print(
          '⚠️ EventController: Cannot save preferences - Not logged in (loggedIn=${loggedIn.value}) or empty instructor ID (id=${currentInstructor.id})');
      return false;
    }

    try {
      // Update local state
      uxPreferences.value = newPrefs;

      // Apply preferences to current state
      userFontSize.value = newPrefs.fontSize;
      themeController.toggleTheme(newPrefs.theme == 'dark');

      // Save to storage
      final success = await InstructorProfileService.saveUxPreferences(
          currentInstructor.id, newPrefs);

      if (success) {
        print(
            '✅ Saved UX preferences for instructor: inOrderOfArrival=${newPrefs.inOrderOfArrival}');
      }

      return success;
    } catch (e) {
      print('❌ Error saving instructor UX preferences: $e');
      return false;
    }
  }

  /// 💾 Save a custom comment to instructor's profile
  Future<bool> saveInstructorCustomComment(
      String exerciseType, String comment) async {
    try {
      if (!loggedIn.value || currentInstructor.id.isEmpty) {
        return false;
      }

      final success = await InstructorProfileService.saveCustomComment(
        currentInstructor.id,
        exerciseType,
        comment,
      );

      if (success) {
        // Reload comments to update UI
        await loadInstructorCustomComments();
      }

      return success;
    } catch (e) {
      print('❌ Error saving instructor custom comment: $e');
      return false;
    }
  }

  /// 🗑️ Remove a custom comment from instructor's profile
  Future<bool> removeInstructorCustomComment(
      String exerciseType, String comment) async {
    try {
      if (!loggedIn.value || currentInstructor.id.isEmpty) {
        return false;
      }

      final success = await InstructorProfileService.removeCustomComment(
        currentInstructor.id,
        exerciseType,
        comment,
      );

      if (success) {
        // Reload comments to update UI
        await loadInstructorCustomComments();
      }

      return success;
    } catch (e) {
      print('❌ Error removing instructor custom comment: $e');
      return false;
    }
  }

  /// 📋 Get instructor's custom comments for a specific exercise type
  List<String> getInstructorCustomCommentsForExercise(String exerciseType) {
    try {
      final List<String> result = [];

      // Add exercise-specific comments
      if (instructorCustomComments.containsKey(exerciseType)) {
        result.addAll(instructorCustomComments[exerciseType]!);
      }

      // Add generic comments
      if (instructorCustomComments.containsKey('generic')) {
        result.addAll(instructorCustomComments['generic']!);
      }

      return result;
    } catch (e) {
      print('❌ Error getting instructor custom comments for exercise: $e');
      return [];
    }
  }
}
