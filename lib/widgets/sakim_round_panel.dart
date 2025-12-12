import 'package:flutter/material.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import 'comments_dialog.dart';
import 'package:sairot/models/sakim_round.dart';
import '../models/types.dart';
import '../utils/tablet_utils.dart';


class SakimRoundPanel extends StatefulWidget {

  const SakimRoundPanel({super.key, required this.round});
  final SakimRound round;

  @override
  State<SakimRoundPanel> createState() => _SakimRoundPanelState();
}

class _SakimRoundPanelState extends State<SakimRoundPanel> {
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
      var h = eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound.length / 3 + 2;
      if (eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound.isEmpty) return SizedBox();
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
                widget.round.round==0?SizedBox.shrink():Text(' שקים מקצה ${widget.round.round} ',
                    style:
                    TextStyle(fontSize: tablet ? 28.0 : 22.0, fontWeight: FontWeight.bold)),
                Expanded(
                    child: GridView.count(
                        physics: NeverScrollableScrollPhysics(),
                        childAspectRatio: eventController.userChildAspectRatio.value,
                        crossAxisCount: crossAxisCount,
                        children: List.generate(
                            eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound.length, (index) {
                          return Padding(
                            padding: EdgeInsets.all(tablet ? 7.5 : 5.0),
                            child: GestureDetector(
                              onDoubleTap: () {
                                eventController.loading.value = true;
                                eventController.currentEvent.value.sakimRounds[widget.round.round-1].participantsInRound.add(eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound[index]);
                                widget.round.participantsInRound.remove(eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound[index]);
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
                                    if (eventController.sakimEditModeOn.value) {
                                      eventController.loading.value = true;
                                      if (eventController.currentEvent.value.sakimRounds.length == widget.round.round+1) {
                                        eventController.currentEvent.value.sakimRounds.add(
                                            SakimRound(
                                                round: widget.round.round + 1,
                                                participantsInRound: [eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound[index]]
                                            )
                                        );
                                        eventController.setParticipantSakimPosition(eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound[index], eventController.currentEvent.value.sakimRounds[widget.round.round+1].participantsInRound.length);
                                      } else {
                                        eventController.currentEvent.value.sakimRounds[widget.round.round+1].participantsInRound
                                            .add(eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound[index]);
                                        eventController.setParticipantSakimPosition(eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound[index], eventController.currentEvent.value.sakimRounds[widget.round.round+1].participantsInRound.length);
                                      }
                                      eventController.currentEvent.value.sakimRounds[widget.round.round] = widget.round;
                                      //setState(() {
                                      widget.round.participantsInRound.remove(eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound[index]);
                                      //});
                                      eventController.loading.value = false;
                                      eventController.currentEvent.value.saveToFirestore();
                                    }
                                  },
                                  onLongPress: () async {
                                    var participantNumber = eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound[index];
                                    var res = await showDialog<List<String>>(
                                        context: context,
                                        builder: (BuildContext context) =>
                                            CommentsDialog(
                                                commentsList: eventController.gradesData.listOfCommentsSakim,
                                              selectedComments: (eventController.getParticipant(participantNumber)).sakimInstructorComments,
                                              title: participantNumber.toString(),
                                            ));
                                    if (res!=null) {
                                      if (res.contains(ParticipantStatus.Droped.name)) {
                                        print('dropped');
                                        eventController.loading.value =
                                        true;
                                        eventController.dropParticipant(
                                            widget.round.participantsInRound[index]);
                                        widget.round.participantsInRound
                                            .removeAt(index);
                                        eventController.loading.value=false;
                                      } else {
                                        eventController.addSakimComments(res,eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound[index]);
                                      }
                                    }
                                  },
                                  child: Text(
                                      eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound[index].toString(),
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
