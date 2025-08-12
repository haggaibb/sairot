import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/types.dart';
import '../event_controller.dart';
import '../models/participant.dart';

class ParticipantsStatusPage extends StatefulWidget {
  const ParticipantsStatusPage({super.key});

  @override
  State<ParticipantsStatusPage> createState() => _ParticipantsStatusPageState();
}

class _ParticipantsStatusPageState extends State<ParticipantsStatusPage> {
  final eventController = Get.put(EventController());

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
                        ? _buildParticipantGrid(activeParticipants, ParticipantStatus.Active)
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
                                participant.status = ParticipantStatus.Active;
                                _.currentEvent.refresh(); // Ensure UI updates
                              }
                            },
                            builder: (context, candidateData, rejectedData) {
                              return _buildParticipantGrid(
                                  activeParticipants, ParticipantStatus.Active);
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
                            droppedParticipants, ParticipantStatus.Droped)
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
                                participant.status = ParticipantStatus.Droped;

                                // Ensure UI updates properly
                                _.currentEvent.update((val) {
                                  val?.participants = List.from(
                                      val.participants); // Force update
                                });
                                _.update(); // Trigger GetX UI refresh
                              }
                            },
                            builder: (context, candidateData, rejectedData) {
                              return _buildParticipantGrid(droppedParticipants,
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
      List<Participant> participants, ParticipantStatus status) {
    final isFinalized = eventController.currentEvent.value.finalized;
    return Container(
      padding: EdgeInsets.all(8),
      height: (participants.length / 3 + 2) < 2
          ? 120
          : (participants.length / 3 + 2) * 55,
      color: status == ParticipantStatus.Active
          ? Colors.green.shade800.withOpacity(0.7)
          : Colors.red.shade300.withOpacity(0.7),
      child: GridView.count(
        crossAxisSpacing: 20,
        crossAxisCount: 3,
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
                          fontSize: eventController.userFontSize.value,
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
                                fontSize: eventController.userFontSize.value,
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
                            fontSize: eventController.userFontSize.value,
                            fontWeight: FontWeight.bold)),
                  ),
                );
        }).toList(),
      ),
    );
  }
}
