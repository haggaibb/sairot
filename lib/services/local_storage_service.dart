import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../models/event.dart';
import '../models/instructor.dart';
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
  Box<dynamic>? _eventListBox;
  Box<dynamic>? _deletedEventsBox;

  /// Initialize Hive boxes for local storage
  Future<void> initialize() async {
    try {
      // Instructor adapter should already be registered in event_controller.dart
      // Just verify it's registered
      if (!Hive.isAdapterRegistered(103)) {
        print('⚠️ Warning: Instructor adapter (103) not registered. Please register it in event_controller.dart');
      }

      // Open or create boxes
      if (kIsWeb) {
        _eventsBox = await Hive.openBox('events');
        _instructorsBox = await Hive.openBox<Instructor>('instructors');
        _eventListBox = await Hive.openBox('event_list');
        _deletedEventsBox = await Hive.openBox('deleted_events');
      } else {
        var dir = await getApplicationDocumentsDirectory();
        _eventsBox = await Hive.openBox('events', path: dir.path);
        _instructorsBox = await Hive.openBox<Instructor>('instructors', path: dir.path);
        _eventListBox = await Hive.openBox('event_list', path: dir.path);
        _deletedEventsBox = await Hive.openBox('deleted_events', path: dir.path);
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
      
      final key = '${event.eventName}/${event.date}';
      final eventJson = event.toJson();
      
      await _eventsBox!.put(key, jsonEncode(eventJson));
      
      // Also update event list
      await _updateEventList(event.eventName);
      
      print('✅ Event saved locally: $key');
      return true;
    } catch (e) {
      print('❌ Error saving event locally: $e');
      return false;
    }
  }

  /// Load event from local Hive storage
  Future<Event?> loadEventLocally(String eventName, String date) async {
    try {
      if (_eventsBox == null) await initialize();
      
      final key = '$eventName/$date';
      final eventData = _eventsBox!.get(key);
      
      if (eventData == null) {
        return null;
      }
      
      final eventJson = jsonDecode(eventData as String) as Map<String, dynamic>;
      return Event.fromJson(eventJson);
    } catch (e) {
      print('❌ Error loading event locally: $e');
      return null;
    }
  }

  /// Get all unfinalized events from local storage
  Future<List<Event>> getLocalUnfinalizedEvents() async {
    try {
      if (_eventsBox == null) await initialize();
      
      List<Event> events = [];
      
      for (var key in _eventsBox!.keys) {
        try {
          final eventData = _eventsBox!.get(key);
          if (eventData != null) {
            final eventJson = jsonDecode(eventData as String) as Map<String, dynamic>;
            final event = Event.fromJson(eventJson);
            
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

  /// Get list of event names from local storage
  Future<List<String>> getLocalEventList() async {
    try {
      if (_eventListBox == null) await initialize();
      
      final eventList = _eventListBox!.get('list', defaultValue: <String>[]) as List<dynamic>?;
      return eventList?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      print('❌ Error getting local event list: $e');
      return [];
    }
  }

  /// Update event list with new event name
  Future<void> _updateEventList(String eventName) async {
    try {
      // Skip playground events - they should not appear in the event list
      if (eventName == 'playground') {
        return;
      }
      
      if (_eventListBox == null) await initialize();
      
      final currentList = await getLocalEventList();
      if (!currentList.contains(eventName)) {
        currentList.add(eventName);
        await _eventListBox!.put('list', currentList);
      }
    } catch (e) {
      print('❌ Error updating event list: $e');
    }
  }

  /// Delete event from local storage
  Future<bool> deleteEventLocally(String eventName, String date) async {
    try {
      if (_eventsBox == null) await initialize();
      
      final key = '$eventName/$date';
      await _eventsBox!.delete(key);
      
      print('✅ Event deleted locally: $key');
      return true;
    } catch (e) {
      print('❌ Error deleting event locally: $e');
      return false;
    }
  }

  /// Mark event as deleted to prevent restoration from Firebase
  Future<bool> markEventAsDeleted(String eventName, String date) async {
    try {
      if (_deletedEventsBox == null) await initialize();
      
      final key = '$eventName/$date';
      await _deletedEventsBox!.put(key, true);
      
      print('✅ Event marked as deleted: $key');
      return true;
    } catch (e) {
      print('❌ Error marking event as deleted: $e');
      return false;
    }
  }

  /// Check if event is marked as deleted
  Future<bool> isEventDeleted(String eventName, String date) async {
    try {
      if (_deletedEventsBox == null) await initialize();
      
      final key = '$eventName/$date';
      final isDeleted = _deletedEventsBox!.get(key, defaultValue: false) as bool;
      return isDeleted;
    } catch (e) {
      print('❌ Error checking if event is deleted: $e');
      return false;
    }
  }

  /// Remove event from deleted events list (after successful Firebase deletion)
  Future<bool> unmarkEventAsDeleted(String eventName, String date) async {
    try {
      if (_deletedEventsBox == null) await initialize();
      
      final key = '$eventName/$date';
      await _deletedEventsBox!.delete(key);
      
      print('✅ Event unmarked as deleted: $key');
      return true;
    } catch (e) {
      print('❌ Error unmarking event as deleted: $e');
      return false;
    }
  }

  /// Cleanup old finalized events from local storage
  /// Deletes finalized events that are backed up and older than retention period
  /// [retentionDays] - Number of days to keep finalized events (default: 30)
  /// [excludeEventKeys] - List of event keys to exclude from deletion (e.g., currently loaded events)
  /// Returns count of deleted events
  Future<int> cleanupOldFinalizedEvents({
    int retentionDays = 30,
    List<String> excludeEventKeys = const [],
  }) async {
    try {
      if (_eventsBox == null) await initialize();
      
      int deletedCount = 0;
      final now = DateTime.now();
      final retentionThreshold = now.subtract(Duration(days: retentionDays));
      
      print('🧹 Starting cleanup of finalized events older than $retentionDays days...');
      
      // Get all keys from events box
      final allKeys = _eventsBox!.keys.toList();
      
      for (var key in allKeys) {
        try {
          // Skip if this event should be excluded (e.g., currently loaded)
          if (excludeEventKeys.contains(key)) {
            continue;
          }
          
          final eventData = _eventsBox!.get(key);
          if (eventData == null) continue;
          
          final eventJson = jsonDecode(eventData as String) as Map<String, dynamic>;
          final event = Event.fromJson(eventJson);
          
          // Only delete finalized events
          if (!event.finalized) {
            continue;
          }
          
          // Only delete if backed up (or assume true if finalized and successfully saved)
          // For safety, we'll check isBackedUp flag, but if it's finalized we assume it's backed up
          if (!event.isBackedUp && event.finalized) {
            // If finalized but not explicitly marked as backed up, we'll still consider it
            // as potentially backed up (might be from older version without the flag)
            // But to be safe, we'll skip it if isBackedUp is explicitly false
            print('⚠️ Skipping finalized event $key - isBackedUp flag is false');
            continue;
          }
          
          // Calculate age using lastUpdate or use a default if null
          DateTime eventDate;
          if (event.lastUpdate != null) {
            eventDate = event.lastUpdate!;
          } else {
            // If no lastUpdate, try to parse from date string or use current time
            try {
              // Try to parse date string (format: DD-MM-YYYY)
              final dateParts = event.date.split('-');
              if (dateParts.length == 3) {
                eventDate = DateTime(
                  int.parse(dateParts[2]), // year
                  int.parse(dateParts[1]), // month
                  int.parse(dateParts[0]), // day
                );
              } else {
                // Fallback to current time (will not delete)
                eventDate = now;
              }
            } catch (e) {
              // Fallback to current time (will not delete)
              eventDate = now;
            }
          }
          
          // Check if event is older than retention period
          if (eventDate.isBefore(retentionThreshold)) {
            // Delete the event
            await deleteEventLocally(event.eventName, event.date);
            deletedCount++;
            print('🗑️ Deleted old finalized event: $key (age: ${now.difference(eventDate).inDays} days)');
          }
        } catch (e) {
          print('❌ Error processing event $key during cleanup: $e');
          continue;
        }
      }
      
      if (deletedCount > 0) {
        print('✅ Cleanup completed: Deleted $deletedCount old finalized event(s)');
      } else {
        print('✅ Cleanup completed: No events to delete');
      }
      
      return deletedCount;
    } catch (e) {
      print('❌ Error during cleanup of old finalized events: $e');
      return 0;
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
      if (_eventListBox != null) await _eventListBox!.clear();
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
        _instructorCustomCommentsBox = await Hive.openBox('instructor_custom_comments');
      } else {
        var dir = await getApplicationDocumentsDirectory();
        _instructorCustomCommentsBox = await Hive.openBox('instructor_custom_comments', path: dir.path);
      }
    }
  }

  /// Save instructor custom comments to local storage
  Future<bool> saveInstructorCustomCommentsLocally(String instructorId, Map<String, List<String>> comments) async {
    try {
      await _initInstructorCustomCommentsBox();
      
      await _instructorCustomCommentsBox!.put(instructorId, jsonEncode(comments));
      
      print('✅ Instructor custom comments saved locally for: $instructorId');
      return true;
    } catch (e) {
      print('❌ Error saving instructor custom comments locally: $e');
      return false;
    }
  }

  /// Load instructor custom comments from local storage
  Future<Map<String, List<String>>> loadInstructorCustomCommentsLocally(String instructorId) async {
    try {
      await _initInstructorCustomCommentsBox();
      
      final commentsData = _instructorCustomCommentsBox!.get(instructorId);
      
      if (commentsData == null) {
        return {};
      }
      
      final commentsJson = jsonDecode(commentsData as String) as Map<String, dynamic>;
      
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
}

