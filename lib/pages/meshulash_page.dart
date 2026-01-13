import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../widgets/meshulash_round_panel.dart';
import '../widgets/meshulash_grid_view.dart';
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

class _MeshulashPageState extends State<MeshulashPage> with EventValidationMixin {
  final eventController = Get.put(EventController());
  int runTime = 0;
  late Timer _timer;
  late bool editModeOn;
  bool _isGridView = false;
  final ScrollController _scrollController = ScrollController();
  bool _floatingPttEnabled = false;
  bool _volumeButtonPttEnabled = false;
  bool inOrderOfArrival = true; // Order of arrival mode (default: true)

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
    double scaledFontSize = getTabletScaledFontSize(context, eventController.userFontSize.value);
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
                Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), 'משך התרגיל $runTime דקות ',
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
              IconButton(
                onPressed: () {
                  setState(() {
                    inOrderOfArrival = !inOrderOfArrival; // Toggle state
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
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                tooltip: _isGridView ? 'מעבר לתצוגת רשימה' : 'מעבר לתצוגת רשת',
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
                        url: 'https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000&slide=id.g384f00aea19_0_29',
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
                              key: ValueKey('meshulash_grid_$inOrderOfArrival'),
                              inOrderOfArrival: inOrderOfArrival,
                            ),
                            SizedBox(height: tablet ? 60.0 : 40.0), // Increased gap between grid and button
                            if (eventController.currentEvent.value.meshulashEndTime == null)
                              Padding(
                                padding: EdgeInsets.fromLTRB(buttonPadding, buttonPadding, buttonPadding, 80.0),
                                child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                                    eventController.currentEvent.value.meshulashEndTime = DateTime.now();
                                    _timer.cancel();
                                    _.meshulashEditModeOn.value = false;
                                    editModeOn = _.meshulashEditModeOn.value;
                                    // Use non-blocking save to prevent delays when offline
                                    eventController.saveEventWithOfflineSupport(
                                      eventController.currentEvent.value
                                    );
                                  });
                                }
                              },
                                child: Text('סיום התרגיל',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: scaledFontSize),
                                )),
                              )
                            else
                              Padding(
                                padding: EdgeInsets.fromLTRB(buttonPadding, buttonPadding, buttonPadding, 80.0),
                                child: Column(
                                  children: [
                                    eventController.currentEvent.value.finalized
                                        ? SizedBox.shrink()
                                        : TextButton.icon(
                                            onPressed: () {
                                              if (editModeOn) {
                                                // Use non-blocking save to prevent delays when offline
                                                eventController.saveEventWithOfflineSupport(
                                                  eventController.currentEvent.value
                                                );
                                              } else {}
                                              _.meshulashEditModeOn.value = !_.meshulashEditModeOn.value;
                                              setState(() {
                                                editModeOn = !_.meshulashEditModeOn.value;
                                              });
                                            },
                                            icon: editModeOn
                                                ? const Icon(Icons.edit)
                                                : const Icon(Icons.save),
                                            label: !editModeOn
                                                ? Text('סיים',
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: scaledFontSize),
                                                )
                                                : Text('עריכה',
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: scaledFontSize),
                                                ),
                                            iconAlignment: IconAlignment.start,
                                          ),
                                    SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        minimumSize: tablet ? Size(200, 60) : null,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ExerciseGradingPage(exerciseType: 'meshulash'),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.grade),
                                      label: Text('ציון התרגיל',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: scaledFontSize),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text('  התרגיל הסתיים  ',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: scaledFontSize),
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
              child: eventController.currentEvent.value.meshulashRounds.isNotEmpty
                  ? Center(
                      child: Obx(() {
                        // Use inOrderOfArrival in the key to force rebuild when it changes
                        final orderKey = inOrderOfArrival;
                        return eventController.loading.value
                          ? LinearProgressIndicator()
                          : Column(
                                key: ValueKey('meshulash_rounds_$orderKey'),
                              children: [
                                SizedBox(
                                  height: 15,
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                        eventController.currentEvent.value.meshulashRounds.length,
                                      (index) {
                                    return Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child:
                                          Obx(() => eventController.loading.value
                                              ? CircularProgressIndicator()
                                              : MeshulashRoundPanel(
                                                    key: ValueKey('meshulash_round_${eventController.currentEvent.value.meshulashRounds[index].round}_$inOrderOfArrival'),
                                                    round: eventController.currentEvent.value
                                                      .meshulashRounds[index],
                                                    inOrderOfArrival: inOrderOfArrival,
                                                )),
                                    );
                                  }),
                                ),
                                Divider(
                                  thickness: dividerThickness,
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                eventController.currentEvent.value.meshulashEndTime ==
                                        null
                                    ? Column(
                                      children: [
                                        Padding(
                                            padding: EdgeInsets.fromLTRB(buttonPadding, buttonPadding, buttonPadding, 80.0),
                                            child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                                                      eventController
                                                              .currentEvent
                                                              .value
                                                              .meshulashEndTime =
                                                          DateTime.now();
                                                    });
                                                    // Use non-blocking save to prevent delays when offline
                                                    eventController.saveEventWithOfflineSupport(
                                                      eventController.currentEvent.value
                                                    );
                                                    _timer.cancel();
                                                    _.meshulashEditModeOn.value =
                                                        false;
                                                    editModeOn =
                                                        _.meshulashEditModeOn.value;
                                                  }
                                                },
                                                child: Text('סיום התרגיל',
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: scaledFontSize),
                                                )),
                                          ),
                                        SizedBox(height: 50,)
                                      ],
                                    )
                                    : Padding(
                                        padding: EdgeInsets.fromLTRB(buttonPadding, buttonPadding, buttonPadding, 80.0),
                                        child: Column(
                                          children: [
                                            eventController
                                                    .currentEvent.value.finalized
                                                ? SizedBox.shrink()
                                                : TextButton.icon(
                                                    onPressed: () async {
                                                      if (editModeOn) {
                                                        ///save
                                                        // Use non-blocking save to prevent delays when offline
                                                        eventController.saveEventWithOfflineSupport(
                                                          eventController.currentEvent.value
                                                        );
                                                      } else {}
                                                      _.meshulashEditModeOn.value =
                                                          !_.meshulashEditModeOn
                                                              .value;
                                                      setState(() {
                                                        editModeOn = !_
                                                            .meshulashEditModeOn
                                                            .value;
                                                      });
                                                    },
                                                    icon: editModeOn
                                                        ? const Icon(Icons.save)
                                                        : const Icon(Icons.edit),
                                                    label: editModeOn
                                                        ? Text('סיים',
                                                          style: TextStyle(fontWeight: FontWeight.bold,fontSize: scaledFontSize),
                                                        )
                                                        : Text('עריכה',
                                                          style: TextStyle(fontWeight: FontWeight.bold,fontSize: scaledFontSize),
                                                        ),
                                                    iconAlignment:
                                                        IconAlignment.start,
                                                  ),
                                            SizedBox(
                                              height: 20,
                                            ),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                foregroundColor: Colors.white,
                                                minimumSize: tablet ? Size(200, 60) : null,
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ExerciseGradingPage(exerciseType: 'meshulash'),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.grade),
                                              label: Text('ציון התרגיל',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: scaledFontSize),
                                              ),
                                            ),
                                            SizedBox(height: 20),
                                            Text('  התרגיל הסתיים  ',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: scaledFontSize),
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
                          child: Text('אין נתונים',
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
