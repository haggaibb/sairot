import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/performance_page.dart';
import 'admin_controller.dart'; // Ensure the correct import for AdminController
import '../theme_controller.dart';
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final adminController = Get.put(AdminController());
  final themeController = Get.put(ThemeController());


  @override
  void initState() {
    super.initState();
  }

  /// Load the selected event from the Hive Box by Date
  Future<void> loadSelectedEvent() async {
    if ((adminController.selectedInstructor.value == null && adminController.selectedGroup.value == null) ||
        adminController.selectedDay.value == null) {
      print("❌ No Instructor , Group or Day Selected!");
      return;
    }
    try {
      String selectedDate = adminController.selectedDay.value!;
      String eventName = adminController.selectedEvent.value!;
      String? instructorId;
      if (!adminController.isInstructorMode.value) {
        /// group mode
        print('group mode');
        print(adminController.selectedGroup.value);
        String groupNumber = adminController.selectedGroup.value!;
        instructorId = adminController.groupNumberToInstructor[groupNumber];
      } else {
        print('instructor mode');
        instructorId = adminController.selectedInstructor.value;
      }
      // Fetch event data from Firebase if needed
      if (instructorId!=null) {
        await adminController.loadEvent(eventName, selectedDate, instructorId);

        print("✅ Event Data Loaded Successfully");
      } else {
        print("❌ No Instructor Id");
      }
      // Navigate to the next screen
      Get.toNamed('/grades_page');
    } catch (e) {
      print("❌ Error loading event: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Enforce RTL layout
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
                    ],
                  ),
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
                    Get.offAllNamed('/front_door');
                  },
                ),
              ],
            ),
          ),
          appBar: AppBar(
            //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text('ימי סיירות - מסכי ניהול'),
            centerTitle: true,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Obx(() {
                if (adminController.isDownloadingGeneralReport.value) {
                  return SizedBox(
                    height: 100,
                    width: 100,
                    child: CircularProgressIndicator(),
                  );
                }
                return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: () async {
                        Get.toNamed('/admin_live_event_page');
                      },
                      child: Text('סטטוס ארוע פעיל')),
                  SizedBox(height: 10),
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
                   // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    padding:
                    EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(),
                    ),
                    child: Column(
                      children: [
                        // 📌 Event Dropdown
                        Obx(() => false
                            ? SizedBox(width: 150, child: LinearProgressIndicator())
                            : DropdownButton<String>(
                          hint: Text("בחר אירוע"),
                          value: adminController.selectedEvent.value,
                          onChanged: (String? newValue) async {
                            adminController.isDownloading.value = true;
                            adminController.selectedEvent.value = newValue;
                            adminController.selectedDay.value = null;
                            adminController.selectedInstructor.value = null;
                            adminController.selectedGroup.value = null;
                            if (newValue != null) {
                              await adminController.fetchEventDays(newValue);
                            }
                            adminController.isDownloading.value = false;
                          },
                          items: adminController.events
                              .map((event) => DropdownMenuItem(
                            value: event,
                            child: Text(event),
                          ))
                              .toList(),
                        )),
                        SizedBox(height: 15),
                        // 📊 General Event Report Section
                        Obx(() {
                          if (adminController.selectedEvent.value == null) {
                            return SizedBox.shrink();
                          }
                          return Center(
                            child: adminController.isDownloadingGeneralReport.value
                                ? SizedBox(height: 48, width: 48, child: CircularProgressIndicator())
                                : ElevatedButton(
                                onPressed: () async {
                                  await adminController.LoadGeneralEventReport();
                                  Get.toNamed('/admin_event_report_page');
                                },
                                child: Text('דוח כללי')),
                          );
                        }),
                        SizedBox(height: 20),
                        // 📊 Group Report
                        Obx(() {
                          if (adminController.selectedEvent.value == null) {
                            return SizedBox.shrink();
                          }
                          return  Column(
                            children: [
                              Text(
                                'איחזור ציונים לארוע',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                padding: EdgeInsets.only(left: 40, right: 40, top: 10, bottom: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  children: [
                                    // 📅 Day Dropdown (Appears after selecting Event)
                                    Obx(() {
                                      if (adminController.selectedEvent.value == null) {
                                        return SizedBox();
                                      }
                                      var days = adminController.eventDays[adminController.selectedEvent.value] ?? [];
                                      return DropdownButton<String>(
                                        hint: Text("בחר יום"),
                                        value: adminController.selectedDay.value,
                                        onChanged: (String? newValue) async  {
                                          adminController.selectedDay.value = newValue;
                                          adminController.selectedInstructor.value = null;
                                          adminController.selectedGroup.value = null;
                                          if (newValue != null) {
                                            adminController.isDownloading.value=true;
                                            await adminController.fetchInstructorsForEvent(
                                                adminController.selectedEvent.value!, newValue);
                                            await adminController.fetchGroupsForEvent(
                                                adminController.selectedEvent.value!, newValue);
                                            adminController.isDownloading.value=false;
                                          }
                                        },
                                        items: days
                                            .map((day) => DropdownMenuItem(
                                          alignment: AlignmentDirectional.centerEnd,
                                          value: day,
                                          child: Text(day),
                                        ))
                                            .toList(),
                                      );
                                    }),
                                    Obx(() => adminController.selectedDay.value == null
                                        ? SizedBox.shrink()
                                        : SwitchListTile(
                                      title: Text(adminController.isInstructorMode.value
                                          ? "לפי מדריך"
                                          : "לפי קבוצה"),
                                      //activeColor: Colors.red,
                                      inactiveTrackColor: Colors.deepPurpleAccent,
                                      inactiveThumbColor: Colors.white,
                                      value: adminController.isInstructorMode.value,
                                      onChanged: (bool value) {
                                        adminController.toggleDropdownMode(value);
                                      },
                                    )),
                                    SizedBox(height: 10),
                                    // 👨‍🏫 Instructor Dropdown (Appears after selecting Day)
                                    Obx(() {
                                      if (adminController.selectedDay.value == null || !adminController.isInstructorMode.value) {
                                        return SizedBox();
                                      }
                                      var instructors =
                                          adminController.instructorFiles[adminController.selectedDay.value] ?? [];
                                      return DropdownButton<String>(
                                        hint: Text("בחר מדריך"),
                                        value: adminController.selectedInstructor.value,
                                        onChanged: (String? newValue) {
                                          adminController.selectedInstructor.value = newValue;
                                        },
                                        items: instructors
                                            .map((instructor) => DropdownMenuItem(
                                          alignment: AlignmentDirectional.centerEnd,
                                          value: instructor,
                                          child: Text(" ${eventController.getInstructorName(instructor)} "),
                                        ))
                                            .toList(),
                                      );
                                    }),
                                    // 👨‍🏫 Groups Dropdown (Appears after selecting Day)
                                    Obx(() {
                                      if (adminController.selectedDay.value == null || adminController.isInstructorMode.value) {
                                        return SizedBox();
                                      }
                                      var groupNumbers =
                                          adminController.groupNumbers[adminController.selectedDay.value] ?? [];
                                      print(adminController.selectedGroup.value);
                                      return DropdownButton<String>(
                                        hint: Text("בחר קבוצה"),
                                        value: adminController.selectedGroup.value,
                                        onChanged: (String? newValue) {
                                          adminController.selectedGroup.value = newValue;
                                        },
                                        items: groupNumbers
                                            .map((group) => DropdownMenuItem(
                                          alignment: AlignmentDirectional.centerEnd,
                                          value: group,
                                          child: Text(group),
                                        ))
                                            .toList(),
                                      );
                                    }),
                                    // 👨‍🏫 Groups Dropdown (Appears after selecting Day)
                                    // Obx(() {
                                    //   if (adminController.selectedDay.value == null) {
                                    //     return SizedBox();
                                    //   }
                                    //   var groups =
                                    //       adminController.groupNumbers[adminController.selectedDay.value] ?? [];
                                    //   return DropdownButton<String>(
                                    //     hint: Text("בחר קבוצה"),
                                    //     value: adminController.selectedGroup.value,
                                    //     onChanged: (String? newValue) {
                                    //       adminController.selectedGroup.value = newValue;
                                    //     },
                                    //     items: groups
                                    //         .map((group) => DropdownMenuItem(
                                    //       alignment: AlignmentDirectional.centerEnd,
                                    //       value: group,
                                    //       child: Text(group),
                                    //     ))
                                    //         .toList(),
                                    //   );
                                    // }),
                                    SizedBox(height: 10),
                                    // 📥 Show Loader when Downloading Hive Box
                                    Obx(() {
                                      if (adminController.isDownloading.value) {
                                        return Column(
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(height: 10),
                                            Text("📥 הורדת נתונים...")
                                          ],
                                        );
                                      } else {
                                        return SizedBox.shrink();
                                      }
                                    }),
                                    SizedBox(height: 10),
                                    // ▶️ Load Data Button
                                    Obx(() {
                                      if ((adminController.selectedInstructor.value == null && adminController.selectedGroup.value == null) ||
                                          adminController.selectedDay.value == null ||
                                          adminController.isDownloading.value) {
                                        return SizedBox(); // Hide if no selections are made
                                      }
                                      return ElevatedButton(
                                          onPressed: loadSelectedEvent, child: Text('הצג'));
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              );}),
            ),
          ),
        ),
      ),
    );
  }
}