import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'color_schemes.g.dart';
import 'ctx.dart';
import 'event_settings_page.dart';
import 'event_home.dart';
import 'alonka_page.dart';
import 'participants_status_page.dart';
import 'meshulash_page.dart';
import 'sakim_page.dart';
import 'bur_page.dart';
import 'grades_page.dart';
import 'performance_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'models/instructor.dart';
import 'dart:async';
import 'widgets/yes_no.dart';
import 'admin/admin_home.dart';
import 'admin/admin_event_report_page.dart';
import 'admin/admin_live_event_page.dart';
//import '../connectivity_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
      .then((_) => runApp(GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ימי סיירות',
            initialRoute: '/front_door',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: lightColorScheme,
              //colorSchemeSeed: Colors.blueAccent,
            ),
            defaultTransition: Transition.upToDown,
            getPages: [
              GetPage(
                name: '/front_door',
                page: () => FrontDoor(),
              ),
              GetPage(
                name: '/home',
                page: () => Home(),
              ),
              GetPage(
                name: '/event_home',
                page: () => EventHome(),
              ),
              GetPage(
                name: '/event_settings/:date',
                page: () => EventSettingsPage(),
              ),
              GetPage(
                name: '/meshulash',
                page: () => MeshulashPage(),
              ),
              GetPage(
                name: '/sakim',
                page: () => SakimPage(),
              ),
              GetPage(
                name: '/alonka',
                page: () => AlonkaPage(),
              ),
              GetPage(
                name: '/bur',
                page: () => BurPage(),
              ),
              GetPage(
                name: '/participants_status',
                page: () => ParticipantsStatusPage(),
              ),
              GetPage(
                name: '/grades_page',
                page: () => GradesPage(),
              ),
              GetPage(
                name: '/performance_page/:number',
                page: () => PerformancePage(),
              ),
              GetPage(
                name: '/admin',
                page: () => AdminHome(),
              ),
              GetPage(
                name: '/admin_event_report_page',
                page: () => AdminEventReportPage(),
              ),
              GetPage(
                name: '/admin_live_event_page',
                page: () => AdminLiveEventPage(),
              ),
            ],
          )));
}

class FrontDoor extends StatefulWidget {
  const FrontDoor({super.key});

  @override
  State<FrontDoor> createState() => _FrontDoorState();
}

class _FrontDoorState extends State<FrontDoor> {
  final eventController = Get.put(Controller());

  @override
  Widget build(BuildContext context) {
    return Obx(() => !eventController.loggedIn.value ? LoginPage() : Home());
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final eventController = Get.put(Controller());
  //final connectivityController = Get.put(ConnectivityController());

  //late Timer _connectionTimer;

  /// Load Selected Instructor's Event
  Future<void> loadSelectedEvent() async {
    eventController.pastEventsLoading.value = true;
    if (eventController.selectedEvent.value == null ||
        eventController.selectedDay.value == null) {
      print("❌ Missing Selection!");
      eventController.pastEventsLoading.value = false;
      return;
    }

    await eventController.loadInstructorEvent(
      eventController.selectedEvent.value!,
      eventController.selectedDay.value!,
    );
    print('loadInstructorEvent Done!!!');
    eventController.pastEventsLoading.value = false;
  }

  @override
  void initState() {
    //connectivityController.startConnectionCheckInterval();
    Future.microtask(() async {
      await eventController.getUnfinalizedEvents();
      await eventController.fetchInstructorEvents();
    });
    super.initState();
  }

  @override
  void dispose() {
    //connectivityController.stopConnectionCheckInterval();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          TextDirection.rtl, // Enforce LTR layout for the entire body
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
                    ],
                  ),
                ),

                /// exit
                ListTile(
                  title: Row(
                    children: [
                      Icon(Icons.person),
                      SizedBox(
                        width: 10,
                      ),
                      const Text('יציאה מהמערכת'),
                    ],
                  ),
                  onTap: () async {
                    eventController.loading.value = true;
                    eventController.system.value.loggedIn = '';
                    await eventController.system.value.save();
                    eventController.currentInstructor = Instructor(
                        id: '', firstName: '', lastName: '', mobile: '');
                    eventController.loading.value = false;
                    Get.offAllNamed('/front_door');
                  },
                ),

                Obx(() => eventController.loading.value
                    ? SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(),
                      )
                    : SizedBox.shrink())
              ],
            ),
          ),
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text('ימי סיירות'),
            centerTitle: true,
            actions: [
            ],
          ),
          body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              /// name and id
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: SizedBox(
                    width: 150,
                    child: Obx(() => eventController.loading.value
                        ? LinearProgressIndicator()
                        : Column(
                            children: [
                              Text(
                                '${eventController.currentInstructor.firstName} ${eventController.currentInstructor.lastName}',
                                style: TextStyle(fontSize: 20),
                              ),
                              Text(
                                eventController.currentInstructor.id,
                                style: TextStyle(fontSize: 16),
                              )
                            ],
                          ))),
              ),

              /// new day button
              Padding(
                padding: const EdgeInsets.all(1.0),
                child: ElevatedButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(), //get today's date
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101));
                      if (pickedDate != null) {
                        String formattedDate =
                            "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
                        Get.toNamed('/event_settings/$formattedDate');
                      }
                    },
                    child: const Text('פתיחת יום חדש')),
              ),
              const SizedBox(
                height: 60,
              ),

              /// unfinalized events
              Obx(() {
                return !eventController.unfinalizedLoading.value
                    ? Expanded(
                        child: ListView.builder(
                          itemCount: eventController.unfinalizedEvents.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              padding: EdgeInsets.only(
                                  left: 80, right: 80, top: 10, bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 20.0, top: 5),
                                    child: Center(
                                        child: Text('ארוע פעיל',
                                            style: const TextStyle(
                                                fontSize: 22,
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold))),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(' תאריך :',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.normal)),
                                      Text(
                                          eventController
                                              .unfinalizedEvents[index].date,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.normal)),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(' מספר קבוצה :',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.normal)),
                                      Text(
                                          eventController
                                              .unfinalizedEvents[index]
                                              .groupNumber
                                              .toString(),
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.normal)),
                                    ],
                                  ),
                                  Row(
                                          children: [
                                            ElevatedButton(
                                              style: const ButtonStyle(
                                                visualDensity: VisualDensity(
                                                    horizontal: VisualDensity
                                                        .minimumDensity,
                                                    vertical: VisualDensity
                                                        .minimumDensity),
                                              ),
                                              onPressed: () async {
                                                eventController.loading.value =
                                                    true;
                                                var res = await showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return YesNoDialog();
                                                  },
                                                );
                                                if (res) {
                                                  eventController
                                                      .unfinalizedLoading
                                                      .value = true;
                                                  await eventController.delEvent(eventController
                                                      .unfinalizedEvents[
                                                  index]);
                                                  eventController
                                                      .unfinalizedEvents
                                                      .clear();
                                                  await eventController
                                                      .getUnfinalizedEvents();
                                                } else {

                                                }
                                                eventController.loading.value =
                                                    false;
                                                eventController
                                                    .unfinalizedLoading
                                                    .value = false;
                                              },
                                              child: const Text('מחק'),
                                            ),
                                            ElevatedButton(
                                              style: const ButtonStyle(
                                                visualDensity: VisualDensity(
                                                    horizontal: VisualDensity
                                                        .minimumDensity,
                                                    vertical: VisualDensity
                                                        .minimumDensity),
                                              ),
                                              onPressed: () async {
                                                eventController.loading.value =
                                                    true;
                                                eventController
                                                        .currentEvent.value =
                                                    eventController
                                                            .unfinalizedEvents[
                                                        index];
                                                eventController.loading.value =
                                                    false;
                                                Get.toNamed('/event_home');
                                              },
                                              child: const Text('טען'),
                                            ),
                                          ],
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                        ),
                                  /// participants count
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    : SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(),
                      );
              }),
              const SizedBox(
                height: 0,
              ),

              ///
              /// Past Events
              const Text(
                'ארועי עבר',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding:
                    EdgeInsets.only(left: 80, right: 80, top: 10, bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    // 📌 Event Dropdown
                    Obx(() {
                      return DropdownButton<String>(
                        hint: Text("בחר אירוע"),
                        value: eventController.selectedEvent.value,
                        onChanged: (String? newValue) async {
                          eventController..selectedEvent.value = newValue;
                          eventController..selectedDay.value = null;
                          if (newValue != null) {
                            await eventController.fetchEventDays(newValue);
                          }
                        },
                        items: eventController.events
                            .map((event) => DropdownMenuItem(
                                  value: event,
                                  child: Text(event),
                                ))
                            .toList(),
                      );
                    }),
                    SizedBox(height: 10),
                    // 📅 Days Dropdown
                    Obx(() {
                      if (eventController.selectedEvent.value == null) {
                        return SizedBox();
                      }
                      var days = eventController
                              .eventDays[eventController.selectedEvent.value] ??
                          [];
                      return DropdownButton<String>(
                        hint: Text("בחר יום"),
                        value: eventController.selectedDay.value,
                        onChanged: (String? newValue) {
                          eventController.selectedDay.value = newValue;
                        },
                        items: days
                            .map((day) => DropdownMenuItem(
                                  value: day,
                                  child: Text(day),
                                ))
                            .toList(),
                      );
                    }),
                    SizedBox(height: 10),
                    // ▶️ Load Data Button
                    Obx(() {
                      if (eventController.selectedDay.value == null) {
                        return SizedBox();
                      }
                      return ElevatedButton(
                          onPressed: () async {
                            await loadSelectedEvent();
                            Get.toNamed('/event_home');
                          },
                          child: Text('הצג אירוע'));
                    }),
                    Obx(() => eventController.pastEventsLoading
                            .value // || eventController.events.isEmpty
                        ? SizedBox(width: 150, child: LinearProgressIndicator())
                        : SizedBox.shrink())
                  ],
                ),
              ),
            ]),
          )),
    );
  }
}
