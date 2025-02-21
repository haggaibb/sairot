import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/participant.dart';
import '../ctx.dart';
import 'package:sairot/models/alonka_sprint.dart';

class AlonkaCharts extends StatelessWidget {
  final int number;

  //final List<int> rounds = [1, 2, 3, 4, 5,6,7,8,9,10,11,12]; // Rounds
  //final List<int> participantCredit = [7, 3, 7, 7, 7, 3, 7, 1, 7, 7, 7, 7];

  AlonkaCharts({super.key, required this.number}); // The round where our participant is currently competing

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(Controller());
    final List<int> rounds = eventController.currentEvent.value.alonkaSprints.map((AlonkaSprint sprint) => sprint.round).toList();
    final List<double> participantsSprintCredit = rounds.map((round) => eventController.getAlonkaSprintCredit(number, round)).toList();
    Participant p = eventController.getParticipant(number);
    return Scaffold(
      //appBar: AppBar(title: Text("Participant Progress Chart")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ///Line Chart - Participant Position (Inverted Y-Axis)
                  LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: rounds.asMap().entries.map((entry) {
                            int index = entry.key;
                            int round = entry.value;
                            return FlSpot(round.toDouble(), ( participantsSprintCredit[index]).toDouble());
                            // The "20 -" part inverts the y-axis
                          }).toList(),
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: false),
                          dotData: FlDotData(show: true),
                        ),
                      ],
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
                      ),
                      gridData: FlGridData(
                        show: false,
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            /// 📃 Instructor Comments Section
            p.alonkaInstructorComments.isNotEmpty?const Text(
              'הערות המדריך',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ):SizedBox.shrink(),
            Container(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: p.alonkaInstructorComments.map((comment) {
                  return Chip(
                    label: Text(comment),
                    backgroundColor: Colors.grey.shade200,
                    labelStyle: TextStyle(color: Colors.black),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}