import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../event_controller.dart';

class InterviewChart extends StatelessWidget {
  final int number;

  InterviewChart({super.key, required this.number}); // The round where our participant is currently competing

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
              children: eventController.currentEvent.value.participants.firstWhere((p)=> p.number == number).interviewInstructorComments.map((comment) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade300, width: 1),
                  ),
                  child: Text(
                    comment,
                    style: TextStyle(color: Colors.grey.shade500),
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