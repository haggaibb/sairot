import 'package:flutter/material.dart';
import 'meshulash_charts.dart';
import 'alonka_charts.dart';
import 'bur_charts.dart';
import 'sakim_charts.dart';

class ExerciseGraphDialog extends StatelessWidget {
  final int participantNumber;
  final String exerciseName;
  final String exerciseNameHebrew;

  const ExerciseGraphDialog({
    super.key,
    required this.participantNumber,
    required this.exerciseName,
    required this.exerciseNameHebrew,
  });

  Widget _buildChart() {
    // Build chart widgets directly - they return Scaffold, but we'll use them as-is
    // The Scaffold's body already has minimal padding
    switch (exerciseName) {
      case 'meshulash':
        return MeshulashCharts(number: participantNumber);
      case 'alonka':
        return AlonkaCharts(number: participantNumber);
      case 'bur':
        return BurCharts(number: participantNumber);
      case 'sakim':
        return SakimCharts(number: participantNumber);
      default:
        return const Center(child: Text('תרגיל לא מזוהה'));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chart widgets already return Scaffold with their own structure
    // Use them directly - they should fill the full screen width
    return _buildChart();
  }
}

