import 'package:hive/hive.dart';
import '../models/types.dart';
part 'sakim_round.g.dart';


@HiveType(typeId: 5)
class SakimRound extends HiveObject {
  SakimRound({required this.round, required this.participantsInRound});

  @HiveField(0)
  final int round;

  @HiveField(1)
  List<int> participantsInRound;


  @override
  String toString() {
    return '$round';
  }

}
