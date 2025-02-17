import 'package:hive/hive.dart';
import '../models/types.dart';
part 'alonka_sprint.g.dart';


@HiveType(typeId: 3)
class AlonkaSprint extends HiveObject {
  AlonkaSprint({required this.round, required this.activeParticipants});

  @HiveField(0)
  final int round;

  @HiveField(1)
  List<int> alonkaCredits=[];

  @HiveField(2)
  List<int> gerikanCredits=[];

  @HiveField(3)
  List<int> runCredits=[];

  @HiveField(4)
  List<int> participationCredits=[];

  @HiveField(5)
  List<int> activeParticipants=[];


  participantHasAlonkaCredit(int number) {
   return  alonkaCredits.contains(number);
  }

  addAlonkaCredit (id,type) {
    switch (type) {
      case AlonkaCreditTypes.Alonka : {
        alonkaCredits.add(id);
        break;
      }
      case AlonkaCreditTypes.Gerikan: {
        gerikanCredits.add(id);
        break;
      }
      case AlonkaCreditTypes.Runner: {
        runCredits.add(id);
        break;
      }
      default: {
        participationCredits.add(id);
        break;
      }
    }

  }


  @override
  String toString() {
    return '$round';
  }

}
