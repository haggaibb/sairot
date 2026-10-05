
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'event_controller.dart';
import 'models/instructor.dart';
import 'widgets/unfinalized_panel.dart';
import 'theme_controller.dart';
import 'package:sairot/models/system.dart';
import 'git_version.dart';
import 'widgets/guideWebView.dart';
import 'utils/tablet_utils.dart';
import 'widgets/date_input_dialog.dart';
import 'widgets/wifi_settings_button.dart';




class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final eventController = Get.put(EventController());
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
      textDirection:
      TextDirection.rtl, // Enforce LTR layout for the entire body
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
                    padding: EdgeInsets.only(
                      bottom: isTablet(context) ? 4.0 : 8.0,
                      top: isTablet(context) ? 4.0 : 8.0,
                      left: 16.0,
                      right: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Text('תפריט',
                        //     style: TextStyle(
                        //         fontWeight: FontWeight.bold, fontSize: 20)),
                        Padding(
                          padding: EdgeInsets.only(
                            right: 0.0,
                            top: isTablet(context) ? 4.0 : 8.0,
                            bottom: isTablet(context) ? 4.0 : 0.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${eventController.currentInstructor.firstName} ${eventController.currentInstructor.lastName}',
                                style: TextStyle(
                                  fontSize: isTablet(context) ? 16.0 : 18.0,
                                  //fontWeight: FontWeight.bold,
                                  //color: Colors.white,
                                ),
                              ),
                              // Text(
                              //   eventController.currentInstructor.id,
                              //   style: TextStyle(
                              //     fontSize: 18,
                              //     //color: Colors.white.withOpacity(0.9),
                              //   ),
                              // ),
                              Text(
                                '[$gitBranch]',
                                style: TextStyle(
                                  fontSize: isTablet(context) ? 12.0 : 14.0,
                                  //color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.info_outline, size: isTablet(context) ? 20.0 : 24.0),
                          tooltip: 'מדריך למשתמש',
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => Directionality(
                                textDirection: TextDirection.rtl,
                                child: const ManualWebView(
                                  url: 'https://docs.google.com/presentation/d/19SF_q3uXPt470mzfOKEorpoIORsOEEmQXL5_UUnelNo/preview?rm=minimal&slide=id.g384f00aea19_0_169',
                                  //https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000
                                ),
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                  /// 🌓 Theme Switch
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
                  /// exit
                  ListTile(
                    title: Row(
                      children: [
                        Icon(Icons.exit_to_app_sharp),
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
                  /// FontSize
                  Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('גודל גופן', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  /// loading
                  Obx(() => eventController.loading.value
                      ? SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(),
                  )
                      : SizedBox.shrink()),
                  /// 🎮 Playground
                  ListTile(
                    leading: Icon(Icons.sports_esports, color: Colors.orange),
                    title: const Text('מגרש משחקים',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      Navigator.pop(context); // Close drawer
                      await eventController.loadPlaygroundEvent();
                      Get.toNamed('/event_home');
                    },
                  ),

                ],
              ),
            ),
            appBar: AppBar(
              //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text('ימי סיירות'),
              centerTitle: true,
              actions: [
                WifiSettingsButton(),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'מדריך למשתמש',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Directionality(
                        textDirection: TextDirection.rtl,
                        child: const ManualWebView(
                          url: 'https://docs.google.com/document/d/1F183qEemrgm-rr_X8OMEoJqlDyApnzhwAEGTTXwjhoc/edit?tab=t.v5ophlwignwk',
                          //https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
            body: Center(
              child:
              Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                /// name and id
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: SizedBox(
                    //width: 150,
                      child: Obx(() => eventController.loading.value
                          ? LinearProgressIndicator()
                          : Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.6),
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              '${eventController.currentInstructor.firstName} ${eventController.currentInstructor.lastName}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              eventController.currentInstructor.id,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ))),
                ),
                /// new day button — hidden while one event is already open
                Obx(() {
                  if (eventController.unfinalizedLoading.value ||
                      eventController.unfinalizedEvents.isNotEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 5,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    onPressed: () async {
                      await eventController.getUnfinalizedEvents();
                      if (!mounted ||
                          eventController.unfinalizedEvents.isNotEmpty) {
                        return;
                      }
                      DateTime today = DateTime.now();
                      // Remove time component to compare only dates
                      today = DateTime(today.year, today.month, today.day);

                      String? formattedDate = await showDialog<String>(
                        context: context,
                        builder: (BuildContext context) {
                          return DateInputDialog(initialDate: today);
                        },
                      );

                      if (formattedDate != null) {
                        Get.toNamed('/event_settings/$formattedDate');
                      }
                    },
                      child: const Text('פתיחת יום חדש',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                );
                }),
                const SizedBox(
                  height: 10,
                ),
                /// unfinalized events
                Obx(() {
                  bool tablet = isTablet(context);
                  double maxWidth = tablet ? 480.0 : 400.0;
                  
                  // Show loading message
                  if (eventController.unfinalizedLoading.value) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          'מחפש ארועים פתוחים...',
                          style: TextStyle(
                            fontSize: tablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }
                  
                  // Show "no open events" message if list is empty
                  if (eventController.unfinalizedEvents.isEmpty) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          'אין ארועים פתוחים',
                          style: TextStyle(
                            fontSize: tablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }
                  
                  // Show the list of events
                  return Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: ListView.builder(
                          itemCount: eventController.unfinalizedEvents.length,
                          itemBuilder: (context, index) {
                            return UnfinalizedPanel(
                                event:
                                eventController.unfinalizedEvents[index]);
                          },
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(height: 50,)
              ]),
            )),
      ),
    );
  }
}

