import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../event_controller.dart';
import '../models/types.dart';

/// Helper method to get adjusted system grade based on group strength
double getAdjustedSystemGrade(double baseGrade, GroupStrength groupStrength) {
  switch (groupStrength) {
    case GroupStrength.weak:
      return (baseGrade - 1.0).clamp(0.0, 10.0); // Reduce 1 point, clamp between 0-10
    case GroupStrength.strong:
      return (baseGrade + 1.0).clamp(0.0, 10.0); // Add 1 point, clamp between 0-10
    case GroupStrength.normal:
      return baseGrade; // No adjustment
  }
}

class SystemGradeBreakdownDialog extends StatelessWidget {
  final int participantNumber;

  const SystemGradeBreakdownDialog({
    super.key,
    required this.participantNumber,
  });

  /// Get adjusted system grade for display (based on group strength)
  double _getAdjustedSystemGrade(EventController eventController, participant) {
    final groupStrength = eventController.currentEvent.value.groupStrength;
    
    // Get base exercise grades
    final baseMeshulash = participant.meshulashGrade;
    final baseAlonka = participant.alonkaGrade;
    final baseSakim = participant.sakimGrade;
    final burGrade = participant.burGrade;
    
    // Apply group strength adjustment to meshulash, alonka, sakim
    final adjustedMeshulash = getAdjustedSystemGrade(baseMeshulash, groupStrength);
    final adjustedAlonka = getAdjustedSystemGrade(baseAlonka, groupStrength);
    final adjustedSakim = getAdjustedSystemGrade(baseSakim, groupStrength);
    
    // Recalculate system grade with adjusted values
    final gradesData = eventController.gradesData;
    return eventController.calculateWeightedGrade(
      param1: adjustedMeshulash,
      param2: adjustedAlonka,
      param3: adjustedSakim,
      param4: burGrade,
      weight1: (gradesData.weighted['meshulash'] as num?)?.toDouble() ?? 0.25,
      weight2: (gradesData.weighted['alonka'] as num?)?.toDouble() ?? 0.25,
      weight3: (gradesData.weighted['sakim'] as num?)?.toDouble() ?? 0.25,
      weight4: (gradesData.weighted['bur'] as num?)?.toDouble() ?? 0.25,
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventController = Get.find<EventController>();
    final participant = eventController.getParticipant(participantNumber);
    final allRanks = eventController.getAllExerciseRanks(participantNumber);
    final bool isTabletDevice = MediaQuery.of(context).size.width > 600;
    final groupStrength = eventController.currentEvent.value.groupStrength;


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
                  'ציון מערכת כולל: ${_getAdjustedSystemGrade(eventController, participant).toStringAsFixed(2)}',
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
                child: _buildFrozenColumnTable(
                  participant,
                  allRanks,
                  isTabletDevice,
                  groupStrength,
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

  Widget _buildTableCell(String text, bool isTablet, {bool isHeader = false, Color? backgroundColor}) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: backgroundColor != null
          ? BoxDecoration(color: backgroundColor)
          : null,
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

  Widget _buildFrozenColumnTable(
    participant,
    allRanks,
    bool isTablet,
    GroupStrength groupStrength,
  ) {
    final firstColumnWidth = isTablet ? 120.0 : 100.0;
    final cellHeight = 48.0;
    final rows = [
      {'exercise': 'משולש', 'grade': getAdjustedSystemGrade(participant.meshulashGrade, groupStrength).toStringAsFixed(2), 'rank': '${allRanks['meshulash']!['rank']}/${allRanks['meshulash']!['total']}'},
      {'exercise': 'אלונקה', 'grade': getAdjustedSystemGrade(participant.alonkaGrade, groupStrength).toStringAsFixed(2), 'rank': '${allRanks['alonka']!['rank']}/${allRanks['alonka']!['total']}'},
      {'exercise': 'בור', 'grade': participant.burGrade.toStringAsFixed(2), 'rank': '${allRanks['bur']!['rank']}/${allRanks['bur']!['total']}'},
      {'exercise': 'שקים', 'grade': getAdjustedSystemGrade(participant.sakimGrade, groupStrength).toStringAsFixed(2), 'rank': '${allRanks['sakim']!['rank']}/${allRanks['sakim']!['total']}'},
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frozen first column
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: firstColumnWidth,
              height: cellHeight,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                border: Border(
                  right: BorderSide(color: Colors.grey[300]!, width: 1),
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: _buildTableCell('תרגיל', isTablet, isHeader: true),
            ),
            // Data rows
            ...rows.map((row) => Container(
              width: firstColumnWidth,
              height: cellHeight,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey[300]!, width: 1),
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: _buildTableCell(row['exercise']!, isTablet),
            )),
          ],
        ),
        // Scrollable columns
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: isTablet ? 120.0 : 100.0,
                      height: cellHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!, width: 1),
                          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: _buildTableCell('ציון', isTablet, isHeader: true),
                    ),
                    Container(
                      width: isTablet ? 120.0 : 100.0,
                      height: cellHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!, width: 1),
                          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: _buildTableCell('דירוג', isTablet, isHeader: true),
                    ),
                  ],
                ),
                // Data rows
                ...rows.map((row) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: isTablet ? 120.0 : 100.0,
                      height: cellHeight,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!, width: 1),
                          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: _buildTableCell(row['grade']!, isTablet),
                    ),
                    Container(
                      width: isTablet ? 120.0 : 100.0,
                      height: cellHeight,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!, width: 1),
                          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: _buildTableCell(row['rank']!, isTablet),
                    ),
                  ],
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

