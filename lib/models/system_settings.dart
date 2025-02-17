import 'package:hive/hive.dart';
part 'system_settings.g.dart';



@HiveType(typeId: 104)
class SystemSettings extends HiveObject {

  SystemSettings();

  @HiveField(0)
  int minutesInterval = 5;// Interval for backup check

  @HiveField(1)
  int checkIntervalSeconds = 10;// 🔄 Check internet every 10 seconds

  @HiveField(2)
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
