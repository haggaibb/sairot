import 'types.dart';

class SystemSettings {
  SystemSettings();

  int minutesInterval = 5; // Interval for backup check
  int checkIntervalSeconds = 10; // 🔄 Check internet every 10 seconds
  int totalChecks = 24; // Number of checks for connection
  Map<String, dynamic> accessibilitySettings = {
    "big": {"child_aspect_ratio": 3, "font_size": 26},
    "biggest": {"child_aspect_ratio": 2},
    "normal": {"child_aspect_ratio": 2.5, "font_size": 18}
  };

  @override
  String toString() {
    return 'System Settings';
  }

  /// Convert from JSON
  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings()
      ..minutesInterval = (json["minutes_interval"] ?? 5).toInt()
      ..checkIntervalSeconds = (json["check_interval_seconds"] ?? 10).toInt()
      ..totalChecks = (json["total_checks"] ?? 24).toInt()
      ..accessibilitySettings = (json["accessibility_settings"]);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      "minutes_interval": minutesInterval,
      "check_interval_seconds": checkIntervalSeconds,
      "total_checks": totalChecks,
      "accessibility_settings": accessibilitySettings, // Convert enum to string
    };
  }
}
