import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../event_controller.dart';
import '../widgets/guideWebView.dart';
import '../utils/tablet_utils.dart';
import '../widgets/wifi_settings_button.dart';
import '../mixins/event_validation_mixin.dart';
import '../models/types.dart';
import '../models/participant.dart';
import '../widgets/custom_grades_table.dart';
import '../widgets/exercise_ranking_dialog.dart';
import '../widgets/meshulash_charts.dart';
import '../widgets/alonka_charts.dart';
import '../widgets/sakim_charts.dart';
import '../widgets/comments_dialog.dart';

class ExerciseGradingPage extends StatefulWidget {
  final String exerciseType; // 'meshulash', 'alonka', or 'sakim'

  const ExerciseGradingPage({super.key, required this.exerciseType});

  @override
  State<ExerciseGradingPage> createState() => _ExerciseGradingPageState();
}

class _ExerciseGradingPageState extends State<ExerciseGradingPage> with EventValidationMixin {
  final eventController = Get.put(EventController());
  bool _showSystemGrades = true;
  bool _showInstructorGrades = true;
  int? _selectedParticipantNumber;

  @override
  void initState() {
    super.initState();
    checkEventValidity();
    // Defer calculateGrades to avoid build phase issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        eventController.calculateGrades();
      }
    });
  }

  String _getExerciseName() {
    switch (widget.exerciseType) {
      case 'meshulash':
        return 'משולש';
      case 'alonka':
        return 'אלונקה';
      case 'sakim':
        return 'שקים';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    bool tablet = isTablet(context);
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          eventController.loading.value = true;
          Get.back();
          eventController.loading.value = false;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'ציונים - ${_getExerciseName()}',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              eventController.loading.value = true;
              Get.back();
              eventController.loading.value = false;
            },
          ),
          actions: [
            // Toggle system grades visibility
            IconButton(
              icon: Icon(
                Icons.assessment,
                color: _showSystemGrades ? Colors.blue : Colors.grey,
              ),
              tooltip: _showSystemGrades ? 'הסתר ציוני מערכת' : 'הצג ציוני מערכת',
              onPressed: () {
                setState(() {
                  _showSystemGrades = !_showSystemGrades;
                });
              },
            ),
            // Instructor grades are always visible in exercise grade page - no toggle button
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'מדריך למשתמש',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Directionality(
                    textDirection: TextDirection.rtl,
                    child: const ManualWebView(
                      url: 'https://docs.google.com/presentation/d/19SF_q3uXPt470mzfOKEorpoIORsOEEmQXL5_UUnelNo/preview?rm=minimal&slide=id.g384f00aea19_0_135',
                    ),
                  ),
                );
              },
            ),
            WifiSettingsButton(),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Color.fromARGB(255, 0, 66, 136)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.ltr,
            children: [
              // Left panel for graph and comments
              if (_selectedParticipantNumber != null)
                SizedBox(
                  width: tablet ? 350 : 295,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(right: 8),
                    padding: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildParticipantPanel(_selectedParticipantNumber!),
                  ),
                ),
              // Table
              Expanded(
                child: SingleChildScrollView(
                  child: _ExerciseGradingTable(
                    eventController: eventController,
                    isTablet: tablet,
                    exerciseType: widget.exerciseType,
                    showSystemGrades: _showSystemGrades,
                    showInstructorGrades: _showInstructorGrades,
                    onParticipantSelected: (int? participantNumber) {
                      setState(() {
                        _selectedParticipantNumber = participantNumber;
                      });
                    },
                    selectedParticipantNumber: _selectedParticipantNumber,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantPanel(int participantNumber) {
    final bool tablet = isTablet(context);
    final participant = eventController.currentEvent.value.participants.firstWhere(
      (p) => p.number == participantNumber,
      orElse: () => eventController.currentEvent.value.participants.first,
    );

    // Get comments for this exercise
    List<String> comments = [];
    switch (widget.exerciseType) {
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'משתתף $participantNumber - ${_getExerciseName()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.black87),
                    onPressed: () {
                      setState(() {
                        _selectedParticipantNumber = null;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'סגור',
                  ),
                ],
              ),
            ),
            // Rank info section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: _buildRankInfo(participantNumber),
            ),
            // Graph section
            LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  height: tablet ? 400 : 300,
                  child: ClipRect(
                    child: _buildChartWidget(participantNumber),
                  ),
                );
              },
            ),
            // Comments section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'הערות המדריך:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  comments.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: comments.map((comment) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $comment',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      : const Text(
                          'לא ניתנו הערות',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddCommentDialog(participantNumber),
                      icon: const Icon(Icons.add_comment, size: 18),
                      label: const Text('הוסף הערה'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getSystemGradeForExercise(Participant participant) {
    final groupStrength = eventController.currentEvent.value.groupStrength;
    switch (widget.exerciseType) {
      case 'meshulash':
        return getAdjustedSystemGrade(participant.meshulashGrade, groupStrength);
      case 'alonka':
        return getAdjustedSystemGrade(participant.alonkaGrade, groupStrength);
      case 'sakim':
        return getAdjustedSystemGrade(participant.sakimGrade, groupStrength);
      default:
        return 0.0;
    }
  }

  Widget _buildRankInfo(int participantNumber) {
    final participant = eventController.currentEvent.value.participants.firstWhere(
      (p) => p.number == participantNumber,
      orElse: () => eventController.currentEvent.value.participants.first,
    );
    final rankInfo = eventController.getExerciseRank(participantNumber, widget.exerciseType);
    final rank = rankInfo['rank'] ?? 0;
    final total = rankInfo['total'] ?? 0;
    final systemGrade = _getSystemGradeForExercise(participant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'ציון: ${systemGrade.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'מקום $rank מתוך $total',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartWidget(int participantNumber) {
    switch (widget.exerciseType) {
      case 'meshulash':
        return MeshulashCharts(number: participantNumber, hideComments: true);
      case 'alonka':
        return AlonkaCharts(number: participantNumber, hideComments: true);
      case 'sakim':
        return SakimCharts(number: participantNumber, hideComments: true);
      default:
        return const Center(child: Text('תרגיל לא מזוהה'));
    }
  }

  Future<void> _showAddCommentDialog(int participantNumber) async {
    final participant = eventController.currentEvent.value.participants.firstWhere(
      (p) => p.number == participantNumber,
      orElse: () => eventController.currentEvent.value.participants.first,
    );

    List<String> commentsList;
    List<String> selectedComments;
    ExerciseType exerciseType;

    switch (widget.exerciseType) {
      case 'meshulash':
        commentsList = eventController.gradesData.listOfCommentsMeshulash;
        selectedComments = participant.meshulashInstructorComments;
        exerciseType = ExerciseType.meshulash;
        break;
      case 'alonka':
        commentsList = eventController.gradesData.listOfCommentsAlonka;
        selectedComments = participant.alonkaInstructorComments;
        exerciseType = ExerciseType.alonka;
        break;
      case 'sakim':
        commentsList = eventController.gradesData.listOfCommentsSakim;
        selectedComments = participant.sakimInstructorComments;
        exerciseType = ExerciseType.sakim;
        break;
      default:
        return;
    }

    final res = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) => CommentsDialog(
        commentsList: commentsList,
        selectedComments: selectedComments,
        title: participantNumber.toString(),
        exerciseType: exerciseType,
        instructorCustomComments: eventController.getInstructorCustomCommentsForExercise(widget.exerciseType),
      ),
    );

    if (res != null) {
      if (res.contains(ParticipantStatus.Droped.name)) {
        // Handle drop participant if needed
        return;
      }

      // Update comments based on exercise type
      switch (widget.exerciseType) {
        case 'meshulash':
          eventController.addMeshulashComments(res, participantNumber);
          break;
        case 'alonka':
          eventController.addAlonkaComments(res, participantNumber);
          break;
        case 'sakim':
          eventController.addSakimComments(res, participantNumber);
          break;
      }

      // Refresh the UI
      setState(() {});
    }
  }
}

class _ExerciseGradingTable extends StatefulWidget {
  final EventController eventController;
  final bool isTablet;
  final String exerciseType;
  final bool showSystemGrades;
  final bool showInstructorGrades;
  final Function(int?)? onParticipantSelected;
  final int? selectedParticipantNumber;

  const _ExerciseGradingTable({
    required this.eventController,
    required this.isTablet,
    required this.exerciseType,
    required this.showSystemGrades,
    required this.showInstructorGrades,
    this.onParticipantSelected,
    this.selectedParticipantNumber,
  });

  @override
  State<_ExerciseGradingTable> createState() => _ExerciseGradingTableState();
}

class _ExerciseGradingTableState extends State<_ExerciseGradingTable> {
  final Map<int, TextEditingController> _gradeControllers = {};
  final Map<int, FocusNode> _gradeFocusNodes = {};
  SortColumn? _sortColumn;
  SortDirection _sortDirection = SortDirection.none;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // Listen to event changes to update controllers
    widget.eventController.currentEvent.listen((event) {
      _updateControllers();
    });
  }

  void _initializeControllers() {
    for (var participant in widget.eventController.currentEvent.value
        .getParticipantsByStatus(ParticipantStatus.Active)) {
      _gradeControllers[participant.number] = TextEditingController();
      _gradeFocusNodes[participant.number] = FocusNode();
      _updateController(participant);
    }
  }

  void _updateControllers() {
    for (var participant in widget.eventController.currentEvent.value
        .getParticipantsByStatus(ParticipantStatus.Active)) {
      if (!_gradeControllers.containsKey(participant.number)) {
        _gradeControllers[participant.number] = TextEditingController();
        _gradeFocusNodes[participant.number] = FocusNode();
      }
      _updateController(participant);
    }
  }

  void _updateController(Participant participant) {
    final controller = _gradeControllers[participant.number];
    if (controller == null) return;

    double grade = 0.0;
    switch (widget.exerciseType) {
      case 'meshulash':
        grade = participant.instructorMeshulashGrade;
        break;
      case 'alonka':
        grade = participant.instructorAlonkaGrade;
        break;
      case 'sakim':
        grade = participant.instructorSakimGrade;
        break;
    }

    if (grade > 0.0) {
      final displayText = grade.toStringAsFixed(
        grade == grade.roundToDouble() ? 0 : 2
      );
      if (controller.text != displayText && !_gradeFocusNodes[participant.number]!.hasFocus) {
        controller.text = displayText;
      }
    } else {
      if (!_gradeFocusNodes[participant.number]!.hasFocus) {
        controller.text = '';
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

  double _getSystemGrade(Participant participant) {
    switch (widget.exerciseType) {
      case 'meshulash':
        return getAdjustedSystemGrade(
          participant.meshulashGrade,
          widget.eventController.currentEvent.value.groupStrength,
        );
      case 'alonka':
        return getAdjustedSystemGrade(
          participant.alonkaGrade,
          widget.eventController.currentEvent.value.groupStrength,
        );
      case 'sakim':
        return getAdjustedSystemGrade(
          participant.sakimGrade,
          widget.eventController.currentEvent.value.groupStrength,
        );
      default:
        return 0.0;
    }
  }

  double _getInstructorGrade(Participant participant) {
    switch (widget.exerciseType) {
      case 'meshulash':
        return participant.instructorMeshulashGrade;
      case 'alonka':
        return participant.instructorAlonkaGrade;
      case 'sakim':
        return participant.instructorSakimGrade;
      default:
        return 0.0;
    }
  }

  Color _getRowColor(Participant participant) {
    // If row is selected, highlight it
    if (widget.selectedParticipantNumber == participant.number) {
      return Colors.blue[100]!;
    }
    
    final exerciseInstructorGrade = _getInstructorGrade(participant);
    final exerciseSystemGrade = _getSystemGrade(participant);

    // Color green if exercise instructor grade meets threshold (>= 5)
    if (exerciseInstructorGrade >= 5) {
      return Colors.green[100]!; // Light green background
    } else if (exerciseSystemGrade >= 5 && exerciseInstructorGrade < 1) {
      // If system grade meets threshold but no instructor grade set yet
      return Colors.green[100]!;
    } else {
      return Colors.white;
    }
  }

  bool _hasExerciseComment(Participant participant) {
    switch (widget.exerciseType) {
      case 'alonka':
        return participant.alonkaInstructorComments.isNotEmpty;
      case 'meshulash':
        return participant.meshulashInstructorComments.isNotEmpty;
      case 'sakim':
        return participant.sakimInstructorComments.isNotEmpty;
      default:
        return false;
    }
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

  List<Participant> _getSortedParticipants(List<Participant> participants) {
    if (_sortColumn == null || _sortDirection == SortDirection.none) {
      return participants;
    }

    final sorted = List<Participant>.from(participants);
    sorted.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn!) {
        case SortColumn.number:
          comparison = a.number.compareTo(b.number);
          break;
        case SortColumn.meshulash:
        case SortColumn.alonka:
        case SortColumn.sakim:
          // For exercise-specific columns, use the system grade for that exercise
          final gradeA = _getSystemGrade(a);
          final gradeB = _getSystemGrade(b);
          comparison = gradeA.compareTo(gradeB);
          break;
        case SortColumn.instructorGrade:
          // Sort by instructor grade for the current exercise
          final gradeA = _getInstructorGrade(a);
          final gradeB = _getInstructorGrade(b);
          comparison = gradeA.compareTo(gradeB);
          break;
        default:
          comparison = 0;
      }
      return _sortDirection == SortDirection.ascending ? comparison : -comparison;
    });

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final participants = widget.eventController.currentEvent.value
        .getParticipantsByStatus(ParticipantStatus.Active)
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    if (participants.isEmpty) {
      return const Center(
        child: Text('אין משתתפים פעילים'),
      );
    }

    final exerciseWidth = widget.isTablet ? 100.0 : 90.0;
    final recruitNumberWidth = widget.isTablet ? 85.0 : 75.0;

    return GetX<EventController>(
      builder: (_) {
        final sortedParticipants = _getSortedParticipants(participants);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.centerRight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Header row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Recruit number header
                        _buildHeaderCell('חולצה', SortColumn.number, recruitNumberWidth),
                        // Exercise grade headers
                        if (widget.showSystemGrades)
                          _buildHeaderCell('מערכת', _getExerciseSortColumn(), exerciseWidth),
                        if (widget.showInstructorGrades)
                          _buildHeaderCell('מדריך', SortColumn.instructorGrade, exerciseWidth),
                      ],
                    ),
                    // Data rows
                    ...sortedParticipants.map((participant) {
                      final rowColor = _getRowColor(participant);
                      final systemGrade = _getSystemGrade(participant);
                      final controller = _gradeControllers[participant.number]!;
                      final focusNode = _gradeFocusNodes[participant.number]!;
                      final isFinalized = widget.eventController.currentEvent.value.finalized;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Recruit number cell
                          _buildCell(
                            width: recruitNumberWidth,
                            backgroundColor: rowColor,
                            onTap: () {
                              if (widget.onParticipantSelected != null) {
                                // Toggle selection - if already selected, deselect
                                if (widget.selectedParticipantNumber == participant.number) {
                                  widget.onParticipantSelected!(null);
                                } else {
                                  widget.onParticipantSelected!(participant.number);
                                }
                              }
                            },
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    participant.number.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  if (_hasExerciseComment(participant))
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.comment,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // System grade cell
                          if (widget.showSystemGrades)
                            _buildCell(
                              width: exerciseWidth,
                              backgroundColor: rowColor,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => ExerciseRankingDialog(
                                    participantNumber: participant.number,
                                    exerciseName: widget.exerciseType,
                                    exerciseNameHebrew: _getExerciseNameHebrew(),
                                    grade: systemGrade,
                                  ),
                                );
                              },
                              child: Center(
                                child: Text(
                                  systemGrade.toStringAsFixed(2),
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          // Instructor grade cell (editable)
                          if (widget.showInstructorGrades)
                            _buildEditableGradeCell(
                              participant: participant,
                              controller: controller,
                              focusNode: focusNode,
                              width: exerciseWidth,
                              backgroundColor: rowColor,
                              isFinalized: isFinalized,
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getExerciseNameHebrew() {
    switch (widget.exerciseType) {
      case 'meshulash':
        return 'משולש';
      case 'alonka':
        return 'אלונקה';
      case 'sakim':
        return 'שקים';
      default:
        return '';
    }
  }

  SortColumn? _getExerciseSortColumn() {
    switch (widget.exerciseType) {
      case 'meshulash':
        return SortColumn.meshulash;
      case 'alonka':
        return SortColumn.alonka;
      case 'sakim':
        return SortColumn.sakim;
      default:
        return null;
    }
  }

  Widget _buildHeaderCell(String title, SortColumn? column, double width) {
    Widget headerContent = Container(
      width: width,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[400]!, width: 1),
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        color: Colors.grey[300],
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
          if (column != null) ...[
            const SizedBox(width: 2),
            _buildSortIcon(column),
          ],
        ],
      ),
    );

    if (column != null) {
      return GestureDetector(
        onTap: () => _handleSort(column),
        child: headerContent,
      );
    }

    return headerContent;
  }

  Widget _buildCell({
    required double width,
    required Color backgroundColor,
    required Widget child,
    VoidCallback? onTap,
  }) {
    Widget cellContent = Container(
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
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cellContent,
      );
    }

    return cellContent;
  }

  Widget _buildEditableGradeCell({
    required Participant participant,
    required TextEditingController controller,
    required FocusNode focusNode,
    required double width,
    required Color backgroundColor,
    required bool isFinalized,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isFinalized) {
          focusNode.requestFocus();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && controller.text.isNotEmpty) {
              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            }
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(color: Colors.grey[400]!, width: 1),
            right: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        child: isFinalized
            ? Center(
                child: Text(
                  _getInstructorGrade(participant) > 0.0
                      ? _getInstructorGrade(participant).toStringAsFixed(
                          _getInstructorGrade(participant) == _getInstructorGrade(participant).roundToDouble() ? 0 : 2
                        )
                      : '-',
                  style: const TextStyle(color: Colors.black),
                ),
              )
            : TextField(
                controller: controller,
                focusNode: focusNode,
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
                  hintText: '-',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
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
                },
                onEditingComplete: () {
                  FocusScope.of(context).unfocus();
                },
                onChanged: (value) {
                  final grade = double.tryParse(value) ?? 0.0;
                  final roundedGrade = double.parse(grade.toStringAsFixed(2));
                  
                  switch (widget.exerciseType) {
                    case 'meshulash':
                      widget.eventController.setParticipantExerciseGrade(
                        participant.number,
                        'meshulash',
                        roundedGrade,
                      );
                      break;
                    case 'alonka':
                      widget.eventController.setParticipantExerciseGrade(
                        participant.number,
                        'alonka',
                        roundedGrade,
                      );
                      break;
                    case 'sakim':
                      widget.eventController.setParticipantExerciseGrade(
                        participant.number,
                        'sakim',
                        roundedGrade,
                      );
                      break;
                  }
                },
              ),
      ),
    );
  }
}
