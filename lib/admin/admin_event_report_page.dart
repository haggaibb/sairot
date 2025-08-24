import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admin_controller.dart';
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
    // 📏 **Detect Tablet or Mobile**
    bool isTablet = MediaQuery.of(context).size.width > 600;

    // 🎨 **Dynamic Sizes for UI Scaling**
    double baseFontSize = isTablet ? 22 : 16;
    double titleFontSize = isTablet ? 26 : 20;
    double sectionSpacing = isTablet ? 40 : 20;
    double containerPadding = isTablet ? 24 : 16;
    double containerWidthFactor = isTablet ? 0.7 : 0.9; // ✅ Restrict width for tablets
    double chartSize = isTablet ? 500 : 300;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, const Color.fromARGB(255, 0, 66, 136)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              'דוח כללי לארוע',
              style: TextStyle(fontSize: titleFontSize),
            ),
          ),
          body: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                  child: Center(
                    child: Obx(() {
                      if (adminController.isDownloadingGeneralReport.value) {
                        return Padding(
                          padding: const EdgeInsets.all(100.0),
                          child: const CircularProgressIndicator(),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),

                          /// **General Info Panel**
                          FractionallySizedBox(
                            widthFactor: containerWidthFactor,
                            child: Column(
                              children: [
                                Text(
                                  adminController.selectedEvent.value ?? '',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 20),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'סיכום כללי',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontSize: baseFontSize,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: EdgeInsets.all(containerPadding),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _infoRow('מספר הימים בארוע: ',
                                          adminController.adminEvent
                                              .getUniqueEventDaysCount()
                                              .toString(), baseFontSize),
                                      _infoRow('מספר מסיימים: ',
                                          adminController.adminEvent
                                              .getTotalActiveParticipantsCount()
                                              .toString(), baseFontSize),
                                      _infoRow('עברו לגיבוש: ',
                                          adminController.adminEvent
                                              .getQualifiedParticipantsCount()
                                              .toString(), baseFontSize),
                                      _infoRow(
                                          'ממוצע קבוצות ביום: ',
                                          (adminController.adminEvent.eventDays
                                              .length /
                                              adminController.adminEvent
                                                  .getUniqueEventDaysCount())
                                              .toStringAsFixed(2),
                                          baseFontSize),
                                      _infoRow(
                                          'אחוז מעבר לגיבוש: ',
                                          (adminController.adminEvent
                                              .getQualifiedParticipantsCount() /
                                              adminController.adminEvent
                                                  .getTotalActiveParticipantsCount() *
                                              100)
                                              .toStringAsFixed(0) +
                                              '%',
                                          baseFontSize),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: sectionSpacing),

                          /// **Grades Distribution Chart**
                          Text('התפלגות ציונים',
                              style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  decorationThickness: 1.0,
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: chartSize,
                            width: chartSize + 50, // Slightly wider for tablets
                            child: EventGradesDistributionCharts(),
                          ),
                          SizedBox(height: sectionSpacing),
                        ],
                      );
                    }),
                  )))),
    );
  }

  /// **Reusable Row for Event Summary**
  Widget _infoRow(String title, String value, double fontSize) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: fontSize)),
        Text(value,
            style:
            TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
      ],
    );
  }
}