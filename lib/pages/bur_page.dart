import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sairot/models/participant.dart';
import '../models/types.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../models/bur.dart';
import '../widgets/bur_grade_panel.dart';
import 'dart:async';
import '../widgets/yes_no.dart';
import '../widgets/guideWebView.dart';
import '../utils/tablet_utils.dart';
import '../services/exercise_context_service.dart';
import '../services/user_preferences_service.dart';
import '../widgets/floating_ptt_button.dart';
import '../widgets/wifi_settings_button.dart';
import '../mixins/event_validation_mixin.dart';

class BurPage extends StatefulWidget {
  const BurPage({super.key});

  @override
  State<BurPage> createState() => _BurPageState();
}

class _BurPageState extends State<BurPage> with EventValidationMixin {
  final eventController = Get.put(EventController());
  int runTime = 0;
  Timer? _timer;
  bool _floatingPttEnabled = false;
  bool _volumeButtonPttEnabled = false;

  @override
  void initState() {
    super.initState();
    checkEventValidity();
    // Set exercise context for STT
    ExerciseContextService().setCurrentExercise('bur');
    _loadSttPreferences();
    
    // Removed debug print of bur IDs
    runTime = eventController.currentEvent.value.getBurRunTime();
    if (eventController.currentEvent.value.burEndTime == null) {
      _timer?.cancel();
      _timer = Timer.periodic(Duration(seconds: 30), (Timer timer) {
        setState(() {
          runTime = eventController.currentEvent.value.getBurRunTime();
        });
      });
    }
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
    // Clear exercise context when leaving page
    ExerciseContextService().clearExercise();
    
    _timer?.cancel(); // Stop timer when widget is disposed
    
    // Restore portrait-only orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            eventController.loading.value = true;
            Get.back();
            eventController.loading.value = false;
          }
        },
        child: Container(
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
                    Text('בור'),
                    Text(
                        style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold),
                        'משך התרגיל $runTime דקות '),
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
                    icon: const Icon(Icons.info_outline),
                    tooltip: 'מדריך למשתמש',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => Directionality(
                          textDirection: TextDirection.rtl,
                          child: const ManualWebView(
                            url: 'https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000&slide=id.g384f00aea19_0_106',
                            //https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000
                          ),
                        ),
                      );
                    },
                  ),
                  WifiSettingsButton(),
                ],
              ),
              body: GetX<EventController>(builder: (_) {
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
                
                return eventController.currentEvent.value.burGrades.isNotEmpty
                      ? tablet 
                        ? Obx(() => eventController.loading.value
                            ? LinearProgressIndicator()
                            : isLandscape
                              ? SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 20,
                                      ),
                                      Obx(() {
                                        // Access burGrades inside Obx to make it reactive
                                        return GridView.count(
                                          shrinkWrap: true,
                                          physics: NeverScrollableScrollPhysics(),
                                          childAspectRatio: eventController.userChildAspectRatio.value,
                                          crossAxisCount: 4,
                                          children: List.generate(
                                              eventController
                                                  .currentEvent
                                                  .value
                                                  .activeParticipants
                                                  .length, (index) {
                                            int burIndex = eventController
                                                .currentEvent.value.burGrades
                                                .indexWhere((Bur bur) =>
                                                    bur.id ==
                                                    eventController
                                                        .currentEvent
                                                        .value
                                                        .activeParticipants[index]
                                                        .number);
                                            // Check if participant has a bur grade entry
                                            bool hasBurGrade = burIndex != -1 && 
                                                burIndex < eventController.currentEvent.value.burGrades.length;
                                            double burGrade = hasBurGrade 
                                                ? eventController.currentEvent.value.burGrades[burIndex].burGrade 
                                                : 0.0;
                                            return Padding(
                                              padding: EdgeInsets.all(7.5),
                                              child: Obx(() => ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                      foregroundColor: Colors.black,
                                                      backgroundColor:
                                                          burGrade != 0
                                                              ? Colors.green
                                                              : Theme.of(context).colorScheme.primary,),
                                                  onPressed: eventController.currentEvent.value.burEndTime != null ? null : () async {
                                                    if (eventController
                                                        .currentEvent
                                                        .value
                                                        .finalized) return;
                                                    if (!hasBurGrade) return; // Don't navigate if no bur grade entry
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              BurGradePanel(
                                                                  bur: eventController
                                                                          .currentEvent
                                                                          .value
                                                                          .burGrades[
                                                                      burIndex])),
                                                    );
                                                  },
                                                  child: Text(eventController
                                                      .currentEvent
                                                      .value
                                                      .activeParticipants[index]
                                                      .number
                                                      .toString(),
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: scaledFontSize),

                                                  ))),
                                            );
                                          }),
                                        );
                                      }),
                                      if (!isLandscape)
                                        Divider(
                                          thickness: dividerThickness,
                                        ),
                                      _.currentEvent.value.burEndTime == null
                                          ? Padding(
                                              padding: EdgeInsets.all(buttonPadding),
                                              child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                                    minimumSize: Size(200, 60),
                                                  ),
                                                  onPressed: () async {
                                                    var res = await showDialog(
                                                      context: context,
                                                      builder:
                                                          (BuildContext context) {
                                                        return YesNoDialog();
                                                      },
                                                    );
                                                    if (res) {
                                                      eventController.loading.value =
                                                      true;
                                                      setState(() {
                                                        _.currentEvent.value
                                                            .burEndTime =
                                                            DateTime.now();
                                                      });
                                                      _timer?.cancel();
                                                      // Use non-blocking save to prevent delays when offline
                                                      eventController.saveEventWithOfflineSupport(
                                                        eventController.currentEvent.value
                                                      );
                                                      eventController.loading.value =
                                                      false;
                                                    }
                                                  },
                                                  //eventController.currentEvent.value.save();
                                                  child: Text('סיום התרגיל',
                                                    style: TextStyle(fontWeight: FontWeight.bold,fontSize: scaledFontSize),
                                                  )),
                                            )
                                          : Column(
                                              children: [
                                                SizedBox(
                                                  height: 20,
                                                ),
                                                Text('  התרגיל הסתיים  ',
                                                  style: TextStyle(fontWeight: FontWeight.bold,fontSize: scaledFontSize),
                                                ),
                                                SizedBox(
                                                  height: 20,
                                                ),
                                                eventController.currentEvent.value
                                                                .burEndTime !=
                                                            null &&
                                                        eventController.currentEvent
                                                                .value.burGrades
                                                                .where((item) =>
                                                                    item.burGrade >
                                                                    0)
                                                                .length <
                                                            eventController
                                                                .currentEvent
                                                                .value
                                                                .burGrades
                                                                .length
                                                    ? Text(
                                                        '  ${eventController.currentEvent.value.burGrades.where((item) => item.burGrade <= 0).length}  משתתפים לא קיבלו ציון סופי ',
                                                        textDirection:
                                                            TextDirection.rtl,
                                                        style: TextStyle(
                                                            color: Colors.red,
                                                          fontWeight: FontWeight.bold,
                                                            fontSize: scaledFontSize
                                                        ),
                                                      )
                                                    : SizedBox.shrink(),
                                                SizedBox(
                                                  height: 20,
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(buttonPadding),
                                                  child: ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.orange,
                                                        foregroundColor: Colors.white,
                                                        minimumSize: Size(200, 60),
                                                      ),
                                                      onPressed: () async {
                                                        var res = await showDialog(
                                                          context: context,
                                                          builder:
                                                              (BuildContext context) {
                                                            return YesNoDialog();
                                                          },
                                                        );
                                                        if (res) {
                                                          eventController.loading.value =
                                                          true;
                                                          setState(() {
                                                            _.currentEvent.value
                                                                .burEndTime = null;
                                                          });
                                                          // Trigger reactive update
                                                          _.currentEvent.refresh();
                                                          _.update();
                                                          // Restart timer
                                                          _timer?.cancel();
                                                          _timer = Timer.periodic(Duration(seconds: 30), (Timer timer) {
                                                            setState(() {
                                                              runTime = eventController.currentEvent.value.getBurRunTime();
                                                            });
                                                          });
                                                          // Use non-blocking save to prevent delays when offline
                                                          eventController.saveEventWithOfflineSupport(
                                                            eventController.currentEvent.value
                                                          );
                                                          eventController.loading.value =
                                                          false;
                                                        }
                                                      },
                                                      child: Text('פתיחה מחדש לעריכה',
                                                        style: TextStyle(fontWeight: FontWeight.bold,fontSize: scaledFontSize),
                                                      )),
                                                ),
                                              ],
                                            ),
                                    ],
                                  ),
                                )
                              : Column(
                                children: [
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Expanded(
                                    child: GridView.count(
                                        childAspectRatio: eventController.userChildAspectRatio.value,
                                        crossAxisCount: eventController.numberOfCols,
                                        children: List.generate(
                                            eventController
                                                .currentEvent
                                                .value
                                                .activeParticipants
                                                .length, (index) {
                                          int burIndex = eventController
                                              .currentEvent.value.burGrades
                                              .indexWhere((Bur bur) =>
                                                  bur.id ==
                                                  eventController
                                                      .currentEvent
                                                      .value
                                                      .activeParticipants[index]
                                                      .number);
                                          // Check if participant has a bur grade entry
                                          bool hasBurGrade = burIndex != -1 && 
                                              burIndex < eventController.currentEvent.value.burGrades.length;
                                          double burGrade = hasBurGrade 
                                              ? eventController.currentEvent.value.burGrades[burIndex].burGrade 
                                              : 0.0;
                                          return Padding(
                                            padding: EdgeInsets.all(7.5),
                                            child: Obx(() => ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                    foregroundColor: Colors.black,
                                                    backgroundColor:
                                                        burGrade != 0
                                                            ? Colors.green
                                                            : Theme.of(context).colorScheme.primary,),
                                                onPressed: eventController.currentEvent.value.burEndTime != null ? null : () async {
                                                  if (eventController
                                                      .currentEvent
                                                      .value
                                                      .finalized) return;
                                                  if (!hasBurGrade) return; // Don't navigate if no bur grade entry
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            BurGradePanel(
                                                                bur: eventController
                                                                        .currentEvent
                                                                        .value
                                                                        .burGrades[
                                                                    burIndex])),
                                                  );
                                                },
                                                child: Text(eventController
                                                    .currentEvent
                                                    .value
                                                    .activeParticipants[index]
                                                    .number
                                                    .toString(),
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: scaledFontSize),

                                                ))),
                                          );
                                        })),
                                  ),
                                  Divider(
                                    thickness: dividerThickness,
                                  ),
                                  _.currentEvent.value.burEndTime == null
                                      ? Padding(
                                          padding: EdgeInsets.all(buttonPadding),
                                          child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Theme.of(context).colorScheme.primary,
                                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                                minimumSize: Size(200, 60),
                                              ),
                                              onPressed: () async {
                                                var res = await showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return YesNoDialog();
                                                  },
                                                );
                                                if (res) {
                                                  eventController.loading.value =
                                                  true;
                                                  setState(() {
                                                    _.currentEvent.value
                                                        .burEndTime =
                                                        DateTime.now();
                                                  });
                                                  _timer?.cancel();
                                                  eventController
                                                      .currentEvent.value
                                                      .saveToFirestore();
                                                  eventController.loading.value =
                                                  false;
                                                }
                                              },
                                              //eventController.currentEvent.value.save();
                                              child: Text('סיום התרגיל',
                                                style: TextStyle(fontWeight: FontWeight.bold,fontSize: scaledFontSize),
                                              )),
                                        )
                                      : Column(
                                          children: [
                                            SizedBox(
                                              height: 20,
                                            ),
                                            Text('  התרגיל הסתיים  ',
                                              style: TextStyle(fontWeight: FontWeight.bold,fontSize: scaledFontSize),
                                            ),
                                            SizedBox(
                                              height: 20,
                                            ),
                                            eventController.currentEvent.value
                                                            .burEndTime !=
                                                        null &&
                                                    eventController.currentEvent
                                                            .value.burGrades
                                                            .where((item) =>
                                                                item.burGrade >
                                                                0)
                                                            .length <
                                                        eventController
                                                            .currentEvent
                                                            .value
                                                            .burGrades
                                                            .length
                                                ? Text(
                                                    '  ${eventController.currentEvent.value.burGrades.where((item) => item.burGrade <= 0).length}  משתתפים לא קיבלו ציון סופי ',
                                                    textDirection:
                                                        TextDirection.rtl,
                                                    style: TextStyle(
                                                        color: Colors.red,
                                                      fontWeight: FontWeight.bold,
                                                        fontSize: scaledFontSize
                                                    ),
                                                  )
                                                : SizedBox.shrink(),
                                            SizedBox(
                                              height: 20,
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(buttonPadding),
                                              child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.orange,
                                                    foregroundColor: Colors.white,
                                                    minimumSize: Size(200, 60),
                                                  ),
                                                      onPressed: () async {
                                                        var res = await showDialog(
                                                          context: context,
                                                          builder:
                                                              (BuildContext context) {
                                                            return YesNoDialog();
                                                          },
                                                        );
                                                        if (res) {
                                                          eventController.loading.value =
                                                          true;
                                                          setState(() {
                                                            _.currentEvent.value
                                                                .burEndTime = null;
                                                          });
                                                          // Trigger reactive update
                                                          _.currentEvent.refresh();
                                                          _.update();
                                                          // Restart timer
                                                          _timer = Timer.periodic(Duration(seconds: 30), (Timer timer) {
                                                            setState(() {
                                                              runTime = eventController.currentEvent.value.getBurRunTime();
                                                            });
                                                          });
                                                          // Use non-blocking save to prevent delays when offline
                                                          eventController.saveEventWithOfflineSupport(
                                                            eventController.currentEvent.value
                                                          );
                                                          eventController.loading.value =
                                                          false;
                                                        }
                                                      },
                                                  child: Text('פתיחה מחדש לעריכה',
                                                    style: TextStyle(fontWeight: FontWeight.bold,fontSize: scaledFontSize),
                                                  )),
                                            ),
                                          ],
                                        ),
                                ],
                              ))
                        : SingleChildScrollView(
                            child: Center(
                              child: Obx(() => eventController.loading.value
                                  ? LinearProgressIndicator()
                                  : Column(
                                      children: [
                                        SizedBox(
                                          height: 20,
                                        ),
                                        SizedBox(
                                          height: (eventController.currentEvent.value.activeParticipants.length / 3 + 2) < 2 
                                              ? 120 
                                              : ((eventController.currentEvent.value.activeParticipants.length / 3 + 2) * 55 * 0.8), // 20% smaller
                                          child: Obx(() {
                                            // Access burGrades inside Obx to make it reactive
                                            return GridView.count(
                                              childAspectRatio: eventController.userChildAspectRatio.value,
                                              crossAxisCount: isLandscape && tablet ? 4 : eventController.numberOfCols,
                                              children: List.generate(
                                                  eventController
                                                      .currentEvent
                                                      .value
                                                      .activeParticipants
                                                      .length, (index) {
                                                int burIndex = eventController
                                                    .currentEvent.value.burGrades
                                                    .indexWhere((Bur bur) =>
                                                        bur.id ==
                                                        eventController
                                                            .currentEvent
                                                            .value
                                                            .activeParticipants[index]
                                                            .number);
                                                // Check if participant has a bur grade entry
                                                bool hasBurGrade = burIndex != -1 && 
                                                    burIndex < eventController.currentEvent.value.burGrades.length;
                                                double burGrade = hasBurGrade 
                                                    ? eventController.currentEvent.value.burGrades[burIndex].burGrade 
                                                    : 0.0;
                                                return Padding(
                                                  padding: const EdgeInsets.all(5.0),
                                                  child: Obx(() => ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                          foregroundColor: Colors.black,
                                                          backgroundColor:
                                                              burGrade != 0
                                                                  ? Colors.green
                                                                  : Theme.of(context).colorScheme.primary,),
                                                      onPressed: eventController.currentEvent.value.burEndTime != null ? null : () async {
                                                        if (eventController
                                                            .currentEvent
                                                            .value
                                                            .finalized) return;
                                                        if (!hasBurGrade) return; // Don't navigate if no bur grade entry
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  BurGradePanel(
                                                                      bur: eventController
                                                                              .currentEvent
                                                                              .value
                                                                              .burGrades[
                                                                          burIndex])),
                                                        );
                                                      },
                                                      child: Text(eventController
                                                          .currentEvent
                                                          .value
                                                          .activeParticipants[index]
                                                          .number
                                                          .toString(),
                                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value),

                                                      ))),
                                                );
                                              }),
                                            );
                                          }),
                                        ),
                                        Divider(
                                          thickness: dividerThickness,
                                        ),
                                        _.currentEvent.value.burEndTime == null
                                            ? Padding(
                                                padding: EdgeInsets.all(buttonPadding),
                                                child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                                    ),
                                                    onPressed: () async {
                                                      var res = await showDialog(
                                                        context: context,
                                                        builder:
                                                            (BuildContext context) {
                                                          return YesNoDialog();
                                                        },
                                                      );
                                                      if (res) {
                                                        eventController.loading.value =
                                                        true;
                                                        setState(() {
                                                          _.currentEvent.value
                                                              .burEndTime =
                                                              DateTime.now();
                                                        });
                                                        _timer?.cancel();
                                                        eventController
                                                            .currentEvent.value
                                                            .saveToFirestore();
                                                        eventController.loading.value =
                                                        false;
                                                      }
                                                    },
                                                    //eventController.currentEvent.value.save();
                                                    child: Text('סיום התרגיל',
                                                      style: TextStyle(fontWeight: FontWeight.bold,fontSize: eventController.userFontSize.value),
                                                    )),
                                              )
                                            : Column(
                                                children: [
                                                  SizedBox(
                                                    height: 20,
                                                  ),
                                                  Text('  התרגיל הסתיים  ',
                                                    style: TextStyle(fontWeight: FontWeight.bold,fontSize: eventController.userFontSize.value),
                                                  ),
                                                  SizedBox(
                                                    height: 20,
                                                  ),
                                                  eventController.currentEvent.value
                                                                  .burEndTime !=
                                                              null &&
                                                          eventController.currentEvent
                                                                  .value.burGrades
                                                                  .where((item) =>
                                                                      item.burGrade >
                                                                      0)
                                                                  .length <
                                                              eventController
                                                                  .currentEvent
                                                                  .value
                                                                  .burGrades
                                                                  .length
                                                      ? Text(
                                                          '  ${eventController.currentEvent.value.burGrades.where((item) => item.burGrade <= 0).length}  משתתפים לא קיבלו ציון סופי ',
                                                          textDirection:
                                                              TextDirection.rtl,
                                                          style: TextStyle(
                                                              color: Colors.red,
                                                            fontWeight: FontWeight.bold,
                                                              fontSize: eventController.userFontSize.value
                                                          ),
                                                        )
                                                      : SizedBox.shrink(),
                                                  SizedBox(
                                                    height: 20,
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.all(buttonPadding),
                                                    child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.orange,
                                                          foregroundColor: Colors.white,
                                                        ),
                                                        onPressed: () async {
                                                          var res = await showDialog(
                                                            context: context,
                                                            builder:
                                                                (BuildContext context) {
                                                              return YesNoDialog();
                                                            },
                                                          );
                                                          if (res) {
                                                            eventController.loading.value =
                                                            true;
                                                            setState(() {
                                                              _.currentEvent.value
                                                                  .burEndTime = null;
                                                            });
                                                            // Trigger reactive update
                                                            _.currentEvent.refresh();
                                                            _.update();
                                                            // Restart timer
                                                            _timer = Timer.periodic(Duration(seconds: 30), (Timer timer) {
                                                              setState(() {
                                                                runTime = eventController.currentEvent.value.getBurRunTime();
                                                              });
                                                            });
                                                            // Use non-blocking save to prevent delays when offline
                                                            eventController.saveEventWithOfflineSupport(
                                                              eventController.currentEvent.value
                                                            );
                                                            eventController.loading.value =
                                                            false;
                                                          }
                                                        },
                                                        child: Text('פתיחה מחדש לעריכה',
                                                          style: TextStyle(fontWeight: FontWeight.bold,fontSize: eventController.userFontSize.value),
                                                        )),
                                                  ),
                                                ],
                                              ),
                                      ],
                                    )),
                            ),
                          )
                      : Padding(
                          padding: EdgeInsets.only(top: tablet ? 300 : 200),
                          child: Center(
                            child: Obx(() => eventController.loading.value
                                ? SizedBox(
                                    height: 100,
                                    width: 100,
                                    child: CircularProgressIndicator(),
                                  )
                                : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  minimumSize: tablet ? Size(200, 60) : null,
                                ),
                                    onPressed: () async {
                                      _.loading.value = true;
                                      //setState(() async {
                                      _.currentEvent.value.activeParticipants =
                                          [];
                                      for (Participant p in _.currentEvent.value
                                          .getParticipantsByStatus(
                                              ParticipantStatus.Active)) {
                                        _.currentEvent.value.activeParticipants
                                            .add(p);
                                        _.currentEvent.value.burGrades
                                            .add(Bur(id: p.number));
                                      }
                                      _.currentEvent.value.burStartTime =
                                          DateTime.now();
                                      // Use non-blocking save to prevent delays when offline
                                      eventController.saveEventWithOfflineSupport(
                                        _.currentEvent.value
                                      );
                                      _.currentEvent.refresh();
                                      _.loading.value = false;
                                      //});
                                    },
                                    child: Text(
                                      'תחילת תרגיל',
                                      style: TextStyle(fontSize: scaledFontSize,fontWeight: FontWeight.bold),
                                    ))),
                          ),
                        );
              }),
          ), // Scaffold closing
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
    );
  }
}
