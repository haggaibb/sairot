import 'package:flutter/foundation.dart';

/// Service to track the current exercise context (e.g., meshulash, alonka, bur, etc.)
/// Used by STT (floating button and volume buttons) to know where to save comments
class ExerciseContextService {
  static final ExerciseContextService _instance = ExerciseContextService._internal();
  factory ExerciseContextService() => _instance;
  ExerciseContextService._internal();

  String? _currentExerciseType; // e.g., 'meshulash', 'alonka', 'sakim', 'bur', 'leadership', 'interview', 'none'
  
  /// ValueNotifier for reactive updates (if needed in the future)
  final ValueNotifier<String?> exerciseTypeNotifier = ValueNotifier<String?>(null);

  /// Set current exercise context
  void setCurrentExercise(String exerciseType) {
    _currentExerciseType = exerciseType;
    exerciseTypeNotifier.value = exerciseType;
  }

  /// Get current exercise type
  String? getCurrentExercise() {
    return _currentExerciseType;
  }

  /// Clear exercise context
  void clearExercise() {
    _currentExerciseType = null;
    exerciseTypeNotifier.value = null;
  }
}










