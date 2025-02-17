import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sairot/performance_page.dart';
import '../models/event.dart';
import 'admin_controller.dart'; // Ensure the correct import for AdminController

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final adminController = Get.put(AdminController());

  @override
  void initState() {
    super.initState();
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

      print("📂 Opening Hive Box for Instructor: $instructorId on $selectedDate");

      // Fetch event data from Firebase if needed
      if (instructorId!=null) {
        await adminController.fetchInstructorDays(eventName, selectedDate, instructorId);
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
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('ימי סיירות - מסכי ניהול'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 10),
                ElevatedButton(
                    onPressed: () async {
                      Get.toNamed('/admin_live_event_page');
                    },
                    child: Text('סטטוס ארוע פעיל')),
                SizedBox(height: 20),
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
                      Obx(() => adminController.isDownloading.value
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
                            await adminController.fetchInstructorFiles(newValue, "");
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
                      // 📌 Event Dropdown
                      SizedBox(height: 30),
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
                                          await adminController.fetchInstructorFiles(
                                              adminController.selectedEvent.value!, newValue);
                                          await adminController.fetchGroupNumbers(
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
                                    print('groupNumbers');
                                    print(groupNumbers);
                                    print('adminController.selectedGroup.value,');
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
                      // 📊 General Event Report Section
                      Obx(() {
                        if (adminController.selectedEvent.value == null) {
                          return SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            Text(
                              'ניתוח כללי לאירוע',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              padding: EdgeInsets.only(left: 80, right: 80, top: 10, bottom: 10),
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
                              child: Center(
                                child: adminController.isDownloadingGeneralReport.value
                                    ? SizedBox(height: 48, width: 48, child: CircularProgressIndicator())
                                    : ElevatedButton(
                                    onPressed: () async {
                                      adminController.getAllAdminEventData();
                                      Get.toNamed('/admin_event_report_page');
                                    },
                                    child: Text('דוח כללי')),
                              ),
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
        ),
      ),
    );
  }
}