import 'package:flutter/material.dart';
import 'models/types.dart';
import 'ctx.dart';
import 'package:get/get.dart';
import 'models/meshulash_round.dart';
import 'widgets/meshulash_round_panel.dart';
import 'dart:async';

class MeshulashPage extends StatefulWidget {
  const MeshulashPage({super.key});

  @override
  State<MeshulashPage> createState() => _MeshulashPageState();
}

class _MeshulashPageState extends State<MeshulashPage> {
  final eventController = Get.put(Controller());
  int runTime = 0;
  late Timer _timer;
  late bool editModeOn;
  @override
  void initState() {
    if (eventController.currentEvent.value.meshulashEndTime != null) {
      eventController.meshulashEditModeOn.value = false;
      editModeOn = eventController.meshulashEditModeOn.value;
    } else {
      eventController.meshulashEditModeOn.value = true;
      editModeOn = eventController.meshulashEditModeOn.value;
    }
    runTime = eventController.currentEvent.value.getMeshulashRunTime();
    if (eventController.currentEvent.value.meshulashEndTime==null) {
      _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
        setState(() {
          runTime = eventController.currentEvent.value.getMeshulashRunTime();
        });
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    if (eventController.currentEvent.value.meshulashEndTime==null) _timer.cancel(); // Stop timer when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Column(
            children: [
              Text('משולש'),
              Text(style: TextStyle(fontSize: 12), 'משך התרגיל $runTime דקות '),
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
          return SingleChildScrollView(
            child: eventController.currentEvent.value.meshulashRounds.isNotEmpty
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
                                    _.currentEvent.value.meshulashRounds.length,
                                    (index) {
                                  return Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child:
                                        Obx(() => eventController.loading.value
                                            ? CircularProgressIndicator()
                                            : MeshulashRoundPanel(
                                                round: _.currentEvent.value
                                                    .meshulashRounds[index],
                                              )),
                                  );
                                }),
                              ),
                              const Divider(
                                thickness: 30,
                              ),
                              eventController.currentEvent.value
                                          .meshulashEndTime ==
                                      null
                                  ? Padding(
                                      padding: const EdgeInsets.all(30.0),
                                      child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            fixedSize: const Size(150, 20),
                                          ),
                                          onPressed: () async {
                                            setState(() {
                                              eventController.currentEvent.value
                                                      .meshulashEndTime =
                                                  DateTime.now();
                                            });
                                            await eventController.currentEvent.value
                                                .saveToFirestore();
                                            _timer.cancel();
                                            _.meshulashEditModeOn.value = false;
                                            editModeOn =
                                                _.meshulashEditModeOn.value;
                                          },
                                          child: Text('סיום התרגיל')),
                                    )
                                  : Column(
                                    children: [
                                      eventController.currentEvent.value.finalized?SizedBox.shrink():TextButton.icon(
                                          onPressed: () async {
                                            if (editModeOn) {
                                              ///save
                                              await eventController.currentEvent.value
                                                  .saveToFirestore();
                                            } else {}
                                            _.meshulashEditModeOn.value =
                                                !_.meshulashEditModeOn.value;
                                            setState(() {
                                              editModeOn =
                                                  _.meshulashEditModeOn.value;
                                            });
                                          },
                                          icon: editModeOn
                                              ? const Icon(Icons.save)
                                              : const Icon(Icons.edit),
                                          label: editModeOn
                                              ? const Text('סיים')
                                              : const Text('עריכה'),
                                          iconAlignment: IconAlignment.start,
                                        ),
                                      SizedBox(height: 20,),
                                      Text('  התרגיל הסתיים  '),
                                    ],
                                  ),
                            ],
                          )),
                  )
                : Obx(() => eventController.loading.value
                ? SizedBox(height: 100, width: 100,child: CircularProgressIndicator(),)
                : Padding(
              padding: const EdgeInsets.only(top: 200),
              child: Column(
                children: [
                  Obx(() => eventController.loading.value
                      ? SizedBox(width: 100, child: LinearProgressIndicator(),)
                      : SizedBox.shrink()
                  ),
                  Center(
                    child: Obx(() =>  eventController.loading.value
                        ? SizedBox(height: 100, width: 100,child: CircularProgressIndicator(),)
                        : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            fixedSize: const Size(200, 40)),
                        onPressed: () async {
                          setState(() {
                            eventController.loading.value = true;
                            eventController.currentEvent.value.meshulashStartTime = DateTime.now();
                            _.currentEvent.value.meshulashRounds.add(MeshulashRound(
                                    round: 0,
                                    participantsInRound: _.currentEvent.value
                                        .getParticipantsByStatus(
                                        ParticipantStatus.Active)
                                        .map((participant) =>
                                    participant.number)
                                        .toList()));
                            eventController.loading.value = false;
                          });
                          _.currentEvent.value.saveToFirestore();
                        },
                        child: const Text(
                          'תחילת תרגיל',
                          style: TextStyle(fontSize: 14),
                        ))
                    ),
                  ),
                ],
              ),
            )
            ),
          );
        }));
  }
}
