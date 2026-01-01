import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/participant.dart';
import 'package:sairot/models/types.dart';
import '../event_controller.dart';


class SakimCharts extends StatelessWidget {
  final int number;

  //final List<int> rounds = [1, 2, 3, 4, 5,6,7,8,9,10,11,12]; // Rounds
  final List<int> participantCounts = [0, 0, 0, 0, 0, 0,5,3,2,1,1,1]; // Total participants in each round
  final List<int> participantPositions = [4, 3, 2, 2, 1, 1,1 ,1,1,1,1,1]; // Position of a specific participant
  final int currentRound = 12;

  SakimCharts({super.key, required this.number}); // The round where our participant is currently competing

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(EventController());
    // Filter out round 0 - only show rounds starting from 1
    final allRounds = eventController.currentEvent.value.sakimRounds;
    final List<int> rounds = allRounds.where((r) => r.round > 0).map((r) => r.round).toList();
    final List<int> participantCounts = allRounds.where((r) => r.round > 0).map((r) => r.participantsInRound.length).toList();
    Participant p = eventController.getParticipant(number);
    
    // Get positions for each filtered round
    // For each round, find if participant is in that round and calculate absolute position
    final filteredRoundsList = allRounds.where((r) => r.round > 0).toList();
    final List<int> participantPositions = filteredRoundsList.asMap().entries.map((entry) {
      int filteredIndex = entry.key;
      final round = entry.value;
      
      // Check if participant is currently in this round
      if (round.participantsInRound.contains(number)) {
        // Calculate absolute position: count participants in higher rounds + index in current round
        int participantsAhead = 0;
        for (var r in allRounds) {
          if (r.round > round.round) {
            participantsAhead += r.participantsInRound.length;
          }
        }
        final indexInRound = round.participantsInRound.indexOf(number);
        return participantsAhead + indexInRound + 1; // 1-based absolute position
      }
      
      // If not in this round, check stored positions as fallback
      final allParticipantPositions = p.sakimPositions;
      if (filteredIndex < allParticipantPositions.length) {
        final storedPosition = allParticipantPositions[filteredIndex];
        if (storedPosition > 0) {
          return storedPosition;
        }
      }
      
      return 0; // No position found
    }).toList();
    
    // Find which round the participant is currently in
    int currentRound = -1;
    for (var round in allRounds) {
      if (round.round > 0 && round.participantsInRound.contains(number)) {
        currentRound = round.round;
        break;
      }
    }
    // If not found, default to 0 (will show no green bar)
    if (currentRound == -1) currentRound = 0;
    
    int numberOfParticipants =  eventController.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active).length;
//int worstPosition = participantPositions.reduce((a, b) => a > b ? a : b);
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
                  /// Bar Chart - Total Participants in Each Round
                  Padding(
                    padding: const EdgeInsets.only(bottom :20.0,right: 0),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: rounds.asMap().entries.map((entry) {
                          int index = entry.key;
                          int round = entry.value;
                          bool isCurrentRound = round == currentRound;
                          double value = participantCounts[index].toDouble();
                          return BarChartGroupData(
                            x: round, // Rounds are already >= 1 after filtering
                            barRods: [
                              BarChartRodData(
                                toY: value,
                                color: isCurrentRound ? Colors.green : Colors.black,
                                width: 20,
                              ),
                            ],
                            // Don't show tooltips
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false), // Hide BarChart X-axis, LineChart will show it
                          ),
                        ),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        // Disable tooltips - don't show participant count
                        barTouchData: BarTouchData(
                          enabled: false, // Disable touch interactions
                        ),
                      ),
                    ),
                  ),

                  ///Line Chart - Participant Position (Inverted Y-Axis)
                  LineChart(
                    LineChartData(
                      minY: 1,  // Ensure Y-axis starts from 1
                      maxY: numberOfParticipants.toDouble(),
                      minX: rounds.isNotEmpty ? rounds.first.toDouble() : 1, // Start from first round
                      maxX: rounds.isNotEmpty ? (rounds.last.toDouble() + 0.5) : 1, // Add 0.5 to ensure last point is fully visible
                      lineBarsData: [
                        LineChartBarData(
                          spots: rounds.asMap().entries
                              .where((entry) {
                            int index = entry.key;
                            // Include all rounds where participant has a valid position (not 0)
                            return index < participantPositions.length && participantPositions[index] > 0;
                          })
                              .map((entry) {
                            int index = entry.key;
                            int round = entry.value;
                            double position = participantPositions[index].toDouble();
                            // Rounds are already >= 1 after filtering, use round directly
                            return FlSpot(round.toDouble(), numberOfParticipants.toDouble() - position);
                          }).toList(),
                          isCurved: false,  // Ensure straight lines
                          color: Colors.red,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: false),
                          dotData: FlDotData(show: true),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2), // Wider padding
                          tooltipMargin: 16, // Space between tooltip and dot
                          fitInsideHorizontally: true, // Ensures tooltip stays in the chart
                          fitInsideVertically: true,
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((touchedSpot) {
                              return LineTooltipItem(
                                '   ${(numberOfParticipants - touchedSpot.y).toInt()} מקום ', // Ensures two decimal places
                                TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  backgroundColor: Colors.white, // Force white background
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              // Skip 0 and only show integers greater than 0
                              if (value > 0 && value % 1 == 0 && value <= numberOfParticipants.toDouble()) {
                                return Text('${(numberOfParticipants - value).toInt()}', style: TextStyle(fontSize: 12));
                              }
                              return SizedBox.shrink();
                            },
                            interval: 1,  // Ensure Y-axis ticks at every integer
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1, // Show label only at integer intervals
                            getTitlesWidget: (value, meta) {
                              // Show only interval numbers (only for integer values)
                              if (value % 1 == 0 && value >= 1 && value <= rounds.length) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(color: Colors.white),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            reservedSize: 30,
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,  // Ensure grid lines match Y-axis ticks
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.3),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.3),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                  ),             ],
              ),
            ),
            const SizedBox(height: 20),
            /// 📃 Instructor Comments Section
            p.sakimInstructorComments.isNotEmpty?const Text(
              'הערות המדריך',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ):SizedBox.shrink(),
            Container(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: p.sakimInstructorComments.map((comment) {
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