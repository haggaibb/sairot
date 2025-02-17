import 'package:hive/hive.dart';
import '../models/types.dart';
part 'bur.g.dart';


@HiveType(typeId: 7)
class Bur extends HiveObject {
  Bur({required this.id});

  @HiveField(0)
  final int id;

  @HiveField(1)
  double burGrade=0;

  @HiveField(2)
  List<String> instructorComments=[];

  @override
  String toString() {
    return '$id';
  }

}
