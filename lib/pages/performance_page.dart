import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sairot/models/participant.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../widgets/meshulash_charts.dart';
import '../widgets/alonka_charts.dart';
import '../widgets/bur_charts.dart';
import '../widgets/sakim_charts.dart';
import '../widgets/interview_chart.dart';
import '../widgets/leadership_chart.dart';

final eventController = Get.put(EventController());

class PerformancePage extends StatelessWidget {
  const PerformancePage({super.key});

  @override
  Widget build(BuildContext context) {
    int number = int.parse(Get.parameters['number'] ?? '0');
    Participant p = eventController.getParticipant(number);

    // 📏 **Detect Tablet or Mobile**
    bool isTablet = MediaQuery.of(context).size.width > 600;

    // 🎨 **Dynamic Sizes for Mobile vs. Tablet**
    double baseFontSize = isTablet ? 24 : 18;
    double chartHeight = isTablet ? 500 : 300;
    double chartWidth = isTablet ? 650 : 350;
    double titleFontSize = isTablet ? 28 : 22;
    double subtitleFontSize = isTablet ? 22 : 16;
    double spacing = isTablet ? 80 : 60;

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
          title: const Text('ניתוח ביצועים'),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Text(
                  'ניתוח ביצועים עבור משתתף $number',
                  style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: spacing),

                /// **Meshulash Chart**
                Text('ניתוח ביצועים - משולש',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.0,
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold)),
                Text('השוואה קבוצתית',
                    style: TextStyle(fontSize: subtitleFontSize, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                SizedBox(
                  height: chartHeight,
                  width: chartWidth,
                  child: MeshulashCharts(number: number),
                ),

                SizedBox(height: spacing),

                /// **Alonka Chart**
                Text('ניתוח ביצועים - אלונקה',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.0,
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold)),
                Text('גרף ביצועים אישי',
                    style: TextStyle(fontSize: subtitleFontSize, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: chartHeight,
                  width: chartWidth,
                  child: AlonkaCharts(number: number),
                ),

                SizedBox(height: spacing),

                /// **Bur Chart**
                Text('ניתוח ביצועים - בור',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.0,
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold)),
                Text('השוואה קבוצתית',
                    style: TextStyle(fontSize: subtitleFontSize, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: chartHeight,
                  width: chartWidth,
                  child: BurCharts(number: number),
                ),

                SizedBox(height: spacing),

                /// **Sakim Chart**
                Text('ניתוח ביצועים - שקים',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.0,
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold)),
                Text('גרף אישי',
                    style: TextStyle(fontSize: subtitleFontSize, fontWeight: FontWeight.bold)),
                SizedBox(height: 40),
                SizedBox(
                  height: chartHeight,
                  width: chartWidth,
                  child: SakimCharts(number: number),
                ),

                SizedBox(height: spacing),

                /// **Leadership Chart**
                Text('מנהיגות',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.0,
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold)),
                SizedBox(
                  height: chartHeight / 2,
                  width: chartWidth,
                  child: LeadershipChart(number: number),
                ),

                SizedBox(height: spacing / 2),

                /// **Interview Chart**
                Text('ראיון אישי',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.0,
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold)),
                SizedBox(
                  height: chartHeight / 2,
                  width: chartWidth,
                  child: InterviewChart(number: number),
                ),

                SizedBox(height: 10),

                /// **Performance Summary**
                Text('ניתוח הנתונים',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.0,
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold)),

                FutureBuilder<String>(
                  future: p.fetchAndGenerateSummary(number.toString()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(height: 100),
                            Text(
                              'מנתח ומסכם את הביצועים של משתתף $number',
                              style: TextStyle(fontSize: baseFontSize - 2),
                            ),
                            SizedBox(width: 200, child: LinearProgressIndicator()),
                          ],
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else {
                      return Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "סיכום ביצועים",
                              style: TextStyle(
                                fontSize: baseFontSize + 4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "${snapshot.data}",
                              style: TextStyle(
                                fontSize: baseFontSize,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),

                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}