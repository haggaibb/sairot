import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../event_controller.dart';
import '../models/participant.dart';
import '../models/types.dart';
import 'exercise_ranking_dialog.dart';
import 'system_grade_breakdown_dialog.dart';

enum SortColumn {
  number,
  finalGrade,
  systemGrade,
  meshulash,
  alonka,
  bur,
  sakim,
}

enum SortDirection {
  ascending,
  descending,
  none,
}

class CustomGradesTable extends StatefulWidget {
  final EventController eventController;
  final bool isTablet;

  const CustomGradesTable({
    super.key,
    required this.eventController,
    required this.isTablet,
  });

  @override
  State<CustomGradesTable> createState() => _CustomGradesTableState();
}

class _CustomGradesTableState extends State<CustomGradesTable> {
  SortColumn? _sortColumn = SortColumn.systemGrade;
  SortDirection _sortDirection = SortDirection.descending;
  final Map<int, TextEditingController> _gradeControllers = {};
  final Map<int, FocusNode> _gradeFocusNodes = {};
  int? _selectedParticipantNumber; // Track selected row

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Dispose old controllers and focus nodes
    for (var controller in _gradeControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _gradeFocusNodes.values) {
      focusNode.dispose();
    }
    _gradeControllers.clear();
    _gradeFocusNodes.clear();
    
    // Create new controllers and focus nodes
    for (var participant in widget.eventController.currentEvent.value.participants) {
      _gradeControllers[participant.number] = TextEditingController(
        text: participant.instructorGrade.toString(),
      );
      _gradeFocusNodes[participant.number] = FocusNode();
    }
  }

  @override
  void didUpdateWidget(CustomGradesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers when participants change
    if (oldWidget.eventController.currentEvent.value.participants.length !=
        widget.eventController.currentEvent.value.participants.length) {
      _initializeControllers();
    } else {
      // Update existing controllers with new values
      for (var participant in widget.eventController.currentEvent.value.participants) {
        final controller = _gradeControllers[participant.number];
        if (controller != null && controller.text != participant.instructorGrade.toString()) {
          controller.text = participant.instructorGrade.toString();
        }
        // Ensure FocusNode exists for new participants
        if (!_gradeFocusNodes.containsKey(participant.number)) {
          _gradeFocusNodes[participant.number] = FocusNode();
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _gradeControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _gradeFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  List<Participant> _getSortedParticipants() {
    // Filter out rejected (dropped) participants
    final participants = List<Participant>.from(
      widget.eventController.currentEvent.value.participants
          .where((p) => p.status == ParticipantStatus.Active),
    );

    if (_sortColumn == null || _sortDirection == SortDirection.none) {
      return participants;
    }

    participants.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn!) {
        case SortColumn.number:
          comparison = a.number.compareTo(b.number);
          break;
        case SortColumn.finalGrade:
          comparison = a.instructorGrade.compareTo(b.instructorGrade);
          break;
        case SortColumn.systemGrade:
          comparison = a.systemGrade.compareTo(b.systemGrade);
          break;
        case SortColumn.meshulash:
          comparison = a.meshulashGrade.compareTo(b.meshulashGrade);
          break;
        case SortColumn.alonka:
          comparison = a.alonkaGrade.compareTo(b.alonkaGrade);
          break;
        case SortColumn.bur:
          comparison = a.burGrade.compareTo(b.burGrade);
          break;
        case SortColumn.sakim:
          comparison = a.sakimGrade.compareTo(b.sakimGrade);
          break;
      }

      return _sortDirection == SortDirection.ascending ? comparison : -comparison;
    });

    return participants;
  }

  void _handleSort(SortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        // Cycle through: ascending -> descending -> none -> ascending
        switch (_sortDirection) {
          case SortDirection.ascending:
            _sortDirection = SortDirection.descending;
            break;
          case SortDirection.descending:
            _sortDirection = SortDirection.none;
            _sortColumn = null;
            break;
          case SortDirection.none:
            _sortDirection = SortDirection.ascending;
            _sortColumn = column;
            break;
        }
      } else {
        _sortColumn = column;
        _sortDirection = SortDirection.ascending;
      }
    });
  }

  Color _getRowColor(Participant participant) {
    // If row is selected, highlight it
    if (_selectedParticipantNumber == participant.number) {
      return Colors.blue[100]!;
    }
    
    final finalGrade = participant.instructorGrade;
    final systemGrade = participant.systemGrade;

    if (finalGrade >= 5) {
      return Colors.greenAccent;
    } else if (systemGrade >= 5 && finalGrade < 1) {
      return Colors.greenAccent;
    } else {
      return Colors.white;
    }
  }

  Widget _buildSortIcon(SortColumn column) {
    if (_sortColumn != column || _sortDirection == SortDirection.none) {
      return const SizedBox(width: 16);
    }
    return Icon(
      _sortDirection == SortDirection.ascending
          ? Icons.arrow_upward
          : Icons.arrow_downward,
      size: 16,
      color: Colors.black87,
    );
  }

  bool _hasComments(Participant participant) {
    // Check only alonka, meshulash, and sakim comments
    return participant.alonkaInstructorComments.isNotEmpty ||
        participant.meshulashInstructorComments.isNotEmpty ||
        participant.sakimInstructorComments.isNotEmpty;
  }

  Widget _buildCommentIndicator(Participant participant) {
    if (!_hasComments(participant)) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(
        Icons.comment,
        size: 16,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildExerciseCommentIndicator(Participant participant, String exercise) {
    bool hasComment = false;
    switch (exercise) {
      case 'alonka':
        hasComment = participant.alonkaInstructorComments.isNotEmpty;
        break;
      case 'meshulash':
        hasComment = participant.meshulashInstructorComments.isNotEmpty;
        break;
      case 'sakim':
        hasComment = participant.sakimInstructorComments.isNotEmpty;
        break;
    }
    
    if (!hasComment) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(
        Icons.comment,
        size: 16,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildHeaderCell(String title, SortColumn column, double width, {bool isFrozen = false}) {
    return GestureDetector(
      onTap: () => _handleSort(column),
      child: Container(
        width: width,
        height: 48, // Fixed height to match cells
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[400]!, width: 1),
            right: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          color: Colors.grey[200],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ),
            const SizedBox(width: 2),
            _buildSortIcon(column),
          ],
        ),
      ),
    );
  }

  Widget _buildCell({
    required Widget child,
    required double width,
    Color? backgroundColor,
    VoidCallback? onDoubleTap,
  }) {
    return Listener(
      onPointerDown: (_) {
        // Unfocus any focused TextField when clicking on a cell
        // Use a small delay to allow the TextField's onTap to complete first if it's the TextField
        Future.microtask(() {
          if (mounted) {
            FocusScope.of(context).unfocus();
          }
        });
      },
      child: GestureDetector(
        onDoubleTap: onDoubleTap,
        child: Container(
          width: width,
          height: 48, // Fixed height to match header and align rows
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey[400]!, width: 1),
              right: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetX<EventController>(
      builder: (_) {
        final sortedParticipants = _getSortedParticipants();
        final isFinalized = widget.eventController.currentEvent.value.finalized;

        // Column widths
        final numberWidth = widget.isTablet ? 100.0 : 90.0;
        final finalGradeWidth = widget.isTablet ? 130.0 : 110.0; // Increased to fit "ציון סופי"
        final systemGradeWidth = widget.isTablet ? 140.0 : 120.0;
        final exerciseWidth = widget.isTablet ? 100.0 : 90.0;
        final burWidth = widget.isTablet ? 80.0 : 70.0;
        final sakimWidth = widget.isTablet ? 80.0 : 70.0;

        return Listener(
          onPointerDown: (_) {
            // Unfocus any focused TextField when clicking anywhere
            // Use Listener instead of GestureDetector to catch events before gesture recognition
            FocusScope.of(context).unfocus();
          },
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  // Frozen first column (מספר - recruit number)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      _buildHeaderCell('מספר', SortColumn.number, numberWidth, isFrozen: true),
                      // Data rows
                      ...sortedParticipants.map((participant) {
                      final rowColor = _getRowColor(participant);
                      return GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _selectedParticipantNumber = participant.number;
                          });
                        },
                        child: _buildCell(
                          width: numberWidth,
                          backgroundColor: rowColor,
                          onDoubleTap: () {
                            Get.toNamed('/performance_page/${participant.number}');
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCommentIndicator(participant),
                              Text(
                                participant.number.toString(),
                                style: const TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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
                              _buildHeaderCell(
                                widget.isTablet ? 'ציון סופי' : 'סופי',
                                SortColumn.finalGrade,
                                finalGradeWidth,
                              ),
                              _buildHeaderCell(
                                widget.isTablet ? 'ציון מערכת' : 'מערכת',
                                SortColumn.systemGrade,
                                systemGradeWidth,
                              ),
                              _buildHeaderCell('משולש', SortColumn.meshulash, exerciseWidth),
                              _buildHeaderCell('אלונקה', SortColumn.alonka, exerciseWidth),
                              _buildHeaderCell('בור', SortColumn.bur, burWidth),
                              _buildHeaderCell('שקים', SortColumn.sakim, sakimWidth),
                            ],
                          ),
                          // Data rows
                          ...sortedParticipants.map((participant) {
              final rowColor = _getRowColor(participant);
              // Ensure controller exists
              if (!_gradeControllers.containsKey(participant.number)) {
                _gradeControllers[participant.number] = TextEditingController(
                  text: participant.instructorGrade.toString(),
                );
              }
              final gradeController = _gradeControllers[participant.number]!;

              return GestureDetector(
                onTap: () {
                  // Unfocus any focused TextField when clicking on a row
                  // Check if we clicked on the final grade TextField - if so, don't unfocus
                  final focusedNode = FocusScope.of(context).focusedChild;
                  if (focusedNode != _gradeFocusNodes[participant.number]) {
                    FocusScope.of(context).unfocus();
                  }
                  setState(() {
                    _selectedParticipantNumber = participant.number;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Final grade cell (editable)
                  GestureDetector(
                    // This GestureDetector will catch taps on the container area
                    // but the TextField's onTap will handle taps on the TextField itself
                    onTap: () {
                      // If clicking on the container (not the TextField), unfocus
                      FocusScope.of(context).unfocus();
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      width: finalGradeWidth,
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: rowColor,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[400]!, width: 1),
                          right: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: Center(
                        child: isFinalized
                            ? Text(
                                participant.instructorGrade.toString(),
                                style: const TextStyle(color: Colors.black),
                              )
                            : GestureDetector(
                                // Prevent the parent GestureDetector from firing when clicking the TextField
                                onTap: () {},
                                child: SizedBox(
                                  height: 20,
                                  width: 60,
                                  child: TextField(
                                    controller: gradeController,
                                    focusNode: _gradeFocusNodes[participant.number],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 0,
                                      ),
                                      isDense: true,
                                    ),
                                    onTap: () {
                                      // Select all text when focused
                                      // Use a post-frame callback to ensure selection happens after focus
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (mounted && gradeController.text.isNotEmpty) {
                                          gradeController.selection = TextSelection(
                                            baseOffset: 0,
                                            extentOffset: gradeController.text.length,
                                          );
                                        }
                                      });
                                      // Also select the row
                                      setState(() {
                                        _selectedParticipantNumber = participant.number;
                                      });
                                    },
                                    onEditingComplete: () {
                                      // Unfocus when editing is complete (Enter key)
                                      FocusScope.of(context).unfocus();
                                    },
                                    onChanged: (value) {
                                      final grade = int.tryParse(value) ?? 0;
                                      widget.eventController.setParticipantsGrade(
                                        participant.number,
                                        grade,
                                      );
                                    },
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  // System grade cell
                  _buildCell(
                    width: systemGradeWidth,
                    backgroundColor: rowColor,
                    onDoubleTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => SystemGradeBreakdownDialog(
                          participantNumber: participant.number,
                        ),
                      );
                    },
                    child: Text(
                      participant.systemGrade.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  // Meshulash cell
                  _buildCell(
                    width: exerciseWidth,
                    backgroundColor: rowColor,
                    onDoubleTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => ExerciseRankingDialog(
                          participantNumber: participant.number,
                          exerciseName: 'meshulash',
                          exerciseNameHebrew: 'משולש',
                          grade: participant.meshulashGrade,
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          participant.meshulashGrade.toStringAsFixed(2),
                          style: const TextStyle(color: Colors.black),
                        ),
                        _buildExerciseCommentIndicator(participant, 'meshulash'),
                      ],
                    ),
                  ),
                  // Alonka cell
                  _buildCell(
                    width: exerciseWidth,
                    backgroundColor: rowColor,
                    onDoubleTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => ExerciseRankingDialog(
                          participantNumber: participant.number,
                          exerciseName: 'alonka',
                          exerciseNameHebrew: 'אלונקה',
                          grade: participant.alonkaGrade,
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          participant.alonkaGrade.toStringAsFixed(2),
                          style: const TextStyle(color: Colors.black),
                        ),
                        _buildExerciseCommentIndicator(participant, 'alonka'),
                      ],
                    ),
                  ),
                  // Bur cell
                  _buildCell(
                    width: burWidth,
                    backgroundColor: rowColor,
                    onDoubleTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => ExerciseRankingDialog(
                          participantNumber: participant.number,
                          exerciseName: 'bur',
                          exerciseNameHebrew: 'בור',
                          grade: participant.burGrade,
                        ),
                      );
                    },
                    child: Text(
                      participant.burGrade.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  // Sakim cell
                  _buildCell(
                    width: sakimWidth,
                    backgroundColor: rowColor,
                    onDoubleTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => ExerciseRankingDialog(
                          participantNumber: participant.number,
                          exerciseName: 'sakim',
                          exerciseNameHebrew: 'שקים',
                          grade: participant.sakimGrade,
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          participant.sakimGrade.toStringAsFixed(2),
                          style: const TextStyle(color: Colors.black),
                        ),
                        _buildExerciseCommentIndicator(participant, 'sakim'),
                      ],
                    ),
                  ),
                  ],
                ),
              );
            }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }
}

