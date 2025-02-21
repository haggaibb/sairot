import 'package:flutter/material.dart';
import 'package:sairot/models/participant.dart';
import 'models/types.dart';
import 'ctx.dart';
import 'package:get/get.dart';
import 'widgets/comments_dialog.dart';


class LeadershipPage extends StatefulWidget {
  const LeadershipPage({super.key});

  @override
  State<LeadershipPage> createState() => _LeadershipPageState();
}

class _LeadershipPageState extends State<LeadershipPage> {
  final eventController = Get.put(Controller());

  @override
  void initState() {
    //setState(() async {
    eventController.currentEvent.value.activeParticipants = [];
    for (Participant p in eventController.currentEvent.value
        .getParticipantsByStatus(ParticipantStatus.Active)) {
      eventController.currentEvent.value.activeParticipants.add(p);
    }
    eventController.currentEvent.value.saveToFirestore();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Text('מנהיגות'),
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
              var h =
                  eventController.currentEvent.value.activeParticipants.length /
                      3 +
                      2;
              return SingleChildScrollView(
                child: Center(
                  child: Obx(() => eventController.loading.value
                      ? LinearProgressIndicator()
                      : Column(
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        height: h < 2 ? 120 : h * 50,
                        child: GridView.count(
                            childAspectRatio: 3,
                            crossAxisCount:
                            eventController.numberOfCols,
                            children: List.generate(
                                eventController
                                    .currentEvent
                                    .value
                                    .activeParticipants
                                    .length, (index) {
                              ;
                              return Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        fixedSize:
                                        const Size(10, 20),
                                        backgroundColor:
                                        eventController
                                            .currentEvent
                                            .value
                                            .activeParticipants[
                                        index]
                                            .leadershipInstructorComments
                                            .isNotEmpty
                                            ? Colors.green
                                            : Colors.white),
                                    onPressed: () async {
                                      if (eventController
                                          .currentEvent
                                          .value
                                          .finalized) return;
                                      var res = await showDialog<List<String>>(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              CommentsDialog(
                                                commentsList: eventController.gradesData.listOfCommentsLeadership,
                                                selectedComments: eventController
                                                    .currentEvent
                                                    .value
                                                    .activeParticipants[index].leadershipInstructorComments,
                                                title: eventController
                                                    .currentEvent
                                                    .value
                                                    .activeParticipants[index]
                                                    .number.toString(),
                                              ));
                                      print('res');
                                      print(res);
                                      if (res!=null) {
                                        print(res);
                                        eventController.addLeadershipComments(res,eventController
                                            .currentEvent
                                            .value
                                            .activeParticipants[index]
                                            .number);
                                      }
                                    },
                                    child: Text(eventController
                                        .currentEvent
                                        .value
                                        .activeParticipants[index]
                                        .number
                                        .toString())),
                              );
                            })),
                      ),
                      const Divider(
                        thickness: 30,
                      ),
                    ],
                  )),
                ),
              );
            })));
  }
}
