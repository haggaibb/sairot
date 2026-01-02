import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../event_controller.dart';
import 'exercise_graph_dialog.dart';

class ExerciseRankingDialog extends StatelessWidget {
  final int participantNumber;
  final String exerciseName;
  final String exerciseNameHebrew;
  final double grade;

  const ExerciseRankingDialog({
    super.key,
    required this.participantNumber,
    required this.exerciseName,
    required this.exerciseNameHebrew,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    final eventController = Get.find<EventController>();
    final rankInfo = eventController.getExerciseRank(participantNumber, exerciseName);
    final rank = rankInfo['rank'] ?? 0;
    final total = rankInfo['total'] ?? 0;
    final bool isTablet = MediaQuery.of(context).size.width > 600;

    return Dialog(
      child: Container(
        width: isTablet ? 500 : 350,
        padding: const EdgeInsets.all(20),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'מידע דירוג - $exerciseNameHebrew',
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'משתתף: $participantNumber',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'ציון: ${grade.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'מקום $rank מתוך $total',
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (grade > 0) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close ranking dialog
                    // Use Navigator.push with fullScreenDialog to avoid Dialog width constraints
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => ExerciseGraphDialog(
                          participantNumber: participantNumber,
                          exerciseName: exerciseName,
                          exerciseNameHebrew: exerciseNameHebrew,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('הצג גרף'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('סגור'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

