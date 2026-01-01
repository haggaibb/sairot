import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/participant.dart';
import 'package:sairot/models/types.dart';
import 'package:sairot/models/meshulash_round.dart';
import '../event_controller.dart';



class MeshulashCharts extends StatelessWidget {
  final int number;

  MeshulashCharts({super.key, required this.number}); // The round where our participant is currently competing

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(EventController());
    // Filter out round 0 - only show rounds starting from 1
    final allRounds = eventController.currentEvent.value.meshulashRounds;
    final List<int> rounds = allRounds.where((r) => r.round > 0).map((r) => r.round).toList();
    final List<int> participantCounts = allRounds.where((r) => r.round > 0).map((r) => r.participantsInRound.length).toList();
    Participant p = eventController.getParticipant(number);
    final List<int> allParticipantPositions = p.meshulashPositions;
    
    // Get positions for each filtered round
    // meshulashPositions stores positions in order as participant moves through rounds
    // We need to map them to the filtered rounds (excluding round 0)
    final filteredRoundsList = allRounds.where((r) => r.round > 0).toList();
    final List<int> participantPositions = filteredRoundsList.asMap().entries.map((entry) {
      int filteredIndex = entry.key;
      MeshulashRound round = entry.value;
      
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
      
      // If not in this round, check if we have a stored position for this round index
      // The positions list might be indexed by the round they moved to
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
                              return Container();
                            },
                          ),
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

                  /// Line Chart - Participant Position
                  LineChart(
                    LineChartData(
                      minY: 1,
                      maxY: participantsCount.toDouble(),
                      minX: 1, // Start intervals from 1
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
                            return FlSpot(round.toDouble(), participantsCount.toDouble() - position); // Invert Y-axis
                          }).toList(),
                          isCurved: false,
                          color: Colors.red,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: false),
                          dotData: FlDotData(show: true),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          tooltipMargin: 16,
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((touchedSpot) {
                              return LineTooltipItem(
                                '   ${participantsCount.toInt() - touchedSpot.y.toInt()} מקום ',
                                TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  backgroundColor: Colors.white,
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
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value % 1 == 0) {
                                return Text('${(participantsCount - value).toInt()}', style: TextStyle(fontSize: 12)); // Invert labels
                              }
                              return SizedBox.shrink();
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
                          color: Colors.grey.withValues(alpha: 0.3),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.3),
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