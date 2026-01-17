import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../widgets/meshulash_round_panel.dart';
import '../widgets/meshulash_grid_view.dart';
import '../widgets/exercise_leaderboard.dart';
import '../models/meshulash_round.dart';
import '../models/types.dart';
import 'dart:async';
import '../widgets/yes_no.dart';
import '../widgets/guideWebView.dart';
import '../utils/tablet_utils.dart';
import '../services/exercise_context_service.dart';
import '../services/user_preferences_service.dart';
import '../widgets/floating_ptt_button.dart';
import '../widgets/wifi_settings_button.dart';
import '../mixins/event_validation_mixin.dart';
import 'exercise_grading_page.dart';

class MeshulashPage extends StatefulWidget {
  const MeshulashPage({super.key});

  @override
  State<MeshulashPage> createState() => _MeshulashPageState();
}

class _MeshulashPageState extends State<MeshulashPage>
    with EventValidationMixin {
  final eventController = Get.find<EventController>();
  int runTime = 0;
  late Timer _timer;
  late bool editModeOn;
  bool _isGridView = false;
  final ScrollController _scrollController = ScrollController();
  bool _floatingPttEnabled = false;
  bool _volumeButtonPttEnabled = false;
  // inOrderOfArrival is now loaded from uxPreferences reactively

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    checkEventValidity();
    // Set exercise context for STT
    ExerciseContextService().setCurrentExercise('meshulash');
    _loadSttPreferences();

    // Initialize meshulashRounds if empty but participants exist
    // This fixes the issue where going offline/online causes rounds to be empty
    if (eventController.currentEvent.value.meshulashRounds.isEmpty) {
      final activeParticipants = eventController.currentEvent.value
          .getParticipantsByStatus(ParticipantStatus.Active);
      if (activeParticipants.isNotEmpty) {
        // Initialize with round 0 containing all active participants
        eventController.currentEvent.value.meshulashRounds.add(
          MeshulashRound(
            round: 0,
            participantsInRound:
                activeParticipants.map((p) => p.number).toList(),
          ),
        );
        // Save the updated event
        eventController
            .saveEventWithOfflineSupport(eventController.currentEvent.value);
        print(
            '✅ Initialized meshulashRounds with ${activeParticipants.length} participants');
      }
    }

    if (eventController.currentEvent.value.meshulashEndTime != null) {
      eventController.meshulashEditModeOn.value = false;
      editModeOn = eventController.meshulashEditModeOn.value;
    } else {
      eventController.meshulashEditModeOn.value = true;
      editModeOn = eventController.meshulashEditModeOn.value;
    }
    runTime = eventController.currentEvent.value.getMeshulashRunTime();
    if (eventController.currentEvent.value.meshulashEndTime == null) {
      _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
        setState(() {
          runTime = eventController.currentEvent.value.getMeshulashRunTime();
        });
      });
    }
    _scrollToEnd();
    // super.initState(); // This was duplicated, removed.
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

  @override
  void dispose() {
    if (eventController.currentEvent.value.meshulashEndTime == null)
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
    final orientation = MediaQuery.of(context).orientation;
    bool isLandscape = orientation == Orientation.landscape;
    double scaledFontSize =
        getTabletScaledFontSize(context, eventController.userFontSize.value);
    double buttonPadding = tablet ? (isLandscape ? 30.0 : 45.0) : 30.0;
    double dividerThickness = tablet ? (isLandscape ? 30.0 : 45.0) : 30.0;

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
              title: Column(
                children: [
                  Text('משולש'),
                  Text(
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    'משך התרגיל $runTime דקות ',
                  ),
                ],
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back), // 🔄 Custom back arrow
                onPressed: () {
                  eventController.loading.value = true;
                  Get.back(); // ⬅️ Go back using GetX
                  eventController.loading.value = false;
                },
              ),
              actions: [
                Obx(() => IconButton(
                      onPressed: () {
                        // Toggle the preference
                        final currentValue = eventController
                            .uxPreferences.value.inOrderOfArrival;
                        final newValue = !currentValue;
                        var updatedPrefs = eventController.uxPreferences.value
                            .copyWith(inOrderOfArrival: newValue);
                        eventController.updateUxPreferences(updatedPrefs);
                      },
                      icon: Icon(
                        Icons.directions_walk_sharp,
                        color:
                            eventController.uxPreferences.value.inOrderOfArrival
                                ? Colors.green
                                : Colors.grey, // Switch color
                        size: 32,
                      ),
                    )),
                IconButton(
                  icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                  tooltip:
                      _isGridView ? 'מעבר לתצוגת רשימה' : 'מעבר לתצוגת רשת',
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
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
                          url:
                              'https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000&slide=id.g384f00aea19_0_29',
                          //https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000
                        ),
                      ),
                    );
                  },
                ),
                WifiSettingsButton(),
              ],
            ),
            body: Stack(
              children: [
                GetX<EventController>(builder: (_) {
                  editModeOn = _.meshulashEditModeOn.value;
                  // Show grid view if enabled
                  if (_isGridView) {
                    return Obx(() => eventController.loading.value
                        ? LinearProgressIndicator()
                        : SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: MediaQuery.of(context).size.height -
                                    AppBar().preferredSize.height -
                                    MediaQuery.of(context).padding.top,
                              ),
                              child: Column(
                                children: [
                                  MeshulashGridView(
                                    key: ValueKey(
                                        'meshulash_grid_${eventController.uxPreferences.value.inOrderOfArrival}'),
                                    inOrderOfArrival: eventController
                                        .uxPreferences.value.inOrderOfArrival,
                                  ),
                                  SizedBox(height: tablet ? 8.0 : 6.0),
                                  // Leaderboard
                                  ExerciseLeaderboard(
                                    exerciseType: 'meshulash',
                                    inOrderOfArrival: eventController
                                        .uxPreferences.value.inOrderOfArrival,
                                  ),
                                  SizedBox(
                                      height: tablet
                                          ? 8.0
                                          : 6.0), // Compact gap between leaderboard and button
                                  if (eventController.currentEvent.value
                                          .meshulashEndTime ==
                                      null)
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                          buttonPadding, 8, buttonPadding, 8),
                                      child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            foregroundColor: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            minimumSize: tablet
                                                ? Size(180, 45)
                                                : Size(150, 40),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
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
                                                eventController
                                                        .currentEvent
                                                        .value
                                                        .meshulashEndTime =
                                                    DateTime.now();
                                                _timer.cancel();
                                                _.meshulashEditModeOn.value =
                                                    false;
                                                editModeOn =
                                                    _.meshulashEditModeOn.value;
                                                // Use non-blocking save to prevent delays when offline
                                                eventController
                                                    .saveEventWithOfflineSupport(
                                                        eventController
                                                            .currentEvent
                                                            .value);
                                              });
                                            }
                                          },
                                          child: Text(
                                            'סיום התרגיל',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: tablet
                                                    ? scaledFontSize - 1
                                                    : scaledFontSize - 2),
                                          )),
                                    )
                                  else
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                          buttonPadding,
                                          buttonPadding,
                                          buttonPadding,
                                          80.0),
                                      child: Column(
                                        children: [
                                          eventController
                                                  .currentEvent.value.finalized
                                              ? SizedBox.shrink()
                                              : TextButton.icon(
                                                  onPressed: () {
                                                    if (editModeOn) {
                                                      // Use non-blocking save to prevent delays when offline
                                                      eventController
                                                          .saveEventWithOfflineSupport(
                                                              eventController
                                                                  .currentEvent
                                                                  .value);
                                                    } else {}
                                                    _.meshulashEditModeOn
                                                            .value =
                                                        !_.meshulashEditModeOn
                                                            .value;
                                                    setState(() {
                                                      editModeOn = !_
                                                          .meshulashEditModeOn
                                                          .value;
                                                    });
                                                  },
                                                  icon: editModeOn
                                                      ? const Icon(Icons.edit)
                                                      : const Icon(Icons.save),
                                                  label: !editModeOn
                                                      ? Text(
                                                          'סיים',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  scaledFontSize),
                                                        )
                                                      : Text(
                                                          'עריכה',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  scaledFontSize),
                                                        ),
                                                  iconAlignment:
                                                      IconAlignment.start,
                                                ),
                                          SizedBox(height: 20),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                              minimumSize:
                                                  tablet ? Size(200, 60) : null,
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ExerciseGradingPage(
                                                          exerciseType:
                                                              'meshulash'),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.grade),
                                            label: Text(
                                              'ציון התרגיל',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: scaledFontSize),
                                            ),
                                          ),
                                          SizedBox(height: 20),
                                          Text(
                                            '  התרגיל הסתיים  ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: scaledFontSize),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ));
                  }
                  // Show existing list view
                  return SingleChildScrollView(
                    controller: _scrollController,
                    child: eventController
                            .currentEvent.value.meshulashRounds.isNotEmpty
                        ? Center(
                            child: Obx(() {
                              // Use inOrderOfArrival in the key to force rebuild when it changes
                              final orderKey = eventController
                                  .uxPreferences.value.inOrderOfArrival;
                              return eventController.loading.value
                                  ? LinearProgressIndicator()
                                  : Column(
                                      key: ValueKey(
                                          'meshulash_rounds_$orderKey'),
                                      children: [
                                        SizedBox(
                                          height: 15,
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: () {
                                            // Filter rounds: show from first round with participants to last round with participants
                                            // This includes empty rounds in between (that participants passed through)
                                            // but excludes empty rounds before the first and after the last
                                            final allRounds = List.from(
                                                eventController.currentEvent
                                                    .value.meshulashRounds);

                                            if (allRounds.isEmpty) {
                                              return <Widget>[];
                                            }

                                            // Sort rounds by round number to ensure proper order
                                            allRounds.sort((a, b) =>
                                                a.round.compareTo(b.round));

                                            // Find the first round index that has participants
                                            int firstRoundWithParticipants = -1;
                                            for (int i = 0;
                                                i < allRounds.length;
                                                i++) {
                                              if (allRounds[i]
                                                  .participantsInRound
                                                  .isNotEmpty) {
                                                firstRoundWithParticipants = i;
                                                break;
                                              }
                                            }

                                            // Find the last round index that has participants
                                            int lastRoundWithParticipants = -1;
                                            for (int i = allRounds.length - 1;
                                                i >= 0;
                                                i--) {
                                              if (allRounds[i]
                                                  .participantsInRound
                                                  .isNotEmpty) {
                                                lastRoundWithParticipants = i;
                                                break;
                                              }
                                            }

                                            // If no rounds with participants found, show only round 0 if it exists
                                            if (firstRoundWithParticipants ==
                                                    -1 ||
                                                lastRoundWithParticipants ==
                                                    -1) {
                                              if (allRounds.isNotEmpty &&
                                                  allRounds[0].round == 0) {
                                                return [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: Obx(() => eventController
                                                            .loading.value
                                                        ? CircularProgressIndicator()
                                                        : MeshulashRoundPanel(
                                                            key: ValueKey(
                                                                'meshulash_round_${allRounds[0].round}_${eventController.uxPreferences.value.inOrderOfArrival}'),
                                                            round: allRounds[0],
                                                            inOrderOfArrival:
                                                                eventController
                                                                    .uxPreferences
                                                                    .value
                                                                    .inOrderOfArrival,
                                                          )),
                                                  )
                                                ];
                                              }
                                              return <Widget>[];
                                            }

                                            // Show rounds from first to last (including empty rounds in between)
                                            // This excludes empty rounds before the first and after the last
                                            final roundsToShow =
                                                allRounds.sublist(
                                                    firstRoundWithParticipants,
                                                    lastRoundWithParticipants +
                                                        1);
                                            print(
                                                '🔍 Meshulash: Showing rounds ${allRounds[firstRoundWithParticipants].round} to ${allRounds[lastRoundWithParticipants].round} (${roundsToShow.length} rounds)');
                                            return roundsToShow.map((round) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(5.0),
                                                child: Obx(() => eventController
                                                        .loading.value
                                                    ? CircularProgressIndicator()
                                                    : MeshulashRoundPanel(
                                                        key: ValueKey(
                                                            'meshulash_round_${round.round}_${eventController.uxPreferences.value.inOrderOfArrival}'),
                                                        round: round,
                                                        inOrderOfArrival:
                                                            eventController
                                                                .uxPreferences
                                                                .value
                                                                .inOrderOfArrival,
                                                      )),
                                              );
                                            }).toList();
                                          }(),
                                        ),
                                        Divider(
                                          thickness: dividerThickness,
                                        ),
                                        SizedBox(
                                          height: 20,
                                        ),
                                        eventController.currentEvent.value
                                                    .meshulashEndTime ==
                                                null
                                            ? Column(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            buttonPadding,
                                                            buttonPadding,
                                                            buttonPadding,
                                                            80.0),
                                                    child: ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          foregroundColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimary,
                                                          minimumSize: tablet
                                                              ? Size(200, 60)
                                                              : null,
                                                        ),
                                                        onPressed: () async {
                                                          var res =
                                                              await showDialog(
                                                            context: context,
                                                            builder:
                                                                (BuildContext
                                                                    context) {
                                                              return YesNoDialog();
                                                            },
                                                          );
                                                          if (res) {
                                                            setState(() {
                                                              eventController
                                                                      .currentEvent
                                                                      .value
                                                                      .meshulashEndTime =
                                                                  DateTime
                                                                      .now();
                                                            });
                                                            // Use non-blocking save to prevent delays when offline
                                                            eventController
                                                                .saveEventWithOfflineSupport(
                                                                    eventController
                                                                        .currentEvent
                                                                        .value);
                                                            _timer.cancel();
                                                            _.meshulashEditModeOn
                                                                .value = false;
                                                            editModeOn = _
                                                                .meshulashEditModeOn
                                                                .value;
                                                          }
                                                        },
                                                        child: Text(
                                                          'סיום התרגיל',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  scaledFontSize),
                                                        )),
                                                  ),
                                                  SizedBox(
                                                    height: 50,
                                                  )
                                                ],
                                              )
                                            : Padding(
                                                padding: EdgeInsets.fromLTRB(
                                                    buttonPadding,
                                                    buttonPadding,
                                                    buttonPadding,
                                                    80.0),
                                                child: Column(
                                                  children: [
                                                    eventController.currentEvent
                                                            .value.finalized
                                                        ? SizedBox.shrink()
                                                        : TextButton.icon(
                                                            onPressed:
                                                                () async {
                                                              if (editModeOn) {
                                                                ///save
                                                                // Use non-blocking save to prevent delays when offline
                                                                eventController.saveEventWithOfflineSupport(
                                                                    eventController
                                                                        .currentEvent
                                                                        .value);
                                                              } else {}
                                                              _.meshulashEditModeOn
                                                                      .value =
                                                                  !_.meshulashEditModeOn
                                                                      .value;
                                                              setState(() {
                                                                editModeOn = !_
                                                                    .meshulashEditModeOn
                                                                    .value;
                                                              });
                                                            },
                                                            icon: editModeOn
                                                                ? const Icon(
                                                                    Icons.save)
                                                                : const Icon(
                                                                    Icons.edit),
                                                            label: editModeOn
                                                                ? Text(
                                                                    'סיים',
                                                                    style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        fontSize:
                                                                            scaledFontSize),
                                                                  )
                                                                : Text(
                                                                    'עריכה',
                                                                    style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        fontSize:
                                                                            scaledFontSize),
                                                                  ),
                                                            iconAlignment:
                                                                IconAlignment
                                                                    .start,
                                                          ),
                                                    SizedBox(
                                                      height: 20,
                                                    ),
                                                    ElevatedButton.icon(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.orange,
                                                        foregroundColor:
                                                            Colors.white,
                                                        minimumSize: tablet
                                                            ? Size(200, 60)
                                                            : null,
                                                      ),
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                ExerciseGradingPage(
                                                                    exerciseType:
                                                                        'meshulash'),
                                                          ),
                                                        );
                                                      },
                                                      icon: const Icon(
                                                          Icons.grade),
                                                      label: Text(
                                                        'ציון התרגיל',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize:
                                                                scaledFontSize),
                                                      ),
                                                    ),
                                                    SizedBox(height: 20),
                                                    Text(
                                                      '  התרגיל הסתיים  ',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize:
                                                              scaledFontSize),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ],
                                    );
                            }),
                          )
                        : Obx(() => eventController.loading.value
                            ? SizedBox(
                                height: 100,
                                width: 100,
                                child: CircularProgressIndicator(),
                              )
                            : Center(
                                child: Text(
                                  'אין נתונים',
                                  style: TextStyle(fontSize: tablet ? 20 : 18),
                                ),
                              )),
                  );
                }),
                // Floating PTT Button - OUTSIDE Scaffold, on top of everything
                if (_floatingPttEnabled || _volumeButtonPttEnabled)
                  FloatingPttButton(
                    instructorId: eventController.currentInstructor.id,
                    enabled: _floatingPttEnabled || _volumeButtonPttEnabled,
                    showButton: _floatingPttEnabled,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
