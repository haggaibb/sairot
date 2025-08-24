import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/types.dart';
import 'event_controller.dart';
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
  final eventController = Get.put(EventController());
  final themeController = Get.put(ThemeController());



  Widget _buildShiningButton(dynamic icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: ShiningButton(
        onPressed: onTap,
        borderColor: Colors.black,
        noneActiveColor: Get.theme.colorScheme.primary,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            icon is String
                ? Image.asset(icon, scale: 6, color: Colors.black)
                : Icon(icon, size: 80, color: Colors.black),
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

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
                /// Loading
                Obx(() => eventController.loading.value
                    ? SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(),
                      )
                    : SizedBox.shrink()),
                /// Close Event
                Obx(() => eventController.currentEvent.value.finalized
                    ? SizedBox.shrink()
                    : ListTile(
                        title: Row(
                          children: [
                            Icon(Icons.save),
                            SizedBox(
                              width: 10,
                            ),
                            const Text('שמירה וסגירת הארוע'),
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
                /// Edit Event Settings
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
                /// Back to Home Page
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
                    await eventController.getUnfinalizedEvents();
                    Get.toNamed('/home');
                  },
                ),
                /// Dark Mode
                Obx(() => SwitchListTile(
                  title: Text(
                    themeController.isDarkMode.value
                        ? 'מצב לילה'
                        : 'מצב יום',
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
                /// Accessibility
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
          body:SingleChildScrollView(
            child: Column(
              children: [
                /// Group Data
                Column(
                  children: [
                    Text(
                      ' קבוצה ${eventController.currentEvent.value.groupNumber} ',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${eventController.currentEvent.value.date}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${eventController.currentInstructor.firstName} ${eventController.currentInstructor.lastName}',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      eventController.currentInstructor.id,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),

                /// **Push Content Down**
                SizedBox(height: 20),

                /// **Events Grid**
                Obx(() {
                  if (eventController.loading.value) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      physics: NeverScrollableScrollPhysics(), // 🔹 Prevents internal scrolling
                      shrinkWrap: true, // 🔹 Allows it to wrap only required space
                      children: [
                        _buildShiningButton('images/meeshulash.png', 'משולש', () => Get.toNamed('/meshulash')),
                        _buildShiningButton('images/alonka.png', 'אלונקה', () {
                          eventController.currentAlonkaRound.value = eventController.currentEvent.value.alonkaSprints.length;
                          Get.toNamed('/alonka');
                        }),
                        _buildShiningButton('images/bur.png', 'בור', () => Get.toNamed('/bur')),
                        _buildShiningButton('images/sakim.png', 'שקים', () => Get.toNamed('/sakim')),
                        _buildShiningButton(Icons.star, 'מנהיגות', () => Get.toNamed('/leadership')),
                        _buildShiningButton(Icons.note_alt_sharp, 'ראיון אישי', () => Get.toNamed('/interview')),
                      ],
                    ),
                  );
                }),

                /// **Push Content Evenly**
                SizedBox(height: 20),

                /// Grades and Status Buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Obx(() {
                    return SizedBox(
                      height: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                              onPressed: () => Get.toNamed('/grades_page'),
                              child: Text(
                                'ציונים',
                                style: TextStyle(fontSize: eventController.userFontSize.value - 5, fontWeight: FontWeight.bold),
                              )),
                          ElevatedButton(
                              onPressed: () => Get.toNamed('/participants_status'),
                              child: Text('סטטוס חניכים',
                                  style: TextStyle(fontSize: eventController.userFontSize.value - 5, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
