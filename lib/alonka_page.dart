import 'package:flutter/material.dart';
import 'package:sairot/models/alonka_sprint.dart';
import 'package:sairot/models/types.dart';
import 'ctx.dart';
import 'package:get/get.dart';
import 'widgets/alonka_round_panel.dart';
import 'dart:async';
import 'widgets/yes_no.dart';

class AlonkaPage extends StatefulWidget {
  const AlonkaPage({super.key});

  @override
  State<AlonkaPage> createState() => _AlonkaPageState();
}

class _AlonkaPageState extends State<AlonkaPage> {
  final eventController = Get.put(Controller());
  int runTime = 0;
  late Timer _timer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
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
  void dispose() {
    if (eventController.currentEvent.value.alonkaEndTime == null)
      _timer.cancel(); // Stop timer when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('אלונקה'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back), // 🔄 Custom back arrow
            onPressed: () {
              print("Back button pressed!"); // ✅ Add your custom logic here
              eventController.loading.value = true;
              Get.back(); // ⬅️ Go back using GetX
              eventController.loading.value = false;
            },
          ),
        ),
        body: GetX<Controller>(builder: (_) {
          return SingleChildScrollView(
            controller: _scrollController,
            child: Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(' דקות  '),
                      Text(runTime.toString()),
                      Text('  משך התרגיל  ')
                    ],
                  ),
                  SizedBox(
                    height: 15,
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
                  const Divider(
                    thickness: 30,
                  ),
                  Obx(() => eventController.loading.value
                      ? SizedBox(
                          height: 100,
                          width: 100,
                          child: CircularProgressIndicator(),
                        )
                      : _.currentEvent.value.alonkaEndTime == null
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  fixedSize: const Size(200, 40)),
                              onPressed: () async {
                                //setState(() async {
                                _.loading.value = true;
                                _.currentAlonkaRound.value =
                                    _.currentEvent.value.alonkaSprints.length;
                                if (_.currentEvent.value.alonkaSprints.isEmpty)
                                  eventController.currentEvent.value
                                      .alonkaStartTime = DateTime.now();
                                _.currentEvent.value.alonkaSprints.add(
                                    AlonkaSprint(
                                        round:
                                            _.currentEvent.value.alonkaSprints
                                                .length,
                                        activeParticipants: _
                                            .currentEvent.value
                                            .getParticipantsByStatus(
                                                ParticipantStatus.Active)
                                            .map((participant) =>
                                                participant.number)
                                            .toList()));
                                _.loading.value = false;
                                _scrollToEnd();
                                _.currentEvent.value.saveToFirestore();
                                //})
                              },
                              child: Text(
                                _.currentEvent.value.alonkaStartTime != null
                                    ? 'התחל סיבוב חדש (צא)'
                                    : 'תחילת תרגיל',
                                style: TextStyle(fontSize: 14),
                              ))
                          : SizedBox.shrink()),
                  SizedBox(
                    height: 100,
                  ),
                  _.currentEvent.value.alonkaEndTime == null &&
                          _.currentEvent.value.alonkaStartTime != null
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            fixedSize: const Size(150, 20),
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
                          child: Text('סיום התרגיל'))
                      : _.currentEvent.value.alonkaEndTime != null
                          ? Text('  התרגיל הסתיים  ')
                          : SizedBox.shrink(),
                  SizedBox(
                    height: 80,
                  ),
                ],
              ),
            ),
          );
        }));
  }
}
