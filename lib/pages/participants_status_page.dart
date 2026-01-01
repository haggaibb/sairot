import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/types.dart';
import '../event_controller.dart';
import '../models/participant.dart';
import '../utils/tablet_utils.dart';
import '../mixins/event_validation_mixin.dart';

class ParticipantsStatusPage extends StatefulWidget {
  const ParticipantsStatusPage({super.key});

  @override
  State<ParticipantsStatusPage> createState() => _ParticipantsStatusPageState();
}

class _ParticipantsStatusPageState extends State<ParticipantsStatusPage> with EventValidationMixin {
  final eventController = Get.put(EventController());

  @override
  void initState() {
    super.initState();
    checkEventValidity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh the event state when page becomes visible again
    // This ensures UI updates when navigating back from other pages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      eventController.currentEvent.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Color.fromARGB(255, 0, 66, 136)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('סטטוס חניכים'),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Text('פעילים',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  /// **Active Participants**
                  GetX<EventController>(builder: (_) {
                    final isFinalized = _.currentEvent.value.finalized;
                    final activeParticipants = _.currentEvent.value
                        .getParticipantsByStatus(ParticipantStatus.Active);
                    return isFinalized
                        ? _buildParticipantGrid(context, activeParticipants, ParticipantStatus.Active)
                        : DragTarget<int>(
                            onWillAcceptWithDetails:
                                (DragTargetDetails<int> details) {
                              int participantNumber = details.data;
                              return !activeParticipants
                                  .any((p) => p.number == participantNumber);
                            },
                            onAcceptWithDetails:
                                (DragTargetDetails<int> details) {
                              int participantNumber = details.data;

                              var participant = _.currentEvent.value
                                  .getParticipantsByStatus(
                                      ParticipantStatus.Droped)
                                  .firstWhereOrNull(
                                      (p) => p.number == participantNumber);

                              if (participant != null) {
                                // Update status immediately
                                participant.status = ParticipantStatus.Active;
                                
                                // Restore participant to the appropriate round
                                // Position data indicates which round they were in
                                // If they have N positions, they moved through N rounds, so they should be in round N
                                
                                // Check meshulash
                                if (participant.meshulashPositions.isNotEmpty && _.currentEvent.value.meshulashRounds.isNotEmpty) {
                                  int targetRound = participant.meshulashPositions.length; // Round number = number of positions
                                  // Ensure target round exists, if not use the highest available round
                                  if (targetRound >= _.currentEvent.value.meshulashRounds.length) {
                                    targetRound = _.currentEvent.value.meshulashRounds.length - 1;
                                  }
                                  if (targetRound < 0) targetRound = 0;
                                  
                                  // Add to target round if not already there
                                  if (!_.currentEvent.value.meshulashRounds[targetRound].participantsInRound.contains(participantNumber)) {
                                    _.currentEvent.value.meshulashRounds[targetRound].participantsInRound.add(participantNumber);
                                  }
                                }
                                
                                // Check sakim
                                if (participant.sakimPositions.isNotEmpty && _.currentEvent.value.sakimRounds.isNotEmpty) {
                                  int targetRound = participant.sakimPositions.length;
                                  if (targetRound >= _.currentEvent.value.sakimRounds.length) {
                                    targetRound = _.currentEvent.value.sakimRounds.length - 1;
                                  }
                                  if (targetRound < 0) targetRound = 0;
                                  
                                  if (!_.currentEvent.value.sakimRounds[targetRound].participantsInRound.contains(participantNumber)) {
                                    _.currentEvent.value.sakimRounds[targetRound].participantsInRound.add(participantNumber);
                                  }
                                }
                                
                                // Update UI immediately (synchronously) to prevent flicker
                                _.currentEvent.refresh();
                                _.update();
                                
                                // Save to Firestore asynchronously (don't await to avoid blocking UI)
                                _.currentEvent.value.saveToFirestore();
                              }
                            },
                            builder: (context, candidateData, rejectedData) {
                              return _buildParticipantGrid(
                                  context, activeParticipants, ParticipantStatus.Active);
                            },
                          );
                  }),
                  //const Divider(thickness: 5),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text('פרשו',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  /// **Dropped Participants**
                  GetX<EventController>(builder: (_) {
                    final droppedParticipants = _.currentEvent.value
                        .getParticipantsByStatus(ParticipantStatus.Droped);
                    final isFinalized = _.currentEvent.value.finalized;
                    return isFinalized
                        ? _buildParticipantGrid(
                            context, droppedParticipants, ParticipantStatus.Droped)
                        : DragTarget<int>(
                            onWillAcceptWithDetails: (details) {
                              return !droppedParticipants
                                  .any((p) => p.number == details.data);
                            },
                            onAcceptWithDetails: (details) {
                              int participantNumber = details.data;

                              var participant = _.currentEvent.value
                                  .getParticipantsByStatus(
                                      ParticipantStatus.Active)
                                  .firstWhereOrNull(
                                      (p) => p.number == participantNumber);

                              if (participant != null) {
                                // Update status immediately
                                participant.status = ParticipantStatus.Droped;
                                
                                // Update UI immediately (synchronously) to prevent flicker
                                _.currentEvent.refresh();
                                _.update();
                                
                                // Save to Firestore asynchronously (don't await to avoid blocking UI)
                                _.currentEvent.value.saveToFirestore();
                              }
                            },
                            builder: (context, candidateData, rejectedData) {
                              return _buildParticipantGrid(context, droppedParticipants,
                                  ParticipantStatus.Droped);
                            },
                          );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// **Reusable GridView for Participants**
  Widget _buildParticipantGrid(
      BuildContext context, List<Participant> participants, ParticipantStatus status) {
    final isFinalized = eventController.currentEvent.value.finalized;
    bool tablet = isTablet(context);
    int crossAxisCount = tablet ? 4 : 3;
    double heightMultiplier = tablet ? 1.3 : 1.0;
    
    return Container(
      padding: EdgeInsets.all(8),
      height: (participants.length / 3 + 2) < 2
          ? (tablet ? 156 : 120)
          : ((participants.length / 3 + 2) * 55 * heightMultiplier),
      color: status == ParticipantStatus.Active
          ? Colors.green.shade800.withValues(alpha: 0.7)
          : Colors.red.shade300.withValues(alpha: 0.7),
      child: GridView.count(
        crossAxisSpacing: 20,
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        childAspectRatio: eventController.userChildAspectRatio.value,
        children: participants.map((participant) {
          return isFinalized
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {}, // Just show participant, no drag
                  child: Text(participant.number.toString(),
                      style: TextStyle(
                          fontSize: getTabletScaledFontSize(context, eventController.userFontSize.value),
                          fontWeight: FontWeight.bold)),
                )
              : Draggable<int>(
                  data: participant.number,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 80,
                      height: 40,
                      decoration: BoxDecoration(
                        color: status == ParticipantStatus.Active
                            ? Colors.blue.shade200
                            : Colors.red.shade200,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 5)
                        ],
                      ),
                      child: Center(
                        child: Text(participant.number.toString(),
                            style: TextStyle(
                                fontSize: getTabletScaledFontSize(context, eventController.userFontSize.value),
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    width: 80,
                    height: 40,
                    color: Colors.transparent,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {},
                    child: Text(participant.number.toString(),
                        style: TextStyle(
                            fontSize: getTabletScaledFontSize(context, eventController.userFontSize.value),
                            fontWeight: FontWeight.bold)),
                  ),
                );
        }).toList(),
      ),
    );
  }
}
