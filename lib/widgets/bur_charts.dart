import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../event_controller.dart';
import 'package:sairot/models/bur.dart';

class BurCharts extends StatelessWidget {
  final int number;

  BurCharts({super.key, required this.number}); // The round where our participant is currently competing

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(EventController());
    // Use activeParticipants and look up bur grades (same logic as grades page)
    final activeParticipants = eventController.currentEvent.value.activeParticipants;
    int currentParticipantIndex = activeParticipants.indexWhere((p) => p.number == number);
    return Scaffold(
      //appBar: AppBar(title: Text("Participant Progress Chart")),
      body: SafeArea(
        minimum: EdgeInsets.zero, // No minimum padding
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 16.0), // No horizontal padding for maximum width
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BarChart(
                BarChartData(
                  barGroups: activeParticipants.asMap().entries.map((entry) {
                    int index = entry.key;
                    int participantNumber = entry.value.number;
                    // Look up bur grade from burGrades collection (same logic as grades page)
                    int burIndex = eventController.currentEvent.value.burGrades
                        .indexWhere((bur) => bur.id == participantNumber);
                    double grade = (burIndex != -1) 
                        ? eventController.currentEvent.value.burGrades[burIndex].burGrade 
                        : 0.0;
                    return BarChartGroupData(
                      x: participantNumber,
                      barRods: [
                        BarChartRodData(
                          toY:  grade,
                          color: currentParticipantIndex == index ? Colors.green : Colors.black, // Highlight the current participant
                          width: 20,
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    rightTitles:  AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // Disable Y-axis titles on BarChart
                    ),
                    // leftTitles: AxisTitles(
                    //   sideTitles: SideTitles(showTitles: false), // Disable Y-axis titles on BarChart
                    // ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // Disable Y-axis titles on BarChart
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // Disable X-axis titles on BarChart
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            SizedBox(height: 20,),
            const Text('הערות המדריך',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            eventController.currentEvent.value.burGrades.isNotEmpty
                ? Container(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: eventController.currentEvent.value.burGrades.firstWhere((bur)=> bur.id == number).instructorComments.map((comment) {
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
            )
                 : SizedBox.shrink(            ),
          ],
        ),
        ),
      ),
    );
  }
}