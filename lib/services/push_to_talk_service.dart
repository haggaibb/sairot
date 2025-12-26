import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'voice_recognition_service.dart';
import 'volume_button_ptt_manager.dart';

/// Unified Push-to-Talk service for web and mobile
/// Web: Uses button-based PTT
/// Mobile: Uses volume button PTT
class PushToTalkService {
  final VoiceRecognitionService _voiceService = VoiceRecognitionService();
  final VolumeButtonPttManager _volumeManager = VolumeButtonPttManager();
  bool _isRecording = false;
  bool _isProcessing = false; // Processing voice-to-text after recording stops
  bool _hasReceivedResult = false; // Track if we've received a result to prevent restarting processing
  bool _audioModeEnabled = false;
  bool _isHandlerRegistered = false;
  bool _disableProcessingIndicator = false; // When true, never show processing indicator (for dialogs)

  // Callbacks
  Function(String)? onResult;
  Function(String)? onError;
  VoidCallback? onRecordingStarted;
  VoidCallback? onRecordingStopped;
  VoidCallback? onProcessingStarted;
  VoidCallback? onProcessingStopped;
  
  /// Disable text cleaning - return raw STT output (for comment dialogs)
  void disableCleaning() {
    _voiceService.disableCleaning();
    // Also disable processing indicator for comment dialogs
    _disableProcessingIndicator = true;
    // Immediately clear any processing state
    _isProcessing = false;
    // Don't call onProcessingStopped here as it might trigger UI updates
  }
  
  /// Enable text cleaning (default, for floating PTT button)
  void enableCleaning() {
    _voiceService.enableCleaning();
    // Re-enable processing indicator for floating PTT button
    _disableProcessingIndicator = false;
  }

  /// Initialize PTT service
  Future<void> initialize() async {
    await _voiceService.initialize();
    
    // Set up voice service callbacks
    _voiceService.onResult = (text) {
      _isRecording = false;
      _hasReceivedResult = true; // Mark that we've received a result
      // Clear processing state before calling result callback
      // For comment dialogs (processing disabled), never set processing state
      if (!_disableProcessingIndicator && !_voiceService.isCleaningDisabled) {
        _isProcessing = false;
        onProcessingStopped?.call();
      } else {
        _isProcessing = false; // Ensure it's false
      }
      onResult?.call(text);
    };

    _voiceService.onError = (error) {
      _isRecording = false;
      _hasReceivedResult = true; // Mark that we've received an error (no processing needed)
      // For comment dialogs (processing disabled), never set processing state
      if (!_disableProcessingIndicator && !_voiceService.isCleaningDisabled) {
        _isProcessing = false;
        onProcessingStopped?.call();
      } else {
        _isProcessing = false; // Ensure it's false
      }
      onError?.call(error);
    };

    _voiceService.onListeningStarted = () {
      _isRecording = true;
      // For comment dialogs (processing disabled), never set processing state
      _isProcessing = false; // Always ensure it's false when starting
      _hasReceivedResult = false; // Reset when starting new recording
      onRecordingStarted?.call();
    };

    _voiceService.onListeningStopped = () {
      _isRecording = false;
      // Never show processing indicator if explicitly disabled (for comment dialogs)
      // Check flag at execution time to ensure it's always respected
      if (_disableProcessingIndicator || _voiceService.isCleaningDisabled) {
        _isProcessing = false;
        // Don't call onProcessingStarted for comment dialogs
      } else {
        // Only start processing indicator if we haven't received a result yet
        // This prevents processing from restarting after onResult has been called
        // Double-check the flag here as well to be absolutely sure
        if (!_hasReceivedResult && !_isProcessing && !_disableProcessingIndicator) {
          _isProcessing = true;
          // Wrap callback to check flag one more time as final safeguard
          if (!_disableProcessingIndicator && !_voiceService.isCleaningDisabled) {
            onProcessingStarted?.call();
          } else {
            // Flag was set after we checked, revert processing state
            _isProcessing = false;
          }
        }
      }
      onRecordingStopped?.call();
    };

    // Don't register volume button handler here - wait for enableAudioMode() call
  }

  /// Register volume button handler with VolumeButtonPttManager
  void _registerVolumeButtonHandler() {
    if (_isHandlerRegistered) return;

    _volumeManager.registerHandler('global_ptt', (event) {
      if (event == 'volumeButtonDown') {
        if (_audioModeEnabled && !_isRecording) {
          startRecording();
        }
      } else if (event == 'volumeButtonUp') {
        if (_isRecording) {
          stopRecording();
        }
      }
    });
    _isHandlerRegistered = true;
  }

  /// Unregister volume button handler
  void _unregisterVolumeButtonHandler() {
    if (!_isHandlerRegistered) return;

    _volumeManager.unregisterHandler('global_ptt');
    _isHandlerRegistered = false;
  }

  /// Enable audio mode (for volume button PTT on mobile)
  Future<void> enableAudioMode() async {
    if (!kIsWeb) {
      try {
        // Ensure handler is registered (register if not already registered)
        if (!_isHandlerRegistered) {
          _registerVolumeButtonHandler();
        }

        // Set audio mode enabled flag
        _audioModeEnabled = true;

        // Add a small delay to ensure handler is ready
        await Future.delayed(const Duration(milliseconds: 100));
        await _volumeManager.setAudioModeEnabled(true);
      } catch (e) {
        _audioModeEnabled = false; // Revert on error
        rethrow;
      }
    } else {
      _audioModeEnabled = true;
    }
  }

  /// Disable audio mode
  Future<void> disableAudioMode() async {
    _audioModeEnabled = false;
    if (!kIsWeb) {
      try {
        await _volumeManager.setAudioModeEnabled(false);
      } catch (e) {
        rethrow;
      }
    }
  }

  /// Start recording (button-based for web, can also be called programmatically)
  Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPermission = await _voiceService.checkPermission();
    if (!hasPermission) {
      final granted = await _voiceService.requestPermission();
      if (!granted) {
        onError?.call('נדרשת הרשאה למיקרופון');
        return;
      }
    }

    await _voiceService.startListening();
  }

  /// Stop recording
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    // For comment dialogs (processing disabled), ensure processing is never set
    if (_disableProcessingIndicator || _voiceService.isCleaningDisabled) {
      _isProcessing = false;
    }
    await _voiceService.stopListening();
  }

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Check if currently processing (voice-to-text conversion)
  /// Always returns false if processing indicator is disabled (for comment dialogs)
  bool get isProcessing {
    if (_disableProcessingIndicator || _voiceService.isCleaningDisabled) {
      return false; // Never report processing when disabled
    }
    return _isProcessing;
  }

  /// Check if processing indicator should be shown
  /// Returns false if processing is disabled (for comment dialogs)
  bool get shouldShowProcessingIndicator {
    return !_disableProcessingIndicator && !_voiceService.isCleaningDisabled;
  }

  /// Dispose resources
  void dispose() {
    _unregisterVolumeButtonHandler();
    _voiceService.dispose();
  }
}

