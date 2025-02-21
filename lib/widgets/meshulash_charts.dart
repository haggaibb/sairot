import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/participant.dart';
import '../ctx.dart';
import 'package:sairot/models/meshulash_round.dart';



class MeshulashCharts extends StatelessWidget {
  final int number;

  MeshulashCharts({super.key, required this.number}); // The round where our participant is currently competing

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(Controller());
    final List<int> rounds = eventController.currentEvent.value.meshulashRounds.map((MeshulashRound round) => round.round).toList();
    final List<int> participantCounts = eventController.currentEvent.value.meshulashRounds.map((MeshulashRound round) => round.participantsInRound.length).toList();
    Participant p = eventController.getParticipant(number);
    final List<int> participantPositions = p.meshulashPositions;
    int currentRound = participantPositions.length;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 📊 Bar and Line Charts
            Expanded(
              child: Stack(
                children: [
                  /// Bar Chart - Total Participants in Each Round
                  BarChart(
                    BarChartData(
                      barGroups: rounds.asMap().entries.map((entry) {
                        int index = entry.key;
                        int round = entry.value;
                        bool isCurrentRound = round == currentRound;
                        return BarChartGroupData(
                          x: round,
                          barRods: [
                            BarChartRodData(
                              toY: participantCounts[index].toDouble(),
                              color: isCurrentRound ? Colors.green : Colors.blue,
                              width: 20,
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),

                  /// Line Chart - Participant Position
                  LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: rounds.asMap().entries.map((entry) {
                            int index = entry.key;
                            int round = entry.value;
                            return FlSpot(round.toDouble(),
                                (index + 1 > participantPositions.length ? 0 : participantPositions[index].toDouble()));
                          }).toList(),
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: false),
                          dotData: FlDotData(show: true),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            /// 📃 Instructor Comments Section
            p.meshulashInstructorComments.isNotEmpty?const Text(
              'הערות המדריך',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ):SizedBox.shrink(),
            Container(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: p.meshulashInstructorComments.map((comment) {
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