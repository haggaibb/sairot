import 'package:flutter/material.dart';
import 'package:sairot/models/participant.dart';
import '../models/types.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../models/bur.dart';
import '../widgets/bur_grade_panel.dart';
import 'dart:async';
import '../widgets/yes_no.dart';
import '../widgets/guideWebView.dart';

class BurPage extends StatefulWidget {
  const BurPage({super.key});

  @override
  State<BurPage> createState() => _BurPageState();
}

class _BurPageState extends State<BurPage> {
  final eventController = Get.put(EventController());
  int runTime = 0;
  late Timer _timer;

  @override
  void initState() {
    // Removed debug print of bur IDs
    runTime = eventController.currentEvent.value.getBurRunTime();
    if (eventController.currentEvent.value.burEndTime == null) {
      _timer = Timer.periodic(Duration(seconds: 30), (Timer timer) {
        setState(() {
          runTime = eventController.currentEvent.value.getBurRunTime();
        });
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    if (eventController.currentEvent.value.burEndTime == null)
      _timer.cancel(); // Stop timer when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Color.fromARGB(255, 0, 66, 136)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Scaffold(
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
                  )
                ],
              ),
              body: GetX<EventController>(builder: (_) {
                var h =
                    eventController.currentEvent.value.activeParticipants.length /
                            3 +
                        2;
                return SingleChildScrollView(
                  child: eventController.currentEvent.value.burGrades.isNotEmpty
                      ? Center(
                          child: Obx(() => eventController.loading.value
                              ? LinearProgressIndicator()
                              : Column(
                                  children: [
                                    SizedBox(
                                      height: 20,
                                    ),
                                    SizedBox(
                                      height: h < 2 ? 120 : h * 55,
                                      child: GridView.count(
                                          childAspectRatio: eventController.userChildAspectRatio.value,
                                          crossAxisCount:
                                              eventController.numberOfCols,
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
                                            return Padding(
                                              padding: const EdgeInsets.all(5.0),
                                              child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                      foregroundColor: Colors.black,
                                                      backgroundColor:
                                                          eventController
                                                                      .currentEvent
                                                                      .value
                                                                      .burGrades[
                                                                          burIndex]
                                                                      .burGrade !=
                                                                  0
                                                              ? Colors.green
                                                              : Theme.of(context).colorScheme.primary,),
                                                  onPressed: () async {
                                                    if (eventController
                                                        .currentEvent
                                                        .value
                                                        .finalized) return;
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

                                                  )),
                                            );
                                          })),
                                    ),
                                    const Divider(
                                      thickness: 30,
                                    ),
                                    _.currentEvent.value.burEndTime == null
                                        ? Padding(
                                            padding: const EdgeInsets.all(30.0),
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
                                                    _timer.cancel();
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
                                                  : SizedBox.shrink()
                                            ],
                                          ),
                                  ],
                                )),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 200),
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
                                      _.currentEvent.value.saveToFirestore();
                                      _.currentEvent.refresh();
                                      _.loading.value = false;
                                      //});
                                    },
                                    child: Text(
                                      'תחילת תרגיל',
                                      style: TextStyle(fontSize: eventController.userFontSize.value,fontWeight: FontWeight.bold),
                                    ))),
                          ),
                        ),
                );
              })),
        ));
  }
}
