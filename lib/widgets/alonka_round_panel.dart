import 'package:flutter/material.dart';
import 'package:sairot/models/alonka_sprint.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../models/types.dart';
import 'comments_dialog.dart';
import 'alonka_credit_panel.dart';
import '../utils/tablet_utils.dart';

class AlonkaRoundPanel extends StatefulWidget {
  AlonkaRoundPanel({super.key, required this.round});
  final AlonkaSprint round;

  @override
  State<AlonkaRoundPanel> createState() => _AlonkaRoundPanelState();
}

class _AlonkaRoundPanelState extends State<AlonkaRoundPanel> {
  final eventController = Get.put(EventController());
  List<int> stillActiveInRound = [];

  @override
  void initState() {
    stillActiveInRound = eventController.currentEvent.value.participants
        .map((participant) => participant.number)
        .toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool tablet = isTablet(context);
    int crossAxisCount = tablet ? (eventController.numberOfCols + 1) : eventController.numberOfCols;
    double scaledFontSize = getTabletScaledFontSize(context, eventController.userFontSize.value);
    double dividerThickness = tablet ? 45.0 : 30.0;
    
    return GetX<EventController>(builder: (eventController) {
      eventController.currentAlonkaRound.value == widget.round.round;
      if (widget.round.activeParticipants.isNotEmpty) {
        var h = widget.round.activeParticipants.length / 3 + 2;
        double heightMultiplier = tablet ? 1.3 : 1.0;
        return SizedBox(
            height: h <= 3 ? (tablet ? 390 : 300) : (h * 80 * heightMultiplier),
            child: Center(
              child: Obx(() => eventController.loading.value
                  ? LinearProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Divider(
                          thickness: dividerThickness,
                        ),
                        Text('אלונקה  מקצה ${widget.round.round + 1}  ',
                            style: TextStyle(
                                fontSize: tablet ? 28.0 : 22.0, fontWeight: FontWeight.bold)),
                        Expanded(
                            child: GridView.count(
                                childAspectRatio:
                                    eventController.userChildAspectRatio.value,
                                crossAxisCount: crossAxisCount,
                                children: List.generate(
                                    widget.round.activeParticipants.length,
                                    (index) {
                                  return Padding(
                                    padding: EdgeInsets.all(tablet ? 7.5 : 5.0),
                                    child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          foregroundColor: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        ),
                                        onPressed: () async {
                                          var participantNumber = widget.round.activeParticipants[index];
                                          var res = await showDialog<
                                              AlonkaCreditTypes>(
                                            context: context,
                                            builder: (BuildContext context) =>
                                                AlonkaCreditPanel(participantNumber: participantNumber),
                                          );
                                          if (res != null) {
                                            switch (res) {
                                              case AlonkaCreditTypes.Alonka:
                                                setState(() {
                                                  widget.round.alonkaCredits
                                                      .add(widget.round
                                                              .activeParticipants[
                                                          index]);
                                                  widget
                                                      .round.activeParticipants
                                                      .removeAt(index);
                                                });
                                                break;
                                              case AlonkaCreditTypes.Gerikan:
                                                setState(() {
                                                  widget.round.gerikanCredits
                                                      .add(widget.round
                                                              .activeParticipants[
                                                          index]);
                                                  widget
                                                      .round.activeParticipants
                                                      .removeAt(index);
                                                });
                                                break;
                                              case AlonkaCreditTypes.Runner:
                                                setState(() {
                                                  widget.round.runCredits.add(
                                                      widget.round
                                                              .activeParticipants[
                                                          index]);
                                                  widget
                                                      .round.activeParticipants
                                                      .removeAt(index);
                                                });
                                                break;
                                              default:
                                            }
                                          }
                                        },
                                        onLongPress: () async {
                                          var participantNumber = widget.round.activeParticipants[index];
                                          var res = await showDialog<
                                                  List<String>>(
                                              context: context,
                                              builder: (BuildContext context) => CommentsDialog(
                                                  commentsList: eventController
                                                      .gradesData
                                                      .listOfCommentsAlonka,
                                                  selectedComments: (eventController
                                                          .getParticipant(participantNumber))
                                                      .alonkaInstructorComments,
                                                  title: participantNumber.toString(),
                                              ));
                                          if (res != null) {
                                            if (res.contains(ParticipantStatus.Droped.name)) {
                                              print('dropped');
                                              eventController.loading.value =
                                                  true;
                                              eventController.dropParticipant(
                                                  widget.round
                                                          .activeParticipants[
                                                      index]);
                                              widget.round.activeParticipants
                                                  .removeAt(index);
                                              eventController.loading.value=false;
                                            } else {
                                              eventController.addAlonkaComments(
                                                  res,
                                                  widget.round
                                                          .activeParticipants[
                                                      index]);
                                            }
                                          }
                                        },
                                        child: Text(
                                          widget.round.activeParticipants[index]
                                              .toString(),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: scaledFontSize),
                                        )),
                                  );
                                }))),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                            onPressed: () async {
                              eventController.widgetLoading.value = true;
                              for (var participantNumber
                                  in widget.round.activeParticipants) {
                                widget.round.participationCredits
                                    .add(participantNumber);
                              }

                              /// clear participants list
                              setState(() {
                                widget.round.activeParticipants = [];
                              });
                              eventController.currentEvent.value
                                      .alonkaSprints[widget.round.round] =
                                  widget.round;
                              //await eventController.currentEvent.value.saveToFirestore();
                              eventController.currentEvent.value.saveToFirestore();
                              setState(() {
                                eventController.widgetLoading.value = false;
                              });
                            },
                            child: Text(
                              'סיים',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: scaledFontSize),
                            )),
                        SizedBox(
                            height: 110,
                            child: Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Row(
                                    children: [
                                      Row(
                                          children: List.generate(1, (index) {
                                        return Padding(
                                          padding: const EdgeInsets.all(1.0),
                                          child: Row(
                                            children: widget.round.alonkaCredits
                                                .map((number) {
                                              return GestureDetector(
                                                onDoubleTap: () => setState(() {
                                                  widget.round.alonkaCredits
                                                      .remove(number);
                                                  widget
                                                      .round.activeParticipants
                                                      .add(number);
                                                  //widget.round.activeParticipants.sort();
                                                }),
                                                onLongPress: () async {
                                                  var res = await showDialog<List<String>>(
                                                    context: context,
                                                    builder: (BuildContext context) => CommentsDialog(
                                                      commentsList: eventController
                                                          .gradesData
                                                          .listOfCommentsAlonka,
                                                      selectedComments: (eventController
                                                              .getParticipant(number))
                                                          .alonkaInstructorComments,
                                                      title: number.toString(),
                                                    ),
                                                  );
                                                  if (res != null) {
                                                    if (res.contains(ParticipantStatus.Droped.name)) {
                                                      eventController.loading.value = true;
                                                      eventController.dropParticipant(number);
                                                      widget.round.alonkaCredits.remove(number);
                                                      eventController.loading.value = false;
                                                    } else {
                                                      eventController.addAlonkaComments(res, number);
                                                    }
                                                  }
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    '$number', // Convert the number to a string
                                                    style: TextStyle(
                                                        fontSize: tablet ? 28.0 : 20.0, // 40% bigger on tablets (20 * 1.4)
                                                        color:
                                                            Colors.orangeAccent,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              );
                                            }).toList(), // Convert the iterable to a list of widgets
                                          ),
                                        );
                                      })),
                                      const SizedBox(
                                        width: 25,
                                      ),
                                      Row(
                                          children: List.generate(1, (index) {
                                        return Padding(
                                          padding: const EdgeInsets.all(1.0),
                                          child: Row(
                                            children: widget
                                                .round.gerikanCredits
                                                .map((number) {
                                              return GestureDetector(
                                                onDoubleTap: () => setState(() {
                                                  widget.round.gerikanCredits
                                                      .remove(number);
                                                  widget
                                                      .round.activeParticipants
                                                      .add(number);
                                                  //widget.round.activeParticipants.sort();
                                                }),
                                                onLongPress: () async {
                                                  var res = await showDialog<List<String>>(
                                                    context: context,
                                                    builder: (BuildContext context) => CommentsDialog(
                                                      commentsList: eventController
                                                          .gradesData
                                                          .listOfCommentsAlonka,
                                                      selectedComments: (eventController
                                                              .getParticipant(number))
                                                          .alonkaInstructorComments,
                                                      title: number.toString(),
                                                    ),
                                                  );
                                                  if (res != null) {
                                                    if (res.contains(ParticipantStatus.Droped.name)) {
                                                      eventController.loading.value = true;
                                                      eventController.dropParticipant(number);
                                                      widget.round.gerikanCredits.remove(number);
                                                      eventController.loading.value = false;
                                                    } else {
                                                      eventController.addAlonkaComments(res, number);
                                                    }
                                                  }
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    '$number', // Convert the number to a string
                                                    style: TextStyle(
                                                        fontSize: tablet ? 28.0 : 20.0, // 40% bigger on tablets (20 * 1.4)
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              );
                                            }).toList(), // Convert the iterable to a list of widgets
                                          ),
                                        );
                                      })),
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 25,
                                  ),
                                  Row(
                                      children: List.generate(1, (index) {
                                    return Padding(
                                      padding: const EdgeInsets.all(1.0),
                                      child: Row(
                                        children: widget.round.runCredits
                                            .map((number) {
                                          return GestureDetector(
                                            onDoubleTap: () => setState(() {
                                              widget.round.runCredits
                                                  .remove(number);
                                              widget.round.activeParticipants
                                                  .add(number);
                                              //widget.round.activeParticipants.sort();
                                            }),
                                            onLongPress: () async {
                                              var res = await showDialog<List<String>>(
                                                context: context,
                                                builder: (BuildContext context) => CommentsDialog(
                                                  commentsList: eventController
                                                      .gradesData
                                                      .listOfCommentsAlonka,
                                                  selectedComments: (eventController
                                                          .getParticipant(number))
                                                      .alonkaInstructorComments,
                                                  title: number.toString(),
                                                ),
                                              );
                                              if (res != null) {
                                                if (res.contains(ParticipantStatus.Droped.name)) {
                                                  eventController.loading.value = true;
                                                  eventController.dropParticipant(number);
                                                  widget.round.runCredits.remove(number);
                                                  eventController.loading.value = false;
                                                } else {
                                                  eventController.addAlonkaComments(res, number);
                                                }
                                              }
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                '$number', // Convert the number to a string
                                                style: TextStyle(
                                                    fontSize: tablet ? 28.0 : 20.0, // 40% bigger on tablets (20 * 1.4)
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          );
                                        }).toList(), // Convert the iterable to a list of widgets
                                      ),
                                    );
                                  })),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                ],
                              ),
                            )),
                      ],
                    )),
            ));
      } else {
        return SizedBox(
            height: 115,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Divider(
                    thickness: dividerThickness,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      eventController.currentEvent.value.finalized
                          ? SizedBox.shrink()
                          : IconButton(
                              onPressed: () {
                                for (int participant
                                    in widget.round.participationCredits) {
                                  widget.round.activeParticipants
                                      .add(participant);
                                }
                                setState(() {
                                  widget.round.participationCredits = [];
                                });
                              },
                              icon: Icon(Icons.edit)),
                      Text(' ${widget.round.round + 1} אלונקה מקצה ',
                          style: TextStyle(
                              fontSize: tablet ? 28.0 : 22.0, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      Row(
                          children: List.generate(1, (index) {
                        return Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Text(
                            widget.round.alonkaCredits
                                .map((credit) => credit)
                                .toList()
                                .toString(),
                            style: TextStyle(
                                fontSize: tablet ? 28.0 : 20.0, // 40% bigger on tablets (20 * 1.4)
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold),
                          ),
                        );
                      })),
                      const SizedBox(
                        width: 25,
                      ),
                      Row(
                          children: List.generate(1, (index) {
                        return Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Text(
                            widget.round.gerikanCredits
                                .map((credit) => credit)
                                .toList()
                                .toString(),
                            style: TextStyle(
                                fontSize: tablet ? 28.0 : 20.0, // 40% bigger on tablets (20 * 1.4)
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        );
                      })),
                    ],
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                ],
              ),
            ));
      }
    });
  }
}
