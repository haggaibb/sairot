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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
                            if(await eventController.currentEvent.value.saveToFirestore()) {
                              showCustomMessageAlert(context, "הצלחה",
                                  "הארוע נסגר בהצלחה", Icons.check);
                            }
                          } else {

                          }
                          eventController.loading.value = false;
                          }
                        else {
                          showCustomMessageAlert(context, "תקלה",
                              "לא ניתנו ציונים סופיים", Icons.check);
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
                    eventController.currentEvent.value.saveToFirestore();
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
              return SingleChildScrollView(
                child: SizedBox(
                  height: 500,
                  width: 400,
                  child: GridView.count(
                    childAspectRatio: 1.2,
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
                                        borderRadius: BorderRadius.circular(70.0),
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
                                  scale : 6,
                                ),
                                const Text('משולש',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ],
                            )),
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
                                  scale : 6,
                                ),
                                const Text('שקים',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ],
                            )),
                      ),
                      /// Bur
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
                                  scale : 6,
                                ),
                                const Text('בור',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ],
                            )),
                      ),
                      /// Alonka
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: ElevatedButton(
                            style: ButtonStyle(
                                shape: WidgetStateProperty.all<
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
                                  scale : 6,
                                ),
                                const Text('אלונקה',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ],
                            )),
                      ),
                      /// Leadership
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: ElevatedButton(
                            style: ButtonStyle(
                                shape: WidgetStateProperty.all<
                                    RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(70.0),
                                        side: BorderSide(
                                            width: 5,
                                            color: eventController.getLeadershipStatus())))),
                            onPressed: () => {Get.toNamed('/leadership')},
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(0.0),
                                  child: Icon(
                                      color: Colors.black,
                                      size: 80,
                                      Icons.star
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(0.0),
                                  child: const Text('מנהיגות',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            )),
                      ),
                      /// interview
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: ElevatedButton(
                            style: ButtonStyle(
                                shape: WidgetStateProperty.all<
                                    RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(70.0),
                                        side: BorderSide(
                                            width: 5,
                                            color: eventController.getInterviewStatus())))),
                            onPressed: () => {Get.toNamed('/interview')},
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(0.0),
                                  child: Icon(
                                      color: Colors.black,
                                      size: 70,
                                      Icons.note_alt_sharp
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(0.0),
                                  child: const Text('ראיון אישי',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            )),
                      ),
                    ],
                  ),
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
