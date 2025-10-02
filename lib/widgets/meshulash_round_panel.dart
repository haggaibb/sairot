import 'package:flutter/material.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import 'package:sairot/models/meshulash_round.dart';
import '../widgets/comments_dialog.dart';

class MeshulashRoundPanel extends StatefulWidget {

  const MeshulashRoundPanel({super.key, required this.round});
    final MeshulashRound round;

  @override
  State<MeshulashRoundPanel> createState() => _MeshulashRoundPanelState();
}

class _MeshulashRoundPanelState extends State<MeshulashRoundPanel> {
  final eventController = Get.put(EventController());
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetX<EventController>(builder: (eventController) {
      var h = eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound.length / 3 + 2;
        if (eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound.isEmpty) return SizedBox();
        return SizedBox(
            height: h < 2 ? 120 : h * 55,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Divider(
                    thickness: 30,
                  ),
                      widget.round.round==0?SizedBox.shrink():Text('משלוש מקצה ${widget.round.round}  ',
                      style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Expanded(
                      child: GridView.count(
                          childAspectRatio: eventController.userChildAspectRatio.value,
                          crossAxisCount: eventController.numberOfCols,
                          children: List.generate(
                              eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: GestureDetector(
                                  onDoubleTap: () {
                                    eventController.loading.value = true;
                                    eventController.currentEvent.value.meshulashRounds[widget.round.round-1].participantsInRound.add(eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound[index]);
                                    widget.round.participantsInRound.remove(eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound[index]);
                                    eventController.update();
                                    eventController.currentEvent.value.saveToFirestore();
                                    eventController.loading.value = false;
                                  },
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                      onPressed: () {
                                        if (eventController.meshulashEditModeOn.value) {
                                          eventController.loading.value = true;
                                          print(widget.round.round);
                                          if (eventController.currentEvent.value.meshulashRounds.length == widget.round.round+1) {
                                            eventController.currentEvent.value.meshulashRounds.add(
                                                MeshulashRound(
                                                    round: widget.round.round + 1,
                                                    participantsInRound: [eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound[index]]
                                                )
                                            );
                                            eventController.setParticipantMeshulashPosition(eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound[index], eventController.currentEvent.value.meshulashRounds[widget.round.round+1].participantsInRound.length);
                                          }
                                          else {
                                            eventController.currentEvent.value.meshulashRounds[widget.round.round+1].participantsInRound
                                                .add(eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound[index]);
                                            eventController.setParticipantMeshulashPosition(eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound[index], eventController.currentEvent.value.meshulashRounds[widget.round.round+1].participantsInRound.length);
                                          }
                                          eventController.currentEvent.value.meshulashRounds[widget.round.round] = widget.round;
                                          widget.round.participantsInRound.remove(eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound[index]);
                                          eventController.update();
                                          eventController.currentEvent.value.saveToFirestore();
                                          //setState(() {
                                          //});
                                          eventController.loading.value = false;
                                        }
                                      },
                                      onLongPress: () async {
                                        var res = await showDialog<List<String>>(
                                            context: context,
                                            builder: (BuildContext context) =>
                                            CommentsDialog(
                                                commentsList: eventController.gradesData.listOfCommentsMeshulash,
                                              selectedComments: (eventController.getParticipant(eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound[index]).meshulashInstructorComments),
                                            ));
                                        if (res!=null){
                                          eventController.addMeshulashComments(res,eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound[index]);
                                        }
                                      },
                                      child: Text(
                                          eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound[index].toString(),
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value),
                                      ),
                                  ),
                                ),
                              );
                          }))),
                ],
              ),
            ));

    });
  }
}
