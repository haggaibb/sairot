import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/types.dart';
import 'ctx.dart';
import 'models/participant.dart';

class ParticipantsStatusPage extends StatefulWidget {
  const ParticipantsStatusPage({super.key});

  @override
  State<ParticipantsStatusPage> createState() => _ParticipantsStatusPageState();
}

class _ParticipantsStatusPageState extends State<ParticipantsStatusPage> {
  final eventController = Get.put(Controller());

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
                  const Text('פעילים', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

                  /// **Active Participants**
                  GetX<Controller>(builder: (_) {
                    final activeParticipants = _.currentEvent.value
                        .getParticipantsByStatus(ParticipantStatus.Active);

                    return DragTarget<int>(
                      onWillAccept: (participantNumber) {
                        return !activeParticipants
                            .any((p) => p.number == participantNumber);
                      },
                      onAccept: (participantNumber) {
                        var participant = _.currentEvent.value
                            .getParticipantsByStatus(ParticipantStatus.Droped)
                            .firstWhereOrNull((p) => p.number == participantNumber);

                        if (participant != null) {
                          participant.status = ParticipantStatus.Active;
                          _.currentEvent.refresh(); // Ensure UI updates
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        return _buildParticipantGrid(activeParticipants, ParticipantStatus.Active);
                      },
                    );
                  }),

                  //const Divider(thickness: 5),
                  const SizedBox(height: 10,),
                  const Text('פרשו', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

                  /// **Dropped Participants**
                  GetX<Controller>(builder: (_) {
                    final droppedParticipants = _.currentEvent.value
                        .getParticipantsByStatus(ParticipantStatus.Droped);

                    return DragTarget<int>(
                      onWillAcceptWithDetails: (details) {
                        return !droppedParticipants.any((p) => p.number == details.data);
                      },
                      onAcceptWithDetails: (details) {
                        int participantNumber = details.data;

                        var participant = _.currentEvent.value
                            .getParticipantsByStatus(ParticipantStatus.Active)
                            .firstWhereOrNull((p) => p.number == participantNumber);

                        if (participant != null) {
                          participant.status = ParticipantStatus.Droped;

                          // Ensure UI updates properly
                          _.currentEvent.update((val) {
                            val?.participants = List.from(val!.participants); // Force update
                          });
                          _.update();  // Trigger GetX UI refresh
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        return _buildParticipantGrid(droppedParticipants, ParticipantStatus.Droped);
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
  Widget _buildParticipantGrid(List<Participant> participants, ParticipantStatus status) {
    var h = participants.length / 3 + 2;
    return Container(
      height:  h < 2 ? 120 : h * 55,
      padding: EdgeInsets.all(8),
      color: status == ParticipantStatus.Active
          ? Colors.green.shade800.withValues(
        alpha: (Colors.green.shade300.a * 0.7), // 50% opacity
        red: Colors.green.shade300.r.toDouble(),
        green: Colors.green.shade100.g.toDouble(),
        blue: Colors.green.shade100.b.toDouble(),
      )
          : Colors.red.shade300..withValues(
        alpha: (Colors.green.shade100.a * 0.7), // 50% opacity
        red: Colors.green.shade100.r.toDouble(),
        green: Colors.green.shade100.g.toDouble(),
        blue: Colors.green.shade100.b.toDouble(),
      ),
      child: GridView.count(
        crossAxisSpacing: 20,
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        childAspectRatio: eventController.userChildAspectRatio.value,
        children: participants.map((participant) {
          return Draggable<int>(
            data: participant.number, // Dragging the participant's number
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
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                ),
                child: Center(
                  child: Text(participant.number.toString(),
                      style: TextStyle(fontSize: eventController.userFontSize.value, fontWeight: FontWeight.bold)),
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
                  style: TextStyle(fontSize: eventController.userFontSize.value, fontWeight: FontWeight.bold)),
            ),
          );
        }).toList(),
      ),
    );
  }
}