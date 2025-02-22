import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/participant.dart';
import '../ctx.dart';
import 'package:sairot/models/bur.dart';

class BurCharts extends StatelessWidget {
  final int number;

  BurCharts({super.key, required this.number}); // The round where our participant is currently competing

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(Controller());
    final List<Bur> participantsGrades = eventController.currentEvent.value.burGrades;
    int participantIndex = eventController.currentEvent.value.participants.indexWhere((participant) => participant.number== number);
    return Scaffold(
      //appBar: AppBar(title: Text("Participant Progress Chart")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BarChart(
                BarChartData(
                  barGroups: participantsGrades.asMap().entries.map((entry) {
                    int index = entry.key;
                    double grade = entry.value.burGrade;
                    return BarChartGroupData(
                      x: participantsGrades[index].id,
                      barRods: [
                        BarChartRodData(
                          toY:  grade,
                          color: participantIndex==index ? Colors.green : Colors.black, // Highlight the current round
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
              child: Wrap(
                spacing: 12,
                children:  eventController.currentEvent.value.burGrades.firstWhere((bur)=> bur.id == number).instructorComments.map((comment) {
                  return Chip(
                    label: Text(comment),
                  );
                }).toList(),
              ),
            )
                 : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}