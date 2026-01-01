import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sairot/models/participant.dart';
import '../models/types.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../widgets/comments_dialog.dart';
import '../widgets/guideWebView.dart';
import '../utils/tablet_utils.dart';
import '../services/exercise_context_service.dart';
import '../services/user_preferences_service.dart';
import '../widgets/floating_ptt_button.dart';
import '../mixins/event_validation_mixin.dart';


class InterviewPage extends StatefulWidget {
  const InterviewPage({super.key});

  @override
  State<InterviewPage> createState() => _InterviewPageState();
}

class _InterviewPageState extends State<InterviewPage> with EventValidationMixin {
  final eventController = Get.put(EventController());
  bool _floatingPttEnabled = false;
  bool _volumeButtonPttEnabled = false;

  @override
  void initState() {
    super.initState();
    checkEventValidity();
    // Set exercise context for STT
    ExerciseContextService().setCurrentExercise('interview');
    _loadSttPreferences();
    
    //setState(() async {
    eventController.currentEvent.value.activeParticipants = [];
    for (Participant p in eventController.currentEvent.value
        .getParticipantsByStatus(ParticipantStatus.Active)) {
      eventController.currentEvent.value.activeParticipants.add(p);
    }
    eventController.currentEvent.value.saveToFirestore();
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
              resizeToAvoidBottomInset: true,
              appBar: AppBar(
                //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                centerTitle: true,
                title: Text('ראיון אישי'),
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
                            url: 'https://docs.google.com/presentation/d/19SF_q3uXPt470mzfOKEorpoIORsOEEmQXL5_UUnelNo/preview?rm=minimal&slide=id.g384f00aea19_0_117',
                            //https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
              body: Obx(() => eventController.loading.value
                  ? LinearProgressIndicator()
                  : Column(
                      children: [
                        SizedBox(
                          height: 20,
                        ),
                        Expanded(
                          child: GridView.count(
                              childAspectRatio: eventController.userChildAspectRatio.value,
                              crossAxisCount: isLandscape && tablet ? 4 : eventController.numberOfCols,
                                children: List.generate(
                                    eventController
                                        .currentEvent
                                        .value
                                        .activeParticipants
                                        .length, (index) {
                                  ;
                                  return Padding(
                                    padding: EdgeInsets.all(tablet ? 7.5 : 5.0),
                                    child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.black,
                                            backgroundColor:
                                             eventController
                                                .currentEvent
                                                .value
                                                .activeParticipants[
                                            index]
                                                .interviewInstructorComments
                                                .isNotEmpty
                                                ? Colors.green
                                                : Theme.of(context).colorScheme.primary),
                                        onPressed: () async {
                                          if (eventController
                                              .currentEvent
                                              .value
                                              .finalized) return;
                                          var res = await showDialog<List<String>>(
                                              context: context,
                                              builder: (BuildContext context) =>
                                                  CommentsDialog(
                                                      commentsList: eventController.gradesData.listOfCommentsInterview,
                                                      selectedComments: eventController
                                                        .currentEvent
                                                        .value
                                                        .activeParticipants[index].interviewInstructorComments,
                                                    title: eventController
                                                        .currentEvent
                                                        .value
                                                        .activeParticipants[index]
                                                        .number.toString(),
                                                  ));
                                          if (res!=null) {
                                            if (res.contains(ParticipantStatus.Droped.name)) {
                                              eventController.loading.value =
                                              true;
                                              eventController.dropParticipant(
                                                  eventController
                                                      .currentEvent
                                                      .value
                                                      .activeParticipants[index]
                                                      .number);
                                              eventController.currentEvent.value.activeParticipants
                                                  .removeAt(index);
                                              eventController.loading.value=false;
                                            } else {
                                              eventController.addInterviewComments(res,eventController
                                                  .currentEvent
                                                  .value
                                                  .activeParticipants[index]
                                                  .number);                                          }
                                          }
                                        },
                                        child: Text(eventController
                                            .currentEvent
                                            .value
                                            .activeParticipants[index]
                                            .number
                                            .toString(),
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: scaledFontSize),
                                        )),
                                  );
                                })),
                          ),
                        Divider(
                          thickness: dividerThickness,
                        ),
                      ],
                    )),
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
