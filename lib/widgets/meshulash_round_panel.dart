import 'package:flutter/material.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import 'package:sairot/models/meshulash_round.dart';
import '../widgets/comments_dialog.dart';
import '../models/types.dart';
import '../utils/tablet_utils.dart';

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
    bool tablet = isTablet(context);
    int crossAxisCount = tablet ? (eventController.numberOfCols + 1) : eventController.numberOfCols;
    
    return GetX<EventController>(builder: (eventController) {
      var h = eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound.length / 3 + 2;
        if (eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound.isEmpty) return SizedBox();
        double heightMultiplier = tablet ? 1.3 : 1.0;
        return SizedBox(
            height: h < 2 ? (tablet ? 156 : 120) : (h * 55 * heightMultiplier),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Divider(
                    thickness: tablet ? 45.0 : 30.0,
                  ),
                      widget.round.round==0?SizedBox.shrink():Text('משלוש מקצה ${widget.round.round}  ',
                      style:
                      TextStyle(fontSize: tablet ? 28.0 : 22.0, fontWeight: FontWeight.bold)),
                  Expanded(
                      child: GridView.count(
                          physics: NeverScrollableScrollPhysics(),
                          childAspectRatio: eventController.userChildAspectRatio.value,
                          crossAxisCount: crossAxisCount,
                          children: List.generate(
                              eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound.length, (index) {
                              return Padding(
                                padding: EdgeInsets.all(tablet ? 7.5 : 5.0),
                                child: GestureDetector(
                                  onDoubleTap: () {
                                    if (eventController.meshulashEditModeOn.value) {
                                      eventController.loading.value = true;
                                      eventController.currentEvent.value.meshulashRounds[widget.round.round-1].participantsInRound.add(eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound[index]);
                                      widget.round.participantsInRound.remove(eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound[index]);
                                      eventController.update();
                                      eventController.currentEvent.value.saveToFirestore();
                                      eventController.loading.value = false;
                                    }
                                  },
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                      onPressed: () {
                                        if (eventController.meshulashEditModeOn.value) {
                                          eventController.loading.value = true;
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
                                        var participantNumber = eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound[index];
                                        var res = await showDialog<List<String>>(
                                            context: context,
                                            builder: (BuildContext context) =>
                                            CommentsDialog(
                                                commentsList: eventController.gradesData.listOfCommentsMeshulash,
                                              selectedComments: (eventController.getParticipant(participantNumber).meshulashInstructorComments),
                                              title: participantNumber.toString(),
                                            ));
                                        if (res!=null) {
                                          if (res.contains(ParticipantStatus.Droped.name)) {
                                            eventController.loading.value =
                                            true;
                                            eventController.dropParticipant(
                                                widget.round.participantsInRound[index]);
                                            widget.round.participantsInRound
                                                .removeAt(index);
                                            eventController.loading.value=false;
                                          } else {
                                            eventController.addMeshulashComments(res,eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound[index]);
                                          }
                                        }
                                      },
                                      child: Text(
                                          eventController.currentEvent.value.meshulashRounds[widget.round.round].participantsInRound[index].toString(),
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: getTabletScaledFontSize(context, eventController.userFontSize.value)),
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
