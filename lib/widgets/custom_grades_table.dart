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
  final bool showSystemGrades;
  final bool showInstructorGrades;

  const CustomGradesTable({
    super.key,
    required this.eventController,
    required this.isTablet,
    this.showSystemGrades = true,
    this.showInstructorGrades = true,
  });

  @override
  State<CustomGradesTable> createState() => _CustomGradesTableState();
}

class _CustomGradesTableState extends State<CustomGradesTable> {
  SortColumn? _sortColumn = SortColumn.systemGrade;
  SortDirection _sortDirection = SortDirection.descending;
  final Map<int, TextEditingController> _gradeControllers = {};
  final Map<int, FocusNode> _gradeFocusNodes = {};
  final Map<int, TextEditingController> _meshulashGradeControllers = {};
  final Map<int, FocusNode> _meshulashGradeFocusNodes = {};
  final Map<int, TextEditingController> _alonkaGradeControllers = {};
  final Map<int, FocusNode> _alonkaGradeFocusNodes = {};
  final Map<int, TextEditingController> _sakimGradeControllers = {};
  final Map<int, FocusNode> _sakimGradeFocusNodes = {};
  final Map<int, TextEditingController> _burGradeControllers = {};
  final Map<int, FocusNode> _burGradeFocusNodes = {};
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
    for (var controller in _meshulashGradeControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _meshulashGradeFocusNodes.values) {
      focusNode.dispose();
    }
    for (var controller in _alonkaGradeControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _alonkaGradeFocusNodes.values) {
      focusNode.dispose();
    }
    for (var controller in _sakimGradeControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _sakimGradeFocusNodes.values) {
      focusNode.dispose();
    }
    for (var controller in _burGradeControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _burGradeFocusNodes.values) {
      focusNode.dispose();
    }
    _gradeControllers.clear();
    _gradeFocusNodes.clear();
    _meshulashGradeControllers.clear();
    _meshulashGradeFocusNodes.clear();
    _alonkaGradeControllers.clear();
    _alonkaGradeFocusNodes.clear();
    _sakimGradeControllers.clear();
    _sakimGradeFocusNodes.clear();
    _burGradeControllers.clear();
    _burGradeFocusNodes.clear();
    
    // Create new controllers and focus nodes
    for (var participant in widget.eventController.currentEvent.value.participants) {
      _gradeControllers[participant.number] = TextEditingController(
        text: participant.instructorGrade.toString(),
      );
      _gradeFocusNodes[participant.number] = FocusNode();
      _meshulashGradeControllers[participant.number] = TextEditingController(
        text: participant.instructorMeshulashGrade.toString(),
      );
      _meshulashGradeFocusNodes[participant.number] = FocusNode();
      _alonkaGradeControllers[participant.number] = TextEditingController(
        text: participant.instructorAlonkaGrade.toString(),
      );
      _alonkaGradeFocusNodes[participant.number] = FocusNode();
      _sakimGradeControllers[participant.number] = TextEditingController(
        text: participant.instructorSakimGrade.toString(),
      );
      _sakimGradeFocusNodes[participant.number] = FocusNode();
      _burGradeControllers[participant.number] = TextEditingController(
        text: participant.instructorBurGrade.toString(),
      );
      _burGradeFocusNodes[participant.number] = FocusNode();
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
    for (var controller in _meshulashGradeControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _meshulashGradeFocusNodes.values) {
      focusNode.dispose();
    }
    for (var controller in _alonkaGradeControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _alonkaGradeFocusNodes.values) {
      focusNode.dispose();
    }
    for (var controller in _sakimGradeControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _sakimGradeFocusNodes.values) {
      focusNode.dispose();
    }
    for (var controller in _burGradeControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _burGradeFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  List<Participant> _getSortedParticipants() {
    // Filter out rejected (dropped) participants - only show Active participants
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

  Widget _buildMasterHeaderCell(String title, double width) {
    return Container(
      width: width,
      height: 48, // Fixed height to match cells
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[400]!, width: 1),
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        color: Colors.grey[300],
      ),
      child: Center(
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

  Widget _buildEditableExerciseGradeCell({
    required int participantNumber,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String exercise,
    required double width,
    required Color backgroundColor,
    required bool isFinalized,
  }) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: width,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(color: Colors.grey[400]!, width: 1),
            right: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        child: Center(
          child: isFinalized
              ? Text(
                  controller.text,
                  style: const TextStyle(color: Colors.black),
                )
              : GestureDetector(
                  onTap: () {},
                  child: SizedBox(
                    height: 20,
                    width: 60,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
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
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && controller.text.isNotEmpty) {
                            controller.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: controller.text.length,
                            );
                          }
                        });
                        setState(() {
                          _selectedParticipantNumber = participantNumber;
                        });
                      },
                      onEditingComplete: () {
                        FocusScope.of(context).unfocus();
                      },
                      onChanged: (value) {
                        final grade = int.tryParse(value) ?? 0;
                        widget.eventController.setParticipantExerciseGrade(
                          participantNumber,
                          exercise,
                          grade,
                        );
                      },
                    ),
                  ),
                ),
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
        final instructorExerciseWidth = widget.isTablet ? 100.0 : 90.0; // Width for instructor grade columns
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
                      // Empty cell for master header row alignment (only if master header is shown)
                      if (widget.showSystemGrades && widget.showInstructorGrades)
                        Container(
                          width: numberWidth,
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[400]!, width: 1),
                              right: BorderSide(color: Colors.grey[300]!, width: 1),
                            ),
                            color: Colors.grey[300],
                          ),
                        ),
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
                          // Master header row (grouping columns) - only show when both system and instructor grades are visible
                          if (widget.showSystemGrades && widget.showInstructorGrades)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMasterHeaderCell(
                                  widget.isTablet ? 'ציון סופי' : 'סופי',
                                  finalGradeWidth + systemGradeWidth,
                                ),
                                _buildMasterHeaderCell(
                                  'משולש',
                                  exerciseWidth + instructorExerciseWidth,
                                ),
                                _buildMasterHeaderCell(
                                  'אלונקה',
                                  exerciseWidth + instructorExerciseWidth,
                                ),
                                _buildMasterHeaderCell(
                                  'בור',
                                  instructorExerciseWidth,
                                ),
                                _buildMasterHeaderCell(
                                  'שקים',
                                  sakimWidth + instructorExerciseWidth,
                                ),
                              ],
                            ),
                          // Header row (individual column headers)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHeaderCell(
                                widget.isTablet ? 'ציון סופי' : 'סופי',
                                SortColumn.finalGrade,
                                finalGradeWidth,
                              ),
                              if (widget.showSystemGrades)
                                _buildHeaderCell(
                                  widget.isTablet ? 'ציון מערכת' : 'מערכת',
                                  SortColumn.systemGrade,
                                  systemGradeWidth,
                                ),
                              if (widget.showSystemGrades || widget.showInstructorGrades) ...[
                                if (widget.showSystemGrades)
                                  _buildHeaderCell('משולש', SortColumn.meshulash, exerciseWidth),
                                if (widget.showInstructorGrades)
                                  _buildHeaderCell(widget.isTablet ? 'ציון מדריך משולש' : 'מדריך משולש', SortColumn.meshulash, instructorExerciseWidth),
                                if (widget.showSystemGrades)
                                  _buildHeaderCell('אלונקה', SortColumn.alonka, exerciseWidth),
                                if (widget.showInstructorGrades)
                                  _buildHeaderCell(widget.isTablet ? 'ציון מדריך אלונקה' : 'מדריך אלונקה', SortColumn.alonka, instructorExerciseWidth),
                                if (widget.showInstructorGrades)
                                  _buildHeaderCell(widget.isTablet ? 'ציון מדריך בור' : 'מדריך בור', SortColumn.bur, instructorExerciseWidth),
                                if (widget.showSystemGrades)
                                  _buildHeaderCell('שקים', SortColumn.sakim, sakimWidth),
                                if (widget.showInstructorGrades)
                                  _buildHeaderCell(widget.isTablet ? 'ציון מדריך שקים' : 'מדריך שקים', SortColumn.sakim, instructorExerciseWidth),
                              ],
                            ],
                          ),
                          // Data rows
                          ...sortedParticipants.map((participant) {
              final rowColor = _getRowColor(participant);
              // Ensure controllers exist
              if (!_gradeControllers.containsKey(participant.number)) {
                _gradeControllers[participant.number] = TextEditingController(
                  text: participant.instructorGrade.toString(),
                );
              }
              if (!_meshulashGradeControllers.containsKey(participant.number)) {
                _meshulashGradeControllers[participant.number] = TextEditingController(
                  text: participant.instructorMeshulashGrade.toString(),
                );
              }
              if (!_alonkaGradeControllers.containsKey(participant.number)) {
                _alonkaGradeControllers[participant.number] = TextEditingController(
                  text: participant.instructorAlonkaGrade.toString(),
                );
              }
              if (!_sakimGradeControllers.containsKey(participant.number)) {
                _sakimGradeControllers[participant.number] = TextEditingController(
                  text: participant.instructorSakimGrade.toString(),
                );
              }
              final gradeController = _gradeControllers[participant.number]!;
              final meshulashGradeController = _meshulashGradeControllers[participant.number]!;
              final alonkaGradeController = _alonkaGradeControllers[participant.number]!;
              final sakimGradeController = _sakimGradeControllers[participant.number]!;
              final burGradeController = _burGradeControllers[participant.number]!;
              
              // Ensure focus nodes exist
              if (!_meshulashGradeFocusNodes.containsKey(participant.number)) {
                _meshulashGradeFocusNodes[participant.number] = FocusNode();
              }
              if (!_alonkaGradeFocusNodes.containsKey(participant.number)) {
                _alonkaGradeFocusNodes[participant.number] = FocusNode();
              }
              if (!_sakimGradeFocusNodes.containsKey(participant.number)) {
                _sakimGradeFocusNodes[participant.number] = FocusNode();
              }
              if (!_burGradeFocusNodes.containsKey(participant.number)) {
                _burGradeFocusNodes[participant.number] = FocusNode();
              }

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
                  if (widget.showSystemGrades)
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
                  // Exercise cells (only show if at least one type is visible)
                  if (widget.showSystemGrades || widget.showInstructorGrades) ...[
                    // Meshulash system grade cell
                    if (widget.showSystemGrades)
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
                    // Meshulash instructor grade cell
                    if (widget.showInstructorGrades)
                      _buildEditableExerciseGradeCell(
                        participantNumber: participant.number,
                        controller: meshulashGradeController,
                        focusNode: _meshulashGradeFocusNodes[participant.number]!,
                        exercise: 'meshulash',
                        width: instructorExerciseWidth,
                        backgroundColor: rowColor,
                        isFinalized: isFinalized,
                      ),
                    // Alonka system grade cell
                    if (widget.showSystemGrades)
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
                    // Alonka instructor grade cell
                    if (widget.showInstructorGrades)
                      _buildEditableExerciseGradeCell(
                        participantNumber: participant.number,
                        controller: alonkaGradeController,
                        focusNode: _alonkaGradeFocusNodes[participant.number]!,
                        exercise: 'alonka',
                        width: instructorExerciseWidth,
                        backgroundColor: rowColor,
                        isFinalized: isFinalized,
                      ),
                    // Bur instructor grade cell (only instructor grade, no system grade)
                    if (widget.showInstructorGrades)
                      _buildEditableExerciseGradeCell(
                        participantNumber: participant.number,
                        controller: burGradeController,
                        focusNode: _burGradeFocusNodes[participant.number]!,
                        exercise: 'bur',
                        width: instructorExerciseWidth,
                        backgroundColor: rowColor,
                        isFinalized: isFinalized,
                      ),
                    // Sakim system grade cell
                    if (widget.showSystemGrades)
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
                    // Sakim instructor grade cell
                    if (widget.showInstructorGrades)
                      _buildEditableExerciseGradeCell(
                        participantNumber: participant.number,
                        controller: sakimGradeController,
                        focusNode: _sakimGradeFocusNodes[participant.number]!,
                        exercise: 'sakim',
                        width: instructorExerciseWidth,
                        backgroundColor: rowColor,
                        isFinalized: isFinalized,
                      ),
                  ],
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

