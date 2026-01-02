import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sairot/models/participant.dart';
import 'package:sairot/models/types.dart';
import '../event_controller.dart';
import 'package:sairot/models/alonka_sprint.dart';
import '../utils/tablet_utils.dart';

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
      body: SafeArea(
        minimum: EdgeInsets.zero, // No minimum padding
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2.0), // No horizontal padding for maximum width
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔘 Toggle Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('קווי', style: TextStyle(fontSize: 12)), // Smaller text
                Obx(() => Switch(
                  value: toggleController.showPieChart.value,
                  onChanged: (value) {
                    toggleController.showPieChart.value = value;
                  },
                )),
                Text('עוגה', style: TextStyle(fontSize: 12)), // Smaller text
              ],
            ),
            SizedBox(height: 2), // Minimal spacing to maximize chart height
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
                      bool tablet = isTablet(context);
                      final yAxisWidth = tablet ? 50.0 : 55.0; // Original values
                      final rightPadding = tablet ? 25.0 : 35.0; // Space for labels on the right to prevent clipping
                      final bottomAxisHeight = 15.0; // Minimized to maximize chart height
                      final chartWidth = constraints.maxWidth - yAxisWidth - rightPadding;
                      final chartHeight = constraints.maxHeight - bottomAxisHeight;
                      
                      return Stack(
                        children: [
                          // Constrain LineChart to leave space for right-side labels
                          Padding(
                            padding: EdgeInsets.only(right: rightPadding),
                            child: LineChart(
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
                                    reservedSize: tablet ? 50.0 : 55.0, // Original values
                                    interval: tablet ? 1 : (maxY > 15 ? 3 : maxY > 10 ? 2 : 1), // Better spacing for clarity
                                    getTitlesWidget: (value, meta) {
                                      // Show position numbers on Y-axis (inverted: top = 1, bottom = maxY)
                                      if (value % 1 == 0 && value >= 1 && value <= maxY) {
                                        // Invert the display: value at top (maxY) shows 1, value at bottom (1) shows maxY
                                        final invertedPosition = (maxY - value.toInt() + 1).toInt();
                                        return Padding(
                                          padding: EdgeInsets.only(right: tablet ? 4.0 : 8.0),
                                          child: Text(
                                            invertedPosition.toString(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: tablet ? 14 : 12, // Increased from 12/10 for better clarity
                                              fontWeight: FontWeight.w500, // Slightly bolder for better visibility
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
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
                            // chartWidth already accounts for rightPadding
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
                            
                            // Calculate label position with bounds checking to prevent right clipping
                            // Label is approximately 40px wide (icon 16px + spacing 4px + text ~20px)
                            final labelWidth = 40.0;
                            final labelLeft = xPos - labelWidth / 2; // Center label on point
                            // Ensure label doesn't go beyond right edge (account for rightPadding)
                            final maxLeft = constraints.maxWidth - labelWidth - 4.0; // 4px margin from edge
                            final finalLeft = (labelLeft > maxLeft ? maxLeft : (labelLeft < 0 ? 0.0 : labelLeft)).toDouble();
                            
                            return Positioned(
                              left: finalLeft,
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
            const SizedBox(height: 4), // Minimal spacing to maximize chart height
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