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
      } else {
        var dir = await getApplicationDocumentsDirectory();
        _eventsBox = await Hive.openBox('events', path: dir.path);
        _instructorsBox = await Hive.openBox<Instructor>('instructors', path: dir.path);
        _eventListBox = await Hive.openBox('event_list', path: dir.path);
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
}

