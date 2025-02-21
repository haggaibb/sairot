import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/participant.dart';
import '../ctx.dart';

class InterviewChart extends StatelessWidget {
  final int number;

  InterviewChart({super.key, required this.number}); // The round where our participant is currently competing

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(Controller());
    int participantIndex = eventController.currentEvent.value.participants.indexWhere((participant) => participant.number== number);
    Participant p = eventController.currentEvent.value.participants[participantIndex];
    return Scaffold(
      //appBar: AppBar(title: Text("Participant Progress Chart")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:  Wrap(
          spacing: 12,
          children:  eventController.currentEvent.value.participants.firstWhere((p)=> p.number == number).interviewInstructorComments.map((comment) {
            return Chip(
              label: Text(comment),
            );
          }).toList(),
        ),
      ),
    );
  }
}