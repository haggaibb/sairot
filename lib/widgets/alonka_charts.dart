import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/participant.dart';
import '../ctx.dart';
import 'package:sairot/models/alonka_sprint.dart';

class AlonkaCharts extends StatelessWidget {
  final int number;

  AlonkaCharts({super.key, required this.number}); // The round where our participant is currently competing

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(Controller());
    final List<int> rounds = eventController.currentEvent.value.alonkaSprints.map((AlonkaSprint sprint) => sprint.round).toList();
    final List<double> participantsSprintCredit = rounds.map((round) => eventController.getAlonkaSprintCredit(number, round)).toList();
    Participant p = eventController.getParticipant(number);
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
                  ///Line Chart - Participant Position (Inverted Y-Axis)
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
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            interval: 0.1,
                            getTitlesWidget: (value, meta) {
                              int roundedValue = (value * 10).round(); // Workaround for floating-point precision
                              switch (roundedValue) {
                                case 10: // 1.0 * 10
                                  return const Text('Alonka', style: TextStyle(fontSize: 12));
                                case 5:  // 0.5 * 10
                                  return const Text('Gerikan', style: TextStyle(fontSize: 12));
                                case 2:  // 0.2 * 10
                                  return const Text('Run', style: TextStyle(fontSize: 12));
                                case 0:
                                  return const Text('0', style: TextStyle(fontSize: 12));
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
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            /// 📃 Instructor Comments Section
            p.alonkaInstructorComments.isNotEmpty?const Text(
              'הערות המדריך',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ):SizedBox.shrink(),
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