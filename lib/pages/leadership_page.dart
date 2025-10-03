import 'package:flutter/material.dart';
import 'package:sairot/models/participant.dart';
import '../models/types.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../widgets/comments_dialog.dart';
import '../widgets/guideWebView.dart';


class LeadershipPage extends StatefulWidget {
  const LeadershipPage({super.key});

  @override
  State<LeadershipPage> createState() => _LeadershipPageState();
}

class _LeadershipPageState extends State<LeadershipPage> {
  final eventController = Get.put(EventController());

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
                title: Text('מנהיגות'),
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
              body: GetX<EventController>(builder: (_) {
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
                                ;
                                return Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          fixedSize:
                                          const Size(10, 20),
                                          foregroundColor: Colors.black,
                                          backgroundColor:
                                          eventController
                                              .currentEvent
                                              .value
                                              .activeParticipants[
                                          index]
                                              .leadershipInstructorComments
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
                                        if (res!=null) {
                                          if (res.contains(ParticipantStatus.Droped.name)) {
                                            print('dropped');
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
                                            eventController.addLeadershipComments(res,eventController
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
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value),
                                      )),
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
              })),
        ));
  }
}
