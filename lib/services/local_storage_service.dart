import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../models/event.dart';
import '../models/instructor.dart';
import '../models/instructor_ux_preferences.dart';
import 'dart:convert';

/// Service for managing local Hive storage of events and instructors
class LocalStorageService {
  static LocalStorageService? _instance;
  static LocalStorageService get instance {
    _instance ??= LocalStorageService._();
    return _instance!;
  }

  LocalStorageService._();

  Box<dynamic>? _eventsBox;
  Box<Instructor>? _instructorsBox;
  Box<dynamic>? _deletedEventsBox;

  /// Initialize Hive boxes for local storage
  Future<void> initialize() async {
    try {
      // Instructor adapter should already be registered in event_controller.dart
      // Just verify it's registered
      if (!Hive.isAdapterRegistered(103)) {
        print(
            '⚠️ Warning: Instructor adapter (103) not registered. Please register it in event_controller.dart');
      }

      // Open or create boxes
      if (kIsWeb) {
        _eventsBox = await Hive.openBox('events');
        _instructorsBox = await Hive.openBox<Instructor>('instructors');
        _deletedEventsBox = await Hive.openBox('deleted_events');
      } else {
        var dir = await getApplicationDocumentsDirectory();
        _eventsBox = await Hive.openBox('events', path: dir.path);
        _instructorsBox =
            await Hive.openBox<Instructor>('instructors', path: dir.path);
        _deletedEventsBox =
            await Hive.openBox('deleted_events', path: dir.path);
      }
    } catch (e) {
      print('❌ Error initializing LocalStorageService: $e');
    }
  }

  /// Save event to local Hive storage
  /// Key format: "{eventName}/{date}"
  Future<bool> saveEventLocally(Event event) async {
    try {
      if (_eventsBox == null) await initialize();

      final key = '${event.instructorId}/${event.eventName}/${event.date}';
      final eventJson = event.toJson();

      await _eventsBox!.put(key, jsonEncode(eventJson));

      print('✅ Event saved locally: $key');
      return true;
    } catch (e) {
      print('❌ Error saving event locally: $e');
      return false;
    }
  }

  /// Load event from local Hive storage
  /// [instructorId] - Required to scope the search to the correct instructor
  Future<Event?> loadEventLocally(
      String eventName, String date, String instructorId) async {
    try {
      if (_eventsBox == null) await initialize();

      // New key format: "{instructorId}/{eventName}/{date}"
      final newKey = '$instructorId/$eventName/$date';
      var eventData = _eventsBox!.get(newKey);

      if (eventData != null) {
        final eventJson =
            jsonDecode(eventData as String) as Map<String, dynamic>;
        return Event.fromJson(eventJson);
      }

      return null;
    } catch (e) {
      print('❌ Error loading event locally: $e');
      return null;
    }
  }

  /// Get all unfinalized events from local storage for a specific instructor
  Future<List<Event>> getLocalUnfinalizedEvents(String instructorId) async {
    try {
      if (_eventsBox == null) await initialize();

      List<Event> events = [];

      for (var key in _eventsBox!.keys) {
        try {
          // STRICT FILTER: Only consider keys belonging to this instructor
          // Key format: instructorId/eventName/date
          // This ignores legacy unscoped keys ("eventName/date")
          if (!key.toString().startsWith('$instructorId/')) {
            continue;
          }

          final eventData = _eventsBox!.get(key);
          if (eventData != null) {
            final eventJson =
                jsonDecode(eventData as String) as Map<String, dynamic>;
            final event = Event.fromJson(eventJson);

            // Filter by instructor ID
            if (event.instructorId != instructorId) {
              continue;
            }

            // Only include unfinalized events
            if (!event.finalized) {
              events.add(event);
            }
          }
        } catch (e) {
          print('❌ Error parsing event $key: $e');
          continue;
        }
      }

      return events;
    } catch (e) {
      print('❌ Error getting local unfinalized events: $e');
      return [];
    }
  }

  /// Every locally stored event for this instructor, including closed days.
  Future<List<Event>> getLocalEvents(String instructorId) async {
    try {
      if (_eventsBox == null) await initialize();

      final events = <Event>[];
      for (final key in _eventsBox!.keys) {
        try {
          if (!key.toString().startsWith('$instructorId/')) continue;
          final eventData = _eventsBox!.get(key);
          if (eventData == null) continue;
          final eventJson =
              jsonDecode(eventData as String) as Map<String, dynamic>;
          final event = Event.fromJson(eventJson);
          if (event.instructorId != instructorId) continue;
          events.add(event);
        } catch (e) {
          print('❌ Error parsing event $key: $e');
        }
      }
      return events;
    } catch (e) {
      print('❌ Error getting local events: $e');
      return [];
    }
  }

  /// Delete event from local storage
  Future<bool> deleteEventLocally(
      String eventName, String date, String instructorId) async {
    try {
      if (_eventsBox == null) await initialize();

      // Try new key
      final newKey = '$instructorId/$eventName/$date';
      if (_eventsBox!.containsKey(newKey)) {
        await _eventsBox!.delete(newKey);
        print('✅ Event deleted locally: $newKey');
      }

      return true;
    } catch (e) {
      print('❌ Error deleting event locally: $e');
      return false;
    }
  }

  /// Mark event as deleted to prevent restoration from Firebase
  Future<bool> markEventAsDeleted(
      String eventName, String date, String instructorId) async {
    try {
      if (_deletedEventsBox == null) await initialize();

      final key = '$instructorId/$eventName/$date';
      await _deletedEventsBox!.put(key, true);

      // Also support legacy key for consistency? No, deleted events are just flags.
      // If we used a legacy key before, we should check it too.

      print('✅ Event marked as deleted: $key');
      return true;
    } catch (e) {
      print('❌ Error marking event as deleted: $e');
      return false;
    }
  }

  /// Check if event is marked as deleted
  Future<bool> isEventDeleted(
      String eventName, String date, String instructorId) async {
    try {
      if (_deletedEventsBox == null) await initialize();

      // Check new key
      final newKey = '$instructorId/$eventName/$date';
      return _deletedEventsBox!.get(newKey, defaultValue: false) as bool;
    } catch (e) {
      print('❌ Error checking if event is deleted: $e');
      return false;
    }
  }

  /// Remove event from deleted events list (after successful Firebase deletion)
  Future<bool> unmarkEventAsDeleted(
      String eventName, String date, String instructorId) async {
    try {
      if (_deletedEventsBox == null) await initialize();

      final charKey = '$instructorId/$eventName/$date';
      await _deletedEventsBox!.delete(charKey);

      print('✅ Event unmarked as deleted: $charKey');
      return true;
    } catch (e) {
      print('❌ Error unmarking event as deleted: $e');
      return false;
    }
  }

  /// Keep this instructor's playground and [keep]. Delete every other local day.
  Future<void> pruneLocalEvents({
    required String instructorId,
    Event? keep,
  }) async {
    try {
      if (instructorId.isEmpty) return;
      if (_eventsBox == null) await initialize();

      final keys = _eventsBox!.keys.toList();
      for (final key in keys) {
        final keyString = key.toString();
        if (!keyString.startsWith('$instructorId/')) continue;

        try {
          final eventData = _eventsBox!.get(key);
          if (eventData == null) {
            await _eventsBox!.delete(key);
            continue;
          }

          final eventJson =
              jsonDecode(eventData as String) as Map<String, dynamic>;
          final event = Event.fromJson(eventJson);

          if (event.eventName == 'playground') continue;
          // A close that has not reached Firestore yet must stay on the device.
          if (event.finalized && !event.isBackedUp) continue;
          if (keep != null &&
              event.instructorId == keep.instructorId &&
              event.eventName == keep.eventName &&
              event.date == keep.date) {
            continue;
          }

          await _eventsBox!.delete(key);
          print('🗑️ Pruned local event: $keyString');
        } catch (e) {
          print('❌ Error pruning event $keyString: $e');
          await _eventsBox!.delete(key);
        }
      }
    } catch (e) {
      print('❌ Error pruning local events: $e');
    }
  }

  /// Save instructors list to local storage
  Future<bool> saveInstructorsLocally(List<Instructor> instructors) async {
    try {
      if (_instructorsBox == null) await initialize();

      // Clear existing instructors
      await _instructorsBox!.clear();

      // Save each instructor with their ID as key
      for (var instructor in instructors) {
        await _instructorsBox!.put(instructor.id, instructor);
      }

      print('✅ Instructors saved locally: ${instructors.length}');
      return true;
    } catch (e) {
      print('❌ Error saving instructors locally: $e');
      return false;
    }
  }

  /// Load instructors list from local storage
  Future<List<Instructor>> loadInstructorsLocally() async {
    try {
      if (_instructorsBox == null) await initialize();

      return _instructorsBox!.values.toList();
    } catch (e) {
      print('❌ Error loading instructors locally: $e');
      return [];
    }
  }

  /// Get instructor by ID from local storage
  Instructor? getInstructorLocally(String id) {
    try {
      if (_instructorsBox == null) {
        // Try to initialize synchronously (not ideal but needed for getter)
        return null;
      }
      return _instructorsBox!.get(id);
    } catch (e) {
      print('❌ Error getting instructor locally: $e');
      return null;
    }
  }

  /// Clear all local event data (for testing/cleanup)
  Future<void> clearAllEvents() async {
    try {
      if (_eventsBox != null) await _eventsBox!.clear();
      print('✅ All local events cleared');
    } catch (e) {
      print('❌ Error clearing events: $e');
    }
  }

  Box<dynamic>? _instructorCustomCommentsBox;

  /// Initialize instructor custom comments box
  Future<void> _initInstructorCustomCommentsBox() async {
    if (_instructorCustomCommentsBox == null) {
      if (kIsWeb) {
        _instructorCustomCommentsBox =
            await Hive.openBox('instructor_custom_comments');
      } else {
        var dir = await getApplicationDocumentsDirectory();
        _instructorCustomCommentsBox =
            await Hive.openBox('instructor_custom_comments', path: dir.path);
      }
    }
  }

  /// Save instructor custom comments to local storage
  Future<bool> saveInstructorCustomCommentsLocally(
      String instructorId, Map<String, List<String>> comments) async {
    try {
      await _initInstructorCustomCommentsBox();

      await _instructorCustomCommentsBox!
          .put(instructorId, jsonEncode(comments));

      print('✅ Instructor custom comments saved locally for: $instructorId');
      return true;
    } catch (e) {
      print('❌ Error saving instructor custom comments locally: $e');
      return false;
    }
  }

  /// Load instructor custom comments from local storage
  Future<Map<String, List<String>>> loadInstructorCustomCommentsLocally(
      String instructorId) async {
    try {
      await _initInstructorCustomCommentsBox();

      final commentsData = _instructorCustomCommentsBox!.get(instructorId);

      if (commentsData == null) {
        return {};
      }

      final commentsJson =
          jsonDecode(commentsData as String) as Map<String, dynamic>;

      // Convert to Map<String, List<String>>
      final Map<String, List<String>> result = {};
      commentsJson.forEach((key, value) {
        if (value is List) {
          result[key] = value.map((e) => e.toString()).toList();
        }
      });

      return result;
    } catch (e) {
      print('❌ Error loading instructor custom comments locally: $e');
      return {};
    }
  }

  Box<dynamic>? _instructorUxPreferencesBox;

  /// Initialize instructor UX preferences box
  Future<void> _initInstructorUxPreferencesBox() async {
    if (_instructorUxPreferencesBox == null) {
      if (kIsWeb) {
        _instructorUxPreferencesBox =
            await Hive.openBox('instructor_ux_preferences');
      } else {
        var dir = await getApplicationDocumentsDirectory();
        _instructorUxPreferencesBox =
            await Hive.openBox('instructor_ux_preferences', path: dir.path);
      }
    }
  }

  /// Save instructor UX preferences to local storage
  Future<bool> saveInstructorUxPreferencesLocally(
      String instructorId, InstructorUxPreferences preferences) async {
    try {
      await _initInstructorUxPreferencesBox();

      await _instructorUxPreferencesBox!
          .put(instructorId, jsonEncode(preferences.toJson()));

      print('✅ Instructor UX preferences saved locally for: $instructorId');
      return true;
    } catch (e) {
      print('❌ Error saving instructor UX preferences locally: $e');
      return false;
    }
  }

  /// Load instructor UX preferences from local storage
  Future<InstructorUxPreferences> loadInstructorUxPreferencesLocally(
      String instructorId) async {
    try {
      await _initInstructorUxPreferencesBox();

      final prefsData = _instructorUxPreferencesBox!.get(instructorId);

      if (prefsData == null) {
        return InstructorUxPreferences();
      }

      final prefsJson = jsonDecode(prefsData as String) as Map<String, dynamic>;

      return InstructorUxPreferences.fromJson(prefsJson);
    } catch (e) {
      print('❌ Error loading instructor UX preferences locally: $e');
      return InstructorUxPreferences();
    }
  }
}
