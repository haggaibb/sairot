import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/participant.dart';
import '../event_controller.dart';

class LeadershipChart extends StatelessWidget {
  final int number;

  LeadershipChart({super.key, required this.number}); // The round where our participant is currently competing

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(EventController());
    int participantIndex = eventController.currentEvent.value.participants.indexWhere((participant) => participant.number== number);
    return Scaffold(
      //appBar: AppBar(title: Text("Participant Progress Chart")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:  Wrap(
          spacing: 12,
          children:  eventController.currentEvent.value.participants.firstWhere((p)=> p.number == number).leadershipInstructorComments.map((comment) {
            return Chip(
              label: Text(comment),
            );
          }).toList(),
        ),
      ),
    );
  }
}