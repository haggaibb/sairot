import 'package:flutter/material.dart';
import '../models/types.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../models/sakim_round.dart';
import '../widgets/sakim_round_panel.dart';
import 'dart:async';
import '../widgets/yes_no.dart';

class SakimPage extends StatefulWidget {
  const SakimPage({super.key});

  @override
  State<SakimPage> createState() => _SakimPageState();
}

class _SakimPageState extends State<SakimPage> {
  final eventController = Get.put(Controller());
  int runTime = 0;
  late Timer _timer;
  late bool editModeOn;
  final ScrollController _scrollController = ScrollController();

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
    if (eventController.currentEvent.value.sakimEndTime != null) {
      eventController.sakimEditModeOn.value = false;
      editModeOn = eventController.sakimEditModeOn.value;
    } else {
      eventController.sakimEditModeOn.value = true;
      editModeOn = eventController.sakimEditModeOn.value;
    }
    runTime = eventController.currentEvent.value.getSakimRunTime();
    if (eventController.currentEvent.value.sakimEndTime == null) {
      _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
        setState(() {
          runTime = eventController.currentEvent.value.getSakimRunTime();
          ;
        });
      });
    }
    _scrollToEnd();
    super.initState();
  }

  @override
  void dispose() {
    if (eventController.currentEvent.value.sakimEndTime == null)
      _timer.cancel(); // Stop timer when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text('שקים'),
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
          ),
          body: GetX<Controller>(builder: (_) {
            editModeOn = _.sakimEditModeOn.value;
            return SingleChildScrollView(
              controller: _scrollController,
              child: eventController.currentEvent.value.sakimRounds.isNotEmpty
                  ? Center(
                      child: Obx(() => eventController.loading.value
                          ? LinearProgressIndicator()
                          : Column(
                              children: [
                                SizedBox(
                                  height: 15,
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                      _.currentEvent.value.sakimRounds.length,
                                      (index) {
                                    return Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child:
                                          Obx(() => eventController.loading.value
                                              ? CircularProgressIndicator()
                                              : SakimRoundPanel(
                                                  round: _.currentEvent.value
                                                      .sakimRounds[index],
                                                )),
                                    );
                                  }),
                                ),
                                const Divider(
                                  thickness: 30,
                                ),
                                SizedBox(
                                  height: 50,
                                ),
                                eventController.currentEvent.value.sakimEndTime ==
                                        null
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
                                                builder: (BuildContext context) {
                                                  return YesNoDialog();
                                                },
                                              );
                                              if (res) {
                                                setState(() {
                                                  eventController.currentEvent.value
                                                      .sakimEndTime =
                                                      DateTime.now();
                                                  _timer.cancel();
                                                  _.sakimEditModeOn.value = false;
                                                  editModeOn =
                                                      _.sakimEditModeOn.value;
                                                  eventController.currentEvent.value
                                                      .saveToFirestore();
                                                });
                                              }
                                            },
                                            //eventController.currentEvent.value.save();
                                            child: Text('סיום התרגיל',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value),
                                            )),
                                      )
                                    : Column(
                                        children: [
                                          eventController
                                                  .currentEvent.value.finalized
                                              ? SizedBox.shrink()
                                              : TextButton.icon(
                                                  onPressed: () {
                                                    if (editModeOn) {
                                                      ///save
                                                      eventController
                                                          .currentEvent.value
                                                          .saveToFirestore();
                                                    } else {}
                                                    _.sakimEditModeOn.value =
                                                        !_.sakimEditModeOn.value;
                                                    setState(() {
                                                      editModeOn =
                                                          _.sakimEditModeOn.value;
                                                    });
                                                  },
                                                  icon: editModeOn
                                                      ? const Icon(Icons.save)
                                                      : const Icon(Icons.edit),
                                                  label: editModeOn
                                                      ? Text('סיים',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value),
                                                  )
                                                      : Text('עריכה',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value),
                                                  ),
                                                  iconAlignment:
                                                      IconAlignment.start,
                                                ),
                                          SizedBox(
                                            height: 20,
                                          ),
                                          Text('  התרגיל הסתיים  ',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value),
                                          ),
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
                            : Column(
                                children: [
                                  ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                      onPressed: () async {
                                        setState(() {
                                          eventController.currentEvent.value
                                              .sakimStartTime = DateTime.now();
                                          _.currentEvent.value.sakimRounds.add(
                                              SakimRound(
                                                  round: 0,
                                                  participantsInRound: _
                                                      .currentEvent.value
                                                      .getParticipantsByStatus(
                                                          ParticipantStatus
                                                              .Active)
                                                      .map((participant) =>
                                                          participant.number)
                                                      .toList()));
                                        });
                                        await _.currentEvent.value
                                            .saveToFirestore();
                                      },
                                      child: Text(
                                        'תחילת תרגיל',
                                        style: TextStyle(fontSize: eventController.userFontSize.value, fontWeight: FontWeight.bold),
                                      )),
                                ],
                              )),
                      ),
                    ),
            );
          })),
    );
  }
}
