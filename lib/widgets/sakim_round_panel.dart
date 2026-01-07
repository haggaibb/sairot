import 'package:flutter/material.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import 'comments_dialog.dart';
import 'package:sairot/models/sakim_round.dart';
import '../models/types.dart';
import '../utils/tablet_utils.dart';
import '../models/participant.dart';


class SakimRoundPanel extends StatefulWidget {

  const SakimRoundPanel({super.key, required this.round, required this.inOrderOfArrival});
  final SakimRound round;
  final bool inOrderOfArrival;

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
    
    // Use widget.inOrderOfArrival to ensure rebuild when it changes
    final inOrderOfArrival = widget.inOrderOfArrival;
    
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
                        children: () {
                          // Get participants in this round
                          final participantsInRound = List<int>.from(
                            eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound
                          );
                          
                          // Sort based on order of arrival toggle
                          if (inOrderOfArrival) {
                            // Sort by Sakim grade (descending - higher grade = better position)
                            participantsInRound.sort((a, b) => eventController
                                .getSakimGrade(b)
                                .compareTo(eventController.getSakimGrade(a)));
                          } else {
                            // Sort by participant number ascending
                            participantsInRound.sort((a, b) => a.compareTo(b));
                          }
                          
                          return List.generate(participantsInRound.length, (index) {
                            final participantNumber = participantsInRound[index];
                            // Calculate absolute position based on sorted order
                            final currentRound = widget.round.round;
                            int participantsAhead = 0;
                            
                            // Count all participants in rounds higher than current round
                            for (var round in eventController.currentEvent.value.sakimRounds) {
                              if (round.round > currentRound) {
                                participantsAhead += round.participantsInRound.length;
                              }
                            }
                            
                            // Calculate position based on sorted order
                            int position;
                            if (inOrderOfArrival) {
                              // When sorted by grade, calculate position based on sorted order
                              // Get all participants sorted by grade
                              final allParticipants = eventController.currentEvent.value
                                  .getParticipantsByStatus(ParticipantStatus.Active);
                              final sortedByGrade = List<Participant>.from(allParticipants)
                                ..sort((a, b) => eventController
                                    .getSakimGrade(b.number)
                                    .compareTo(eventController.getSakimGrade(a.number)));
                              
                              // Find position in sorted list (1-based)
                              final foundIndex = sortedByGrade.indexWhere((p) => p.number == participantNumber);
                              position = foundIndex >= 0 ? foundIndex + 1 : participantsAhead + index + 1;
                            } else {
                              // When sorted by number, calculate position based on original round order
                              // Need to find the original index in the unsorted round
                              final originalRoundList = eventController.currentEvent.value
                                  .sakimRounds[currentRound].participantsInRound;
                              final originalIndex = originalRoundList.indexOf(participantNumber);
                              position = participantsAhead + (originalIndex >= 0 ? originalIndex : index) + 1;
                            }
                          final scaledFontSize = getTabletScaledFontSize(context, eventController.userFontSize.value);
                          
                          return Padding(
                            padding: EdgeInsets.all(tablet ? 7.5 : 5.0),
                            child: GestureDetector(
                              onDoubleTap: () {
                                eventController.loading.value = true;
                                final participantNumber = eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound[index];
                                
                                // Get the stored original index
                                final originalIndex = eventController.getLastSakimIndex(participantNumber);
                                
                                // Remove the last position from the array
                                eventController.removeLastSakimPosition(participantNumber);
                                
                                // Remove participant from current round
                                widget.round.participantsInRound.remove(participantNumber);
                                
                                // Insert participant at original index in previous round (or add to end if no index stored)
                                final previousRound = eventController.currentEvent.value.sakimRounds[widget.round.round-1];
                                if (originalIndex != null && originalIndex >= 0 && originalIndex <= previousRound.participantsInRound.length) {
                                  previousRound.participantsInRound.insert(originalIndex, participantNumber);
                                } else {
                                  previousRound.participantsInRound.add(participantNumber);
                                }
                                
                                // Clear the stored index
                                eventController.setLastSakimIndex(participantNumber, null);
                                
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
                                          final participantNumber = eventController.currentEvent.value.sakimRounds[widget.round.round].participantsInRound[index];
                                          
                                          // Store the current index before moving forward (for undo)
                                          eventController.setLastSakimIndex(participantNumber, index);
                                          
                                          if (eventController.currentEvent.value.sakimRounds.length == widget.round.round+1) {
                                            eventController.currentEvent.value.sakimRounds.add(
                                                SakimRound(
                                                    round: widget.round.round + 1,
                                                    participantsInRound: [participantNumber]
                                                )
                                            );
                                            eventController.setParticipantSakimPosition(participantNumber, eventController.currentEvent.value.sakimRounds[widget.round.round+1].participantsInRound.length);
                                          } else {
                                            eventController.currentEvent.value.sakimRounds[widget.round.round+1].participantsInRound
                                                .add(participantNumber);
                                            eventController.setParticipantSakimPosition(participantNumber, eventController.currentEvent.value.sakimRounds[widget.round.round+1].participantsInRound.length);
                                          }
                                          eventController.currentEvent.value.sakimRounds[widget.round.round] = widget.round;
                                          //setState(() {
                                          widget.round.participantsInRound.remove(participantNumber);
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
                                  // Position badge - notification style in upper right corner (only show if round > 0)
                                  if (widget.round.round > 0)
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
                        });
                      }(),
                    ),
                  ),
              ],
            ),
          ));

    });
  }
}
