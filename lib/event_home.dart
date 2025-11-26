import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/types.dart';
import 'event_controller.dart';
import 'widgets/yes_no.dart';
import 'theme_controller.dart';
import 'widgets/strobe_button.dart';
import 'models/system.dart';
import 'widgets/guideWebView.dart';
import 'utils/tablet_utils.dart';

class EventHome extends StatefulWidget {
  const EventHome({super.key});

  @override
  State<EventHome> createState() => _EventHomeState();
}

class _EventHomeState extends State<EventHome> {
  final eventController = Get.put(EventController());
  final themeController = Get.put(ThemeController());



  Widget _buildShiningButton(BuildContext context, dynamic icon, String title, VoidCallback onTap) {
    bool tablet = isTablet(context);
    double fontSize = tablet ? 24.0 : 15.36; // 12.8 * 1.2 = 15.36 (20% bigger for mobile)
    double iconSize = tablet ? 100.0 : 76.8; // 64.0 * 1.2 = 76.8 (20% bigger for mobile)
    double imageScale = tablet ? 5.0 : 6.25; // 7.5 / 1.2 = 6.25 (20% bigger image for mobile)
    
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ShiningButton(
        onPressed: onTap,
        borderColor: Colors.black,
        noneActiveColor: Get.theme.colorScheme.primary,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            icon is String
                ? Image.asset(icon, scale: imageScale, color: Colors.black)
                : Icon(icon, size: iconSize, color: Colors.black),
            Text(title, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
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
                      // Text('תפריט',
                      //     style: TextStyle(
                      //         fontWeight: FontWeight.bold, fontSize: 20)),
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
                      IconButton(
                          icon: const Icon(Icons.info_outline),
                          tooltip: 'מדריך למשתמש',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => Directionality(
                                textDirection: TextDirection.rtl,
                                child: const ManualWebView(
                                  url: 'https://docs.google.com/presentation/d/19SF_q3uXPt470mzfOKEorpoIORsOEEmQXL5_UUnelNo/preview?rm=minimal&slide=id.g384f00aea19_0_156',
                                  //https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000
                                ),
                              ),
                            );
                          },
                        )
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
                        url: 'https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000&slide=id.g384f00aea19_0_19',
                      ),
                    ),
                  );
                },
              )
            ],
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
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: isTablet(context) ? 1.5 : 1.25, // 1.5 / 1.2 = 1.25 (20% bigger buttons for mobile)
                      physics: NeverScrollableScrollPhysics(), // 🔹 Prevents internal scrolling
                      shrinkWrap: true, // 🔹 Allows it to wrap only required space
                      children: [
                        _buildShiningButton(context, 'images/meeshulash.png', 'משולש', () => Get.toNamed('/meshulash')),
                        _buildShiningButton(context, 'images/alonka.png', 'אלונקה', () {
                          eventController.currentAlonkaRound.value = eventController.currentEvent.value.alonkaSprints.length;
                          Get.toNamed('/alonka');
                        }),
                        _buildShiningButton(context, 'images/bur.png', 'בור', () => Get.toNamed('/bur')),
                        _buildShiningButton(context, 'images/sakim.png', 'שקים', () => Get.toNamed('/sakim')),
                        _buildShiningButton(context, Icons.star, 'מנהיגות', () => Get.toNamed('/leadership')),
                        _buildShiningButton(context, Icons.note_alt_sharp, 'ראיון אישי', () => Get.toNamed('/interview')),
                      ],
                    ),
                  );
                }),


                /// Grades and Status Buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Obx(() {
                    bool tablet = isTablet(context);
                    double buttonFontSize = tablet 
                        ? getTabletScaledFontSize(context, eventController.userFontSize.value) - 5
                        : eventController.userFontSize.value - 5;
                    double buttonHeight = tablet ? 150.0 : 100.0;
                    
                    return SizedBox(
                      height: buttonHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: tablet ? Size(200, 70) : null,
                              ),
                              onPressed: () => Get.toNamed('/grades_page'),
                              child: Text(
                                'ציונים',
                                style: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.bold),
                              )),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: tablet ? Size(200, 70) : null,
                              ),
                              onPressed: () => Get.toNamed('/participants_status'),
                              child: Text('סטטוס חניכים',
                                  style: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    );
                  }),
                ),

                SizedBox(height: 30,)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
