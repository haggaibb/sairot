import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sairot/models/participant.dart';
import 'ctx.dart';
import 'package:get/get.dart';
import 'widgets/meshulash_charts.dart';
import 'widgets/alonka_charts.dart';
import 'widgets/bur_charts.dart';
import 'widgets/sakim_charts.dart';
import 'widgets/interview_chart.dart';
import 'widgets/leadership_chart.dart';

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
                Text('ניתוח גרפי'),
              ],
            ),
          ),
          body: SingleChildScrollView(
              child: Center(
            child: Column(
              //mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20,
                ),
                Text('$number  ניתוח ביצועים עבור משתתף  ',
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
                  height: 300,
                  width: 350,
                  child: LeadershipChart(number: number),
                ),
                const SizedBox(
                  height: 40,
                ),
                const Text('ראיון אישי',
                    style: TextStyle(decoration: TextDecoration.underline,decorationThickness: 1.0,fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 300,
                  width: 350,
                  child: InterviewChart(number: number),
                ),
                const SizedBox(
                  height: 10,
                ),
              ],
            ),
          ))),
    );
  }
}
