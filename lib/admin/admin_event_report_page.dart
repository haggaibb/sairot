import 'package:flutter/material.dart';
import 'package:sairot/pages/performance_page.dart';
import 'admin_controller.dart';
import 'package:get/get.dart';
import '../widgets/event_grades_distribution_charts.dart';


class AdminEventReportPage extends StatefulWidget {
  const AdminEventReportPage({super.key});

  @override
  State<AdminEventReportPage> createState() => _AdminEventReportPageState();
}

class _AdminEventReportPageState extends State<AdminEventReportPage> {
  final adminController = Get.put(AdminController());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Color.fromARGB(255, 0, 66, 136)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
          appBar: AppBar(
            //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            centerTitle: true,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('דוח כללי לארוע'),
              ],
            ),
          ),
          body: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                  child: Center(
                child: Obx(()  {
                  if (adminController.isDownloadingGeneralReport.value) {
                    return Padding(
                      padding: const EdgeInsets.all(100.0),
                      child: SizedBox(
                        height: 50,
                        width: 50,
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                   return Column(
                  //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),

                    /// General Info Panel
                    Column(
                      children: [
                        Text(
                          adminController.selectedEvent.value??'',
                          textAlign:
                          TextAlign.right, // Ensures text is aligned RTL
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20,right: 35.0),
                          child: Align(
                            alignment: Alignment
                                .centerRight, // Aligns only the text to the right
                            child: Text(
                              'סיכום כללי',
                              textAlign:
                                  TextAlign.right, // Ensures text is aligned RTL
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          padding: EdgeInsets.only(
                              left: 60, right: 60, top: 10, bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              /// event # days
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(' מספר הימים בארוע :' ,style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
                                  Text(adminController.adminEvent
                                      .getUniqueEventDaysCount()
                                      .toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
                                ],
                              ),
                              /// participants count
                              Row(
                                //mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(' מספר מסיימים :', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
                                  Text(adminController.adminEvent
                                      .getTotalActiveParticipantsCount()
                                      .toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
                                ],
                              ),
                              /// passed to Gibush
                              Row(
                                //mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(' עברו לגיבוש :', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
                                  Text(adminController.adminEvent
                                      .getQualifiedParticipantsCount()
                                      .toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
                                ],
                              ),
                              /// Avrage groups per day
                              Row(
                                //mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(' ממוצע קבוצות ביום :', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
                                  Text((adminController.adminEvent.eventDays.length/adminController.adminEvent.getUniqueEventDaysCount())
                                      .toStringAsFixed(2), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
                                ],
                              ),
                              /// % of success
                              Row(
                                //mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(' אחוז מעבר לגיבוש :', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
                                  Text( (adminController.adminEvent.getQualifiedParticipantsCount()/adminController.adminEvent.getTotalActiveParticipantsCount()*100)
                                      .toStringAsFixed(0)+'%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 60,
                    ),
                    const Text('התפלגות ציונים',
                        style: TextStyle(
                            decoration: TextDecoration.underline,
                            decorationThickness: 1.0,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 300,
                      width: 350,
                      child: EventGradesDistributionCharts(),
                    ),
                    const SizedBox(
                      height: 180,
                    ),
                  ],
                );
                }),
              )))),
    );
  }
}
