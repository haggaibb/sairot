import 'package:hive/hive.dart';
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
