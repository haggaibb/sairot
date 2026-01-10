import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/local_storage_service.dart';

/// Service for managing instructor profile data, specifically custom comments
class InstructorProfileService {
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final LocalStorageService _localStorage = LocalStorageService.instance;

  /// Load instructor's custom comments from Firebase with local cache fallback
  static Future<Map<String, List<String>>> loadInstructorCustomComments(String instructorId) async {
    try {
      // First, try to load from local cache
      final localComments = await _localStorage.loadInstructorCustomCommentsLocally(instructorId);
      
      // Try to load from Firestore if online
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
          final Map<String, List<String>> comments = {};
          data.forEach((key, value) {
            if (value is List) {
              comments[key] = value.map((e) => e.toString()).toList();
            }
          });
          
          // Update local cache
          await _localStorage.saveInstructorCustomCommentsLocally(instructorId, comments);
          
          print('✅ Loaded instructor custom comments from Firestore for: $instructorId');
          return comments;
        }
      } catch (e) {
        print('⚠️ Error loading instructor custom comments from Firestore: $e');
        // Fall through to use local cache
      }
      
      // Return local cache if available, otherwise empty map
      if (localComments.isNotEmpty) {
        print('📴 Using cached instructor custom comments (offline mode)');
        return localComments;
      }
      
      return {};
    } catch (e) {
      print('❌ Error in loadInstructorCustomComments: $e');
      return {};
    }
  }

  /// Save a custom comment to Firebase and local cache
  static Future<bool> saveCustomComment(String instructorId, String exerciseType, String comment) async {
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
      
      // Save to Firestore if online
      try {
        await firestore
            .collection('Instructors')
            .doc(instructorId)
            .collection('profile')
            .doc('customComments')
            .set(currentComments);
        
        print('✅ Saved custom comment to Firestore: $exerciseType - $comment');
      } catch (e) {
        print('⚠️ Error saving custom comment to Firestore: $e');
        // Continue to save locally even if Firestore fails
      }
      
      // Always save to local cache
      await _localStorage.saveInstructorCustomCommentsLocally(instructorId, currentComments);
      
      return true;
    } catch (e) {
      print('❌ Error in saveCustomComment: $e');
      return false;
    }
  }

  /// Remove a custom comment from Firebase and local cache
  static Future<bool> removeCustomComment(String instructorId, String exerciseType, String comment) async {
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
      
      // Save to Firestore if online
      try {
        await firestore
            .collection('Instructors')
            .doc(instructorId)
            .collection('profile')
            .doc('customComments')
            .set(currentComments);
        
        print('✅ Removed custom comment from Firestore: $exerciseType - $comment');
      } catch (e) {
        print('⚠️ Error removing custom comment from Firestore: $e');
        // Continue to save locally even if Firestore fails
      }
      
      // Always save to local cache
      await _localStorage.saveInstructorCustomCommentsLocally(instructorId, currentComments);
      
      return true;
    } catch (e) {
      print('❌ Error in removeCustomComment: $e');
      return false;
    }
  }

  /// Get instructor's custom comments for a specific exercise type or generic
  static Future<List<String>> getInstructorCustomComments(String instructorId, String? exerciseType) async {
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
}

