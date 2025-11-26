import 'package:flutter/material.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import 'package:sairot/models/meshulash_round.dart';
import '../widgets/comments_dialog.dart';
import '../models/types.dart';
import '../utils/tablet_utils.dart';

class MeshulashGridView extends StatelessWidget {
  const MeshulashGridView({super.key});

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(EventController());
    bool tablet = isTablet(context);
    double scaledFontSize = getTabletScaledFontSize(context, eventController.userFontSize.value);
    
    return GetX<EventController>(builder: (_) {
      // Get all active participants
      final activeParticipants = _.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active);
      
      if (activeParticipants.isEmpty) {
        return Center(
          child: Text(
            'אין משתתפים פעילים',
            style: TextStyle(fontSize: _.userFontSize.value),
          ),
        );
      }

      return GridView.count(
        childAspectRatio: _.userChildAspectRatio.value,
        crossAxisCount: tablet ? 4 : 3,
        mainAxisSpacing: 5,
        crossAxisSpacing: 3,
        padding: EdgeInsets.all(3),
        children: activeParticipants.map((participant) {
          final participantNumber = participant.number;
          
          // Find which round this participant is in
          int currentRound = _.currentEvent.value.meshulashRounds.indexWhere(
            (round) => round.participantsInRound.contains(participantNumber),
          );
          
          // If participant not found in any round, they're in round 0 (initial round)
          if (currentRound == -1) {
            currentRound = 0;
          }

          return Padding(
            padding: const EdgeInsets.all(2.0),
            child: GestureDetector(
              onDoubleTap: () {
                if (_.meshulashEditModeOn.value && currentRound > 0) {
                  _.loading.value = true;
                  _.currentEvent.value.meshulashRounds[currentRound - 1].participantsInRound.add(participantNumber);
                  _.currentEvent.value.meshulashRounds[currentRound].participantsInRound.remove(participantNumber);
                  _.update();
                  _.currentEvent.value.saveToFirestore();
                  _.loading.value = false;
                }
              },
              child: Stack(
                children: [
                  SizedBox.expand(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    onPressed: () {
                      if (_.meshulashEditModeOn.value) {
                        _.loading.value = true;
                        print(currentRound);
                        if (_.currentEvent.value.meshulashRounds.length == currentRound + 1) {
                          _.currentEvent.value.meshulashRounds.add(
                            MeshulashRound(
                              round: currentRound + 1,
                              participantsInRound: [participantNumber],
                            ),
                          );
                          _.setParticipantMeshulashPosition(participantNumber, _.currentEvent.value.meshulashRounds[currentRound + 1].participantsInRound.length);
                        } else {
                          _.currentEvent.value.meshulashRounds[currentRound + 1].participantsInRound.add(participantNumber);
                          _.setParticipantMeshulashPosition(participantNumber, _.currentEvent.value.meshulashRounds[currentRound + 1].participantsInRound.length);
                        }
                        _.currentEvent.value.meshulashRounds[currentRound].participantsInRound.remove(participantNumber);
                        _.update();
                        _.currentEvent.value.saveToFirestore();
                        _.loading.value = false;
                      }
                    },
                    onLongPress: () async {
                      var res = await showDialog<List<String>>(
                        context: context,
                        builder: (BuildContext context) => CommentsDialog(
                          commentsList: _.gradesData.listOfCommentsMeshulash,
                          selectedComments: _.getParticipant(participantNumber).meshulashInstructorComments,
                          title: participantNumber.toString(),
                        ),
                      );
                      if (res != null) {
                        if (res.contains(ParticipantStatus.Droped.name)) {
                          print('dropped');
                          _.loading.value = true;
                          _.dropParticipant(participantNumber);
                          // Remove from current round if exists
                          if (currentRound != -1 && currentRound < _.currentEvent.value.meshulashRounds.length) {
                            _.currentEvent.value.meshulashRounds[currentRound].participantsInRound.remove(participantNumber);
                          }
                          _.loading.value = false;
                        } else {
                          _.addMeshulashComments(res, participantNumber);
                        }
                      }
                    },
                    child: Text(
                      participantNumber.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: scaledFontSize,
                      ),
                      ),
                    ),
                  ),
                  // Round indicator badge
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        currentRound.toString(),
                        style: TextStyle(
                          fontSize: scaledFontSize * 1.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

