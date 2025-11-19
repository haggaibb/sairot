import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/participant.dart';
import 'package:sairot/models/types.dart';
import '../event_controller.dart';
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
    final eventController = Get.put(EventController());
    final List<int> rounds = eventController.currentEvent.value.sakimRounds.map((SakimRound round) => round.round).toList();
    final List<int> participantCounts = eventController.currentEvent.value.sakimRounds.map((SakimRound round) => round.participantsInRound.length).toList();
    Participant p = eventController.getParticipant(number);
    final List<int> participantPositions = p.sakimPositions;
    int currentRound = participantPositions.length;
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
                        barGroups: rounds.asMap().entries
                            .where((entry) => entry.key > 0 && entry.key < participantCounts.length)
                            .map((entry) {
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
                            showingTooltipIndicators: [0],
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
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
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
                  ),

                  ///Line Chart - Participant Position (Inverted Y-Axis)
                  LineChart(
                    LineChartData(
                      minY: 1,  // Ensure Y-axis starts from 1
                      maxY: numberOfParticipants.toDouble(),
                      maxX: rounds.length.toDouble() - 1,
                      lineBarsData: [
                        LineChartBarData(
                          spots: rounds
                              .asMap()
                              .entries
                              .where((entry) =>
                          entry.key > 0 &&
                              entry.key < rounds.length - 1 &&
                              entry.key < participantPositions.length)
                              .map((entry) {
                            int index = entry.key;
                            int round = entry.value;
                            double position = participantPositions[index].toDouble();
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
                          sideTitles: SideTitles(showTitles: true),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,  // Ensure grid lines match Y-axis ticks
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