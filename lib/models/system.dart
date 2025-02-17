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

  @HiveField(1)
  List<Instructor> instructors = [];

  @HiveField(2)
  GradeSettings gradeSettings = GradeSettings();

  @HiveField(3)
  SystemSettings systemSettings = SystemSettings();

  getLoggedInInstructorData() {
    if (loggedIn!='') {
      return instructors.firstWhere((Instructor i) => i.id==loggedIn);
    } else {
      return null;
    }
  }

  @override
  String toString() {
    return loggedIn;
  }

}
