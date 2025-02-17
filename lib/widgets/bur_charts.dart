import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/participant.dart';
import '../ctx.dart';
import 'package:sairot/models/bur.dart';

class BurCharts extends StatelessWidget {
  final int number;

  //final List<int> participants= [1, 2, 3, 4, 5, 6, 7 , 8, 9, 10, 11, 12]; // Position of a specific participant
  //final List<int> participantsGrades = [4, 3, 4, 5, 6, 3, 3 , 3, 6, 5, 5, 4]; // Position of a specific participant
  //final int participantIndex = 3;

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
          children: [
            Expanded(
              child: BarChart(
                BarChartData(
                  barGroups: participantsGrades.asMap().entries.map((entry) {
                    int index = entry.key;
                    double grade = entry.value.burGrade;
                    print('-----');
                    print(index);
                    print(entry.value.burGrade);

                    return BarChartGroupData(
                      x: participantsGrades[index].id,
                      barRods: [
                        BarChartRodData(
                          toY:  grade,
                          color: participantIndex==index ? Colors.green : Colors.blue, // Highlight the current round
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
            Container(
              child: Wrap(
                spacing: 12,
                children: [
                  Chip(
                label: Text('הבין את התרגיל'),
                  ),
                  Chip(
                      label: Text('לוקח אחריות')
                  ),
                  Chip(
                    label: Text('בור יפה'),
                  )

                ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}