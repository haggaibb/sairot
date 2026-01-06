
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'event_controller.dart';
import 'models/instructor.dart';
import 'dart:async';
import 'widgets/unfinalized_panel.dart';
import 'theme_controller.dart';
import 'package:sairot/models/system.dart';
import 'git_version.dart';
import 'widgets/guideWebView.dart';
import 'utils/tablet_utils.dart';
import 'services/platform_service.dart';




class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final eventController = Get.put(EventController());
  final themeController = Get.put(ThemeController());
  final platformService = PlatformService.create();


  /// Load Selected Instructor's Event
  Future<void> loadSelectedEvent() async {
    eventController.pastEventsLoading.value = true;
    if (eventController.selectedEvent.value == null ||
        eventController.selectedDay.value == null) {
      eventController.pastEventsLoading.value = false;
      return;
    }

    // Save to cache before loading
    await eventController.saveSelectedEventAndDay(
      eventController.selectedEvent.value,
      eventController.selectedDay.value,
    );

    await eventController.loadInstructorEvent(
      eventController.selectedEvent.value!,
      eventController.selectedDay.value!,
    );
    eventController.pastEventsLoading.value = false;
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

                ],
              ),
            ),
            appBar: AppBar(
              //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text('ימי סיירות'),
              centerTitle: true,
              actions: [
                if (!kIsWeb)
                  IconButton(
                      onPressed: () async {
                        if (await platformService.canOpenKioskSettings()) {
                          await platformService.openWifiPicker();
                        }
                      },
                      icon: Icon(
                        Icons.wifi_find_rounded,
                        color: Colors.grey,
                        size: 30.0,
                      )),
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
                /// new day button
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 5,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    onPressed: () async {
                      // Define the allowed valid dates
                      // Convert eventDays List<DateTime>
                      var currentEventDays = await eventController.getCurrentEventDays();
                      List<DateTime> validDates= currentEventDays.map<DateTime>((dateStr) {
                        final parts = dateStr.split('-');
                        final day = int.parse(parts[0]);
                        final month = int.parse(parts[1]);
                        final year = int.parse(parts[2]);
                        return DateTime(year, month, day);
                      }).toList();

                      // Helper to compare just the date (ignores time)
                      bool isSameDate(DateTime a, DateTime b) {
                        return a.year == b.year && a.month == b.month && a.day == b.day;
                      }

                      // Sort to get the earliest valid date
                      validDates.sort((a, b) => a.compareTo(b));
                      DateTime fallbackInitialDate = validDates.first;

                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: fallbackInitialDate,
                        firstDate: validDates.first,
                        lastDate: DateTime(2101),
                        locale: const Locale('he', 'IL'),

                        // Only allow specific valid dates
                        selectableDayPredicate: (DateTime day) {
                          return validDates.any((valid) => isSameDate(valid, day));
                        },
                      );

                      if (pickedDate != null) {
                        String formattedDate =
                            "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
                        Get.toNamed('/event_settings/$formattedDate');
                      }
                    },
                      child: const Text('פתיחת יום חדש',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                ),
                const SizedBox(
                  height: 10,
                ),
                /// unfinalized events
                Obx(() {
                  bool tablet = isTablet(context);
                  double maxWidth = tablet ? 480.0 : 400.0;
                  
                  return !eventController.unfinalizedLoading.value
                      ? Expanded(
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
                  )
                      : SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(),
                  );
                }),
                /// Past Events
                const Text(
                  'ארועי עבר',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Builder(
                  builder: (context) {
                    bool tablet = isTablet(context);
                    double maxWidth = tablet ? 480.0 : 400.0;
                    
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 30.0, right: 30),
                          child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                    padding:
                    EdgeInsets.only(left: 40, right: 40, top: 10, bottom: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest, // 🆕
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
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
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: "בחר אירוע",
                                labelStyle: TextStyle(
                                  //color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                filled: true,
                                //fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    //color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color:
                                    Theme.of(context).colorScheme.secondary,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(Icons.event,
                                    color: Theme.of(context).colorScheme.primary),
                              ),
                              value: eventController.selectedEvent.value,
                              onChanged: (String? newValue) async {
                                eventController.selectedEvent.value = newValue;
                                eventController.selectedDay.value = null;
                                // Save to cache
                                await eventController.saveSelectedEventAndDay(newValue, null);
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
                              icon: Icon(Icons.arrow_drop_down,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                          );
                        }),
                        SizedBox(height: 10),
                        // 📅 Days Dropdown
                        Obx(() {
                          if (eventController.selectedEvent.value == null) {
                            return SizedBox();
                          }
                          var days = eventController.eventDays[
                          eventController.selectedEvent.value] ??
                              [];
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: "בחר יום",
                                labelStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                filled: true,
                                //fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color:
                                    Theme.of(context).colorScheme.secondary,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(Icons.calendar_today,
                                    color: Theme.of(context).colorScheme.primary),
                              ),
                              value: eventController.selectedDay.value,
                              onChanged: (String? newValue) async {
                                eventController.selectedDay.value = newValue;
                                // Save to cache
                                await eventController.saveSelectedEventAndDay(
                                  eventController.selectedEvent.value,
                                  newValue,
                                );
                              },
                              items: days
                                  .map((day) => DropdownMenuItem(
                                value: day,
                                child: Text(day),
                              ))
                                  .toList(),
                              icon: Icon(Icons.arrow_drop_down,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                          );
                        }),
                        SizedBox(height: 10),
                        // ▶️ Load Data Button
                        Obx(() {
                          if (eventController.selectedDay.value == null) {
                            return SizedBox();
                          }
                          return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 10,
                                backgroundColor:
                                Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                              onPressed: () async {
                                await loadSelectedEvent();
                                Get.toNamed('/event_home');
                              },
                              child: Text('הצג אירוע',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ));
                        }),
                        Obx(() => eventController.pastEventsLoading
                            .value // || eventController.events.isEmpty
                            ? SizedBox(
                            width: 150, child: LinearProgressIndicator())
                            : SizedBox.shrink()),
                        SizedBox(height: 10),
                      ],
                    ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 50,)
              ]),
            )),
      ),
    );
  }
}

