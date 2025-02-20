import 'package:flutter/material.dart';
import 'package:sairot/models/participant.dart';
import 'models/types.dart';
import 'ctx.dart';
import 'package:get/get.dart';
import 'models/bur.dart';
import 'widgets/participant_action_dialog.dart';
import 'widgets/bur_grade_panel.dart';
import 'dart:async';

class BurPage extends StatefulWidget {
  const BurPage({super.key});

  @override
  State<BurPage> createState() => _BurPageState();
}

class _BurPageState extends State<BurPage> {
  final eventController = Get.put(Controller());
  int runTime=0;
  late Timer _timer;


  @override
  void initState() {
    eventController.currentEvent.value.burGrades.forEach((e) => print(e.id));
    runTime =  eventController.currentEvent.value.getBurRunTime();
    if (eventController.currentEvent.value.burEndTime==null) {
      _timer = Timer.periodic(Duration(seconds: 30), (Timer timer) {
        setState(() {
          runTime = eventController.currentEvent.value.getBurRunTime();
        });
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    if (eventController.currentEvent.value.burEndTime==null)_timer.cancel(); // Stop timer when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child:Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Column(
                children: [
                  Text('בור'),
                  Text(
                      style: TextStyle(fontSize: 12),
                      'משך התרגיל $runTime דקות '
                  ),
                ],
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back), // 🔄 Custom back arrow
                onPressed: () {
                  eventController.loading.value = true;
                  Get.back(); // ⬅️ Go back using GetX
                  eventController.loading.value = false;
                },
              ),
            ),
            body: GetX<Controller>(builder: (_) {
              var h = eventController.currentEvent.value.activeParticipants.length / 3 + 2;
              return SingleChildScrollView(
                child:  eventController.currentEvent.value.burGrades.isNotEmpty
                    ? Center(
                  child: Obx(() => eventController.loading.value
                      ? LinearProgressIndicator()
                      : Column(
                    children: [
                      SizedBox(height: 20,),
                      SizedBox(
                        height: h < 2 ? 120 : h * 50,
                        child: GridView.count(
                            childAspectRatio: 3,
                            crossAxisCount: eventController.numberOfCols,
                            children: List.generate(
                                eventController.currentEvent.value.activeParticipants.length, (index) {
                              int burIndex = eventController.currentEvent.value.burGrades.indexWhere((Bur bur) => bur.id == eventController.currentEvent.value.activeParticipants[index].number);
                              return Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        fixedSize: const Size(10, 20),
                                        backgroundColor:  eventController.currentEvent.value.burGrades[burIndex].burGrade!=0?Colors.green:Colors.white
                                    ),
                                    onPressed: () async {
                                      if (eventController.currentEvent.value.finalized) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => BurGradePanel(bur: eventController.currentEvent.value.burGrades[burIndex])),
                                      );
                                    },
                                    onLongPress: () async {
                                      var res = await showDialog<
                                          ParticipantStatus>(
                                          context: context,
                                          builder: (BuildContext context) =>
                                          const ParticipantActionDialog());
                                      if (res!=null){
                                        if (res == ParticipantStatus.Droped) {
                                          eventController.updateParticipantStatus(
                                              eventController.currentEvent.value.activeParticipants[index].number, res);
                                          setState(() {
                                            eventController.currentEvent.value.activeParticipants.removeAt(index);
                                          });
                                        }
                                      }
                                    },
                                    child: Text(eventController.currentEvent.value.activeParticipants[index].number.toString())),
                              );
                            })),
                      ),
                      const Divider(
                        thickness: 30,
                      ),
                      _.currentEvent.value.burEndTime==null
                          ?Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              fixedSize: const Size(150, 20),
                            ),
                            onPressed: () async {
                              eventController.loading.value = true;
                              setState(() {
                                _.currentEvent.value.burEndTime = DateTime.now();
                              });
                              _timer.cancel();
                              eventController.currentEvent.value.saveToFirestore();
                              eventController.loading.value = false;
                            },
                            //eventController.currentEvent.value.save();
                            child: Text('סיום התרגיל')),
                      )
                          :Column(
                        children: [
                          SizedBox(height: 20,),
                          Text('  התרגיל הסתיים  '),
                          SizedBox(height: 20,),
                          eventController.currentEvent.value.burEndTime!=null
                              && eventController.currentEvent.value.burGrades.where((item) => item.burGrade > 0).length<eventController.currentEvent.value.burGrades.length
                              ? Text('  ${eventController.currentEvent.value.burGrades
                              .where((item) => item.burGrade <= 0).length}  משתתפים לא קיבלו ציון סופי ' , textDirection: TextDirection.rtl,
                            style: TextStyle(color: Colors.red),
                          )
                              : SizedBox.shrink()
                        ],
                      ),
                    ],
                  )),
                )
                    : Padding(
                  padding: const EdgeInsets.only(top: 200),
                  child: Center(
                    child: Obx(() => eventController.loading.value
                        ? SizedBox(height: 100, width: 100,child: CircularProgressIndicator(),)
                        : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            fixedSize: const Size(200, 40)),
                        onPressed: () async {
                          _.loading.value = true;
                          //setState(() async {
                          _.currentEvent.value.activeParticipants=[];
                          for (Participant p in _.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active)) {
                            _.currentEvent.value.activeParticipants.add(p);
                            _.currentEvent.value.burGrades.add(Bur(id: p.number));
                          }
                          _.currentEvent.value.burStartTime = DateTime.now();
                          _.currentEvent.value.saveToFirestore();
                          _.currentEvent.refresh();
                          _.loading.value = false;
                          //});
                        },
                        child: const Text(
                          'תחילת תרגיל',
                          style: TextStyle(fontSize: 14),
                        ))
                    ),
                  ),
                ),
              );
            }))
    );
  }
}
