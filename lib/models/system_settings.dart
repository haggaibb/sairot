


class SystemSettings {

  SystemSettings();

  int minutesInterval = 5;// Interval for backup check

  int checkIntervalSeconds = 10;// 🔄 Check internet every 10 seconds

  int totalChecks = 24; // number of checks for connection


  @override
  String toString() {
    return 'system settings';
  }


  /// Convert from JSON
  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings()
      ..minutesInterval = (json["minutes_interval"] ?? 5).toInt()
      ..checkIntervalSeconds = (json["check_interval_seconds"] ?? 10).toInt()
      ..totalChecks = (json["total_checks"] ?? 24).toInt();
  }




}
