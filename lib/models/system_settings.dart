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
    // Helper to convert LinkedMap or any Map to Map<String, dynamic>
    Map<String, dynamic> convertMap(dynamic map) {
      if (map is Map<String, dynamic>) {
        return map;
      } else if (map is Map) {
        final converted = <String, dynamic>{};
        for (var entry in map.entries) {
          final key = entry.key.toString();
          final value = entry.value;
          // Recursively convert nested maps
          if (value is Map) {
            converted[key] = convertMap(value);
          } else {
            converted[key] = value;
          }
        }
        return converted;
      }
      return {};
    }
    
    final accessibilitySettingsRaw = json["accessibility_settings"];
    final accessibilitySettings = accessibilitySettingsRaw != null 
        ? convertMap(accessibilitySettingsRaw)
        : {
            "big": {"child_aspect_ratio": 3, "font_size": 26},
            "biggest": {"child_aspect_ratio": 2},
            "normal": {"child_aspect_ratio": 2.5, "font_size": 18}
          };
    
    return SystemSettings()
      ..minutesInterval = (json["minutes_interval"] ?? 5).toInt()
      ..checkIntervalSeconds = (json["check_interval_seconds"] ?? 10).toInt()
      ..totalChecks = (json["total_checks"] ?? 24).toInt()
      ..accessibilitySettings = accessibilitySettings;
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
