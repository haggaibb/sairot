import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sairot/models/alonka_sprint.dart';
import 'package:sairot/models/types.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../widgets/alonka_round_panel.dart';
import 'dart:async';
import '../widgets/yes_no.dart';
import '../widgets/guideWebView.dart';
import '../utils/tablet_utils.dart';
import '../services/exercise_context_service.dart';
import '../services/user_preferences_service.dart';
import '../widgets/floating_ptt_button.dart';
import '../widgets/wifi_settings_button.dart';
import '../mixins/event_validation_mixin.dart';
import '../widgets/alonka_credit_panel.dart';
import '../widgets/comments_dialog.dart';
import 'exercise_grading_page.dart';

class AlonkaPage extends StatefulWidget {
  const AlonkaPage({super.key});

  @override
  State<AlonkaPage> createState() => _AlonkaPageState();
}

class _AlonkaPageState extends State<AlonkaPage> with EventValidationMixin {
  final eventController = Get.put(EventController());
  int runTime = 0;
  late Timer _timer;
  final ScrollController _scrollController = ScrollController();
  bool inOrderOfArrival = true;
  bool _floatingPttEnabled = false;
  bool _volumeButtonPttEnabled = false;
  bool _showMatrix = false; // Toggle between list and matrix view

  @override
  void initState() {
    super.initState();
    checkEventValidity();
    // Set exercise context for STT
    ExerciseContextService().setCurrentExercise('alonka');
    _loadSttPreferences();
    
    runTime = eventController.currentEvent.value.getAlonkaRunTime();
    if (eventController.currentEvent.value.alonkaEndTime == null) {
      _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
        setState(() {
          runTime = eventController.currentEvent.value.getAlonkaRunTime();
        });
      });
    }
    _scrollToEnd();
    super.initState();
  }

  Future<void> _loadSttPreferences() async {
    final floatingEnabled = await UserPreferencesService.getFloatingPttButton();
    final volumeEnabled = await UserPreferencesService.getVolumeButtonPtt();
    if (mounted) {
      setState(() {
        _floatingPttEnabled = floatingEnabled;
        _volumeButtonPttEnabled = volumeEnabled;
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent - 200,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  void sortActiveList() {}

  bool showStartRoundButton() {
    if (eventController.currentEvent.value.alonkaStartTime == null) return false;
    if (eventController.currentEvent.value.alonkaSprints.last.activeParticipants
        .isNotEmpty || eventController.currentEvent.value.alonkaEndTime!=null) return false;
    return true;
  }

  @override
  void dispose() {
    // Clear exercise context when leaving page
    ExerciseContextService().clearExercise();
    
    if (eventController.currentEvent.value.alonkaEndTime == null)
      _timer.cancel(); // Stop timer when widget is disposed
    
    // Restore portrait-only orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool tablet = isTablet(context);
    double scaledFontSize = getTabletScaledFontSize(context, eventController.userFontSize.value);
    
    // Allow landscape orientation for tablets
    if (tablet) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Color.fromARGB(255, 0, 66, 136)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Scaffold(
          appBar: AppBar(
            //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            centerTitle: true,
            title: Text('אלונקה'),
            actions: [
              // Matrix toggle icon
              IconButton(
                icon: Icon(
                  _showMatrix ? Icons.list : Icons.grid_on,
                  color: _showMatrix ? Colors.blue : Colors.grey,
                ),
                tooltip: _showMatrix ? 'הצג רשימת סיבובים' : 'הצג מטריצה',
                onPressed: () {
                  setState(() {
                    _showMatrix = !_showMatrix;
                  });
                },
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    inOrderOfArrival = !inOrderOfArrival; // Toggle state
                    // Only update active participants if there are sprints
                    if (eventController.currentEvent.value.alonkaSprints.isNotEmpty) {
                      List<int> activeList = eventController.currentEvent.value
                          .getParticipantsByStatus(ParticipantStatus.Active)
                          .map((participant) => participant.number)
                          .toList();
                      if (inOrderOfArrival) {
                        /// Sort by Alonka grade (descending)
                        activeList.sort((a, b) => eventController
                            .getAlonkaGrade(b)
                            .compareTo(eventController.getAlonkaGrade(a)));
                      }
                      eventController
                          .currentEvent
                          .value
                          .alonkaSprints[eventController
                                  .currentEvent.value.alonkaSprints.length -
                              1]
                          .activeParticipants = activeList;
                      eventController.update();
                    }
                  });
                },
                icon: Icon(
                  Icons.directions_walk_sharp,
                  color: inOrderOfArrival
                      ? Colors.green
                      : Colors.grey, // Switch color
                  size: 32,
                ),
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
                        url:
                            'https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000&slide=id.g384f00aea19_0_72',
                        //https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000
                      ),
                    ),
                  );
                },
              ),
              WifiSettingsButton(),
            ],
            leading: IconButton(
              icon: Icon(Icons.arrow_back), // 🔄 Custom back arrow
              onPressed: () {
                eventController.loading.value = true;
                Get.back(); // ⬅️ Go back using GetX
                eventController.loading.value = false;
              },
            ),
          ),
          body: _showMatrix
              ? _AlonkaExerciseMatrixView(
                  key: ValueKey('matrix_$inOrderOfArrival'), // Force rebuild when sort order changes
                  inOrderOfArrival: inOrderOfArrival,
                )
              : GetX<EventController>(builder: (_) {
                  // Show the normal list view
                  return SingleChildScrollView(
              controller: _scrollController,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: tablet ? 20.0 : 16.0),
                  child: Column(
                    children: [
                      SizedBox(height: tablet ? 20.0 : 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ' דקות  ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            runTime.toString(),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '  משך התרגיל  ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                      SizedBox(
                        height: tablet ? 25.0 : 20.0,
                      ),
                      Obx(() => eventController.loading.value
                          ? SizedBox(
                              height: 100,
                              width: 100,
                              child: CircularProgressIndicator(),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                  _.currentEvent.value.alonkaSprints.length,
                                  (index) {
                                return Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: AlonkaRoundPanel(
                                    round:
                                        _.currentEvent.value.alonkaSprints[index],
                                  ),
                                );
                              }),
                            )),
                      SizedBox(height: tablet ? 20.0 : 15.0),
                      Divider(
                        thickness: tablet ? 45.0 : 30.0,
                      ),
                      SizedBox(height: tablet ? 25.0 : 20.0),

                      /// widget loading indicator
                      /// show hide start Alonka Exam
                      Obx(() => eventController.loading.value || eventController.currentEvent.value
                          .alonkaStartTime != null
                          ?  SizedBox.shrink()
                          :  Padding(
                            padding: EdgeInsets.symmetric(horizontal: tablet ? 20.0 : 16.0),
                            child: ElevatedButton (
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          Theme.of(context).colorScheme.primary,
                          foregroundColor:
                          Theme.of(context).colorScheme.onPrimary,
                          minimumSize: tablet ? Size(200, 60) : null,
                        ),
                        onPressed: () async {
                          _.loading.value = true;
                          _.currentAlonkaRound.value =
                              _.currentEvent.value.alonkaSprints.length;
                          if (_
                              .currentEvent.value.alonkaSprints.isEmpty)
                            eventController.currentEvent.value
                                .alonkaStartTime = DateTime.now();
                          List<int> activeList = _.currentEvent.value
                              .getParticipantsByStatus(
                              ParticipantStatus.Active)
                              .map((participant) => participant.number)
                              .toList();
                          if (inOrderOfArrival) {
                            /// Sort by Alonka grade (descending)
                            activeList.sort((a, b) => eventController
                                .getAlonkaGrade(b)
                                .compareTo(
                                eventController.getAlonkaGrade(a)));
                          }

                          /// create new Alonka Sprint
                          _.currentEvent.value.alonkaSprints.add(
                              AlonkaSprint(
                                  round: _.currentEvent.value
                                      .alonkaSprints.length,
                                  activeParticipants: activeList));
                          _.loading.value = false;
                          _scrollToEnd();
                          _.currentEvent.value.saveToFirestore();
                          //})
                        },
                        child: Text(
                          showStartRoundButton()
                              ? 'התחל סיבוב חדש (צא)'
                              : 'תחילת תרגיל',
                          style: TextStyle(
                              fontSize: scaledFontSize,
                              fontWeight: FontWeight.bold),
                        ),
                            ),
                          )),
                    Obx(() => eventController.widgetLoading.value
                        ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                              height: 10,
                              width: 200,
                              child: LinearProgressIndicator()
                            ),
                        )
                        :!showStartRoundButton()
                        ? SizedBox.shrink()
                        :  ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  minimumSize: tablet ? Size(200, 60) : null,
                                ),
                                onPressed: () async {
                                  _.loading.value = true;
                                  _.currentAlonkaRound.value =
                                      _.currentEvent.value.alonkaSprints.length;
                                  if (_
                                      .currentEvent.value.alonkaSprints.isEmpty)
                                    eventController.currentEvent.value
                                        .alonkaStartTime = DateTime.now();
                                  List<int> activeList = _.currentEvent.value
                                      .getParticipantsByStatus(
                                          ParticipantStatus.Active)
                                      .map((participant) => participant.number)
                                      .toList();
                                  if (inOrderOfArrival) {
                                    /// Sort by Alonka grade (descending)
                                    activeList.sort((a, b) => eventController
                                        .getAlonkaGrade(b)
                                        .compareTo(
                                            eventController.getAlonkaGrade(a)));
                                  }

                                  /// create new Alonka Sprint
                                  _.currentEvent.value.alonkaSprints.add(
                                      AlonkaSprint(
                                          round: _.currentEvent.value
                                              .alonkaSprints.length,
                                          activeParticipants: activeList));
                                  _.loading.value = false;
                                  _scrollToEnd();
                                  _.currentEvent.value.saveToFirestore();
                                  //})
                                },
                                child: Text(
                                  'התחל סיבוב חדש (צא)',
                                  style: TextStyle(
                                      fontSize: scaledFontSize,
                                      fontWeight: FontWeight.bold),
                                ))),
                    SizedBox(
                      height: 100,
                    ),
                    _.currentEvent.value.alonkaEndTime == null &&
                            _.currentEvent.value.alonkaStartTime != null &&
                            _.currentEvent.value.alonkaSprints.last
                                .activeParticipants.isEmpty
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              minimumSize: tablet ? Size(200, 60) : null,
                            ),
                            onPressed: () async {
                              var res = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return YesNoDialog();
                                },
                              );
                              if (res) {
                                setState(() {
                                  _.currentEvent.value.alonkaEndTime =
                                      DateTime.now();
                                });
                                _timer.cancel();
                                await eventController.currentEvent.value
                                    .saveToFirestore();
                              }
                            },
                            //eventController.currentEvent.value.save();
                            child: Text(
                              'סיום התרגיל',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: scaledFontSize),
                            ))
                        : _.currentEvent.value.alonkaEndTime != null
                            ? Text(
                                '  התרגיל הסתיים  ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: scaledFontSize),
                              )
                            : SizedBox.shrink(),
                    SizedBox(
                      height: 80,
                    ),
                  ],
                ),
                  ),
                ),
              );
            }),
        ),
        // Floating PTT Button - OUTSIDE Scaffold, on top of everything
        if (_floatingPttEnabled || _volumeButtonPttEnabled)
          FloatingPttButton(
            instructorId: eventController.currentInstructor.id,
            enabled: _floatingPttEnabled || _volumeButtonPttEnabled,
            showButton: _floatingPttEnabled,
          ),
      ],
    ),
    );
  }
}

/// Matrix view for the alonka exercise page showing all recruits and rounds
class _AlonkaExerciseMatrixView extends StatefulWidget {
  final bool inOrderOfArrival;
  
  const _AlonkaExerciseMatrixView({super.key, required this.inOrderOfArrival});
  
  @override
  State<_AlonkaExerciseMatrixView> createState() => _AlonkaExerciseMatrixViewState();
}

class _AlonkaExerciseMatrixViewState extends State<_AlonkaExerciseMatrixView> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _frozenColumnScrollController = ScrollController();
  bool _previousShowNewRoundColumn = false;
  
  @override
  void initState() {
    super.initState();
    // Synchronize vertical scrolling between frozen column and scrollable part
    _verticalScrollController.addListener(() {
      if (_frozenColumnScrollController.hasClients && 
          _verticalScrollController.hasClients) {
        _frozenColumnScrollController.jumpTo(_verticalScrollController.offset);
      }
    });
    _frozenColumnScrollController.addListener(() {
      if (_verticalScrollController.hasClients && 
          _frozenColumnScrollController.hasClients) {
        _verticalScrollController.jumpTo(_frozenColumnScrollController.offset);
      }
    });
  }
  
  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _frozenColumnScrollController.dispose();
    super.dispose();
  }
  
  void _scrollToNewColumn() {
    // Wait for the frame to render, then scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a small delay to ensure layout is complete
      Future.delayed(Duration(milliseconds: 100), () {
        if (_horizontalScrollController.hasClients && 
            _horizontalScrollController.position.maxScrollExtent > 0) {
          _horizontalScrollController.animateTo(
            _horizontalScrollController.position.maxScrollExtent, // Scroll to end (left side for RTL) to show new column
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }
  
  Color _getCreditColor(AlonkaSprint sprint, int participantNumber) {
    if (sprint.alonkaCredits.contains(participantNumber)) {
      return Colors.red; // Alonka credit - red
    } else if (sprint.gerikanCredits.contains(participantNumber)) {
      return Colors.green; // Gerikan credit - green
    } else if (sprint.runCredits.contains(participantNumber)) {
      return Colors.black; // Runner credit - black
    } else if (sprint.participationCredits.contains(participantNumber)) {
      return Colors.white; // Participation credit - white
    }
    return Colors.grey; // No credit
  }

  String _getCreditLabel(AlonkaSprint sprint, int participantNumber) {
    if (sprint.alonkaCredits.contains(participantNumber)) {
      return 'א';
    } else if (sprint.gerikanCredits.contains(participantNumber)) {
      return 'ג';
    } else if (sprint.runCredits.contains(participantNumber)) {
      return 'ר';
    }
    // No text for participation or no credit
    return '';
  }

  bool _isRoundOpen(AlonkaSprint sprint) {
    return sprint.activeParticipants.isNotEmpty;
  }

  Future<void> _handleCellClick(AlonkaSprint sprint, int participantNumber) async {
    final eventController = Get.put(EventController());
    
    // Check if participant is in activeParticipants (round is open)
    if (!sprint.activeParticipants.contains(participantNumber)) {
      return; // Can't grant credit if not in active participants
    }

    var res = await showDialog<AlonkaCreditTypes>(
      context: context,
      builder: (BuildContext context) => AlonkaCreditPanel(participantNumber: participantNumber),
    );

    if (res != null) {
      setState(() {
        switch (res) {
          case AlonkaCreditTypes.Alonka:
            sprint.alonkaCredits.add(participantNumber);
            sprint.activeParticipants.remove(participantNumber);
            break;
          case AlonkaCreditTypes.Gerikan:
            sprint.gerikanCredits.add(participantNumber);
            sprint.activeParticipants.remove(participantNumber);
            break;
          case AlonkaCreditTypes.Runner:
            sprint.runCredits.add(participantNumber);
            sprint.activeParticipants.remove(participantNumber);
            break;
          case AlonkaCreditTypes.Participated:
            // Add participation credit and remove from active
            sprint.participationCredits.add(participantNumber);
            sprint.activeParticipants.remove(participantNumber);
            break;
        }
      });
      eventController.currentEvent.value.saveToFirestore();
    }
  }

  void _handleCellDoubleClick(AlonkaSprint sprint, int participantNumber) {
    final eventController = Get.put(EventController());
    
    setState(() {
      // Remove from credits and add back to active participants
      if (sprint.alonkaCredits.contains(participantNumber)) {
        sprint.alonkaCredits.remove(participantNumber);
        sprint.activeParticipants.add(participantNumber);
      } else if (sprint.gerikanCredits.contains(participantNumber)) {
        sprint.gerikanCredits.remove(participantNumber);
        sprint.activeParticipants.add(participantNumber);
      } else if (sprint.runCredits.contains(participantNumber)) {
        sprint.runCredits.remove(participantNumber);
        sprint.activeParticipants.add(participantNumber);
      } else if (sprint.participationCredits.contains(participantNumber)) {
        sprint.participationCredits.remove(participantNumber);
        sprint.activeParticipants.add(participantNumber);
      }
    });
    eventController.currentEvent.value.saveToFirestore();
  }

  Future<void> _handleRecruitLongPress(int participantNumber) async {
    final eventController = Get.put(EventController());
    var res = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) => CommentsDialog(
        commentsList: eventController.gradesData.listOfCommentsAlonka,
        selectedComments: eventController.getParticipant(participantNumber).alonkaInstructorComments,
        title: participantNumber.toString(),
        exerciseType: ExerciseType.alonka,
        instructorCustomComments: eventController.getInstructorCustomCommentsForExercise('alonka'),
      ),
    );
    if (res != null) {
      if (res.contains(ParticipantStatus.Droped.name)) {
        eventController.loading.value = true;
        eventController.dropParticipant(participantNumber);
        eventController.loading.value = false;
      } else {
        eventController.addAlonkaComments(res, participantNumber);
      }
    }
  }

  Future<void> _handleStopRound(AlonkaSprint sprint) async {
    final eventController = Get.put(EventController());
    eventController.widgetLoading.value = true;
    
    setState(() {
      // Add all remaining active participants to participation credits
      for (var participantNumber in sprint.activeParticipants) {
        sprint.participationCredits.add(participantNumber);
      }
      // Clear active participants
      sprint.activeParticipants = [];
    });
    
    eventController.currentEvent.value.alonkaSprints[sprint.round] = sprint;
    await eventController.currentEvent.value.saveToFirestore();
    eventController.widgetLoading.value = false;
    
    // Scroll to show the new placeholder column if it appears (scroll to max extent for RTL - left side)
    // The scroll will happen automatically in build() when showNewRoundColumn becomes true
  }

  Future<void> _handleStartNewRound() async {
    final eventController = Get.put(EventController());
    eventController.loading.value = true;
    eventController.currentAlonkaRound.value = eventController.currentEvent.value.alonkaSprints.length;
    
    if (eventController.currentEvent.value.alonkaSprints.isEmpty) {
      eventController.currentEvent.value.alonkaStartTime = DateTime.now();
    }
    
    List<int> activeList = eventController.currentEvent.value
        .getParticipantsByStatus(ParticipantStatus.Active)
        .map((participant) => participant.number)
        .toList();
    
    if (eventController.currentEvent.value.alonkaSprints.isNotEmpty &&
        eventController.currentEvent.value.alonkaSprints.last.activeParticipants.isEmpty) {
      // Sort by alonka grade if in order of arrival mode
      activeList.sort((a, b) => eventController
          .getAlonkaGrade(b)
          .compareTo(eventController.getAlonkaGrade(a)));
    }

    setState(() {
      eventController.currentEvent.value.alonkaSprints.add(
        AlonkaSprint(
          round: eventController.currentEvent.value.alonkaSprints.length,
          activeParticipants: activeList,
        ),
      );
    });
    
    eventController.loading.value = false;
    await eventController.currentEvent.value.saveToFirestore();
    
    // Scroll to show the new column (scroll to max extent for RTL - left side where new columns appear)
    _scrollToNewColumn();
  }

  @override
  Widget build(BuildContext context) {
    // Use the inOrderOfArrival value directly - this ensures rebuild when it changes
    final inOrderOfArrival = widget.inOrderOfArrival;
    
    // Use Obx to make it reactive to EventController changes
    return Obx(() {
      final eventController = Get.find<EventController>();
      final allSprints = eventController.currentEvent.value.alonkaSprints;
      bool isTablet = MediaQuery.of(context).size.width > 600;
      
      // Show all rounds including open ones
      List<AlonkaSprint> sprints = List.from(allSprints);
      
      // Check if we need to add a new round column (last round is finalized)
      bool showNewRoundColumn = allSprints.isEmpty || 
          (allSprints.isNotEmpty && allSprints.last.activeParticipants.isEmpty &&
           eventController.currentEvent.value.alonkaEndTime == null);
      
      // Scroll to show placeholder column when it first appears
      if (showNewRoundColumn && !_previousShowNewRoundColumn) {
        _previousShowNewRoundColumn = true;
        _scrollToNewColumn();
      } else if (!showNewRoundColumn) {
        _previousShowNewRoundColumn = false;
      }
      
      // Get participants and sort based on order of arrival toggle
      // Create a new list to ensure sorting happens
      final participantsList = List.from(eventController.currentEvent.value
          .getParticipantsByStatus(ParticipantStatus.Active));
      
      // Sort based on order of arrival toggle
      if (inOrderOfArrival) {
        // Sort by estimated order of arrival (using getAlonkaGrade - same as other view)
        // This calculates grade based on credits and arrival bonuses
        participantsList.sort((a, b) => eventController
            .getAlonkaGrade(b.number)
            .compareTo(eventController.getAlonkaGrade(a.number)));
      } else {
        // Sort by recruit number ascending
        participantsList.sort((a, b) => a.number.compareTo(b.number));
      }
      
      final participants = participantsList;

    if (participants.isEmpty) {
      return Center(
        child: Text(
          'אין נתונים',
          style: TextStyle(color: Colors.white, fontSize: isTablet ? 18 : 16),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          // Scrollable table content - fills entire stack
          Positioned.fill(
            child: Container(
              color: Colors.transparent, // Use transparent to show the gradient background
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    // Frozen first column (recruit numbers) - no scroll view needed, parent handles vertical scrolling
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header cell
                        Container(
                          width: isTablet ? 80 : 70,
                          height: isTablet ? 48 : 44,
                          decoration: BoxDecoration(
                            color: isDark 
                                ? theme.colorScheme.surfaceContainerHighest
                                : Colors.grey[200],
                            border: Border(
                              bottom: BorderSide(
                                color: isDark 
                                    ? theme.colorScheme.outline.withOpacity(0.3)
                                    : Colors.grey[300]!, 
                                width: 1
                              ),
                              left: BorderSide(
                                color: isDark 
                                    ? theme.colorScheme.outline.withOpacity(0.3)
                                    : Colors.grey[300]!, 
                                width: 1
                              ),
                            ),
                          ),
                          child: SizedBox.shrink(),
                        ),
                        // Data rows
                        ...participants.map((participant) {
                          return Container(
                            width: isTablet ? 80 : 70,
                            height: isTablet ? 48 : 44, // Fixed height to match scrollable cells
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? theme.colorScheme.surfaceContainer
                                  : Colors.grey[100],
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark 
                                      ? theme.colorScheme.outline.withOpacity(0.3)
                                      : Colors.grey[300]!, 
                                  width: 1
                                ),
                                left: BorderSide(
                                  color: isDark 
                                      ? theme.colorScheme.outline.withOpacity(0.3)
                                      : Colors.grey[300]!, 
                                  width: 1
                                ),
                              ),
                            ),
                            child: GestureDetector(
                              onLongPress: () => _handleRecruitLongPress(participant.number),
                              child: Center(
                                child: Text(
                                  participant.number.toString(),
                                  style: TextStyle(
                                    color: isDark 
                                        ? theme.colorScheme.onSurface
                                        : Colors.black,
                                    fontSize: isTablet ? 16 : 14,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                    // Scrollable columns (rounds) - horizontal scroll only
                    Expanded(
                      child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(), // Smooth scrolling
                      child: SizedBox(
                        width: (sprints.length + (showNewRoundColumn ? 1 : 0)) * (isTablet ? 60.0 : 50.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header row
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.rtl,
                              children: [
                                  ...sprints.map((sprint) {
                                    bool isOpen = _isRoundOpen(sprint);
                                    return GestureDetector(
                                      onTap: isOpen ? () => _handleStopRound(sprint) : null,
                                      child: Container(
                                        width: isTablet ? 60 : 50,
                                        height: isTablet ? 48 : 44,
                                        decoration: BoxDecoration(
                                          color: isDark 
                                              ? theme.colorScheme.surfaceContainerHighest
                                              : Colors.grey[200],
                                          border: Border(
                                            bottom: BorderSide(
                                              color: isDark 
                                                  ? theme.colorScheme.outline.withOpacity(0.3)
                                                  : Colors.grey[300]!, 
                                              width: 1
                                            ),
                                            right: BorderSide(
                                              color: isDark 
                                                  ? theme.colorScheme.outline.withOpacity(0.3)
                                                  : Colors.grey[300]!, 
                                              width: 1
                                            ),
                                          ),
                                        ),
                                        child: Center(
                                          child: isOpen
                                              ? Icon(Icons.stop, color: Colors.red, size: isTablet ? 24 : 20)
                                              : Text(
                                                  (sprint.round + 1).toString(),
                                                  style: TextStyle(
                                                    color: isDark 
                                                        ? theme.colorScheme.onSurface
                                                        : Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: isTablet ? 16 : 14,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  if (showNewRoundColumn)
                                    GestureDetector(
                                      onTap: () => _handleStartNewRound(),
                                      child: Container(
                                        width: isTablet ? 60 : 50,
                                        height: isTablet ? 48 : 44,
                                        decoration: BoxDecoration(
                                          color: isDark 
                                              ? theme.colorScheme.surfaceContainerHighest
                                              : Colors.grey[200],
                                          border: Border(
                                            bottom: BorderSide(
                                              color: isDark 
                                                  ? theme.colorScheme.outline.withOpacity(0.3)
                                                  : Colors.grey[300]!, 
                                              width: 1
                                            ),
                                            right: BorderSide(
                                              color: isDark 
                                                  ? theme.colorScheme.outline.withOpacity(0.3)
                                                  : Colors.grey[300]!, 
                                              width: 1
                                            ),
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(Icons.play_arrow, color: Colors.green, size: isTablet ? 24 : 20),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              // Data rows
                              ...participants.map((participant) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    ...sprints.map((sprint) {
                                      Color cellColor = _getCreditColor(sprint, participant.number);
                                      String label = _getCreditLabel(sprint, participant.number);
                                      bool isOpen = _isRoundOpen(sprint);
                                      bool isActive = sprint.activeParticipants.contains(participant.number);
                                      
                                      // Check if participant has any credit in this sprint
                                      bool hasCredit = sprint.alonkaCredits.contains(participant.number) ||
                                                     sprint.gerikanCredits.contains(participant.number) ||
                                                     sprint.runCredits.contains(participant.number) ||
                                                     sprint.participationCredits.contains(participant.number);
                                      
                                      // For active cells in open rounds, show white background with recruit number
                                      // This represents participation credit as default
                                      Color displayColor = cellColor;
                                      Widget displayChild;
                                      
                                      // Priority: If participant has a credit, show that credit (not active status)
                                      if (hasCredit) {
                                        if (label.isNotEmpty) {
                                          // Has a credit label (א, ג, or ר) - show label with appropriate color
                                          displayColor = cellColor;
                                          displayChild = Center(
                                            child: Text(
                                              label,
                                              style: TextStyle(
                                                color: cellColor == Colors.black
                                                    ? Colors.white  // White text for black cells (runner credit)
                                                    : Colors.white,  // White text for colored cells (red/green)
                                                fontSize: isTablet ? 16 : 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          );
                                        } else if (cellColor == Colors.white) {
                                          // Participation credit: white background with NO text
                                          displayColor = Colors.white;
                                          displayChild = SizedBox.shrink();
                                        } else {
                                          // Other credit type without label
                                          displayColor = cellColor;
                                          displayChild = SizedBox.shrink();
                                        }
                                      } else if (isActive && isOpen) {
                                        // Active round: show white background with recruit number (participation credit default)
                                        displayColor = Colors.white;
                                        displayChild = Center(
                                          child: Text(
                                            participant.number.toString(),
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: isTablet ? 14 : 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      } else {
                                        // Empty cell (grey) - no credit and not active
                                        displayColor = cellColor;
                                        displayChild = SizedBox.shrink();
                                      }
                                      
                                      return Container(
                                        width: isTablet ? 60 : 50,
                                        height: isTablet ? 48 : 44, // Fixed height to match frozen column
                                        decoration: BoxDecoration(
                                          color: displayColor,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: isDark 
                                                  ? theme.colorScheme.outline.withOpacity(0.3)
                                                  : Colors.grey[300]!, 
                                              width: 1
                                            ),
                                            right: BorderSide(
                                              color: isDark 
                                                  ? theme.colorScheme.outline.withOpacity(0.3)
                                                  : Colors.grey[300]!, 
                                              width: 1
                                            ),
                                          ),
                                        ),
                                        child: GestureDetector(
                                          onTap: isOpen && isActive ? () => _handleCellClick(sprint, participant.number) : null,
                                          onDoubleTap: () => _handleCellDoubleClick(sprint, participant.number),
                                          child: displayChild,
                                        ),
                                      );
                                    }).toList(),
                                    // New round column cell
                                    if (showNewRoundColumn)
                                      Container(
                                        width: isTablet ? 60 : 50,
                                        height: isTablet ? 48 : 44,
                                        decoration: BoxDecoration(
                                          color: isDark 
                                              ? theme.colorScheme.surfaceContainer
                                              : Colors.grey[300],
                                          border: Border(
                                            bottom: BorderSide(
                                              color: isDark 
                                                  ? theme.colorScheme.outline.withOpacity(0.3)
                                                  : Colors.grey[300]!, 
                                              width: 1
                                            ),
                                            right: BorderSide(
                                              color: isDark 
                                                  ? theme.colorScheme.outline.withOpacity(0.3)
                                                  : Colors.grey[300]!, 
                                              width: 1
                                            ),
                                          ),
                                        ),
                                        child: SizedBox.shrink(),
                                      ),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ),
          ), // Positioned.fill closes here
          // Fixed button at bottom center
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: GetX<EventController>(builder: (_) {
                bool showEndButton = _.currentEvent.value.alonkaEndTime == null &&
                    _.currentEvent.value.alonkaStartTime != null &&
                    _.currentEvent.value.alonkaSprints.isNotEmpty &&
                    _.currentEvent.value.alonkaSprints.last.activeParticipants.isEmpty;
                
                if (showEndButton) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      minimumSize: isTablet ? Size(200, 60) : null,
                    ),
                    onPressed: () async {
                      var res = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return YesNoDialog();
                        },
                      );
                      if (res) {
                        setState(() {
                          _.currentEvent.value.alonkaEndTime = DateTime.now();
                        });
                        // Cancel timer - need to access parent's timer
                        // The timer is managed in the parent widget, so we'll let it handle cancellation
                        await _.currentEvent.value.saveToFirestore();
                      }
                    },
                    child: Text(
                      'סיום התרגיל',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 18 : 16,
                      ),
                    ),
                  );
                } else if (_.currentEvent.value.alonkaEndTime != null) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: isTablet ? Size(200, 60) : null,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExerciseGradingPage(exerciseType: 'alonka'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.grade),
                        label: Text(
                          'ציון התרגיל',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 18 : 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '  התרגיל הסתיים  ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 18 : 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  );
                }
                return SizedBox.shrink();
              }),
            ),
          ),
        ],
      ),
    );
    });
  }
}
