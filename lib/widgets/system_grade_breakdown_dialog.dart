import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../event_controller.dart';

class SystemGradeBreakdownDialog extends StatelessWidget {
  final int participantNumber;

  const SystemGradeBreakdownDialog({
    super.key,
    required this.participantNumber,
  });

  @override
  Widget build(BuildContext context) {
    final eventController = Get.find<EventController>();
    final participant = eventController.getParticipant(participantNumber);
    final allRanks = eventController.getAllExerciseRanks(participantNumber);
    final bool isTabletDevice = MediaQuery.of(context).size.width > 600;


    return Dialog(
      child: Container(
        width: isTabletDevice ? 600 : 400,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'פירוט ציון מערכת',
                style: TextStyle(
                  fontSize: isTabletDevice ? 24 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'משתתף: $participantNumber',
                style: TextStyle(
                  fontSize: isTabletDevice ? 20 : 18,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ציון מערכת כולל: ${participant.systemGrade.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isTabletDevice ? 22 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'פירוט לפי תרגילים:',
                style: TextStyle(
                  fontSize: isTabletDevice ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: Table(
                    border: TableBorder.all(color: Colors.grey[300]!),
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey[800]),
                        children: [
                          _buildTableCell('תרגיל', isTabletDevice, isHeader: true),
                          _buildTableCell('ציון', isTabletDevice, isHeader: true),
                          _buildTableCell('דירוג', isTabletDevice, isHeader: true),
                        ],
                      ),
                      // Meshulash row
                      TableRow(
                        children: [
                          _buildTableCell('משולש', isTabletDevice),
                          _buildTableCell(
                            participant.meshulashGrade.toStringAsFixed(2),
                            isTabletDevice,
                          ),
                          _buildTableCell(
                            '${allRanks['meshulash']!['rank']}/${allRanks['meshulash']!['total']}',
                            isTabletDevice,
                          ),
                        ],
                      ),
                      // Alonka row
                      TableRow(
                        children: [
                          _buildTableCell('אלונקה', isTabletDevice),
                          _buildTableCell(
                            participant.alonkaGrade.toStringAsFixed(2),
                            isTabletDevice,
                          ),
                          _buildTableCell(
                            '${allRanks['alonka']!['rank']}/${allRanks['alonka']!['total']}',
                            isTabletDevice,
                          ),
                        ],
                      ),
                      // Bur row
                      TableRow(
                        children: [
                          _buildTableCell('בור', isTabletDevice),
                          _buildTableCell(
                            participant.burGrade.toStringAsFixed(2),
                            isTabletDevice,
                          ),
                          _buildTableCell(
                            '${allRanks['bur']!['rank']}/${allRanks['bur']!['total']}',
                            isTabletDevice,
                          ),
                        ],
                      ),
                      // Sakim row
                      TableRow(
                        children: [
                          _buildTableCell('שקים', isTabletDevice),
                          _buildTableCell(
                            participant.sakimGrade.toStringAsFixed(2),
                            isTabletDevice,
                          ),
                          _buildTableCell(
                            '${allRanks['sakim']!['rank']}/${allRanks['sakim']!['total']}',
                            isTabletDevice,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
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

  Widget _buildTableCell(String text, bool isTablet, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isTablet ? 16 : 14,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: Colors.white,
        ),
      ),
    );
  }
}

