import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/participant.dart';
import 'package:sairot/models/types.dart';
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
    int participantsCount = eventController.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active).length;
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
                              color: isCurrentRound ? Colors.green : Colors.black,
                              width: 20,
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value > 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text('${value.toInt()}'),
                                );
                              }
                              return Container(); // Skip zero entry
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),

                  /// Line Chart - Participant Position
                  LineChart(
                    LineChartData(
                      minY: 1, // Ensure the Y-axis starts from 0
                      maxY: participantsCount.toDouble(), // Ensure it covers the highest possible value
                      maxX: rounds.length.toDouble()-1,
                      lineBarsData: [
                        LineChartBarData(
                          spots: rounds.asMap().entries
                              .where((entry) =>
                          entry.key != rounds.length - 1 ||
                              (entry.key < participantPositions.length && participantPositions[entry.key] != 0))
                              .map((entry) {
                            int index = entry.key;
                            int round = entry.value;
                            double position = (index < participantPositions.length)
                                ? participantPositions[index].toDouble()
                                : 0.0;
                            return FlSpot(round.toDouble(), position);
                          }).where((spot) => spot.y != 0.0 )
                              .toList(),
                          isCurved: false,
                          color: Colors.red,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: false),
                          dotData: FlDotData(show: true),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 1, // Ensure Y-axis ticks at every integer
                            getTitlesWidget: (value, meta) {
                              if (value % 1 == 0) {
                                return Text('${value.toInt()}', style: TextStyle(fontSize: 12));
                              }
                              return SizedBox.shrink(); // Hide non-integer values
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  )
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