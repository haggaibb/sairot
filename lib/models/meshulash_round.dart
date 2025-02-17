import 'package:hive/hive.dart';
import '../models/types.dart';
part 'meshulash_round.g.dart';


@HiveType(typeId: 4)
class MeshulashRound extends HiveObject {
  MeshulashRound({required this.round, required this.participantsInRound});

  @HiveField(0)
  final int round;

  @HiveField(1)
  List<int> participantsInRound;


  @override
  String toString() {
    return '$round';
  }

}
