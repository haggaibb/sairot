import 'package:flutter/material.dart';
import 'package:sairot/models/types.dart';
import 'models/types.dart';
import 'ctx.dart';
import 'package:get/get.dart';
import 'widgets/participant_action_dialog.dart';


class ParticipantsStatusPage extends StatefulWidget {
  const ParticipantsStatusPage({super.key});


  @override
  State<ParticipantsStatusPage> createState() => _ParticipantsStatusPageState();
}

class _ParticipantsStatusPageState extends State<ParticipantsStatusPage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('סטטוס חניכים'),
        ),
        body: GetX<Controller>(builder: (_) {
          var hActive = _.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active).length / 3 + 2;
          hActive = hActive < 2 ? 120 : hActive * 75;
          return SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    children: [
                      SizedBox(height: 10,),
                      const Text('פעילים',style: TextStyle(fontSize: 24),),
                      SizedBox(
                        height: hActive,
                        child: GridView.count(
                            childAspectRatio: 2,
                            crossAxisCount: 3, //_.displaySettings.value.numberOfCols,
                            children: List.generate(
                                _.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active).length, (index) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        fixedSize: const Size(10, 20),
                                    ),
                                    onPressed: ()  {

                                    },
                                    onLongPress: () async {
                                      if (_.currentEvent.value.finalized) return;
                                      var res = await showDialog<ParticipantStatus>(
                                          context: context,
                                          builder: (BuildContext context) => ParticipantActionDialog()
                                      );
                                      if (res!=null && res!=ParticipantStatus.Active) {
                                        setState(() {
                                          _.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active)[index].status = ParticipantStatus.Droped;
                                        });
                                      }
                                    },
                                    child: Text(_.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active)[index].number.toString(), style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold))
                                ),
                              );
                            })),
                      ),
                      const Divider(thickness: 15,),
                      const Text('פרשו',style: TextStyle(fontSize: 24),),
                      SizedBox(
                        height: 200,
                        child: GridView.count(
                            childAspectRatio: 2,
                            crossAxisCount: 3, //_.displaySettings.value.numberOfCols,
                            children: List.generate(
                                _.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Droped).length, (index) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        fixedSize: const Size(10, 20),
                                    ),
                                    onPressed: ()  {
                                    },
                                    onLongPress: () async {
                                      if (_.currentEvent.value.finalized) return;
                                      var res = await showDialog<ParticipantStatus>(
                                          context: context,
                                          builder: (BuildContext context) => ParticipantActionDialog()
                                      );
                                      if (res!=null && res!=ParticipantStatus.Droped) {
                                        setState(() {
                                          _.currentEvent.value.activeParticipants.add(_.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Droped)[index]);
                                          _.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Droped)[index].status = ParticipantStatus.Active;
                                        });
                                      }
                                      //_.setKidStatus(foldedParticipants[index], res);
                                      /// todo change kid status (active, dropped)
                                    },
                                    child: Text(
                                        _.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Droped)[index].number.toString()
                                        , style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold))
                                ),
                              );
                            })),
                      ),
                    ],
                  ),
                ),
              ));
        }));
  }
}
