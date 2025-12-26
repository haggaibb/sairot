import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// Abstract platform service for handling platform-specific functionality
abstract class PlatformService {
  /// Get device ID (Android ID on Android, null on web)
  Future<String?> getDeviceId();

  /// Check if kiosk settings can be opened (Android only)
  Future<bool> canOpenKioskSettings();

  /// Open MDM kiosk settings (Android only)
  Future<void> openKioskSettings();

  /// Open WiFi picker (Android only)
  Future<void> openWifiPicker();

  /// Check if device registration is required (Android tablets only, not phones or web)
  /// Note: This returns true for all Android devices. The actual tablet check
  /// should be done in the UI layer using MediaQuery since this service doesn't have BuildContext.
  bool requiresDeviceRegistration();

  /// Factory method to get the appropriate platform service
  factory PlatformService.create() {
    if (kIsWeb) {
      return WebPlatformService();
    } else if (Platform.isAndroid) {
      return AndroidPlatformService();
    } else {
      // Fallback for other platforms (iOS, etc.)
      return WebPlatformService();
    }
  }
}

/// Android platform service implementation
class AndroidPlatformService implements PlatformService {
  static const MethodChannel _channel = MethodChannel('kiosk_settings');

  @override
  Future<String?> getDeviceId() async {
    try {
      final String? androidId = await _channel.invokeMethod<String>('getAndroidId');
      return androidId;
    } catch (e) {
      print('❌ Error getting Android ID: $e');
      return null;
    }
  }

  @override
  Future<bool> canOpenKioskSettings() async {
    return true; // Android supports kiosk settings
  }

  @override
  Future<void> openKioskSettings() async {
    try {
      await _channel.invokeMethod('openKioskSettings');
    } catch (e) {
      print('❌ Error opening kiosk settings: $e');
    }
  }

  @override
  Future<void> openWifiPicker() async {
    try {
      await _channel.invokeMethod('openWifiPicker');
    } catch (e) {
      print('❌ Error opening WiFi picker: $e');
    }
  }

  @override
  bool requiresDeviceRegistration() {
    return true; // Android devices may require registration (tablet check done in UI)
  }
}

/// Web platform service implementation
class WebPlatformService implements PlatformService {
  @override
  Future<String?> getDeviceId() async {
    // Device registration is Android-only, return null on web
    return null;
  }

  @override
  Future<bool> canOpenKioskSettings() async {
    return false; // Web doesn't support kiosk settings
  }

  @override
  Future<void> openKioskSettings() async {
    // No-op on web
  }

  @override
  Future<void> openWifiPicker() async {
    // No-op on web
  }

  @override
  bool requiresDeviceRegistration() {
    return false; // Web doesn't require device registration
  }
}

