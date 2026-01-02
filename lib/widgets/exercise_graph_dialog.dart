import 'package:flutter/material.dart';
import 'meshulash_charts.dart';
import 'alonka_charts.dart';
import 'bur_charts.dart';
import 'sakim_charts.dart';
import '../utils/tablet_utils.dart';

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
    // Build chart widgets - they return Scaffold
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
    final bool isTabletDevice = isTablet(context);
    final screenSize = MediaQuery.of(context).size;
    final dialogHeight = isTabletDevice 
        ? screenSize.height * 0.85 
        : screenSize.height * 0.75;
    
    return Dialog(
      child: SizedBox(
        width: isTabletDevice ? 600 : 400,
        height: dialogHeight,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'גרף $exerciseNameHebrew - משתתף $participantNumber',
                      style: TextStyle(
                        fontSize: isTabletDevice ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Chart content
              Expanded(
                child: _buildChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

