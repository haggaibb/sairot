import 'package:flutter/material.dart';
import '../ctx.dart';
import 'package:get/get.dart';
import 'comments_dialog.dart';
import 'package:sairot/models/sakim_round.dart';

class SakimRoundPanel extends StatefulWidget {

  const SakimRoundPanel({super.key, required this.round});
  final SakimRound round;

  @override
  State<SakimRoundPanel> createState() => _SakimRoundPanelState();
}

class _SakimRoundPanelState extends State<SakimRoundPanel> {
  final eventController = Get.put(Controller());

  @override
  void initState() {

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetX<Controller>(builder: (eventController) {
      var h = eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound.length / 3 + 2;
      if (eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound.isEmpty) return SizedBox();
      return SizedBox(
          height: h < 2 ? 120 : h * 50,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Divider(
                  thickness: 30,
                ),
                widget.round.round==0?SizedBox.shrink():Text(' שקים מקצה ${widget.round.round} ',
                    style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Expanded(
                    child: GridView.count(
                        childAspectRatio: 3,
                        crossAxisCount: eventController.numberOfCols,
                        children: List.generate(
                            eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  fixedSize: const Size(10, 20),
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
                                  var res = await showDialog<List<String>>(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          CommentsDialog(commentsList: eventController.gradesData.listOfCommentsSakim));
                                  if (res!=null){
                                    eventController.addSakimComments(res,eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound[index]);
                                  }
                                },
                                child: Text(eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound[index].toString())),
                          );
                        }))),
              ],
            ),
          ));

    });
  }
}
