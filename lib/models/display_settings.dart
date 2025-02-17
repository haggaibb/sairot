import 'package:hive/hive.dart';
part 'display_settings.g.dart';


@HiveType(typeId: 6)
class DisplaySettings extends HiveObject {

  @HiveField(0)
  bool sprintsFullScreen = false;

  @HiveField(1)
  int numberOfCols = 3;

  @HiveField(2)
  bool alonkaFullScreen = false;


  @override
  String toString() {
    return 'display settings obj';
  }

}
