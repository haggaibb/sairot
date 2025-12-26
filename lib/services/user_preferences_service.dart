import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Service to manage user preferences and settings
/// Stores preferences in SharedPreferences for persistence across app restarts
class UserPreferencesService {
  // Keys for different preference types
  static const String _floatingPttButtonKey = 'user_floating_ptt_button';
  static const String _volumeButtonPttKey = 'user_volume_button_ptt';
  static const String _floatingPttButtonXKey = 'user_floating_ptt_button_x';
  static const String _floatingPttButtonYKey = 'user_floating_ptt_button_y';

  /// Save floating PTT button preference
  /// enabled: true to show floating PTT button, false to hide it
  static Future<void> saveFloatingPttButton(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_floatingPttButtonKey, enabled);
      print('✓ Saved floating PTT button: $enabled');
    } catch (e) {
      print('Error saving floating PTT button: $e');
      rethrow;
    }
  }

  /// Get saved floating PTT button preference
  /// Returns false if no preference is saved (default: disabled)
  static Future<bool> getFloatingPttButton() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_floatingPttButtonKey) ?? false;
    } catch (e) {
      print('Error loading floating PTT button: $e');
      return false;
    }
  }

  /// Save volume button PTT preference
  /// enabled: true to enable volume buttons as PTT, false to disable
  static Future<void> saveVolumeButtonPtt(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_volumeButtonPttKey, enabled);
      print('✓ Saved volume button PTT: $enabled');
    } catch (e) {
      print('Error saving volume button PTT: $e');
      rethrow;
    }
  }

  /// Get saved volume button PTT preference
  /// Returns false if no preference is saved (default: disabled)
  static Future<bool> getVolumeButtonPtt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_volumeButtonPttKey) ?? false;
    } catch (e) {
      print('Error loading volume button PTT: $e');
      return false;
    }
  }

  /// Save floating PTT button position (as percentage of screen size)
  /// x: horizontal position as percentage (0.0 to 1.0)
  /// y: vertical position as percentage (0.0 to 1.0)
  static Future<void> saveFloatingPttButtonPosition(double x, double y) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_floatingPttButtonXKey, x);
      await prefs.setDouble(_floatingPttButtonYKey, y);
      print('✓ Saved floating PTT button position: x=$x, y=$y');
    } catch (e) {
      print('Error saving floating PTT button position: $e');
      rethrow;
    }
  }

  /// Get saved floating PTT button position (as percentage of screen size)
  /// Returns Offset with x and y as percentages (0.0 to 1.0), or null if not set
  static Future<Offset?> getFloatingPttButtonPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final x = prefs.getDouble(_floatingPttButtonXKey);
      final y = prefs.getDouble(_floatingPttButtonYKey);
      
      if (x != null && y != null) {
        return Offset(x, y);
      }
      return null;
    } catch (e) {
      print('Error loading floating PTT button position: $e');
      return null;
    }
  }

  /// Clear all STT preferences (useful for logout or reset)
  static Future<void> clearSttPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_floatingPttButtonKey);
      await prefs.remove(_volumeButtonPttKey);
      await prefs.remove(_floatingPttButtonXKey);
      await prefs.remove(_floatingPttButtonYKey);
      print('✓ Cleared all STT preferences');
    } catch (e) {
      print('Error clearing STT preferences: $e');
    }
  }
}

