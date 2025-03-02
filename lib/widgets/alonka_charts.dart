import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sairot/models/participant.dart';
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
    final eventController = Get.put(Controller());
    final toggleController = Get.put(ChartToggleController());

    final List<int> rounds = eventController.currentEvent.value.alonkaSprints
        .map((AlonkaSprint sprint) => sprint.round)
        .toList();
    final List<double> participantsSprintCredit =
    rounds.map((round) => eventController.getAlonkaSprintCredit(number, round)).toList();
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
              child: Obx(() => Stack(
                children: [
                  if (!toggleController.showPieChart.value)
                    LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: rounds.asMap().entries.map((entry) {
                              int index = entry.key;
                              int round = entry.value;
                              return FlSpot(round.toDouble() + 1, participantsSprintCredit[index].toDouble());
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
                                String creditStr = touchedSpot.y.toStringAsFixed(2) == '1.00'
                                    ? 'אלונקה'
                                    : touchedSpot.y.toStringAsFixed(2) == '0.50'
                                    ? 'גריקן'
                                    : 'רץ';
                                return LineTooltipItem(
                                  ' ${creditStr} ',
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
                              reservedSize: 60,
                              interval: 0.1,
                              getTitlesWidget: (value, meta) {
                                int roundedValue = (value * 10).round();
                                switch (roundedValue) {
                                  case 10:
                                    return const Text('אלונקה', style: TextStyle(fontSize: 12));
                                  case 5:
                                    return const Text('גריקן', style: TextStyle(fontSize: 12));
                                  case 2:
                                    return const Text('רץ', style: TextStyle(fontSize: 12));
                                  default:
                                    return const SizedBox.shrink();
                                }
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                              reservedSize: 30,
                            ),
                          ),
                        ),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        minX: 1,
                        maxX: rounds.length.toDouble(),
                        minY: 0.0,
                        maxY: 1.0,
                      ),
                    ),

                  /// 🎯 Pie Chart - Shown When Toggle is ON
                  if (toggleController.showPieChart.value)
                    SprintCreditPieChart(participantsSprintCredit: participantsSprintCredit),
                ],
              )),
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