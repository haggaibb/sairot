import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Handler callback for volume button events
typedef VolumeButtonHandler = void Function(String event);

/// Singleton service that manages volume button PTT EventChannel
/// Routes events to multiple registered handlers to prevent conflicts
class VolumeButtonPttManager {
  static final VolumeButtonPttManager _instance = VolumeButtonPttManager._internal();
  factory VolumeButtonPttManager() => _instance;
  VolumeButtonPttManager._internal();

  // EventChannel for volume button events (mobile only)
  static const EventChannel _volumeButtonEventChannel = 
      EventChannel('com.sairot/volume_button_events');
  static const MethodChannel _audioModeMethodChannel = 
      MethodChannel('com.sairot/audio_mode');

  StreamSubscription<dynamic>? _volumeButtonSubscription;
  final Map<String, VolumeButtonHandler> _handlers = {};
  bool _audioModeEnabled = false;

  /// Register a handler for volume button events
  /// id: Unique identifier for this handler (e.g., "global_ptt")
  /// handler: Callback function that receives "volumeButtonDown" or "volumeButtonUp" events
  void registerHandler(String id, VolumeButtonHandler handler) {
    if (kIsWeb) return;

    _handlers[id] = handler;

    // Initialize EventChannel listener if this is the first handler
    if (_volumeButtonSubscription == null) {
      _initializeListener();
    }
  }

  /// Unregister a handler
  void unregisterHandler(String id) {
    _handlers.remove(id);

    // Cancel EventChannel listener if no handlers remain
    if (_handlers.isEmpty && _volumeButtonSubscription != null) {
      _volumeButtonSubscription?.cancel();
      _volumeButtonSubscription = null;
    }
  }

  /// Initialize the EventChannel listener
  void _initializeListener() {
    if (kIsWeb || _volumeButtonSubscription != null) return;

    try {
      _volumeButtonSubscription = _volumeButtonEventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is String) {
            // Route event to all registered handlers
            for (final handler in _handlers.values) {
              try {
                handler(event);
              } catch (e) {
                // Silently handle errors in handlers
              }
            }
          }
        },
        onError: (error) {
          // Silently handle EventChannel errors
        },
        cancelOnError: false,
      );
    } catch (e) {
      // Silently handle initialization errors
    }
  }

  /// Set audio mode enabled state in native code
  /// This enables/disables volume button interception in MainActivity
  Future<void> setAudioModeEnabled(bool enabled) async {
    if (kIsWeb) return;

    _audioModeEnabled = enabled;
    try {
      await _audioModeMethodChannel.invokeMethod('setAudioModeEnabled', enabled);
    } catch (e) {
      rethrow;
    }
  }

  /// Get current audio mode state
  bool isAudioModeEnabled() => _audioModeEnabled;

  /// Check if any handlers are registered
  bool hasHandlers() => _handlers.isNotEmpty;

  /// Dispose the manager (cancel listener)
  void dispose() {
    _volumeButtonSubscription?.cancel();
    _volumeButtonSubscription = null;
    _handlers.clear();
    _audioModeEnabled = false;
  }
}

