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


class EventController extends GetxController {
  var loading = false.obs;
  var widgetLoading = false.obs;
  var unfinalizedLoading = true.obs; // Start as true to show loading message initially
  var pastEventsLoading = false.obs;
  var backgroundLoading = false.obs; // Track background cache/network loading
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
  /// Grades table sort state (shared with performance page)
  Rx<SortColumn?> sortColumn = SortColumn.systemGrade.obs;
  Rx<SortDirection> sortDirection = SortDirection.descending.obs;
  /// Progress bar state
  RxBool showProgressBar = false.obs;
  /// Instructor custom comments (exercise type -> list of comments)
  RxMap<String, List<String>> instructorCustomComments = <String, List<String>>{}.obs;
  
  /// Retention period for finalized events in local cache (days)
  /// Default: 30 days - finalized events older than this will be cleaned up
  static const int finalizedEventRetentionDays = 30;
  
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
          final gradeA = a.instructorGrade > 0.0 ? a.instructorGrade : getCalculatedInstructorGrade(a);
          final gradeB = b.instructorGrade > 0.0 ? b.instructorGrade : getCalculatedInstructorGrade(b);
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
          comparison = a.instructorMeshulashGrade.compareTo(b.instructorMeshulashGrade);
          break;
        case SortColumn.instructorAlonka:
          comparison = a.instructorAlonkaGrade.compareTo(b.instructorAlonkaGrade);
          break;
        case SortColumn.instructorSakim:
          comparison = a.instructorSakimGrade.compareTo(b.instructorSakimGrade);
          break;
      }

      return sortDirection.value == SortDirection.ascending ? comparison : -comparison;
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
      if (!Hive.isAdapterRegistered(200)) Hive.registerAdapter(AccessibilityAdapter());
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
      if (!Hive.isAdapterRegistered(200)) Hive.registerAdapter(AccessibilityAdapter());
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
      // Don't load unfinalized events here - wait for connectivity check to avoid showing stale data
      // Only load event list from cache (for dropdown, less critical)
      await fetchInstructorEvents(); // Loads from local first
      // Don't auto-load cached event on startup to avoid showing stale data
      // User can manually select an event from the list
      // await restoreSelectedEventAndDay(); // Disabled to prevent flash of stale events
    }
    
    // Step 5: Set loading to false to show UI
    super.onInit();
    loading.value = false;
    
    // Step 6: Do network operations in background (non-blocking)
    backgroundLoading.value = true; // Show background loading indicator
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
        print('🔍 Connectivity check completed. isConnected: ${isConnected.value}');
      } catch (e) {
        print('⚠️ Connectivity check error (non-critical): $e');
        isConnected.value = false;
      }
      
      // Load network-dependent data in background (non-blocking when offline)
      // Only do Firestore operations if online to avoid blocking
      if (isConnected.value) {
        gradesUpdate().catchError((e) {
          print('⚠️ Error updating grades (non-critical): $e');
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
        getSystemSettings(); // Loads from local cache
        getCurrentEventName(); // Loads from local cache
        getUpdatedInstructorsList(); // Loads from local cache
      }
      
      if (loggedIn.value) {
        // Load instructor's custom comments (non-blocking - fire and forget)
        loadInstructorCustomComments().catchError((e) {
          print('⚠️ Error loading custom comments (non-critical): $e');
        });
        
        // Load unfinalized events (from Firestore if online, local if offline)
        // This is done here after connectivity check to avoid showing stale data
        // Don't await - function returns immediately with local events, Firebase fetch happens in background
        getUnfinalizedEvents();
        
        // Cleanup old finalized events from local cache (non-blocking)
        // Run after loading events to ensure we don't delete currently loaded events
        cleanupOldFinalizedEvents().catchError((e) {
          print('⚠️ Error during cleanup of old finalized events (non-critical): $e');
        });
        
        // Refresh events from network in background if online (non-blocking)
        if (isConnected.value) {
          fetchInstructorEvents().then((_) {
            // After syncing, restore and load cached event if it's still valid
            restoreSelectedEventAndDay().catchError((e) {
              print('⚠️ Error restoring selected event (non-critical): $e');
            });
          }).catchError((e) {
            print('⚠️ Error fetching instructor events (non-critical): $e');
          });
        } else {
          // If offline, load from local and restore cached event (non-blocking)
          fetchInstructorEvents().then((_) {
            restoreSelectedEventAndDay().catchError((e) {
              print('⚠️ Error restoring selected event (non-critical): $e');
            });
          }).catchError((e) {
            print('⚠️ Error fetching instructor events from local (non-critical): $e');
          });
        }
        
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
                      converted[entry.key.toString()] = convertValue(entry.value);
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
          DocumentSnapshot docSnapshot =
              await firestore.collection('System').doc('app_system_settings').get();
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
  
  /// 🔎 Get a List of Unfinalized Events for an Instructor in a Specific Event (works offline)
  getUnfinalizedEvents() async {
    AppLogger.debug(" ➡️ get Unfinalized Events.");
    try {
      unfinalizedLoading.value=true;
      unfinalizedEvents.clear();
      
      // If currentEventName is 'playground', load all unfinalized events for the instructor
      // Otherwise, load only events for the current event name
      final shouldLoadAllEvents = currentEventName == 'playground' || currentEventName.isEmpty;
      
      // LOCAL-FIRST STRATEGY: Load from local storage first
      final localEvents = await LocalStorageService.instance.getLocalUnfinalizedEvents();
      // Filter by current instructor, exclude playground
      List<Event> filteredLocalEvents;
      if (shouldLoadAllEvents) {
        // Load all unfinalized events for this instructor (excluding playground)
        filteredLocalEvents = localEvents.where((e) => 
          e.instructorId == currentInstructor.id && 
          e.eventName != 'playground'
        ).toList();
      } else {
        // Load only events for current event name
        filteredLocalEvents = localEvents.where((e) => 
          e.instructorId == currentInstructor.id && 
          e.eventName == currentEventName &&
          e.eventName != 'playground'
        ).toList();
      }
      
      // Start with local events (these are the most up-to-date)
      if (filteredLocalEvents.isNotEmpty) {
        unfinalizedEvents.addAll(filteredLocalEvents);
        print('✅ Loaded ${filteredLocalEvents.length} unfinalized events from local cache');
      }
      
      // Return immediately with local events to avoid blocking UI
      // Firebase fetch will happen in background if online
      unfinalizedLoading.value = false;
      
      // If online, also fetch from Firebase to catch any events that might not be in local cache
      // But don't overwrite local events (local is source of truth)
      // Do this in background (non-blocking) with timeout to prevent delays when offline
      // IMPORTANT: Start this in background but don't await - return immediately
      if (isConnected.value) {
        // Fire and forget - don't await, let it run in background
        unawaited(Future(() async {
          try {
            // Add timeout to prevent blocking when offline but connectivity check says online
            await Future.any([
              Future(() async {
                if (shouldLoadAllEvents) {
            // Load all unfinalized events across all event names for this instructor
            QuerySnapshot eventsSnapshot = await firestore.collection('Results')
                .doc(currentInstructor.id)
                .collection('events')
                .get();
            
            // Merge Firebase events with local (don't overwrite local events)
            // Use a map to track events by key to avoid duplicates
            final Map<String, Event> eventMap = {};
            // First, add all local events to the map (these take priority)
            for (var localEvent in filteredLocalEvents) {
              final key = '${localEvent.eventName}/${localEvent.date}';
              eventMap[key] = localEvent;
            }
            
            for (var eventDoc in eventsSnapshot.docs) {
              if (eventDoc.id == 'playground') continue; // Skip playground
              
              QuerySnapshot daysSnapshot = await firestore.collection('Results')
                  .doc(currentInstructor.id)
                  .collection('events')
                  .doc(eventDoc.id)
                  .collection('days')
                  .where('finalized', isEqualTo: false)
                  .get();
              
              for (var doc in daysSnapshot.docs) {
                Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
                final event = Event.fromJson(docData);
                // Exclude playground events
                if (event.eventName != 'playground') {
                  final key = '${event.eventName}/${event.date}';
                  // Check if event was deleted locally (don't restore deleted events)
                  final isDeleted = await LocalStorageService.instance.isEventDeleted(event.eventName, event.date);
                  if (isDeleted) {
                    print('⚠️ Skipping deleted event from Firebase: $key');
                    continue;
                  }
                  // Only add if not already in map (local events take priority)
                  if (!eventMap.containsKey(key)) {
                    eventMap[key] = event;
                    // Save to local storage for future loads
                    await LocalStorageService.instance.saveEventLocally(event);
                  }
                }
              }
                }
                // Update unfinalizedEvents with merged results
                unfinalizedEvents.clear();
                unfinalizedEvents.addAll(eventMap.values);
                print('✅ Merged ${unfinalizedEvents.length} unfinalized events (local-first, Firebase fallback)');
              } else {
            // Load only for current event name
            QuerySnapshot unfinalizedSnapshot = await firestore.collection('Results')
                .doc(currentInstructor.id)
                .collection('events')
                .doc(currentEventName)
                .collection('days')
                .where('finalized', isEqualTo: false)
                .get();
            
            if (unfinalizedSnapshot.docs.isNotEmpty) {
              // Merge Firebase events with local (don't overwrite local events)
              // Use a map to track events by key to avoid duplicates
              final Map<String, Event> eventMap = {};
              // First, add all local events to the map (these take priority)
              for (var localEvent in filteredLocalEvents) {
                final key = '${localEvent.eventName}/${localEvent.date}';
                eventMap[key] = localEvent;
              }
              
              for (var doc in unfinalizedSnapshot.docs) {
                Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
                final event = Event.fromJson(docData);
                // Exclude playground events
                if (event.eventName != 'playground') {
                  final key = '${event.eventName}/${event.date}';
                  // Check if event was deleted locally (don't restore deleted events)
                  final isDeleted = await LocalStorageService.instance.isEventDeleted(event.eventName, event.date);
                  if (isDeleted) {
                    print('⚠️ Skipping deleted event from Firebase: $key');
                    continue;
                  }
                  // Only add if not already in map (local events take priority)
                  if (!eventMap.containsKey(key)) {
                    eventMap[key] = event;
                    // Save to local storage for future loads
                    await LocalStorageService.instance.saveEventLocally(event);
                  }
                }
                }
                  // Update unfinalizedEvents with merged results
                  unfinalizedEvents.clear();
                  unfinalizedEvents.addAll(eventMap.values);
                  print('✅ Merged ${unfinalizedEvents.length} unfinalized events (local-first, Firebase fallback)');
                }
              }
              }),
              Future.delayed(Duration(seconds: 2), () {
                print('⏱️ Firebase fetch timeout - using local events only');
                throw TimeoutException('Firebase fetch timeout');
              })
            ]);
          } catch (e) {
            if (e is TimeoutException) {
              print("⏱️ Firebase fetch timed out - using local events");
            } else {
              print("⚠️ Error fetching unfinalized events from Firestore: $e");
            }
            // Fall through to use local events
          }
        }).catchError((e) {
          print("⚠️ Background Firebase fetch error: $e");
        }));
      }
      
      // Return immediately - don't wait for Firebase fetch
      // If offline or no events loaded yet, ensure we have local events
      if (!isConnected.value && unfinalizedEvents.isEmpty) {
        // Already loaded local events above, but if we're offline and nothing was loaded, use local
        if (filteredLocalEvents.isNotEmpty) {
          unfinalizedEvents.addAll(filteredLocalEvents);
          print('📴 Using local unfinalized events (offline mode): ${filteredLocalEvents.length} events');
        }
      }
      
      // Final check: if still empty and we have local events, use them
      if (unfinalizedEvents.isEmpty && filteredLocalEvents.isNotEmpty) {
        unfinalizedEvents.addAll(filteredLocalEvents);
        print('✅ Using local unfinalized events as fallback: ${filteredLocalEvents.length} events');
      }
    } catch (e) {
      unfinalizedLoading.value=false;
      print("❌ Error in getUnfinalizedEvents: $e");
    }
    // Ensure loading is false (already set above, but ensure it's set on error paths)
    unfinalizedLoading.value=false;
    // Return immediately - function completes here, Firebase fetch continues in background
    return unfinalizedEvents;
  }

  /// 📂 Fetch Main Event list from firebase Where Current Instructor Has Data for dropdown (works offline)
  Future<void> fetchInstructorEvents() async {
    pastEventsLoading.value=true;
    try {
      // First, load from local cache
      final localEventList = await LocalStorageService.instance.getLocalEventList();
      if (localEventList.isNotEmpty) {
        final filteredList = localEventList
            .where((eventName) => eventName != 'playground')
            .toList();
        events.value = filteredList;
        print('✅ Loaded ${filteredList.length} events from local cache (playground filtered)');
      }
      
      // If online, sync with Firestore and update cache
      if (isConnected.value) {
        try {
          QuerySnapshot eventsSnapshot = await firestore.collection('Results').doc(currentInstructor.id).collection('events').get();
          if (eventsSnapshot.docs.isNotEmpty) {
            events.value = eventsSnapshot.docs
                .map((doc) => doc.id)
                .where((eventName) => eventName != 'playground')
                .toList();
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
            print('✅ Synced ${events.length} events from Firestore');
          } else {
            print('⚠️ No Main Events Found in Firestore');
            // Keep using local events if available
          }
        } catch (e) {
          print('⚠️ Error fetching events from Firestore: $e');
          // Keep using local events if Firestore fetch fails
        }
      } else {
        print('📴 Using local event list (offline mode)');
      }
    } catch (e) {
      print('❌ Error in fetchInstructorEvents: $e');
    }
    pastEventsLoading.value=false;
    AppLogger.debug("📂 Found events: ${events.toList()}");
  }

  /// 📅 Fetch Available Days for Selected Event
  Future<void> fetchEventDays(String eventName) async {
    pastEventsLoading.value = true;
    // Skip fetching days for playground
    if (eventName == 'playground') {
      pastEventsLoading.value = false;
      return;
    }
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

  /// 📥 Load Selected Event for the Instructor (works offline, local-first)
  /// Always prioritizes local cache to prevent stale cloud data from overwriting fresh local data
  Future<void> loadInstructorEvent(String eventName, String day) async {
    pastEventsLoading.value = true;
    try {
      // Clear current event to avoid showing stale data during load
      // Only clear if we're loading a different event than what's currently loaded
      if (currentEvent.value.eventName != eventName || currentEvent.value.date != day) {
        currentEvent.value = Event(date: '', instructorId: '', eventName: '');
      }
      
      // LOCAL-FIRST STRATEGY: Always try local cache first
      // This prevents stale Firebase data from overwriting fresh local data
      final localEvent = await LocalStorageService.instance.loadEventLocally(eventName, day);
      if (localEvent != null) {
        currentEvent.value = localEvent;
        print('✅ Loaded event from local cache (local-first): $eventName - $day');
        pastEventsLoading.value = false;
        return; // Successfully loaded from local cache, exit early
      }
      
      // If local cache doesn't exist or failed, try Firebase as fallback
      if (isConnected.value) {
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
            currentEvent.value = Event.fromJson(eventData);
            
            // Update local cache for future loads
            await LocalStorageService.instance.saveEventLocally(currentEvent.value);
            print('✅ Loaded event from Firebase (fallback, cached locally): $eventName - $day');
            pastEventsLoading.value = false;
            return; // Successfully loaded from Firebase, exit early
          }
        } catch (e) {
          print("⚠️ Error loading event from Firestore: $e");
          // Fall through to error message
        }
      }
      
      // Neither local nor Firebase had the event
      print('⚠️ Event not found in local cache or Firebase: $eventName - $day');
    } catch (e) {
      pastEventsLoading.value = false;
      print("❌ Error in loadInstructorEvent: $e");
    } finally {
      pastEventsLoading.value = false;
    }
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
          
          if (cachedEventName != null && cachedEventName.isNotEmpty && cachedEventName != 'NA') {
            currentEventName = cachedEventName;
            print('✅ Loaded current event name from local cache: $currentEventName');
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
              print('✅ Updated current event name cache from Firestore: $currentEventName');
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

  /// Save selected event and day to cache
  Future<void> saveSelectedEventAndDay(String? event, String? day) async {
    try {
      if (systemBox != null) {
        if (event != null) {
          await systemBox!.put('selectedEvent', event);
        }
        if (day != null) {
          await systemBox!.put('selectedDay', day);
        }
        print('✅ Saved selected event and day to cache: $event / $day');
      }
    } catch (e) {
      print('⚠️ Error saving selected event and day: $e');
    }
  }

  /// Restore selected event and day from cache, then load the event
  Future<void> restoreSelectedEventAndDay() async {
    try {
      if (systemBox != null) {
        // Restore selected event
        if (systemBox!.containsKey('selectedEvent')) {
          try {
            final cachedEventData = systemBox!.get('selectedEvent');
            String? cachedEvent;
            if (cachedEventData is String) {
              cachedEvent = cachedEventData;
            } else if (cachedEventData != null) {
              cachedEvent = cachedEventData.toString();
            }
            
            if (cachedEvent != null && cachedEvent.isNotEmpty) {
              selectedEvent.value = cachedEvent;
              print('✅ Restored selected event from cache: $cachedEvent');
            }
          } catch (e) {
            print('⚠️ Error restoring selected event: $e');
          }
        }

        // Restore selected day
        if (systemBox!.containsKey('selectedDay')) {
          try {
            final cachedDayData = systemBox!.get('selectedDay');
            String? cachedDay;
            if (cachedDayData is String) {
              cachedDay = cachedDayData;
            } else if (cachedDayData != null) {
              cachedDay = cachedDayData.toString();
            }
            
            if (cachedDay != null && cachedDay.isNotEmpty) {
              selectedDay.value = cachedDay;
              print('✅ Restored selected day from cache: $cachedDay');
            }
          } catch (e) {
            print('⚠️ Error restoring selected day: $e');
          }
        }

        // If both event and day are available, verify the event still exists in current unfinalized events
        // This prevents loading stale cached events that no longer exist or are from different dates
        if (selectedEvent.value != null && selectedDay.value != null) {
          // Check if this event/day combination exists in the current unfinalized events list
          bool eventExistsInUnfinalized = unfinalizedEvents.any((e) => 
            e.eventName == selectedEvent.value && e.date == selectedDay.value
          );
          
          if (!eventExistsInUnfinalized) {
            // Cached event is not in current unfinalized events, clear the cache
            print('⚠️ Cached event not in current unfinalized events, clearing cache: ${selectedEvent.value} / ${selectedDay.value}');
            selectedEvent.value = null;
            selectedDay.value = null;
            await saveSelectedEventAndDay(null, null);
            return; // Don't load stale event
          }
          
          // Check if the event still exists in local storage before auto-loading
          final cachedEvent = await LocalStorageService.instance.loadEventLocally(
            selectedEvent.value!, 
            selectedDay.value!
          );
          
          if (cachedEvent != null) {
            // Verify the cached event matches currentEventName (if set) to avoid loading wrong events
            // Only auto-load if it's a valid, current event
            bool shouldLoad = true;
            if (currentEventName.isNotEmpty && cachedEvent.eventName != currentEventName) {
              print('⚠️ Cached event name mismatch: cached=${cachedEvent.eventName}, current=$currentEventName');
              shouldLoad = false;
            }
            
            if (shouldLoad) {
              print('🔄 Auto-loading cached event: ${selectedEvent.value} / ${selectedDay.value}');
              await loadInstructorEvent(selectedEvent.value!, selectedDay.value!);
            } else {
              // Clear stale cache if event doesn't match
              print('⚠️ Cached event is stale, clearing cache: ${selectedEvent.value} / ${selectedDay.value}');
              selectedEvent.value = null;
              selectedDay.value = null;
              await saveSelectedEventAndDay(null, null);
            }
          } else {
            // Clear stale cache if event no longer exists
            print('⚠️ Cached event no longer exists, clearing cache: ${selectedEvent.value} / ${selectedDay.value}');
            selectedEvent.value = null;
            selectedDay.value = null;
            await saveSelectedEventAndDay(null, null);
          }
        }
      }
    } catch (e) {
      print('❌ Error in restoreSelectedEventAndDay: $e');
    }
  }

  /// Helper method to save event with offline support
  /// Always saves locally first, then syncs to Firestore if online (non-blocking)
  Future<bool> saveEventWithOfflineSupport(Event event, {bool isCreate = false}) async {
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
  void _saveToFirestoreInBackground(Event event, {bool isCreate = false}) async {
    try {
      // Check connectivity before attempting Firestore save
      if (!isConnected.value) {
        // Offline: queue for sync when internet becomes available
        await SyncQueueService.instance.queueFirestoreOperation(
          isCreate ? 'createEvent' : 'saveEvent', 
          event.toJson()
        );
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
            await SyncQueueService.instance.queueFirestoreOperation('createEvent', event.toJson());
            print('⚠️ Firestore create failed, queued for retry');
          }
        } else {
          final firestoreSuccess = await event.saveToFirestore();
          if (firestoreSuccess) {
            print('✅ Event saved to Firestore');
            // Note: isBackedUp flag is set in saveToFirestore() method
          } else {
            // Queue for retry
            await SyncQueueService.instance.queueFirestoreOperation('saveEvent', event.toJson());
            print('⚠️ Firestore save failed, queued for retry');
          }
        }
        // Note: Playground is NOT deleted here - it persists like a real event
        // It will only be deleted when user explicitly saves/closes it
      } catch (e) {
        print('⚠️ Error saving to Firestore: $e, queuing for retry');
        // Queue for retry
        await SyncQueueService.instance.queueFirestoreOperation(
          isCreate ? 'createEvent' : 'saveEvent', 
          event.toJson()
        );
      }
    } catch (e) {
      print('❌ Error in _saveToFirestoreInBackground: $e');
      // Even if background save fails, queue it for later
      try {
        await SyncQueueService.instance.queueFirestoreOperation(
          isCreate ? 'createEvent' : 'saveEvent', 
          event.toJson()
        );
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
    await saveEventWithOfflineSupport(event, isCreate: true);
    loading.value = false;
  }

  delEvent(Event event) async {
    try {
      // 🔒 Safety check: If this is the currently loaded event, clear it first
      final isCurrentEvent = currentEvent.value.eventName == event.eventName && 
                             currentEvent.value.date == event.date;
      if (isCurrentEvent) {
        print('⚠️ Deleting currently loaded event - clearing currentEvent first');
        currentEvent.value = Event(date: '', instructorId: '', eventName: '');
        currentEvent.refresh();
      }
      
      // 🔥 Step 1: Delete from local storage first (immediate, works offline)
      await LocalStorageService.instance.deleteEventLocally(event.eventName, event.date);
      
      // 🔥 Step 2: Refresh eventDays cache for this event
      if (eventDays.containsKey(event.eventName)) {
        eventDays[event.eventName]?.remove(event.date);
        if (eventDays[event.eventName]!.isEmpty) {
          eventDays.remove(event.eventName);
        }
      }
      
      // 🔥 Step 3: Delete from Firestore (queue if offline, execute if online)
      if (isConnected.value) {
        // Online: Delete from Firestore immediately
        Future(() async {
          try {
            await deleteEventFromFirestore(event);
            // Unmark as deleted after successful Firebase deletion
            await LocalStorageService.instance.unmarkEventAsDeleted(event.eventName, event.date);
            print("✅ Event '${event.date}' deleted successfully from Firestore.");
          } catch (e) {
            print("❌ Error deleting event from Firestore: $e");
            // If Firestore delete fails, queue it for retry
            await SyncQueueService.instance.queueFirestoreOperation(
              'deleteEvent',
              {
                'eventName': event.eventName,
                'date': event.date,
                'instructorId': event.instructorId,
                'groupNumber': event.groupNumber,
              }
            );
            // Keep it marked as deleted until Firebase deletion succeeds
          }
        }).catchError((e) {
          print('❌ Error in background Firestore delete: $e');
        });
      } else {
        // Offline: Queue deletion for sync when online
        print('📴 Offline: Event deleted locally, queuing Firestore delete for sync');
        await SyncQueueService.instance.queueFirestoreOperation(
          'deleteEvent',
          {
            'eventName': event.eventName,
            'date': event.date,
            'instructorId': event.instructorId,
            'groupNumber': event.groupNumber,
          }
        );
        
        // Track deleted event locally to prevent restoration from Firebase
        await LocalStorageService.instance.markEventAsDeleted(event.eventName, event.date);
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
      DocumentReference eventRef = firestore.collection('Results')
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
      DocumentReference adminRef = firestore.collection('AdminIndex')
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
        item is Map<String, dynamic> && item['instructorId'] == event.instructorId);
        await adminRef.update({'groupsAndInstructors': groupsArray}).timeout(Duration(seconds: 3));
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

  /// Remove the last position from sakimPositions array (for undo)
  void removeLastSakimPosition(int number) {
    int participantIndex = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    if (participantIndex != -1 && currentEvent.value.participants[participantIndex].sakimPositions.isNotEmpty) {
      currentEvent.value.participants[participantIndex].sakimPositions.removeLast();
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
        currentEvent.value.participants[participantIndex].lastSakimIndexStack.clear();
      } else {
        // Push index to stack
        currentEvent.value.participants[participantIndex].lastSakimIndexStack.add(index);
      }
    }
  }

  /// Pop and return the last sakim index from stack (for undo tracking)
  /// Returns null if stack is empty
  int? getLastSakimIndex(int number) {
    int participantIndex = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    if (participantIndex != -1) {
      final stack = currentEvent.value.participants[participantIndex].lastSakimIndexStack;
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
      currentEvent.value.participants[participantIndex].lastSakimIndexStack.clear();
    }
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
    if (participantIndex != -1 && currentEvent.value.participants[participantIndex].meshulashPositions.isNotEmpty) {
      currentEvent.value.participants[participantIndex].meshulashPositions.removeLast();
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
        currentEvent.value.participants[participantIndex].lastMeshulashIndexStack.clear();
      } else {
        // Push index to stack
        currentEvent.value.participants[participantIndex].lastMeshulashIndexStack.add(index);
      }
    }
  }

  /// Pop and return the last meshulash index from stack (for undo tracking)
  /// Returns null if stack is empty
  int? getLastMeshulashIndex(int number) {
    int participantIndex = currentEvent.value.participants
        .indexWhere((Participant p) => p.number == number);
    if (participantIndex != -1) {
      final stack = currentEvent.value.participants[participantIndex].lastMeshulashIndexStack;
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
      currentEvent.value.participants[participantIndex].lastMeshulashIndexStack.clear();
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
      currentEvent.value.participants[index].meshulashInstructorComments = comments;
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
      currentEvent.value.participants[index].alonkaInstructorComments = comments;
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
      currentEvent.value.participants[index].interviewInstructorComments = comments;
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
      currentEvent.value.participants[index].genericInstructorComments = comments;
      print("✅ Generic comments saved successfully: ${comments}");
      // Use non-blocking save to prevent delays when offline
      saveEventWithOfflineSupport(currentEvent.value);
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
    int burIndex = currentEvent.value.burGrades.indexWhere((Bur bur) => bur.id == participantNumber);
    
    if (burIndex != -1) {
      // Get the existing comments
      List<String> existingComments = currentEvent.value.burGrades[burIndex].instructorComments;
      
      // Add new comment if it doesn't already exist (merge, don't replace)
      if (!existingComments.contains(comment)) {
        existingComments.add(comment);
        currentEvent.value.burGrades[burIndex].instructorComments = existingComments;
        print("✅ Bur comment added successfully to participant $participantNumber: $comment");
        // Use non-blocking save to prevent delays when offline
        saveEventWithOfflineSupport(currentEvent.value);
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
    if (participantBurIndex == -1) return 0; // Participant not found in burGrades
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
      if (!currentEvent.value.finalized) saveEventWithOfflineSupport(currentEvent.value);
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
    int burIndex = currentEvent.value.burGrades.indexWhere((Bur bur) => bur.id == p.number);
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
    // Convert to double and round to 2 decimal places
    double gradeValue = grade is double ? grade : (grade as num).toDouble();
    currentEvent.value.participants[participantIndex].instructorGrade = 
        double.parse(gradeValue.toStringAsFixed(2));
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
        // Convert to double and round to 2 decimal places
        double meshulashGradeValue = grade is double ? grade : (grade as num).toDouble();
        currentEvent.value.participants[participantIndex].instructorMeshulashGrade = 
            double.parse(meshulashGradeValue.toStringAsFixed(2));
        // Instructor grade for meshulash doesn't affect system grade (system uses system-calculated grade)
        // But it affects final instructor grade, so recalculate
        calculateInstructorGrade(currentEvent.value.participants[participantIndex]);
        break;
      case 'alonka':
        // Convert to double and round to 2 decimal places
        double alonkaGradeValue = grade is double ? grade : (grade as num).toDouble();
        currentEvent.value.participants[participantIndex].instructorAlonkaGrade = 
            double.parse(alonkaGradeValue.toStringAsFixed(2));
        // Instructor grade for alonka doesn't affect system grade (system uses system-calculated grade)
        // But it affects final instructor grade, so recalculate
        calculateInstructorGrade(currentEvent.value.participants[participantIndex]);
        break;
      case 'sakim':
        // Convert to double and round to 2 decimal places
        double sakimGradeValue = grade is double ? grade : (grade as num).toDouble();
        currentEvent.value.participants[participantIndex].instructorSakimGrade = 
            double.parse(sakimGradeValue.toStringAsFixed(2));
        // Instructor grade for sakim doesn't affect system grade (system uses system-calculated grade)
        // But it affects final instructor grade, so recalculate
        calculateInstructorGrade(currentEvent.value.participants[participantIndex]);
        break;
      case 'bur':
        // Bur grades are stored only in burGrades collection (single source of truth)
        // Bur has no system grade, only instructor grade, so it affects system grade calculation
        // Grade can be int or double for Bur
        double burGradeValue;
        if (grade is double) {
          burGradeValue = grade;
        } else {
          burGradeValue = (grade as num).toDouble();
        }
        int burIndex = currentEvent.value.burGrades.indexWhere((Bur bur) => bur.id == number);
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
        calculateInstructorGrade(currentEvent.value.participants[participantIndex]);
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
    // Use non-blocking save to prevent delays when offline
    saveEventWithOfflineSupport(currentEvent.value);
  }

  /// Cloud
  Future<void> connectionEnabled() async {
    try {
      print("🔍 Starting connectivity check...");
      
      // Quick connectivity check first (no HTTP)
      var connectivityResult = await Connectivity().checkConnectivity()
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
        print("🌐 Web platform detected - skipping HTTP check (CORS restrictions).");
        print("✅ Internet connection assumed OK based on connectivity check.");
        isConnected.value = true;
        return;
      }

      // ✅ Check actual internet access using an HTTP request (mobile/desktop only)
      // Single attempt with shorter timeout for faster response
      try {
        print("🔍 Attempting HTTP request to google.com...");
        final response = await http.get(Uri.parse("https://www.google.com")).timeout(
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
      isConnected.value = false; // Mark as offline to prevent blocking operations
      
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
      final localInstructor = LocalStorageService.instance.getInstructorLocally(id);
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
        print('⚠️ Failed to load instructor custom comments (non-critical): $e');
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
      final localInstructors = await LocalStorageService.instance.loadInstructorsLocally();
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
            await LocalStorageService.instance.saveInstructorsLocally(instructorList);
            print('✅ Updated instructors cache with ${instructorList.length} instructors from Firestore');
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
      final localInstructors = await LocalStorageService.instance.loadInstructorsLocally();
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
        //print('logged in');
        loggedIn.value = true;
        toggleTheme(system.value.isDarkMode);
        
        // Try to get instructor from local cache first
        var instructor = getInstructor(system.value.loggedIn);
        
        // If not in instructorList, try loading from local storage
        if (instructor == null) {
          final localInstructor = LocalStorageService.instance.getInstructorLocally(system.value.loggedIn);
          if (localInstructor != null) {
            // Add to instructorList if not already there
            if (!instructorList.any((inst) => inst.id == system.value.loggedIn)) {
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
            print('⚠️ Failed to load instructor custom comments (non-critical): $e');
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
      ..instructorName = '${currentInstructor.firstName} ${currentInstructor.lastName}'
      ..groupNumber = 1  // Set groupNumber to pass validation (non-zero)
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
      final existingPlayground = await LocalStorageService.instance.loadEventLocally('playground', '01-01-2026');
      
      if (existingPlayground != null && existingPlayground.participants.isNotEmpty) {
        // Load existing playground
        // Ensure the loaded event has the correct instructor ID (in case instructor changed)
        // Note: eventName, date, and instructorId are final, so they should already be correct from JSON
        currentEvent.value = existingPlayground;
        
        // Explicitly save to ensure it's persisted (in case of any issues)
        await existingPlayground.saveToLocal();
        
        print('✅ Loaded existing playground event: ${existingPlayground.participants.length} participants, first participant: ${existingPlayground.participants.first.number}, eventName: ${existingPlayground.eventName}');
        print('   Participants: ${existingPlayground.participants.map((p) => p.number).join(", ")}');
      } else {
        // Create new playground event only if it doesn't exist or is empty
        print('🆕 No existing playground found (or empty), creating new one...');
        if (existingPlayground != null) {
          print('   Existing playground was empty (${existingPlayground.participants.length} participants)');
        }
        final playgroundEvent = _createPlaygroundEvent();
        currentEvent.value = playgroundEvent;
        
        // Save the new playground to local storage so it persists
        await playgroundEvent.saveToLocal();
        print('✅ Created new playground event: ${playgroundEvent.participants.length} participants, groupNumber: ${playgroundEvent.groupNumber}, first participant: ${playgroundEvent.participants.first.number}');
        print('   Participants: ${playgroundEvent.participants.map((p) => p.number).join(", ")}');
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
        await LocalStorageService.instance.deleteEventLocally('playground', '01-01-2026');
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
      Instructor instructor = instructorList.firstWhere((i) => i.id == instructorId);
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
      
      final comments = await InstructorProfileService.loadInstructorCustomComments(currentInstructor.id);
      instructorCustomComments.value = comments;
      instructorCustomComments.refresh();
      print('✅ Loaded ${comments.length} custom comment categories for instructor');
    } catch (e) {
      print('❌ Error loading instructor custom comments: $e');
    }
  }

  /// 💾 Save a custom comment to instructor's profile
  Future<bool> saveInstructorCustomComment(String exerciseType, String comment) async {
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
  Future<bool> removeInstructorCustomComment(String exerciseType, String comment) async {
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

  /// Cleanup old finalized events from local cache
  /// This is called on app initialization and after event finalization
  /// Excludes currently loaded events for safety
  Future<void> cleanupOldFinalizedEvents() async {
    try {
      // Build list of event keys to exclude (currently loaded events)
      List<String> excludeKeys = [];
      
      // Exclude currently loaded event if it exists
      if (currentEvent.value.eventName.isNotEmpty && 
          currentEvent.value.date.isNotEmpty) {
        excludeKeys.add('${currentEvent.value.eventName}/${currentEvent.value.date}');
      }
      
      // Exclude all unfinalized events (they should never be deleted)
      for (var event in unfinalizedEvents) {
        if (event.eventName.isNotEmpty && event.date.isNotEmpty) {
          excludeKeys.add('${event.eventName}/${event.date}');
        }
      }
      
      // Run cleanup with safety exclusions
      final deletedCount = await LocalStorageService.instance.cleanupOldFinalizedEvents(
        retentionDays: finalizedEventRetentionDays,
        excludeEventKeys: excludeKeys,
      );
      
      if (deletedCount > 0) {
        print('🧹 Cleaned up $deletedCount old finalized event(s) from local cache');
      }
    } catch (e) {
      print('❌ Error in cleanupOldFinalizedEvents: $e');
    }
  }
}
