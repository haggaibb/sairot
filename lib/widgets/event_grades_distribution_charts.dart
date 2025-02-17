import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../admin/admin_controller.dart';



class EventGradesDistributionCharts extends StatelessWidget {

  const EventGradesDistributionCharts({super.key}); // The round where our participant is currently competing


  @override
  Widget build(BuildContext context) {
    final adminController = Get.put(AdminController());
    final List<int> grades = adminController.adminEvent.getInstructorGradeDistribution();
    return Scaffold(
      //appBar: AppBar(title: Text("Participant Progress Chart")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            /// Bar Chart - Total Participants in Each Round
            BarChart(
              BarChartData(
                barGroups: grades.asMap().entries.map((entry) {
                  int index = entry.key;
                  int grade = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: grades[index].toDouble(),
                        color: index>=5? Colors.green : Colors.black, // Highlight the current round
                        width: 20,
                      ),
                    ],
                  );
                }).toList(),
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
                  // bottomTitles: AxisTitles(
                  //   sideTitles: SideTitles(showTitles: false), // Disable X-axis titles on BarChart
                  // ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}