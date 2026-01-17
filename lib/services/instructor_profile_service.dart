import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../services/local_storage_service.dart';
import '../services/sync_queue_service.dart';
import '../connectivity_controller.dart';
import '../models/instructor_ux_preferences.dart';

/// Service for managing instructor profile data, specifically custom comments
class InstructorProfileService {
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final LocalStorageService _localStorage = LocalStorageService.instance;

  /// Load instructor's custom comments with smart merge strategy
  /// Merges Firebase and local cache to ensure no data loss
  static Future<Map<String, List<String>>> loadInstructorCustomComments(
      String instructorId) async {
    try {
      // Check connectivity
      bool isOnline = false;
      try {
        final connectivityController = Get.find<ConnectivityController>();
        isOnline = connectivityController.isConnected.value;
      } catch (e) {
        // ConnectivityController not available, assume offline
        print('⚠️ ConnectivityController not available, assuming offline');
      }

      // Load from local cache (always, as fallback)
      final localComments =
          await _localStorage.loadInstructorCustomCommentsLocally(instructorId);

      // Try to load from Firestore if online
      Map<String, List<String>> firebaseComments = {};
      if (isOnline) {
        try {
          final docSnapshot = await firestore
              .collection('Instructors')
              .doc(instructorId)
              .collection('profile')
              .doc('customComments')
              .get();

          if (docSnapshot.exists && docSnapshot.data() != null) {
            final data = docSnapshot.data() as Map<String, dynamic>;

            // Convert to Map<String, List<String>>
            data.forEach((key, value) {
              if (value is List) {
                firebaseComments[key] = value.map((e) => e.toString()).toList();
              }
            });

            print(
                '✅ Loaded instructor custom comments from Firestore for: $instructorId');
          }
        } catch (e) {
          print(
              '⚠️ Error loading instructor custom comments from Firestore: $e');
          // Continue with merge using local cache only
        }
      }

      // Merge both sources: union of all unique comments
      final Map<String, List<String>> mergedComments = {};

      // Add all exercise types from both sources
      final allExerciseTypes = <String>{};
      allExerciseTypes.addAll(localComments.keys);
      allExerciseTypes.addAll(firebaseComments.keys);

      // Merge comments for each exercise type
      for (final exerciseType in allExerciseTypes) {
        final Set<String> uniqueComments = {};

        // Add comments from local cache
        if (localComments.containsKey(exerciseType)) {
          uniqueComments.addAll(localComments[exerciseType]!);
        }

        // Add comments from Firebase
        if (firebaseComments.containsKey(exerciseType)) {
          uniqueComments.addAll(firebaseComments[exerciseType]!);
        }

        // Convert set to list (preserves uniqueness)
        mergedComments[exerciseType] = uniqueComments.toList();
      }

      // Save merged result back to both Firebase (if online) and local cache
      // Always update local cache with merged result
      await _localStorage.saveInstructorCustomCommentsLocally(
          instructorId, mergedComments);

      // Update Firebase if online (merged result may include local-only comments)
      if (isOnline && mergedComments.isNotEmpty) {
        try {
          await firestore
              .collection('Instructors')
              .doc(instructorId)
              .collection('profile')
              .doc('customComments')
              .set(mergedComments);
          print('✅ Updated Firestore with merged comments for: $instructorId');
        } catch (e) {
          print('⚠️ Error updating Firestore with merged comments: $e');
          // Non-critical, local cache is already updated
        }
      }

      if (mergedComments.isNotEmpty) {
        print(
            '✅ Merged ${mergedComments.length} custom comment categories (${isOnline ? 'online' : 'offline'})');
      } else if (localComments.isNotEmpty) {
        print('📴 Using cached instructor custom comments (offline mode)');
      }

      return mergedComments;
    } catch (e) {
      print('❌ Error in loadInstructorCustomComments: $e');
      // Fallback to local cache if available
      try {
        final localComments = await _localStorage
            .loadInstructorCustomCommentsLocally(instructorId);
        return localComments;
      } catch (e2) {
        print('❌ Error loading local cache fallback: $e2');
        return {};
      }
    }
  }

  /// Save a custom comment to Firebase and local cache
  /// Queues operation for sync if offline
  static Future<bool> saveCustomComment(
      String instructorId, String exerciseType, String comment,
      {bool skipLocalSave = false}) async {
    try {
      // Load current comments
      final currentComments = await loadInstructorCustomComments(instructorId);

      // Add comment to appropriate exercise type list
      if (!currentComments.containsKey(exerciseType)) {
        currentComments[exerciseType] = [];
      }

      // Only add if not already in list
      if (!currentComments[exerciseType]!.contains(comment)) {
        currentComments[exerciseType]!.add(comment);
      }

      // Always save to local cache first (unless skipLocalSave is true)
      if (!skipLocalSave) {
        await _localStorage.saveInstructorCustomCommentsLocally(
            instructorId, currentComments);
      }

      // Check connectivity
      bool isOnline = false;
      try {
        final connectivityController = Get.find<ConnectivityController>();
        isOnline = connectivityController.isConnected.value;
      } catch (e) {
        // ConnectivityController not available, assume offline
        print('⚠️ ConnectivityController not available, assuming offline');
      }

      // Try to save to Firestore if online
      bool firestoreSuccess = false;
      if (isOnline) {
        try {
          await firestore
              .collection('Instructors')
              .doc(instructorId)
              .collection('profile')
              .doc('customComments')
              .set(currentComments);

          print(
              '✅ Saved custom comment to Firestore: $exerciseType - $comment');
          firestoreSuccess = true;
        } catch (e) {
          print('⚠️ Error saving custom comment to Firestore: $e');
          // Will queue for sync below
        }
      }

      // Queue operation if offline or Firestore failed
      if (!firestoreSuccess) {
        try {
          await SyncQueueService.instance.queueFirestoreOperation(
            'saveInstructorCustomComment',
            {
              'instructorId': instructorId,
              'exerciseType': exerciseType,
              'comment': comment,
            },
          );
          print('📋 Queued saveInstructorCustomComment operation for sync');
        } catch (e) {
          print('⚠️ Error queueing saveInstructorCustomComment operation: $e');
          // Non-critical, local cache is already saved
        }
      }

      return true;
    } catch (e) {
      print('❌ Error in saveCustomComment: $e');
      return false;
    }
  }

  /// Remove a custom comment from Firebase and local cache
  /// Queues operation for sync if offline
  static Future<bool> removeCustomComment(
      String instructorId, String exerciseType, String comment,
      {bool skipLocalSave = false}) async {
    try {
      // Load current comments
      final currentComments = await loadInstructorCustomComments(instructorId);

      // Remove comment from appropriate exercise type list
      if (currentComments.containsKey(exerciseType)) {
        currentComments[exerciseType]!.remove(comment);

        // Remove empty lists
        if (currentComments[exerciseType]!.isEmpty) {
          currentComments.remove(exerciseType);
        }
      }

      // Always save to local cache first (unless skipLocalSave is true)
      if (!skipLocalSave) {
        await _localStorage.saveInstructorCustomCommentsLocally(
            instructorId, currentComments);
      }

      // Check connectivity
      bool isOnline = false;
      try {
        final connectivityController = Get.find<ConnectivityController>();
        isOnline = connectivityController.isConnected.value;
      } catch (e) {
        // ConnectivityController not available, assume offline
        print('⚠️ ConnectivityController not available, assuming offline');
      }

      // Try to save to Firestore if online
      bool firestoreSuccess = false;
      if (isOnline) {
        try {
          await firestore
              .collection('Instructors')
              .doc(instructorId)
              .collection('profile')
              .doc('customComments')
              .set(currentComments);

          print(
              '✅ Removed custom comment from Firestore: $exerciseType - $comment');
          firestoreSuccess = true;
        } catch (e) {
          print('⚠️ Error removing custom comment from Firestore: $e');
          // Will queue for sync below
        }
      }

      // Queue operation if offline or Firestore failed
      if (!firestoreSuccess) {
        try {
          await SyncQueueService.instance.queueFirestoreOperation(
            'removeInstructorCustomComment',
            {
              'instructorId': instructorId,
              'exerciseType': exerciseType,
              'comment': comment,
            },
          );
          print('📋 Queued removeInstructorCustomComment operation for sync');
        } catch (e) {
          print(
              '⚠️ Error queueing removeInstructorCustomComment operation: $e');
          // Non-critical, local cache is already saved
        }
      }

      return true;
    } catch (e) {
      print('❌ Error in removeCustomComment: $e');
      return false;
    }
  }

  /// Get instructor's custom comments for a specific exercise type or generic
  static Future<List<String>> getInstructorCustomComments(
      String instructorId, String? exerciseType) async {
    try {
      final allComments = await loadInstructorCustomComments(instructorId);

      final List<String> result = [];

      // Add exercise-specific comments if requested
      if (exerciseType != null && allComments.containsKey(exerciseType)) {
        result.addAll(allComments[exerciseType]!);
      }

      // Always add generic comments
      if (allComments.containsKey('generic')) {
        result.addAll(allComments['generic']!);
      }

      return result;
    } catch (e) {
      print('❌ Error in getInstructorCustomComments: $e');
      return [];
    }
  }

  /// Load instructor's UX preferences with smart merge strategy
  /// Merges Firebase and local cache to ensure no data loss
  static Future<InstructorUxPreferences> loadUxPreferences(
      String instructorId) async {
    try {
      // Check connectivity
      bool isOnline = false;
      try {
        final connectivityController = Get.find<ConnectivityController>();
        isOnline = connectivityController.isConnected.value;
      } catch (e) {
        // ConnectivityController not available, assume offline
        print('⚠️ ConnectivityController not available, assuming offline');
      }

      // Load from local cache (always, as fallback)
      final localPrefs =
          await _localStorage.loadInstructorUxPreferencesLocally(instructorId);

      // Try to load from Firestore if online
      InstructorUxPreferences? firebasePrefs;
      if (isOnline) {
        try {
          final docSnapshot = await firestore
              .collection('Instructors')
              .doc(instructorId)
              .collection('profile')
              .doc('uxPreferences')
              .get();

          if (docSnapshot.exists && docSnapshot.data() != null) {
            final data = docSnapshot.data() as Map<String, dynamic>;
            firebasePrefs = InstructorUxPreferences.fromJson(data);
            print(
                '✅ Loaded instructor UX preferences from Firestore for: $instructorId');
          }
        } catch (e) {
          print(
              '⚠️ Error loading instructor UX preferences from Firestore: $e');
          // Continue with local cache only
        }
      }

      // Use Firebase preferences if available, otherwise use local
      final mergedPrefs = firebasePrefs ?? localPrefs;

      // Save merged result back to local cache
      await _localStorage.saveInstructorUxPreferencesLocally(
          instructorId, mergedPrefs);

      // Update Firebase if online and we have preferences
      if (isOnline &&
          firebasePrefs == null &&
          localPrefs != InstructorUxPreferences()) {
        try {
          await firestore
              .collection('Instructors')
              .doc(instructorId)
              .collection('profile')
              .doc('uxPreferences')
              .set(mergedPrefs.toJson());
          print(
              '✅ Updated Firestore with local UX preferences for: $instructorId');
        } catch (e) {
          print('⚠️ Error updating Firestore with UX preferences: $e');
          // Non-critical, local cache is already updated
        }
      }

      print('✅ Loaded UX preferences (${isOnline ? 'online' : 'offline'})');
      return mergedPrefs;
    } catch (e) {
      print('❌ Error in loadUxPreferences: $e');
      // Fallback to default preferences
      return InstructorUxPreferences();
    }
  }

  /// Save instructor's UX preferences to Firebase and local cache
  /// Queues operation for sync if offline
  static Future<bool> saveUxPreferences(
      String instructorId, InstructorUxPreferences preferences) async {
    try {
      // Always save to local cache first
      await _localStorage.saveInstructorUxPreferencesLocally(
          instructorId, preferences);

      // Check connectivity
      bool isOnline = false;
      try {
        final connectivityController = Get.find<ConnectivityController>();
        isOnline = connectivityController.isConnected.value;
      } catch (e) {
        // ConnectivityController not available, assume offline
        print('⚠️ ConnectivityController not available, assuming offline');
      }

      // Try to save to Firestore if online
      bool firestoreSuccess = false;
      if (isOnline) {
        try {
          await firestore
              .collection('Instructors')
              .doc(instructorId)
              .collection('profile')
              .doc('uxPreferences')
              .set(preferences.toJson());

          print('✅ Saved UX preferences to Firestore for: $instructorId');
          firestoreSuccess = true;
        } catch (e) {
          print('⚠️ Error saving UX preferences to Firestore: $e');
          // Will queue for sync below
        }
      }

      // Queue operation if offline or Firestore failed
      if (!firestoreSuccess) {
        try {
          await SyncQueueService.instance.queueFirestoreOperation(
            'saveInstructorUxPreferences',
            {
              'instructorId': instructorId,
              'preferences': preferences.toJson(),
            },
          );
          print('📋 Queued saveInstructorUxPreferences operation for sync');
        } catch (e) {
          print('⚠️ Error queueing saveInstructorUxPreferences operation: $e');
          // Non-critical, local cache is already saved
        }
      }

      return true;
    } catch (e) {
      print('❌ Error in saveUxPreferences: $e');
      return false;
    }
  }
}
