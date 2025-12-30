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
    // Extract body from Scaffold widgets
    Widget chartWidget;
    switch (exerciseName) {
      case 'meshulash':
        chartWidget = MeshulashCharts(number: participantNumber);
        break;
      case 'alonka':
        chartWidget = AlonkaCharts(number: participantNumber);
        break;
      case 'bur':
        chartWidget = BurCharts(number: participantNumber);
        break;
      case 'sakim':
        chartWidget = SakimCharts(number: participantNumber);
        break;
      default:
        return const Center(child: Text('תרגיל לא מזוהה'));
    }
    
    // Extract body from Scaffold by building it and accessing the body
    return Builder(
      builder: (context) {
        // The chart widgets return Scaffold, so we need to extract the body
        // We'll wrap it in a way that gives us access to the content
        return chartWidget;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTabletDevice = isTablet(context);
    final screenSize = MediaQuery.of(context).size;
    final dialogHeight = isTabletDevice 
        ? screenSize.height * 0.85 
        : screenSize.height * 0.75;
    final dialogWidth = isTabletDevice 
        ? screenSize.width * 0.8 
        : screenSize.width * 0.95;

    return Dialog(
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
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

