import 'package:hive/hive.dart';
import 'grade_settings.dart';
import 'instructor.dart';
import 'system_settings.dart';
part 'system.g.dart';




@HiveType(typeId: 102)
class System extends HiveObject {

  System();

  @HiveField(0)
  String loggedIn = '';


  @override
  String toString() {
    return loggedIn;
  }

}
