import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../event_controller.dart';

class LeadershipChart extends StatelessWidget {
  final int number;

  LeadershipChart({super.key, required this.number}); // The round where our participant is currently competing

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(EventController());
    return Scaffold(
      //appBar: AppBar(title: Text("Participant Progress Chart")),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: eventController.currentEvent.value.participants.firstWhere((p)=> p.number == number).leadershipInstructorComments.map((comment) {
                return Chip(
                  label: Text(
                    comment,
                    textAlign: TextAlign.right,
                    softWrap: true,
                    maxLines: null,
                    overflow: TextOverflow.visible,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}