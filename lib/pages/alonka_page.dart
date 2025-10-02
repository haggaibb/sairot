import 'package:flutter/material.dart';
import 'package:sairot/models/alonka_sprint.dart';
import 'package:sairot/models/types.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../widgets/alonka_round_panel.dart';
import 'dart:async';
import '../widgets/yes_no.dart';

class AlonkaPage extends StatefulWidget {
  const AlonkaPage({super.key});

  @override
  State<AlonkaPage> createState() => _AlonkaPageState();
}

class _AlonkaPageState extends State<AlonkaPage> {
  final eventController = Get.put(EventController());
  int runTime = 0;
  late Timer _timer;
  final ScrollController _scrollController = ScrollController();
  bool inOrderOfArrival = true;

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
        _scrollController.position.maxScrollExtent - 200,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  void sortActiveList() {

  }


  @override
  void dispose() {
    if (eventController.currentEvent.value.alonkaEndTime == null)
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
            title: Text('אלונקה'),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    inOrderOfArrival = !inOrderOfArrival; // Toggle state
                    List<int> activeList = eventController.currentEvent.value
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
                    eventController.currentEvent.value.alonkaSprints[eventController.currentEvent.value.alonkaSprints.length-1].activeParticipants = activeList;
                    eventController.update();
                  });
                },
                icon: Icon(
                  Icons.directions_walk_sharp,
                  color: inOrderOfArrival
                      ? Colors.green
                      : Colors.grey, // Switch color
                  size: 32,
                ),
              )
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
          body: GetX<EventController>(builder: (_) {
            return SingleChildScrollView(
              controller: _scrollController,
              child: Center(
                child: Column(
                  children: [
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
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                                onPressed: () async {
                                  //setState(() async {
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
                                  _.currentEvent.value.alonkaStartTime != null
                                      ? 'התחל סיבוב חדש (צא)'
                                      : 'תחילת תרגיל',
                                  style: TextStyle(
                                      fontSize:
                                          eventController.userFontSize.value,
                                      fontWeight: FontWeight.bold),
                                ))
                            : SizedBox.shrink()),
                    SizedBox(
                      height: 100,
                    ),
                    _.currentEvent.value.alonkaEndTime == null &&
                            _.currentEvent.value.alonkaStartTime != null
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
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
                                  fontSize: eventController.userFontSize.value),
                            ))
                        : _.currentEvent.value.alonkaEndTime != null
                            ? Text(
                                '  התרגיל הסתיים  ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        eventController.userFontSize.value),
                              )
                            : SizedBox.shrink(),
                    SizedBox(
                      height: 80,
                    ),
                  ],
                ),
              ),
            );
          })),
    );
  }
}
