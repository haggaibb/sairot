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
                          final participantNumber = eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound[index];
                          // Calculate absolute position based on entry order
                          // Count participants in higher (better) rounds, then add index in current round
                          final currentRound = widget.round.round;
                          int participantsAhead = 0;
                          
                          // Count all participants in rounds higher than current round
                          for (var round in eventController.currentEvent.value.sakimRounds) {
                            if (round.round > currentRound) {
                              participantsAhead += round.participantsInRound.length;
                            }
                          }
                          
                          // Position = participants ahead + index in current round + 1
                          final position = participantsAhead + index + 1;
                          final scaledFontSize = getTabletScaledFontSize(context, eventController.userFontSize.value);
                          
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
                              child: Stack(
                                clipBehavior: Clip.none, // Allow badge to extend beyond chip boundaries
                                children: [
                                  ElevatedButton(
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
                                          participantNumber.toString(),
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: scaledFontSize),
                                      ),
                                  ),
                                  // Position badge - notification style in upper right corner
                                  Positioned(
                                    top: tablet ? -14.68 : -12.26, // 5px lower than previous
                                    right: tablet ? -11.68 : -9.26, // 3px to the left
                                    child: Container(
                                      width: tablet ? 28 : 24, // Fixed width for consistent size
                                      height: tablet ? 28 : 24, // Fixed height for consistent size
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: tablet ? 1.9 : 2.16, // 5% smaller on tablet (2.0 * 0.95), 10% smaller on mobile (2.4 * 0.9)
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          position.toString(),
                                          style: TextStyle(
                                            fontSize: tablet ? scaledFontSize * 0.532 : scaledFontSize * 0.648, // 5% smaller on tablet (0.56 * 0.95), 10% smaller on mobile (0.72 * 0.9)
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
