import 'package:flutter/material.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../models/types.dart';
import 'participant_action_dialog.dart';

class AlonkaSprintPanel extends StatefulWidget {
  AlonkaSprintPanel(
      {super.key, required this.round});
  final int round;
  //final int currentRound;

  @override
  State<AlonkaSprintPanel> createState() => _AlonkaSprintPanelState();
}

class _AlonkaSprintPanelState extends State<AlonkaSprintPanel> {
  final eventController = Get.put(EventController());
  List<int> stillActiveInRound = [];

  @override
  void initState() {
    stillActiveInRound = eventController.currentEvent.value.participants.map((participant) => participant.number).toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetX<EventController>(builder: (eventController) {
      // print(eventController.currentAlonkaRound.value.toString());
      // print(widget.round);
      if (eventController.currentAlonkaRound.value == widget.round) {
         var h = eventController.currentEvent.value
                    .getParticipantsByStatus(ParticipantStatus.Active)
                    .length /
                3 +
            2;
         
        return SizedBox(
            height: h < 2 ? 120 : h * 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Divider(
                    thickness: 30,
                  ),
                  Text('Alonka sprint ${widget.round + 1} ',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Expanded(
                      child: GridView.count(
                          childAspectRatio: 3,
                          crossAxisCount: eventController.numberOfCols,
                          children: List.generate(
                              eventController.currentEvent.value
                                  .getParticipantsByStatus(
                                      ParticipantStatus.Active)
                                  .length, (index) {
                                if (
                                     eventController.currentEvent.value.alonkaSprints[widget.round].alonkaCredits.firstWhereOrNull((p) => p== eventController
                                         .currentEvent.value
                                         .getParticipantsByStatus(
                                         ParticipantStatus
                                             .Active)[index]
                                         .number) ==null &&
                                         eventController.currentEvent.value.alonkaSprints[widget.round].gerikanCredits.firstWhereOrNull((p) => p== eventController
                                             .currentEvent.value
                                             .getParticipantsByStatus(
                                             ParticipantStatus
                                                 .Active)[index]
                                             .number) ==null &&
                                         eventController.currentEvent.value.alonkaSprints[widget.round].runCredits.firstWhereOrNull((p) => p== eventController
                                             .currentEvent.value
                                             .getParticipantsByStatus(
                                             ParticipantStatus
                                                 .Active)[index]
                                             .number) ==null
                                   )
                                  {
                                    return Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          fixedSize: const Size(10, 20),
                                        ),
                                        onPressed: () async {
                                          var res =
                                          await showDialog<AlonkaCreditTypes>(
                                            context: context,
                                            builder: (BuildContext context) =>
                                                AlertDialog(
                                                  title: const Text('בחר פעולה'),
                                                  actions: <Widget>[
                                                    IconButton(
                                                        iconSize: 70,
                                                        onPressed: () => Navigator.pop(
                                                            context,
                                                            AlonkaCreditTypes.Alonka),
                                                        icon: const Icon(Icons
                                                            .medical_services_outlined)),
                                                    IconButton(
                                                        iconSize: 80,
                                                        onPressed: () => Navigator.pop(
                                                            context,
                                                            AlonkaCreditTypes.Gerikan),
                                                        icon: const Icon(
                                                            Icons.water_drop_sharp)),
                                                    IconButton(
                                                        iconSize: 80,
                                                        onPressed: () => Navigator.pop(
                                                            context,
                                                            AlonkaCreditTypes.Runner),
                                                        icon: const Icon(Icons.man)),
                                                  ],
                                                ),
                                          );
                                          if (res != null) {
                                            switch (res) {
                                              case AlonkaCreditTypes.Alonka:
                                                eventController
                                                    .currentEvent
                                                    .value
                                                    .alonkaSprints[index]
                                                    .alonkaCredits
                                                    .add(eventController
                                                    .currentEvent.value
                                                    .getParticipantsByStatus(
                                                    ParticipantStatus
                                                        .Active)[index]
                                                    .number);
                                                break;

                                              default:
                                            }
                                          }
                                        },
                                        onLongPress: () async {
                                          var res = await showDialog<
                                              ParticipantStatus>(
                                              context: context,
                                              builder: (BuildContext context) =>
                                              const ParticipantActionDialog());
                                          // eventController.setKidStatus(eventController.listOfKidsInActiveAlonka[
                                          // index], res);
                                          /// todo change kid status (active, inactive)
                                        },
                                        child: Text(eventController.currentEvent.value
                                            .getParticipantsByStatus(
                                            ParticipantStatus.Active)[index]
                                            .number
                                            .toString())),
                                  );
                                  }
                                else {
                                  return SizedBox.shrink();
                                }
                          }))),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(120, 20),
                      ),
                      onPressed: () {
                        //eventController.stopAlonkaSprint(widget.round);
                      },
                      child: Text('סיים')),
                ],
              ),
            ));
      } else {
        return SizedBox(
            height: 95,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Divider(
                    thickness: 30,
                  ),
                  Text('Alonka sprint ${widget.round + 1}',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Row(
                          children: List.generate(1, (index) {
                        return Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Text(
                            '{alonkaCredits[index]}, ',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        );
                      })),
                      const SizedBox(
                        width: 25,
                      ),
                      Row(
                          children: List.generate(1, (index) {
                        return Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Text(
                            'gerikanCredits, ',
                            style: const TextStyle(
                                fontSize: 20,
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold),
                          ),
                        );
                      })),
                    ],
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                ],
              ),
            ));
      }
    });
  }
}
