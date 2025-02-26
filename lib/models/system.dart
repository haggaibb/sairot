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
    print("🔹 Font size updated: $_userFontSize");
  }
  // Function to update font size based on accessibility settings
  // void updateFontSize(Map<String, dynamic> settings) {
  //   if (settings.isEmpty) {
  //     print("⚠️ Warning: Settings map is empty. Keeping default font size.");
  //     return;
  //   }
  //   switch (accessibility) {
  //     case Accessibility.normal:
  //       print("🔹 Setting font size to NORMAL mode.");
  //       userFontSize = (settings['normal'] ?? 12).toInt();
  //       break;
  //     case Accessibility.big:
  //       print("🔹 Setting font size to BIG mode.");
  //       userFontSize = (settings['big'] ?? 14).toInt();
  //       break;
  //     case Accessibility.biggest:
  //       print("🔹 Setting font size to BIGGEST mode.");
  //       userFontSize = (settings['biggest'] ?? 18).toInt();
  //       break;
  //   }
  // }
  @override
  String toString() {
    return loggedIn;
  }

}
