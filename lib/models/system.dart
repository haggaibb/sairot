import 'package:hive/hive.dart';
part 'system.g.dart';

@HiveType(typeId: 200)
enum Accessibility {
  @HiveField(0)
  normal,
  @HiveField(1)
  big,
  @HiveField(2)
  biggest,
}

@HiveType(typeId: 102)
class System extends HiveObject {

  System();

  @HiveField(0)
  String loggedIn = '';

  @HiveField(1)
  bool isDarkMode = true;

  @HiveField(2)
  Accessibility accessibility = Accessibility.normal;

  double _userFontSize  = 12;

  // Getter for age
  double get userFontSize => _userFontSize;
  // Setter for userFontSize (expects an int)
  set userFontSize(double size) {
    _userFontSize = size;
    /// print("🔹 Font size updated: $_userFontSize");
  }
  @override
  String toString() {
    return loggedIn;
  }

}
