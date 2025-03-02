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
                        double value = participantCounts[index].toDouble();
                        return BarChartGroupData(
                          x: round,
                          barRods: [
                            BarChartRodData(
                              toY: value,
                              color: isCurrentRound ? Colors.green : Colors.black,
                              width: 20,
                            ),
                          ],
                          showingTooltipIndicators: [0], // Always show tooltip on first (and only) rod
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
                      // ✅ Fixed Tooltip (Always Visible)
                      barTouchData: BarTouchData(
                        enabled: false, // Disable touch interactions
                        touchTooltipData: BarTouchTooltipData(
                          tooltipPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          tooltipMargin: 0,
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return rod.toY.toInt()!=0
                                ? BarTooltipItem(
                              '${rod.toY.toInt()}', // Display the value
                              TextStyle(
                                color: Colors.black,
                                fontSize: eventController.userFontSize.value,
                                fontWeight: FontWeight.bold,
                                backgroundColor: Colors.white,
                              ),
                            )
                                : null
                            ;
                          },
                        ),
                      ),
                    ),
                  ),

                  /// Line Chart - Participant Position
                  LineChart(
                    LineChartData(
                      minY: 1,
                      maxY: participantsCount.toDouble(),
                      maxX: rounds.length.toDouble() - 1,
                      lineBarsData: [
                        LineChartBarData(
                          spots: rounds.asMap().entries
                              .where((entry) =>
                          entry.key != rounds.length - 1 ||
                              (entry.key < participantPositions.length &&
                                  participantPositions[entry.key] != 0))
                              .map((entry) {
                            int index = entry.key;
                            int round = entry.value;
                            double position = (index < participantPositions.length)
                                ? participantPositions[index].toDouble()
                                : 0.0;
                            return FlSpot(round.toDouble(), participantsCount.toDouble() - position); // Invert Y-axis
                          }).where((spot) => spot.y != participantsCount.toDouble()).toList(),
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