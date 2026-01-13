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
  var showMatrix = false.obs; // Toggles between Chart and Matrix view
}

class AlonkaCharts extends StatelessWidget {
  final int number;

  AlonkaCharts({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(EventController());
    final toggleController = Get.put(ChartToggleController());

    // Include all rounds including round 0 (first round)
    final List<int> rounds = eventController.currentEvent.value.alonkaSprints
        .where((AlonkaSprint sprint) => sprint.round >= 0)
        .map((AlonkaSprint sprint) => sprint.round)
        .toList()
      ..sort(); // Sort to ensure rounds are in order
    
    
    Participant p = eventController.getParticipant(number);

    return Scaffold(
      body: SafeArea(
        minimum: EdgeInsets.zero, // No minimum padding
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2.0), // No horizontal padding for maximum width
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔘 Toggle Controls Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Matrix icon button (upper left)
                Obx(() => IconButton(
                  icon: Icon(
                    toggleController.showMatrix.value ? Icons.bar_chart : Icons.grid_on,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    toggleController.showMatrix.value = !toggleController.showMatrix.value;
                  },
                  tooltip: toggleController.showMatrix.value ? 'הצג גרף' : 'הצג מטריצה',
                )),
                // Chart type toggle (center)
                Obx(() => !toggleController.showMatrix.value
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('קווי', style: TextStyle(fontSize: 12)),
                          Switch(
                            value: toggleController.showPieChart.value,
                            onChanged: (value) {
                              toggleController.showPieChart.value = value;
                            },
                          ),
                          Text('עוגה', style: TextStyle(fontSize: 12)),
                        ],
                      )
                    : SizedBox.shrink()),
                // Spacer to balance the row
                SizedBox(width: 48),
              ],
            ),
            SizedBox(height: 2), // Minimal spacing to maximize chart height
            /// 📊 Charts/Matrix Stack (Toggles Between Views)
            Expanded(
              child: Obx(() {
                // Show matrix view
                if (toggleController.showMatrix.value) {
                  return AlonkaMatrixView(number: number);
                }
                // Show chart view
                if (!toggleController.showPieChart.value) {
                  // Calculate positions for each sprint (only for rounds > 0)
                  final List<int> positions = rounds.map((round) => eventController.getAlonkaSprintPosition(number, round)).toList();
                  final List<double> baseCredits = rounds.map((round) => eventController.getAlonkaSprintBaseCredit(number, round)).toList();
                  
                  // Get total number of active participants in the exercise for Y-axis range
                  final totalParticipants = eventController.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active).length;
                  final maxY = totalParticipants > 0 ? totalParticipants.toDouble() : 10.0;
                  
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      bool tablet = isTablet(context);
                      // Reduced for embedded view in exercise grading page
                      final yAxisWidth = tablet ? 35.0 : 40.0; // Reduced to make chart wider
                      final rightPadding = tablet ? 18.0 : 25.0; // Reduced space for labels on the right
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
                                    // Use round number directly (including round 0)
                                    if (position > 0) {
                                      return FlSpot(round.toDouble(), maxY - position.toDouble() + 1);
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
                                      // Show round numbers + 1 for display (round 0 shows as "1", round 1 shows as "2", etc.)
                                      if (value % 1 == 0 && rounds.isNotEmpty && 
                                          value >= rounds.first.toDouble() && value <= rounds.last.toDouble()) {
                                        // Check if this value corresponds to an actual round
                                        if (rounds.contains(value.toInt())) {
                                          return Text(
                                            (value.toInt() + 1).toString(),
                                            style: const TextStyle(color: Colors.white),
                                          );
                                        }
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
                              minX: rounds.isNotEmpty ? (rounds.first.toDouble() - 0.5).clamp(0.0, double.infinity) : 0.5,
                              maxX: rounds.isNotEmpty ? rounds.last.toDouble() + 0.5 : 1.5,
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
                            
                            // Exclude positions that are 0
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
                            // X: map round to chart width (minX=rounds.first, maxX=rounds.last)
                            // chartWidth already accounts for rightPadding
                            final minX = rounds.isNotEmpty ? rounds.first.toDouble() - 0.5 : 0.5;
                            final maxX = rounds.isNotEmpty ? rounds.last.toDouble() + 0.5 : 1.5;
                            final xRatio = rounds.length > 1 ? (round.toDouble() - minX) / (maxX - minX) : 0;
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
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: p.alonkaInstructorComments.map((comment) {
                    return Chip(
                      label: Text(
                        comment,
                        textAlign: TextAlign.right,
                        softWrap: true,
                        maxLines: null,
                        overflow: TextOverflow.visible,
                      ),
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: TextStyle(color: Colors.black),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Matrix view showing all recruits' credit types for each round
class AlonkaMatrixView extends StatelessWidget {
  final int number; // Current recruit number (highlighted)

  const AlonkaMatrixView({super.key, required this.number});

  Color _getCreditColor(AlonkaSprint sprint, int participantNumber) {
    if (sprint.alonkaCredits.contains(participantNumber)) {
      return Colors.red; // Alonka credit - red
    } else if (sprint.gerikanCredits.contains(participantNumber)) {
      return Colors.green; // Gerikan credit - green
    } else if (sprint.runCredits.contains(participantNumber)) {
      return Colors.black; // Runner credit - black
    } else if (sprint.participationCredits.contains(participantNumber)) {
      return Colors.white; // Participation credit - white
    }
    return Colors.grey; // No credit
  }

  String _getCreditLabel(AlonkaSprint sprint, int participantNumber) {
    if (sprint.alonkaCredits.contains(participantNumber)) {
      return 'א';
    } else if (sprint.gerikanCredits.contains(participantNumber)) {
      return 'ג';
    }
    // No text for runner, participation, or no credit
    return '';
  }

  bool _hasValidCredits(AlonkaSprint sprint) {
    // A round is valid only if it has Alonka or Gerikan credits
    // Participation credits alone don't make a valid round
    return sprint.alonkaCredits.isNotEmpty || sprint.gerikanCredits.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(EventController());
    final allSprints = eventController.currentEvent.value.alonkaSprints;
    
    // Filter out the last round if it has no valid credits (probably opened by mistake)
    // A round is valid only if it has Alonka or Gerikan credits (not just participation)
    List<AlonkaSprint> sprints = [];
    if (allSprints.isNotEmpty) {
      // Check if last round has valid credits (Alonka or Gerikan)
      final lastSprint = allSprints.last;
      if (_hasValidCredits(lastSprint)) {
        // Last round has valid credits, include all rounds
        sprints = allSprints;
      } else {
        // Last round is empty or only has participation credits, exclude it
        sprints = allSprints.sublist(0, allSprints.length - 1);
      }
    }
    
    final participants = eventController.currentEvent.value
        .getParticipantsByStatus(ParticipantStatus.Active)
        ..sort((a, b) => b.alonkaGrade.compareTo(a.alonkaGrade)); // Sort by grade descending (best on top)
    bool isTablet = MediaQuery.of(context).size.width > 600;

    if (sprints.isEmpty || participants.isEmpty) {
      return Center(
        child: Text(
          'אין נתונים',
          style: TextStyle(color: Colors.white, fontSize: isTablet ? 18 : 16),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Table(
          border: TableBorder.all(color: Colors.white70, width: 1),
          columnWidths: {
            0: FixedColumnWidth(isTablet ? 80 : 70), // Recruit number column
            ...Map.fromIterable(
              List.generate(sprints.length, (index) => index + 1),
              key: (i) => i,
              value: (i) => FixedColumnWidth(isTablet ? 60 : 50), // Round columns
            ),
          },
          children: [
            // Header row
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[800]),
              children: [
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 12 : 8),
                    child: SizedBox.shrink(), // Empty first cell
                  ),
                ),
                ...sprints.map((sprint) {
                  return TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 12 : 8),
                      child: Text(
                        (sprint.round + 1).toString(), // Add +1 to round number
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 16 : 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
            // Data rows - one per recruit
            ...participants.map((participant) {
              bool isCurrentRecruit = participant.number == number;
              return TableRow(
                decoration: isCurrentRecruit
                    ? BoxDecoration(color: Colors.blue.withValues(alpha: 0.2))
                    : null,
                children: [
                  // Recruit number cell
                  TableCell(
                    child: Container(
                      padding: EdgeInsets.all(isTablet ? 12 : 8),
                      color: Colors.grey[900],
                      child: Text(
                        participant.number.toString(),
                        style: TextStyle(
                          color: isCurrentRecruit ? Colors.yellow : Colors.white,
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: isCurrentRecruit ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // Round cells - one per sprint
                  ...sprints.map((sprint) {
                    Color cellColor = _getCreditColor(sprint, participant.number);
                    String label = _getCreditLabel(sprint, participant.number);
                    
                    return TableCell(
                      verticalAlignment: TableCellVerticalAlignment.fill,
                      child: Container(
                        constraints: BoxConstraints.expand(),
                        padding: EdgeInsets.zero,
                        margin: EdgeInsets.zero,
                        color: cellColor,
                        child: label.isNotEmpty
                            ? Center(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: cellColor == Colors.white || cellColor == Colors.black
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: isTablet ? 16 : 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : SizedBox.shrink(),
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
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