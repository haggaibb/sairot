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

  Future<String> GenAIReport(Participant p) async {
    var data = await p.fetchAndGenerateSummary(p.number.toString());
    if (data.isNotEmpty) {
      return data;
    } else {
      return "No Data";
    }
  }

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
          title: Text('ניתוח ביצועים - משתתף $number'),
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
                  style: TextStyle(
                      fontSize: titleFontSize, fontWeight: FontWeight.bold),
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
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold)),
                Text(' ציון ${p.meshulashGrade.toStringAsFixed(2)} ',
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold)),
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
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold)),
                Text(' ציון ${p.alonkaGrade.toStringAsFixed(2)} ',
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold)),
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
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold)),
                Text(' ציון ${p.burGrade.toStringAsFixed(2)} ',
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold)),
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
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold)),
                /// Grade
                Text(' ציון ${p.sakimGrade.toStringAsFixed(2)} ',
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold)),
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

                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () async {
                      eventController.loading.value = true;
                      p.participantAIReport = await GenAIReport(p);
                      eventController.saveParticipantsAIReport(p.number, p.participantAIReport);
                      eventController.loading.value = false;
                    },
                    child: Text(
                      'עריכה אוטומטית',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: eventController.userFontSize.value),
                    )),
                // AI Results
                Obx(
                  () => eventController.loading.value
                      ? Column(
                        children: [
                          SizedBox(
                              child: CircularProgressIndicator(),
                              width: 50,
                              height: 50,
                            ),
                          Text('זה עשוי לקחת כמה קדות...')
                        ],
                      )
                      : Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                            p.participantAIReport,
                            style: TextStyle(
                              fontSize: baseFontSize,
                              height: 1.5,
                            ),
                          ),
                      ),
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
