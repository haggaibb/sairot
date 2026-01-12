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
            // Toggle instructor grades visibility
            IconButton(
              icon: Icon(
                Icons.edit,
                color: _showInstructorGrades ? Colors.blue : Colors.grey,
              ),
              tooltip: _showInstructorGrades ? 'הסתר ציוני מדריך' : 'הצג ציוני מדריך',
              onPressed: () {
                setState(() {
                  _showInstructorGrades = !_showInstructorGrades;
                });
              },
            ),
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
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            child: _ExerciseGradingTable(
              eventController: eventController,
              isTablet: tablet,
              exerciseType: widget.exerciseType,
              showSystemGrades: _showSystemGrades,
              showInstructorGrades: _showInstructorGrades,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseGradingTable extends StatefulWidget {
  final EventController eventController;
  final bool isTablet;
  final String exerciseType;
  final bool showSystemGrades;
  final bool showInstructorGrades;

  const _ExerciseGradingTable({
    required this.eventController,
    required this.isTablet,
    required this.exerciseType,
    required this.showSystemGrades,
    required this.showInstructorGrades,
  });

  @override
  State<_ExerciseGradingTable> createState() => _ExerciseGradingTableState();
}

class _ExerciseGradingTableState extends State<_ExerciseGradingTable> {
  final Map<int, TextEditingController> _gradeControllers = {};
  final Map<int, FocusNode> _gradeFocusNodes = {};

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
    final recruitNumberWidth = widget.isTablet ? 120.0 : 100.0;

    return GetX<EventController>(
      builder: (_) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Header row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Recruit number header
                  _buildHeaderCell('מספר רץ', recruitNumberWidth),
                  // Exercise grade headers
                  if (widget.showSystemGrades)
                    _buildHeaderCell('מערכת', exerciseWidth),
                  if (widget.showInstructorGrades)
                    _buildHeaderCell('מדריך', exerciseWidth),
                ],
              ),
              // Data rows
              ...participants.map((participant) {
                final rowColor = participant.number % 2 == 0
                    ? Colors.grey[100]!
                    : Colors.white;
                final systemGrade = _getSystemGrade(participant);
                final controller = _gradeControllers[participant.number]!;
                final focusNode = _gradeFocusNodes[participant.number]!;
                final isFinalized = widget.eventController.currentEvent.value.finalized;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Recruit number cell
                    _buildCell(
                      width: recruitNumberWidth,
                      backgroundColor: rowColor,
                      child: Center(
                        child: Text(
                          participant.number.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    // System grade cell
                    if (widget.showSystemGrades)
                      _buildCell(
                        width: exerciseWidth,
                        backgroundColor: rowColor,
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
        );
      },
    );
  }

  Widget _buildHeaderCell(String title, double width) {
    return Container(
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
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCell({
    required double width,
    required Color backgroundColor,
    required Widget child,
  }) {
    return Container(
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
