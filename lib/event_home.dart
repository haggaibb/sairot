import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/types.dart';
import 'ctx.dart';
import 'widgets/yes_no.dart';
import 'theme_controller.dart';
import 'widgets/strobe_button.dart';
import 'models/system.dart';

class EventHome extends StatefulWidget {
  const EventHome({super.key});

  @override
  State<EventHome> createState() => _EventHomeState();
}

class _EventHomeState extends State<EventHome> {
  final eventController = Get.put(Controller());
  final themeController = Get.put(ThemeController());


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
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Color.fromARGB(255, 0, 66, 136)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
                Obx(() => SwitchListTile(
                  title: Text(
                    themeController.isDarkMode.value
                        ? 'Dark Mode'
                        : 'Light Mode',
                    style: TextStyle(fontSize: 18),
                  ),
                  secondary: Icon(
                    themeController.isDarkMode.value
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  value: themeController.isDarkMode.value,
                  onChanged: (value) {
                    eventController.toggleTheme(value);
                  },
                )),
                Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('גודל גופן וכפתורים', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Obx(() {
                        double sliderValue;
                        switch (eventController.system.value.accessibility) {
                          case Accessibility.normal:
                            sliderValue = 0;
                            break;
                          case Accessibility.big:
                            sliderValue = 1;
                            break;
                          case Accessibility.biggest:
                            sliderValue = 2;
                            break;
                        }

                        return Column(
                          children: [
                            Slider(
                              value: eventController.system.value.accessibility.index.toDouble(),
                              min: 0,
                              max: 2,
                              divisions: 2,
                              label: sliderValue == 0
                                  ? "רגיל"
                                  : sliderValue == 1
                                  ? "גדול"
                                  : "הכי גדול",
                              onChanged: (double value) {
                                Accessibility newSize;
                                if (value == 0) {
                                  newSize = Accessibility.normal;
                                } else if (value == 1) {
                                  newSize = Accessibility.big;
                                } else {
                                  newSize = Accessibility.biggest;
                                }
                                eventController.system.value.accessibility = newSize;
                                eventController.setUserAccessibility(newSize);
                              },
                            ),

                            // 📌 Text to indicate sizes
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("רגיל", style: TextStyle(fontSize: 14)),
                                Text("גדול", style: TextStyle(fontSize: 16)),
                                Text("הכי גדול", style: TextStyle(fontSize: 18)),
                              ],
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          appBar: AppBar(
            //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                          child: ShiningButton(
                            onPressed: () => Get.toNamed('/meshulash'),
                            borderColor: eventController.currentEvent.value.meshulashStartTime == null
                                ? Colors.black
                                : eventController.currentEvent.value.meshulashEndTime == null
                                ? Colors.red
                                : Colors.green,
                            noneActiveColor: Theme.of(context).colorScheme.primary,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Image.asset(
                                  'images/meeshulash.png',
                                  scale: 6,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                                      : Colors.black,
                                ),
                                const Text('משולש',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),

                        /// Sakim
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: ShiningButton(
                            onPressed: () => Get.toNamed('/sakim'),
                            borderColor: eventController.currentEvent.value.sakimStartTime == null
                                ? Colors.black
                                : eventController.currentEvent.value.sakimEndTime == null
                                ? Colors.red
                                : Colors.green,
                            noneActiveColor: Theme.of(context).colorScheme.primary,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Image.asset(
                                  'images/sakim.png',
                                  scale: 6,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                                      : Colors.black,
                                ),
                                const Text('שקים',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),

                        /// Bur
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: ShiningButton(
                            onPressed: () => Get.toNamed('/bur'),
                            borderColor: eventController.currentEvent.value.burStartTime == null
                                ? Colors.black
                                : eventController.currentEvent.value.burEndTime == null
                                ? Colors.red
                                : Colors.green,
                            noneActiveColor: Theme.of(context).colorScheme.primary,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Image.asset(
                                  'images/bur.png',
                                  scale: 6,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                                      : Colors.black,
                                ),
                                const Text('בור',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),

                        /// Alonka
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: ShiningButton(
                            onPressed: () {
                              eventController.currentAlonkaRound.value =
                                  eventController.currentEvent.value.alonkaSprints.length;
                              Get.toNamed('/alonka');
                            },
                            borderColor: eventController.currentEvent.value.alonkaStartTime == null
                                ? Colors.black
                                : eventController.currentEvent.value.alonkaEndTime == null
                                ? Colors.red
                                : Colors.green,
                            noneActiveColor: Theme.of(context).colorScheme.primary,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Image.asset(
                                  'images/alonka.png',
                                  scale: 6,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                                      : Colors.black,
                                ),
                                const Text('אלונקה',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),

                        /// Leadership
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: ShiningButton(
                            onPressed: () => Get.toNamed('/leadership'),
                            borderColor: eventController.getLeadershipStatus(),
                            noneActiveColor: Theme.of(context).colorScheme.primary,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 80,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                                      : Colors.black,
                                ),
                                const Text('מנהיגות',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),

                        /// Interview
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: ShiningButton(
                            onPressed: () => Get.toNamed('/interview'),
                            borderColor: eventController.getInterviewStatus(),
                            noneActiveColor: Theme.of(context).colorScheme.primary,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(
                                  Icons.note_alt_sharp,
                                  size: 70,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                                      : Colors.black,
                                ),
                                const Text('ראיון אישי',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  ),
                );
              }),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: () => {Get.toNamed('/grades_page')},
                      child: Text(
                        'ציונים',
                        style: TextStyle(fontSize: eventController.userFontSize.value-5,fontWeight: FontWeight.bold),
                      )),
                  ElevatedButton(
                      onPressed: () => {Get.toNamed('/participants_status')},
                      child: Text('סטטוס חניכים',
                          style: TextStyle(fontSize: eventController.userFontSize.value-5, fontWeight: FontWeight.bold))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
