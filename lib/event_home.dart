import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/types.dart';
import 'ctx.dart';
import 'widgets/yes_no.dart';
import 'connectivity_controller.dart';

class EventHome extends StatefulWidget {
  const EventHome({super.key});

  @override
  State<EventHome> createState() => _EventHomeState();
}

class _EventHomeState extends State<EventHome> {
  final eventController = Get.put(Controller());
  final connectivityController = Get.put(ConnectivityController());

  @override
  void initState() {
    if (!eventController.currentEvent.value.finalized) {
      connectivityController.startLiveEventUpdating();
    }
    super.initState();
  }

  @override
  void dispose() {
    connectivityController.stopLiveEventUpdating(); // ✅ Cancel the timer when leaving the screen
    print("🚫 Timer canceled!");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        drawer: Drawer(
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('תפריט',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                    Obx(() => eventController.currentEvent.value.finalized
                        ? Text('הארוע נסגר',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold))
                        : Text(
                            'הארוע פעיל',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          )),
                    SizedBox(
                      height: 12,
                    ),
                    Text(
                        '${eventController.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active).length} משתתפים אקטיבים ',
                        style: TextStyle(fontSize: 16)),
                    Text(
                        'גירסת ציונים: ${eventController.currentEvent.value.gradeSettings.version} ',
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              Obx(() => eventController.loading.value
                  ? SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(),
                    )
                  : SizedBox.shrink()),
              Obx(() => eventController.currentEvent.value.finalized
                  ? SizedBox.shrink()
                  : ListTile(
                      title: Row(
                        children: [
                          Icon(Icons.close),
                          SizedBox(
                            width: 10,
                          ),
                          const Text('סגירת הארוע'),
                        ],
                      ),
                      onTap: () async {
                        if (eventController.gradesCanBeFinalized()) {
                          var res = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return YesNoDialog();
                            },
                          );
                          if (res) {
                            eventController.loading.value = true;
                            eventController.currentEvent.value.finalized = true;
                            eventController.currentEvent.refresh();
                            //await eventController.loadTodayEvent();
                            if (eventController.isConnected.value) {
                              eventController.currentEvent.value.isBackedUp =
                                  true;
                              await eventController.currentEvent.value.save();
                              var res = await eventController.hiveStorage
                                  .backupHiveToFirebase(
                                      eventController.currentEventName,
                                      eventController.currentEvent.value.date,
                                      eventController
                                          .currentEvent.value.instructorId);
                              if (res) {
                                showCustomMessageAlert(
                                    context,
                                    "הצלחה",
                                    "הארוע נסגר בהצלחה וגובה לרשת",
                                    Icons.check);
                              } else {
                                eventController.currentEvent.value.isBackedUp =
                                    false;
                                await eventController.currentEvent.value.save();
                              }
                            } else {
                              showCustomMessageAlert(
                                  context,
                                  "שים לב",
                                  "הארוע נסגר בהצלחה! אבל לא ניתן היה לבצע גיבוי כי לא נמצא חיבור לרשת. יש לגבות מהתפריט הראשי שיש חיבור לרשת",
                                  Icons.error);
                            }
                            eventController.loading.value = false;
                            //Navigator.pop(context);
                          }
                        } else {
                          showCustomMessageAlert(context, "תקלה",
                              "לא ניתנו ציונים סופיים לכולם", Icons.error);
                        }
                      },
                    )),
              Obx(() => eventController.currentEvent.value.finalized
                  ? SizedBox.shrink()
                  : ListTile(
                      title: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(
                            width: 10,
                          ),
                          const Text('עריכת הגדרות הארוע'),
                        ],
                      ),
                      onTap: () async {
                        Get.toNamed(
                            '/event_settings/${eventController.currentEvent.value.date}');
                      },
                    )),
              ListTile(
                title: Row(
                  children: [
                    Icon(Icons.calendar_month_sharp),
                    SizedBox(
                      width: 10,
                    ),
                    const Text('חזרה לתפריט ראשי'),
                  ],
                ),
                onTap: () async {
                  if (!eventController.currentEvent.value.finalized)
                    await eventController.currentEvent.value.save();
                  //connectivityController.stopLiveEventUpdating();
                  //Get.back();
                  //Get.back();
                  Get.toNamed('/home');
                },
              ),
            ],
          ),
        ),
        appBar: AppBar(
          title: Center(child: Text('ימי סיירות')),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Text(
                  ' קבוצה ${eventController.currentEvent.value.groupNumber} ',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${eventController.currentEvent.value.date}',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${eventController.currentInstructor.firstName} ${eventController.currentInstructor.lastName}',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  eventController.currentInstructor.id,
                  style: TextStyle(fontSize: 12),
                )
              ],
            ),
            Obx(() {
              if (eventController.loading.value) {
                return CircularProgressIndicator();
              }
              return SizedBox(
                height: 450,
                width: 400,
                child: GridView.count(
                  childAspectRatio: 1,
                  crossAxisCount: 2,
                  children: [
                    /// Meshulash
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: ElevatedButton(
                            style: ButtonStyle(
                                shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(70.0),
                                        side: BorderSide(
                                            width: 5,
                                            color: eventController
                                                        .currentEvent
                                                        .value
                                                        .meshulashStartTime ==
                                                    null
                                                ? Colors.black
                                                : eventController
                                                            .currentEvent
                                                            .value
                                                            .meshulashEndTime ==
                                                        null
                                                    ? Colors.red
                                                    : Colors.green)))),
                            onPressed: () => {Get.toNamed('/meshulash')},
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Image.asset(
                                  'images/meeshulash.png',
                                  scale: 5,
                                ),
                                const Text('משולש',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ))
                      ,
                    ),
                    /// Sakim
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: ElevatedButton(
                          style: ButtonStyle(
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(70.0),
                                      side: BorderSide(
                                          width: 5,
                                          color: eventController.currentEvent
                                                      .value.sakimStartTime ==
                                                  null
                                              ? Colors.black
                                              : eventController.currentEvent
                                                          .value.sakimEndTime ==
                                                      null
                                                  ? Colors.red
                                                  : Colors.green)))),
                          onPressed: () => {Get.toNamed('/sakim')},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Image.asset(
                                color: Colors.black,
                                'images/sakim.png',
                                scale: 5,
                              ),
                              const Text('שקים',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ],
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: ElevatedButton(
                          style: ButtonStyle(
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(70.0),
                                      side: BorderSide(
                                          width: 5,
                                          color: eventController.currentEvent
                                                      .value.burStartTime ==
                                                  null
                                              ? Colors.black
                                              : eventController.currentEvent
                                                          .value.burEndTime ==
                                                      null
                                                  ? Colors.red
                                                  : Colors.green)))),
                          onPressed: () => {Get.toNamed('/bur')},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Image.asset(
                                'images/bur.png',
                                scale: 5,
                              ),
                              const Text('בור',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ],
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: ElevatedButton(
                          style: ButtonStyle(
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(70.0),
                                      side: BorderSide(
                                          width: 5,
                                          color: eventController.currentEvent
                                                      .value.alonkaStartTime ==
                                                  null
                                              ? Colors.black
                                              : eventController
                                                          .currentEvent
                                                          .value
                                                          .alonkaEndTime ==
                                                      null
                                                  ? Colors.red
                                                  : Colors.green)))),
                          onPressed: () {
                            eventController.currentAlonkaRound.value =
                                eventController
                                    .currentEvent.value.alonkaSprints.length;
                            Get.toNamed('/alonka');
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Image.asset(
                                'images/alonka.png',
                                scale: 5,
                              ),
                              const Text('אלונקה',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ],
                          )),
                    ),
                  ],
                ),
              );
            }),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        fixedSize: const Size(140, 40)),
                    onPressed: () => {Get.toNamed('/grades_page')},
                    child: const Text(
                      'ציונים',
                      style: TextStyle(fontSize: 14),
                    )),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        fixedSize: const Size(140, 40)),
                    onPressed: () => {Get.toNamed('/participants_status')},
                    child: const Text('סטטוס חניכים',
                        style: TextStyle(fontSize: 14))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
