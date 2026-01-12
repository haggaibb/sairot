import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../event_controller.dart';
import '../models/participant.dart';
import '../models/types.dart';
import 'exercise_ranking_dialog.dart';
import 'system_grade_breakdown_dialog.dart';

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
  int? _loadingParticipantNumber; // Track which participant is loading performance page

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
      // Initialize controller with saved final grade if it exists (always show saved values)
      // If no saved value, leave empty so hint shows calculated value
      String initialText = '';
      if (participant.instructorGrade > 0.0) {
        // Always show saved instructorGrade value (it's the saved final grade)
        initialText = participant.instructorGrade.toStringAsFixed(
          participant.instructorGrade == participant.instructorGrade.roundToDouble() ? 0 : 2
        );
      }
      _gradeControllers[participant.number] = TextEditingController(
        text: initialText,
      );
      _gradeFocusNodes[participant.number] = FocusNode();
      _meshulashGradeControllers[participant.number] = TextEditingController(
        text: participant.instructorMeshulashGrade.toStringAsFixed(participant.instructorMeshulashGrade == participant.instructorMeshulashGrade.roundToDouble() ? 0 : 2),
      );
      _meshulashGradeFocusNodes[participant.number] = FocusNode();
      _alonkaGradeControllers[participant.number] = TextEditingController(
        text: participant.instructorAlonkaGrade.toStringAsFixed(participant.instructorAlonkaGrade == participant.instructorAlonkaGrade.roundToDouble() ? 0 : 2),
      );
      _alonkaGradeFocusNodes[participant.number] = FocusNode();
      _sakimGradeControllers[participant.number] = TextEditingController(
        text: participant.instructorSakimGrade.toStringAsFixed(participant.instructorSakimGrade == participant.instructorSakimGrade.roundToDouble() ? 0 : 2),
      );
      _sakimGradeFocusNodes[participant.number] = FocusNode();
      // Get Bur grade from burGrades collection, not from participant.instructorBurGrade
      // Bur grades support doubles, so we keep the decimal value
      int burIndex = widget.eventController.currentEvent.value.burGrades
          .indexWhere((bur) => bur.id == participant.number);
      double burGradeValue = 0.0;
      if (burIndex != -1) {
        burGradeValue = widget.eventController.currentEvent.value.burGrades[burIndex].burGrade;
      }
      _burGradeControllers[participant.number] = TextEditingController(
        text: burGradeValue.toStringAsFixed(burGradeValue == burGradeValue.roundToDouble() ? 0 : 2),
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
        // Update final grade controller - always show saved instructorGrade value
        final controller = _gradeControllers[participant.number];
        if (controller != null && !_gradeFocusNodes[participant.number]!.hasFocus) {
          // Always show saved instructorGrade if it exists (it's the saved final grade)
          String displayText = '';
          if (participant.instructorGrade > 0.0) {
            displayText = participant.instructorGrade.toStringAsFixed(
              participant.instructorGrade == participant.instructorGrade.roundToDouble() ? 0 : 2
            );
          }
          // Only update if text changed (to avoid clearing user input)
          if (controller.text != displayText) {
            controller.text = displayText;
          }
        }
        // Ensure FocusNode exists for new participants
        if (!_gradeFocusNodes.containsKey(participant.number)) {
          _gradeFocusNodes[participant.number] = FocusNode();
        }
        
        // Update Meshulash grade controller
        final meshulashController = _meshulashGradeControllers[participant.number];
        if (meshulashController != null) {
          String formattedGrade = participant.instructorMeshulashGrade.toStringAsFixed(
            participant.instructorMeshulashGrade == participant.instructorMeshulashGrade.roundToDouble() ? 0 : 2
          );
          if (meshulashController.text != formattedGrade && 
              !_meshulashGradeFocusNodes[participant.number]!.hasFocus) {
            meshulashController.text = formattedGrade;
          }
        }
        if (!_meshulashGradeFocusNodes.containsKey(participant.number)) {
          _meshulashGradeFocusNodes[participant.number] = FocusNode();
        }
        
        // Update Alonka grade controller
        final alonkaController = _alonkaGradeControllers[participant.number];
        if (alonkaController != null) {
          String formattedGrade = participant.instructorAlonkaGrade.toStringAsFixed(
            participant.instructorAlonkaGrade == participant.instructorAlonkaGrade.roundToDouble() ? 0 : 2
          );
          if (alonkaController.text != formattedGrade && 
              !_alonkaGradeFocusNodes[participant.number]!.hasFocus) {
            alonkaController.text = formattedGrade;
          }
        }
        if (!_alonkaGradeFocusNodes.containsKey(participant.number)) {
          _alonkaGradeFocusNodes[participant.number] = FocusNode();
        }
        
        // Update Sakim grade controller
        final sakimController = _sakimGradeControllers[participant.number];
        if (sakimController != null) {
          String formattedGrade = participant.instructorSakimGrade.toStringAsFixed(
            participant.instructorSakimGrade == participant.instructorSakimGrade.roundToDouble() ? 0 : 2
          );
          if (sakimController.text != formattedGrade && 
              !_sakimGradeFocusNodes[participant.number]!.hasFocus) {
            sakimController.text = formattedGrade;
          }
        }
        if (!_sakimGradeFocusNodes.containsKey(participant.number)) {
          _sakimGradeFocusNodes[participant.number] = FocusNode();
        }
        
        // Update Bur grade controller from burGrades collection
        final burController = _burGradeControllers[participant.number];
        if (burController != null) {
          int burIndex = widget.eventController.currentEvent.value.burGrades
              .indexWhere((bur) => bur.id == participant.number);
          double burGradeValue = 0.0;
          if (burIndex != -1) {
            burGradeValue = widget.eventController.currentEvent.value.burGrades[burIndex].burGrade;
          }
          String formattedGrade = burGradeValue.toStringAsFixed(burGradeValue == burGradeValue.roundToDouble() ? 0 : 2);
          if (burController.text != formattedGrade && 
              !_burGradeFocusNodes[participant.number]!.hasFocus) {
            burController.text = formattedGrade;
          }
        }
        if (!_burGradeFocusNodes.containsKey(participant.number)) {
          _burGradeFocusNodes[participant.number] = FocusNode();
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
    // Use EventController's shared sort state
    return widget.eventController.getSortedActiveParticipants();
  }

  void _handleSort(SortColumn column) {
    setState(() {
      if (widget.eventController.sortColumn.value == column) {
        // Cycle through: ascending -> descending -> none -> ascending
        switch (widget.eventController.sortDirection.value) {
          case SortDirection.ascending:
            widget.eventController.sortDirection.value = SortDirection.descending;
            break;
          case SortDirection.descending:
            widget.eventController.sortDirection.value = SortDirection.none;
            widget.eventController.sortColumn.value = null;
            break;
          case SortDirection.none:
            widget.eventController.sortDirection.value = SortDirection.ascending;
            widget.eventController.sortColumn.value = column;
            break;
        }
      } else {
        widget.eventController.sortColumn.value = column;
        widget.eventController.sortDirection.value = SortDirection.ascending;
      }
    });
  }

  /// Get the calculated instructor grade as a hint string
  /// Returns formatted calculated grade only if instructorGrade is 0 (no saved value)
  /// The hint is shown in grey when the field is empty
  String _getCalculatedGradeHint(Participant participant) {
    // Only show hint if there's no saved final grade (instructorGrade is 0)
    if (participant.instructorGrade == 0.0) {
      double calculatedGrade = widget.eventController.getCalculatedInstructorGrade(participant);
      return calculatedGrade.toStringAsFixed(
        calculatedGrade == calculatedGrade.roundToDouble() ? 0 : 2
      );
    }
    return ''; // Don't show hint if there's a saved value (it will be shown in regular text)
  }

  /// Get adjusted system grade for display (based on group strength)
  double _getAdjustedSystemGrade(Participant participant) {
    final groupStrength = widget.eventController.currentEvent.value.groupStrength;
    
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
    final gradesData = widget.eventController.gradesData;
    return widget.eventController.calculateWeightedGrade(
      param1: adjustedMeshulash,
      param2: adjustedAlonka,
      param3: adjustedSakim,
      param4: burGrade,
      weight1: gradesData.weighted['meshulash'],
      weight2: gradesData.weighted['alonka'],
      weight3: gradesData.weighted['sakim'],
      weight4: gradesData.weighted['bur'],
    );
  }

  Color _getRowColor(Participant participant) {
    // If row is selected, highlight it
    if (_selectedParticipantNumber == participant.number) {
      return Colors.blue[100]!;
    }
    
    final finalGrade = participant.instructorGrade;
    final systemGrade = _getAdjustedSystemGrade(participant);

    // Color green if final instructor grade meets threshold (>= 5)
    if (finalGrade >= 5) {
      return Colors.green[100]!; // Light green background
    } else if (systemGrade >= 5 && finalGrade < 1) {
      // If system grade meets threshold but no final grade set yet
      return Colors.green[100]!;
    } else {
      return Colors.white;
    }
  }

  Widget _buildSortIcon(SortColumn column) {
    if (widget.eventController.sortColumn.value != column || widget.eventController.sortDirection.value == SortDirection.none) {
      return const SizedBox(width: 16);
    }
    return Icon(
      widget.eventController.sortDirection.value == SortDirection.ascending
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
          left: BorderSide(color: Colors.grey[500]!, width: 2), // Left border to separate groups
        ),
        color: Colors.grey[500], // Darker for master headers
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white, // White text for better contrast
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.visible,
          softWrap: true,
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, SortColumn column, double width, {bool isFrozen = false, bool isFirstInGroup = false, bool hasBoldRightBorder = false, bool hasBoldLeftBorder = false}) {
    return GestureDetector(
      onTap: () => _handleSort(column),
      child: Container(
        width: width,
        height: 48, // Fixed height to match cells
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[400]!, width: 1),
            right: hasBoldRightBorder
                ? BorderSide(color: Colors.grey[500]!, width: 2) // Bold right border to separate groups
                : BorderSide(color: Colors.grey[300]!, width: 1),
            left: (isFirstInGroup || hasBoldLeftBorder)
                ? BorderSide(color: Colors.grey[500]!, width: 2) // Left border for first column in group or when specified
                : BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          color: Colors.grey[300], // Lighter than master but darker than before
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                        // Don't set _selectedParticipantNumber here - only set it when clicking the recruit number cell
                      },
                      onEditingComplete: () {
                        FocusScope.of(context).unfocus();
                      },
                      onChanged: (value) {
                        // All instructor grades support doubles with up to 2 decimal places
                        final grade = double.tryParse(value) ?? 0.0;
                        // Round to 2 decimal places
                        final roundedGrade = double.parse(grade.toStringAsFixed(2));
                        widget.eventController.setParticipantExerciseGrade(
                          participantNumber,
                          exercise,
                          roundedGrade,
                        );
                        // Update final grade hint after calculation (don't overwrite manual values)
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            final participant = widget.eventController.currentEvent.value.participants
                                .firstWhere((p) => p.number == participantNumber);
                            final finalGradeController = _gradeControllers[participantNumber];
                            if (finalGradeController != null && 
                                !_gradeFocusNodes[participantNumber]!.hasFocus) {
                              // Always show saved instructorGrade if it exists
                              String displayText = '';
                              if (participant.instructorGrade > 0.0) {
                                displayText = participant.instructorGrade.toStringAsFixed(
                                  participant.instructorGrade == participant.instructorGrade.roundToDouble() ? 0 : 2
                                );
                              }
                              // Only update if text changed
                              if (finalGradeController.text != displayText) {
                                finalGradeController.text = displayText;
                              }
                            }
                          }
                        });
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
    VoidCallback? onTap,
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
        onTap: onTap,
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
                      if (widget.showSystemGrades || widget.showInstructorGrades)
                        Container(
                          width: numberWidth,
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[400]!, width: 1),
                              right: BorderSide(color: Colors.grey[300]!, width: 1),
                            ),
                            color: Colors.grey[500], // Match master header background
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
                            setState(() {
                              _loadingParticipantNumber = participant.number;
                            });
                            Get.toNamed('/performance_page/${participant.number}')?.then((_) {
                              // Clear loading state when navigation completes (or is cancelled)
                              if (mounted) {
                                setState(() {
                                  _loadingParticipantNumber = null;
                                });
                              }
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_loadingParticipantNumber == participant.number)
                                Text(
                                  'טוען...',
                                  style: const TextStyle(color: Colors.blue),
                                )
                              else ...[
                                _buildCommentIndicator(participant),
                                Text(
                                  participant.number.toString(),
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ],
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
                          // Master header row (grouping columns) - show when at least one grade type is visible
                          if (widget.showSystemGrades || widget.showInstructorGrades)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMasterHeaderCell(
                                  widget.isTablet ? 'ציון סופי' : 'סופי',
                                  finalGradeWidth + (widget.showSystemGrades ? systemGradeWidth : 0),
                                ),
                                if (widget.showSystemGrades || widget.showInstructorGrades)
                                  _buildMasterHeaderCell(
                                    'משולש',
                                    (widget.showSystemGrades ? exerciseWidth : 0) + (widget.showInstructorGrades ? instructorExerciseWidth : 0),
                                  ),
                                if (widget.showSystemGrades || widget.showInstructorGrades)
                                  _buildMasterHeaderCell(
                                    'אלונקה',
                                    (widget.showSystemGrades ? exerciseWidth : 0) + (widget.showInstructorGrades ? instructorExerciseWidth : 0),
                                  ),
                                // Bur column - show when either system or instructor grades are visible (Bur only has instructor grade, no system grade)
                                if (widget.showSystemGrades || widget.showInstructorGrades)
                                  _buildMasterHeaderCell(
                                    'בור',
                                    instructorExerciseWidth,
                                  ),
                                if (widget.showSystemGrades || widget.showInstructorGrades)
                                  _buildMasterHeaderCell(
                                    'שקים',
                                    (widget.showSystemGrades ? sakimWidth : 0) + (widget.showInstructorGrades ? instructorExerciseWidth : 0),
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
                                hasBoldRightBorder: true, // Bold right border to separate final grade group
                                hasBoldLeftBorder: widget.showInstructorGrades && !widget.showSystemGrades, // Bold left border in instructor-only mode
                              ),
                              if (widget.showSystemGrades)
                                _buildHeaderCell(
                                  'מערכת',
                                  SortColumn.systemGrade,
                                  systemGradeWidth,
                                  isFirstInGroup: true, // First column in final grade group
                                ),
                              if (widget.showSystemGrades || widget.showInstructorGrades) ...[
                                if (widget.showSystemGrades)
                                  _buildHeaderCell('מערכת', SortColumn.meshulash, exerciseWidth),
                                if (widget.showInstructorGrades)
                                  _buildHeaderCell('מדריך', SortColumn.meshulash, instructorExerciseWidth, isFirstInGroup: true), // First in meshulash group
                                if (widget.showSystemGrades)
                                  _buildHeaderCell('מערכת', SortColumn.alonka, exerciseWidth),
                                if (widget.showInstructorGrades)
                                  _buildHeaderCell('מדריך', SortColumn.alonka, instructorExerciseWidth, isFirstInGroup: true), // First in alonka group
                              ],
                              // Bur column - show when either system or instructor grades are visible (Bur only has instructor grade, no system grade)
                              if (widget.showSystemGrades || widget.showInstructorGrades)
                                _buildHeaderCell('מדריך', SortColumn.bur, instructorExerciseWidth, isFirstInGroup: true), // First in bur group
                              if (widget.showSystemGrades || widget.showInstructorGrades) ...[
                                if (widget.showSystemGrades)
                                  _buildHeaderCell('מערכת', SortColumn.sakim, sakimWidth),
                                if (widget.showInstructorGrades)
                                  _buildHeaderCell('מדריך', SortColumn.sakim, instructorExerciseWidth, isFirstInGroup: true), // First in sakim group
                              ],
                            ],
                          ),
                          // Data rows
                          ...sortedParticipants.map((participant) {
              final rowColor = _getRowColor(participant);
              // Ensure controllers exist
              if (!_gradeControllers.containsKey(participant.number)) {
                _gradeControllers[participant.number] = TextEditingController(
                                  text: participant.instructorGrade.toStringAsFixed(participant.instructorGrade == participant.instructorGrade.roundToDouble() ? 0 : 2),
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
              // Always update Bur grade controller from burGrades collection (single source of truth)
              // Bur grades support doubles, so we keep the decimal value
              int burIndex = widget.eventController.currentEvent.value.burGrades
                  .indexWhere((bur) => bur.id == participant.number);
              double burGradeValue = 0.0;
              if (burIndex != -1) {
                burGradeValue = widget.eventController.currentEvent.value.burGrades[burIndex].burGrade;
              }
              
              if (!_burGradeControllers.containsKey(participant.number)) {
                _burGradeControllers[participant.number] = TextEditingController(
                  text: burGradeValue.toStringAsFixed(burGradeValue == burGradeValue.roundToDouble() ? 0 : 2),
                );
              } else {
                // Update existing controller if value has changed
                final burController = _burGradeControllers[participant.number]!;
                String formattedBurGrade = burGradeValue.toStringAsFixed(burGradeValue == burGradeValue.roundToDouble() ? 0 : 2);
                if (burController.text != formattedBurGrade && 
                    !_burGradeFocusNodes[participant.number]!.hasFocus) {
                  burController.text = formattedBurGrade;
                }
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
                  // Don't set _selectedParticipantNumber here - only set it when clicking the recruit number cell
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Final grade cell (editable)
                  GestureDetector(
                    // Focus the TextField when clicking anywhere on the cell
                    onTap: () {
                      if (!isFinalized) {
                        _gradeFocusNodes[participant.number]?.requestFocus();
                        // Select all text when focused
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && gradeController.text.isNotEmpty) {
                            gradeController.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: gradeController.text.length,
                            );
                          }
                        });
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: finalGradeWidth,
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: rowColor,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[400]!, width: 1),
                          right: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: isFinalized
                          ? Center(
                              child: Text(
                                participant.instructorGrade.toStringAsFixed(participant.instructorGrade == participant.instructorGrade.roundToDouble() ? 0 : 2),
                                style: const TextStyle(color: Colors.black),
                              ),
                            )
                          : TextField(
                              controller: gradeController,
                              focusNode: _gradeFocusNodes[participant.number],
                              textAlign: TextAlign.center,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 12,
                                ),
                                isDense: false,
                                // Show calculated grade as hint when field is empty or matches calculated
                                hintText: _getCalculatedGradeHint(participant),
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
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
                                // Don't set _selectedParticipantNumber here - only set it when clicking the recruit number cell
                              },
                              onEditingComplete: () {
                                // Unfocus when editing is complete (Enter key)
                                FocusScope.of(context).unfocus();
                              },
                              onChanged: (value) {
                                // Parse as double, allowing up to 2 decimal places
                                final grade = double.tryParse(value) ?? 0.0;
                                // Round to 2 decimal places
                                final roundedGrade = double.parse(grade.toStringAsFixed(2));
                                widget.eventController.setParticipantsGrade(
                                  participant.number,
                                  roundedGrade,
                                );
                              },
                            ),
                    ),
                  ),
                  // System grade cell
                  if (widget.showSystemGrades)
                    _buildCell(
                      width: systemGradeWidth,
                      backgroundColor: rowColor,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => SystemGradeBreakdownDialog(
                            participantNumber: participant.number,
                          ),
                        );
                      },
                      child: Text(
                        _getAdjustedSystemGrade(participant).toStringAsFixed(2),
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
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => ExerciseRankingDialog(
                              participantNumber: participant.number,
                              exerciseName: 'meshulash',
                              exerciseNameHebrew: 'משולש',
                              grade: getAdjustedSystemGrade(
                                participant.meshulashGrade,
                                widget.eventController.currentEvent.value.groupStrength,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              getAdjustedSystemGrade(
                                participant.meshulashGrade,
                                widget.eventController.currentEvent.value.groupStrength,
                              ).toStringAsFixed(2),
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
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => ExerciseRankingDialog(
                              participantNumber: participant.number,
                              exerciseName: 'alonka',
                              exerciseNameHebrew: 'אלונקה',
                              grade: getAdjustedSystemGrade(
                                participant.alonkaGrade,
                                widget.eventController.currentEvent.value.groupStrength,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              getAdjustedSystemGrade(
                                participant.alonkaGrade,
                                widget.eventController.currentEvent.value.groupStrength,
                              ).toStringAsFixed(2),
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
                  ],
                  // Bur instructor grade cell (only instructor grade, no system grade) - show when either system or instructor grades are visible
                  if (widget.showSystemGrades || widget.showInstructorGrades)
                    _buildEditableExerciseGradeCell(
                      participantNumber: participant.number,
                      controller: burGradeController,
                      focusNode: _burGradeFocusNodes[participant.number]!,
                      exercise: 'bur',
                      width: instructorExerciseWidth,
                      backgroundColor: rowColor,
                      isFinalized: isFinalized,
                    ),
                  // Sakim cells (only show if at least one type is visible)
                  if (widget.showSystemGrades || widget.showInstructorGrades) ...[
                    // Sakim system grade cell
                    if (widget.showSystemGrades)
                      _buildCell(
                        width: sakimWidth,
                        backgroundColor: rowColor,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => ExerciseRankingDialog(
                              participantNumber: participant.number,
                              exerciseName: 'sakim',
                              exerciseNameHebrew: 'שקים',
                              grade: getAdjustedSystemGrade(
                                participant.sakimGrade,
                                widget.eventController.currentEvent.value.groupStrength,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              getAdjustedSystemGrade(
                                participant.sakimGrade,
                                widget.eventController.currentEvent.value.groupStrength,
                              ).toStringAsFixed(2),
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

