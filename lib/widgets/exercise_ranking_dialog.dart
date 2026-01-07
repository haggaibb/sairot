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
    
    // Get participant to access comments
    final participant = eventController.currentEvent.value.participants.firstWhere(
      (p) => p.number == participantNumber,
      orElse: () => eventController.currentEvent.value.participants.first,
    );
    
    // Get comments for this exercise
    List<String> comments = [];
    switch (exerciseName) {
      case 'alonka':
        comments = participant.alonkaInstructorComments;
        break;
      case 'meshulash':
        comments = participant.meshulashInstructorComments;
        break;
      case 'sakim':
        comments = participant.sakimInstructorComments;
        break;
    }

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
              // Show comments if they exist
              if (comments.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'הערות המדריך:',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...comments.map((comment) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $comment',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              color: Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
              if (grade > 0) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close ranking dialog
                    showDialog(
                      context: context,
                      builder: (context) => ExerciseGraphDialog(
                        participantNumber: participantNumber,
                        exerciseName: exerciseName,
                        exerciseNameHebrew: exerciseNameHebrew,
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

