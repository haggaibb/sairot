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
import '../widgets/animated_wheels.dart';

final eventController = Get.put(Controller());
const leftStyle = TextStyle(
  color: Colors.black,
  fontWeight: FontWeight.bold,
  fontSize: 14,
);

class PerformancePage extends StatelessWidget {
  const PerformancePage({super.key});

  @override
  Widget build(BuildContext context) {
    int number = int.parse(Get.parameters['number']??'0');
    Participant p = eventController.getParticipant(number);
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
              children: const [
                Text('ניתוח ביצועים'),
              ],
            ),
          ),
          body: SingleChildScrollView(
              child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20,
                ),
                Text('  ניתוח ביצועים עבור משתתף  '+number.toString(),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                ///
                const SizedBox(
                  height: 60,
                ),
                const Text('  ניתוח ביצועים - משולש',
                    style: TextStyle(decoration: TextDecoration.underline,decorationThickness: 1.0,fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('השוואה קבוצתית',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  height: 300,
                  width: 350,
                  child: MeshulashCharts(number: number),
                ),
                ///
                const SizedBox(
                  height: 60,
                ),
                const Text('  ניתוח ביצועים - אלונקה',
                    style: TextStyle(decoration: TextDecoration.underline,decorationThickness: 1.0,fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('גרף ביצועים אישי',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 300,
                  width: 350,
                  child: AlonkaCharts(number: number),
                ),
                const SizedBox(
                  height: 10,
                ),
                ///
                const SizedBox(
                  height: 60,
                ),
                const Text('  ניתוח ביצועים - בור',
                    style: TextStyle(decoration: TextDecoration.underline,decorationThickness: 1.0, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('השוואה קבוצתית',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 300,
                  width: 350,
                  child: BurCharts(number: number),
                ),
                const SizedBox(
                  height: 60,
                ),
                const Text('  ניתוח ביצועים - שקים',
                    style: TextStyle(decoration: TextDecoration.underline,decorationThickness: 1.0,fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('גרף אישי',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(
                  height: 40,
                ),
                SizedBox(
                  height: 300,
                  width: 400,
                  child: SakimCharts(number: number),
                ),
                const SizedBox(
                  height: 40,
                ),
                const Text('מנהיגות',
                    style: TextStyle(decoration: TextDecoration.underline,decorationThickness: 1.0,fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 150,
                  width: 350,
                  child: LeadershipChart(number: number),
                ),
                const SizedBox(
                  height: 40,
                ),
                const Text('ראיון אישי',
                    style: TextStyle(decoration: TextDecoration.underline,decorationThickness: 1.0,fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 150,
                  width: 350,
                  child: InterviewChart(number: number),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(' ניתוח הנתונים',
                    style: TextStyle(decoration: TextDecoration.underline,decorationThickness: 1.0,fontSize: 18, fontWeight: FontWeight.bold)),
                FutureBuilder<String>(
                  future: p.fetchAndGenerateSummary(number.toString()) ,// Call the Future function here
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return
                        Container(
                            margin: EdgeInsets.all(16), // Outer spacing
                            padding: EdgeInsets.all(16), // Inner spacing
                            decoration: BoxDecoration(
                              //color: Colors.white, // Background color
                              borderRadius: BorderRadius.circular(12), // Rounded corners
                              // boxShadow: [
                              //   BoxShadow(
                              //     color: Colors.black12, // Soft shadow
                              //     blurRadius: 6,
                              //     offset: Offset(0, 3),
                              //   ),
                              // ],
                              // border: Border.all(color: Colors.grey.shade300), // Subtle border
                            ),
                      child:  SizedBox(
                        height: 500,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 100,
                            ),
                            Text(
                                ' מנתח ומסכם את הביצועים של משתתף ' + number.toString(),
                              style: TextStyle(fontSize: eventController.userFontSize.value-2),
                            ),
                            SizedBox(
                              width: 200,
                                child: LinearProgressIndicator()
                            ),
                          ],
                        ),
                      )); // Show loading spinner
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else {
                      return
                        Container(
                          margin: EdgeInsets.all(16), // Outer spacing
                          padding: EdgeInsets.all(16), // Inner spacing
                          decoration: BoxDecoration(
                            //color: Colors.white, // Background color
                            borderRadius: BorderRadius.circular(12), // Rounded corners
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12, // Soft shadow
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade300), // Subtle border
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "סיכום ביצועים", // Report Title
                                style: TextStyle(
                                  fontSize: eventController.userFontSize.value+4,
                                  fontWeight: FontWeight.bold,
                                  //color: Colors.blue.shade900,
                                ),
                              ),
                              SizedBox(height: 10), // Space between title & content
                              Text(
                                "${snapshot.data}",
                                style: TextStyle(
                                  fontSize: eventController.userFontSize.value,
                                  //color: Colors.black87,
                                  height: 1.5, // Improve readability
                                ),
                              ),
                            ],
                          ),
                        );
                    }
                  },
                ),
                const SizedBox(
                  height: 50,
                ),
              ],
            ),
          ))),
    );
  }
}
