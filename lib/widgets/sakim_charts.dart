import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/participant.dart';
import '../ctx.dart';
import 'package:sairot/models/sakim_round.dart';


class SakimCharts extends StatelessWidget {
  final int number;

  //final List<int> rounds = [1, 2, 3, 4, 5,6,7,8,9,10,11,12]; // Rounds
  final List<int> participantCounts = [0, 0, 0, 0, 0, 0,5,3,2,1,1,1]; // Total participants in each round
  final List<int> participantPositions = [4, 3, 2, 2, 1, 1,1 ,1,1,1,1,1]; // Position of a specific participant
  final int currentRound = 12;

  SakimCharts({super.key, required this.number}); // The round where our participant is currently competing

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(Controller());
    final List<int> rounds = eventController.currentEvent.value.sakimRounds.map((SakimRound round) => round.round).toList();
    final List<int> participantCounts = eventController.currentEvent.value.sakimRounds.map((SakimRound round) => round.participantsInRound.length).toList();
    Participant p = eventController.getParticipant(number);
    final List<int> participantPositions = p.sakimPositions;
    int currentRound = participantPositions.length;
    print(participantPositions);
//int worstPosition = participantPositions.reduce((a, b) => a > b ? a : b);
    return Scaffold(
      //appBar: AppBar(title: Text("Participant Progress Chart")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                        color: isCurrentRound ? Colors.green : Colors.blue, // Highlight the current round
                        width: 20,
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  rightTitles:  AxisTitles(
                    sideTitles: SideTitles(showTitles: false), // Disable Y-axis titles on BarChart
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false), // Disable Y-axis titles on BarChart
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false), // Disable Y-axis titles on BarChart
                  ),
                  // bottomTitles: AxisTitles(
                  //   sideTitles: SideTitles(showTitles: false), // Disable X-axis titles on BarChart
                  // ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),

            ///Line Chart - Participant Position (Inverted Y-Axis)
            LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: rounds.asMap().entries.map((entry) {
                      int index = entry.key;
                      int round = entry.value;
                      return FlSpot(round.toDouble(), (index+1 > participantPositions.length ? 0 :participantPositions[index]).toDouble());
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
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false), // Disable X-axis titles on BarChart
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
    );
  }
}