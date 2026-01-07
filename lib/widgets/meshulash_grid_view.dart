import 'package:flutter/material.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import 'package:sairot/models/meshulash_round.dart';
import '../widgets/comments_dialog.dart';
import '../models/types.dart';
import '../utils/tablet_utils.dart';
import '../models/system.dart';
import '../models/participant.dart';

class MeshulashGridView extends StatelessWidget {
  const MeshulashGridView({super.key, required this.inOrderOfArrival});
  final bool inOrderOfArrival;

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

      // For tablets, use 3 columns if font size is increased (big or biggest)
      // In landscape mode, always use 4 columns
      final orientation = MediaQuery.of(context).orientation;
      bool isLandscape = orientation == Orientation.landscape;
      
      int crossAxisCount;
      if (tablet) {
        if (isLandscape) {
          crossAxisCount = 4;
        } else if (_.system.value.accessibility == Accessibility.big || 
            _.system.value.accessibility == Accessibility.biggest) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 4;
        }
      } else {
        crossAxisCount = 3;
      }

      // Sort participants based on order of arrival toggle
      final participantsList = List<Participant>.from(activeParticipants);
      if (inOrderOfArrival) {
        // Sort by Meshulash grade (descending - higher grade = better position)
        participantsList.sort((a, b) => _.getMeshulashGrade(b.number)
            .compareTo(_.getMeshulashGrade(a.number)));
      } else {
        // Sort by recruit number ascending
        participantsList.sort((a, b) => a.number.compareTo(b.number));
      }

      return GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        childAspectRatio: _.userChildAspectRatio.value,
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 5,
        crossAxisSpacing: 3,
        padding: EdgeInsets.all(3),
        children: participantsList.map((participant) {
          final participantNumber = participant.number;
          
          // Find which round this participant is in
          int currentRound = _.currentEvent.value.meshulashRounds.indexWhere(
            (round) => round.participantsInRound.contains(participantNumber),
          );
          
          // If participant not found in any round, they're in round 0 (initial round)
          if (currentRound == -1) {
            currentRound = 0;
          }

          // Calculate absolute position to determine if participant is in first place
          int participantsAhead = 0;
          for (var round in _.currentEvent.value.meshulashRounds) {
            if (round.round > currentRound) {
              participantsAhead += round.participantsInRound.length;
            }
          }
          int indexInRound = currentRound >= 0 && currentRound < _.currentEvent.value.meshulashRounds.length
              ? _.currentEvent.value.meshulashRounds[currentRound].participantsInRound.indexOf(participantNumber)
              : -1;
          final absolutePosition = indexInRound >= 0 ? participantsAhead + indexInRound + 1 : 0;
          final isFirstPlace = absolutePosition == 1;

          return Padding(
            padding: const EdgeInsets.all(2.0),
            child: GestureDetector(
              onDoubleTap: () {
                if (_.meshulashEditModeOn.value && currentRound > 0) {
                  _.loading.value = true;
                  
                  // Get the stored original index
                  final originalIndex = _.getLastMeshulashIndex(participantNumber);
                  
                  // Remove the last position from the array
                  _.removeLastMeshulashPosition(participantNumber);
                  
                  // Remove participant from current round
                  _.currentEvent.value.meshulashRounds[currentRound].participantsInRound.remove(participantNumber);
                  
                  // Insert participant at original index in previous round (or add to end if no index stored)
                  final previousRound = _.currentEvent.value.meshulashRounds[currentRound - 1];
                  if (originalIndex != null && originalIndex >= 0 && originalIndex <= previousRound.participantsInRound.length) {
                    previousRound.participantsInRound.insert(originalIndex, participantNumber);
                  } else {
                    previousRound.participantsInRound.add(participantNumber);
                  }
                  
                  // Clear the stored index
                  _.setLastMeshulashIndex(participantNumber, null);
                  
                  _.update();
                  _.currentEvent.value.saveToFirestore();
                  _.loading.value = false;
                }
              },
              child: Stack(
                clipBehavior: Clip.hardEdge, // Keep badge within chip boundaries
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
                        
                        // Find the current index in the round before moving forward (for undo)
                        final currentRoundList = _.currentEvent.value.meshulashRounds[currentRound].participantsInRound;
                        final currentIndex = currentRoundList.indexOf(participantNumber);
                        
                        // Store the current index before moving forward (for undo)
                        if (currentIndex != -1) {
                          _.setLastMeshulashIndex(participantNumber, currentIndex);
                        }
                        
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
                  // Position badge - within chip border, consistent size
                  // First place gets green badge that's 20% larger
                  // Only show if round number > 0 (not the initial round)
                  if (currentRound >= 0 && currentRound < _.currentEvent.value.meshulashRounds.length &&
                      _.currentEvent.value.meshulashRounds[currentRound].round > 0)
                    Positioned(
                      top: tablet ? 4 : 3,
                      right: tablet ? 4 : 3,
                      child: Container(
                        width: tablet ? (isFirstPlace ? 33.6 : 28) : (isFirstPlace ? 28.8 : 24), // 20% larger if first place
                        height: tablet ? (isFirstPlace ? 33.6 : 28) : (isFirstPlace ? 28.8 : 24), // 20% larger if first place
                        decoration: BoxDecoration(
                          color: isFirstPlace ? Colors.green : Colors.red, // Green for first place
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: tablet ? 1.9 : 2.16,
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
                            _.currentEvent.value.meshulashRounds[currentRound].round.toString(),
                            style: TextStyle(
                              fontSize: tablet ? scaledFontSize * 0.532 : scaledFontSize * 0.648,
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
        }).toList(),
      );
    });
  }
}

