import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sairot/models/participant.dart';
import 'package:sairot/models/types.dart';
import '../event_controller.dart';
import 'package:sairot/models/alonka_sprint.dart';

class ChartToggleController extends GetxController {
  var showPieChart = false.obs; // Toggles between Line and Pie Chart
}

class AlonkaCharts extends StatelessWidget {
  final int number;

  AlonkaCharts({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(EventController());
    final toggleController = Get.put(ChartToggleController());

    final List<int> rounds = eventController.currentEvent.value.alonkaSprints
        .map((AlonkaSprint sprint) => sprint.round)
        .toList();
    
    
    Participant p = eventController.getParticipant(number);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔘 Toggle Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('קווי'),
                Obx(() => Switch(
                  value: toggleController.showPieChart.value,
                  onChanged: (value) {
                    toggleController.showPieChart.value = value;
                  },
                )),
                Text('עוגה'),
              ],
            ),
            SizedBox(height: 50),
            /// 📊 Charts Stack (Toggles Between Pie Chart & Line Chart)
            Expanded(
              child: Obx(() {
                if (!toggleController.showPieChart.value) {
                  // Calculate positions for each sprint
                  final List<int> positions = rounds.map((round) => eventController.getAlonkaSprintPosition(number, round)).toList();
                  final List<double> baseCredits = rounds.map((round) => eventController.getAlonkaSprintBaseCredit(number, round)).toList();
                  
                  // Get total number of active participants in the exercise for Y-axis range
                  final totalParticipants = eventController.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active).length;
                  final maxY = totalParticipants > 0 ? totalParticipants.toDouble() : 10.0;
                  
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final yAxisWidth = 50.0;
                      final bottomAxisHeight = 30.0;
                      final chartWidth = constraints.maxWidth - yAxisWidth;
                      final chartHeight = constraints.maxHeight - bottomAxisHeight;
                      
                      return Stack(
                        children: [
                          LineChart(
                            LineChartData(
                              lineBarsData: [
                                // Line showing order of arrival (position) - inverted so position 1 is at top
                                LineChartBarData(
                                  spots: rounds.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    int round = entry.value;
                                    int position = positions[index];
                                    // Only include points where participant has a position
                                    // Invert Y: position 1 should be at top (maxY), higher positions at bottom
                                    if (position > 0) {
                                      return FlSpot(round.toDouble() + 1, maxY - position.toDouble() + 1);
                                    }
                                    return null;
                                  }).where((spot) => spot != null).cast<FlSpot>().toList(),
                                  isCurved: false,
                                  color: Colors.red,
                                  barWidth: 3,
                                  belowBarData: BarAreaData(show: false),
                                  dotData: FlDotData(show: true),
                                ),
                              ],
                              lineTouchData: LineTouchData(enabled: false), // Disable tooltips since we show labels
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      // Show position numbers on Y-axis (inverted: top = 1, bottom = maxY)
                                      if (value % 1 == 0 && value >= 1 && value <= maxY) {
                                        // Invert the display: value at top (maxY) shows 1, value at bottom (1) shows maxY
                                        final invertedPosition = (maxY - value.toInt() + 1).toInt();
                                        return Text(
                                          invertedPosition.toString(),
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      // Show only interval numbers
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
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(show: false),
                              minX: 1,
                              maxX: rounds.length.toDouble(),
                              minY: 1,
                              maxY: maxY,
                            ),
                          ),
                          // Labels showing element icon and position at each point
                          ...rounds.asMap().entries.map((entry) {
                            int index = entry.key;
                            int round = entry.value;
                            int position = positions[index];
                            double baseCredit = baseCredits[index];
                            
                            if (position == 0) return const SizedBox.shrink();
                            
                            // Determine element icon
                            String iconPath;
                            if (baseCredit >= eventController.gradesData.ALONKA_CREDIT - 0.05) {
                              iconPath = 'images/alonka.png';
                            } else if (baseCredit >= eventController.gradesData.GERIKAN_CREDIT - 0.05) {
                              iconPath = 'images/gerikan.png';
                            } else if (baseCredit >= eventController.gradesData.RUNNER_CREDIT - 0.05) {
                              iconPath = 'images/run.png';
                            } else {
                              return const SizedBox.shrink(); // Skip participation
                            }
                            
                            // Calculate position for label
                            // X: map round+1 to chart width (minX=1, maxX=rounds.length)
                            final xRatio = rounds.length > 1 ? (round + 1 - 1) / (rounds.length - 1) : 0;
                            final xPos = yAxisWidth + xRatio * chartWidth;
                            
                            // Y: map position to chart height (inverted: position 1 at top)
                            // Since we invert in the chart (maxY - position + 1), we need to invert here too
                            final invertedY = maxY - position + 1;
                            final yRatio = maxY > 1 ? (invertedY - 1) / (maxY - 1) : 0;
                            final pointY = (1 - yRatio) * chartHeight;
                            
                            // Position label above or below point based on position
                            // If position is in top 20% (positions 1-2 typically), show label below
                            // Otherwise show label above
                            final isTopPosition = position <= (maxY * 0.2).ceil();
                            final labelOffset = isTopPosition ? 25 : -30; // Below if top, above if not
                            final yPos = pointY + labelOffset;
                            
                            return Positioned(
                              left: xPos - 20,
                              top: yPos,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      iconPath,
                                      width: 16,
                                      height: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$position',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  );
                } else {
                  return SprintCreditPieChart(
                    participantsSprintCredit: rounds.map((round) => eventController.getAlonkaSprintBaseCredit(number, round)).toList()
                  );
                }
              }),
            ),
            const SizedBox(height: 20),
            /// 📃 Instructor Comments Section
            p.alonkaInstructorComments.isNotEmpty
                ? const Text(
              'הערות המדריך',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            )
                : SizedBox.shrink(),
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


class SprintCreditPieChart extends StatelessWidget {
  final List<double> participantsSprintCredit;

  const SprintCreditPieChart({
    Key? key,
    required this.participantsSprintCredit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int totalSprints = participantsSprintCredit.length;
    if (totalSprints == 0) return Center(child: Text("No Data"));

    // Count occurrences of each credit type
    int alonkaCount = participantsSprintCredit.where((credit) => credit == 1.0).length;
    int gerikanCount = participantsSprintCredit.where((credit) => credit == 0.5).length;
    int runnerCount = participantsSprintCredit.where((credit) => credit == 0.2).length;
    int noCreditCount = totalSprints - (alonkaCount + gerikanCount + runnerCount);

    // Calculate percentages
    double alonkaPercentage = (alonkaCount / totalSprints) * 100;
    double gerikanPercentage = (gerikanCount / totalSprints) * 100;
    double runnerPercentage = (runnerCount / totalSprints) * 100;
    double noCreditPercentage = (noCreditCount / totalSprints) * 100;

    // Prepare data sections
    List<PieChartSectionData> sections = [];

    if (alonkaCount > 0) {
      sections.add(PieChartSectionData(
        value: alonkaPercentage,
        title: '${alonkaPercentage.toStringAsFixed(1)}% אלונקה',
        color: Colors.red,
        radius: 70,
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }
    if (gerikanCount > 0) {
      sections.add(PieChartSectionData(
        value: gerikanPercentage,
        title: '${gerikanPercentage.toStringAsFixed(1)}% גריקן',
        color: Colors.blue,
        radius: 70,
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }
    if (runnerCount > 0) {
      sections.add(PieChartSectionData(
        value: runnerPercentage,
        title: '${runnerPercentage.toStringAsFixed(1)}% רץ',
        color: Colors.green,
        radius: 70,
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }
    if (noCreditCount > 0) {
      sections.add(PieChartSectionData(
        value: noCreditPercentage,
        title: '${noCreditPercentage.toStringAsFixed(1)}% ללא ניקוד',
        color: Colors.grey,
        radius: 70,
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 40, // Empty space in the center
      ),
    );
  }
}