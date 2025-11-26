import 'package:flutter/material.dart';
import '../models/types.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../models/meshulash_round.dart';
import '../widgets/meshulash_round_panel.dart';
import '../widgets/meshulash_grid_view.dart';
import 'dart:async';
import '../widgets/yes_no.dart';
import '../widgets/guideWebView.dart';

class MeshulashPage extends StatefulWidget {
  const MeshulashPage({super.key});

  @override
  State<MeshulashPage> createState() => _MeshulashPageState();
}

class _MeshulashPageState extends State<MeshulashPage> {
  final eventController = Get.put(EventController());
  int runTime = 0;
  late Timer _timer;
  late bool editModeOn;
  bool _isGridView = false;
  final ScrollController _scrollController = ScrollController();

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void initState() {
    if (eventController.currentEvent.value.meshulashEndTime != null) {
      eventController.meshulashEditModeOn.value = false;
      editModeOn = eventController.meshulashEditModeOn.value;
    } else {
      eventController.meshulashEditModeOn.value = true;
      editModeOn = eventController.meshulashEditModeOn.value;
    }
    runTime = eventController.currentEvent.value.getMeshulashRunTime();
    if (eventController.currentEvent.value.meshulashEndTime == null) {
      _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
        setState(() {
          runTime = eventController.currentEvent.value.getMeshulashRunTime();
        });
      });
    }
    _scrollToEnd();
    super.initState();
  }

  @override
  void dispose() {
    if (eventController.currentEvent.value.meshulashEndTime == null)
      _timer.cancel(); // Stop timer when widget is disposed
    super.dispose();
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
            title: Column(
              children: [
                Text('משולש'),
                Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), 'משך התרגיל $runTime דקות ',
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
            actions: [
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                tooltip: _isGridView ? 'מעבר לתצוגת רשימה' : 'מעבר לתצוגת רשת',
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'מדריך למשתמש',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => Directionality(
                      textDirection: TextDirection.rtl,
                      child: const ManualWebView(
                        url: 'https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000&slide=id.g384f00aea19_0_29',
                        //https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000
                      ),
                    ),
                  );
                },
              )
            ],
          ),
          body: GetX<EventController>(builder: (_) {
            editModeOn = _.meshulashEditModeOn.value;
            // Show grid view if enabled
            if (_isGridView) {
              return Obx(() => eventController.loading.value
                  ? LinearProgressIndicator()
                  : Column(
                      children: [
                        Expanded(child: MeshulashGridView()),
                        if (eventController.currentEvent.value.meshulashEndTime == null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 80.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              ),
                              onPressed: () async {
                                var res = await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return YesNoDialog();
                                  },
                                );
                                if (res) {
                                  setState(() {
                                    eventController.currentEvent.value.meshulashEndTime = DateTime.now();
                                    _timer.cancel();
                                    _.meshulashEditModeOn.value = false;
                                    editModeOn = _.meshulashEditModeOn.value;
                                    eventController.currentEvent.value.saveToFirestore();
                                  });
                                }
                              },
                              child: Text('סיום התרגיל',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value),
                              )),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 80.0),
                            child: Column(
                              children: [
                                eventController.currentEvent.value.finalized
                                    ? SizedBox.shrink()
                                    : TextButton.icon(
                                        onPressed: () {
                                          if (editModeOn) {
                                            eventController.currentEvent.value.saveToFirestore();
                                          } else {}
                                          _.meshulashEditModeOn.value = !_.meshulashEditModeOn.value;
                                          setState(() {
                                            editModeOn = !_.meshulashEditModeOn.value;
                                          });
                                        },
                                        icon: editModeOn
                                            ? const Icon(Icons.edit)
                                            : const Icon(Icons.save),
                                        label: !editModeOn
                                            ? Text('סיים',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value),
                                            )
                                            : Text('עריכה',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value),
                                            ),
                                        iconAlignment: IconAlignment.start,
                                      ),
                                SizedBox(height: 20),
                                Text('  התרגיל הסתיים  ',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ));
            }
            // Show existing list view
            return SingleChildScrollView(
              controller: _scrollController,
              child: eventController.currentEvent.value.meshulashRounds.isNotEmpty
                  ? Center(
                      child: Obx(() => eventController.loading.value
                          ? LinearProgressIndicator()
                          : Column(
                              children: [
                                SizedBox(
                                  height: 15,
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                      _.currentEvent.value.meshulashRounds.length,
                                      (index) {
                                    return Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child:
                                          Obx(() => eventController.loading.value
                                              ? CircularProgressIndicator()
                                              : MeshulashRoundPanel(
                                                  round: _.currentEvent.value
                                                      .meshulashRounds[index],
                                                )),
                                    );
                                  }),
                                ),
                                const Divider(
                                  thickness: 30,
                                ),
                                eventController.currentEvent.value
                                            .meshulashEndTime ==
                                        null
                                    ? Padding(
                                        padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 80.0),
                                        child: Column(
                                          children: [
                                            ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                                onPressed: () async {
                                                  var res = await showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return YesNoDialog();
                                                    },
                                                  );
                                                  if (res) {
                                                    setState(() {
                                                      eventController
                                                              .currentEvent
                                                              .value
                                                              .meshulashEndTime =
                                                          DateTime.now();
                                                    });
                                                    await eventController
                                                        .currentEvent.value
                                                        .saveToFirestore();
                                                    _timer.cancel();
                                                    _.meshulashEditModeOn.value =
                                                        false;
                                                    editModeOn =
                                                        _.meshulashEditModeOn.value;
                                                  }
                                                },
                                                child: Text('סיום התרגיל',
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value),
                                                )),
                                            SizedBox(height: 50)
                                          ],
                                        ),
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 80.0),
                                        child: Column(
                                          children: [
                                            eventController
                                                    .currentEvent.value.finalized
                                                ? SizedBox.shrink()
                                                : TextButton.icon(
                                                    onPressed: () async {
                                                      if (editModeOn) {
                                                        ///save
                                                        await eventController
                                                            .currentEvent.value
                                                            .saveToFirestore();
                                                      } else {}
                                                      _.meshulashEditModeOn.value =
                                                          !_.meshulashEditModeOn
                                                              .value;
                                                      setState(() {
                                                        editModeOn = !_
                                                            .meshulashEditModeOn
                                                            .value;
                                                      });
                                                    },
                                                    icon: editModeOn
                                                        ? const Icon(Icons.edit)
                                                        : const Icon(Icons.save),
                                                    label: !editModeOn
                                                        ? Text('סיים',
                                                          style: TextStyle(fontWeight: FontWeight.bold,fontSize: eventController.userFontSize.value),
                                                        )
                                                        : Text('עריכה',
                                                          style: TextStyle(fontWeight: FontWeight.bold,fontSize: eventController.userFontSize.value),
                                                        ),
                                                    iconAlignment:
                                                        IconAlignment.start,
                                                  ),
                                            SizedBox(
                                              height: 20,
                                            ),
                                            Text('  התרגיל הסתיים  ',
                                              style: TextStyle(fontWeight: FontWeight.bold,fontSize: eventController.userFontSize.value),
                                            ),
                                          ],
                                        ),
                                      ),
                              ],
                            )),
                    )
                  : Obx(() => eventController.loading.value
                      ? SizedBox(
                          height: 100,
                          width: 100,
                          child: CircularProgressIndicator(),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 200),
                          child: Column(
                            children: [
                              Obx(() => eventController.loading.value
                                  ? SizedBox(
                                      width: 100,
                                      child: LinearProgressIndicator(),
                                    )
                                  : SizedBox.shrink()),
                              Center(
                                child: Obx(() => eventController.loading.value
                                    ? SizedBox(
                                        height: 100,
                                        width: 100,
                                        child: CircularProgressIndicator(),
                                      )
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          foregroundColor: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        ),
                                        onPressed: () async {
                                          setState(() {
                                            eventController.loading.value = true;
                                            eventController.currentEvent.value
                                                    .meshulashStartTime =
                                                DateTime.now();
                                            _.currentEvent.value.meshulashRounds
                                                .add(MeshulashRound(
                                                    round: 0,
                                                    participantsInRound: _
                                                        .currentEvent.value
                                                        .getParticipantsByStatus(
                                                            ParticipantStatus
                                                                .Active)
                                                        .map((participant) =>
                                                            participant.number)
                                                        .toList()));
                                            eventController.loading.value = false;
                                          });
                                          _.currentEvent.value.saveToFirestore();
                                        },
                                        child: Text(
                                          'תחילת תרגיל',
                                          style: TextStyle(fontSize: eventController.userFontSize.value-5, fontWeight: FontWeight.bold ),
                                        ))),
                              ),
                            ],
                          ),
                        )),
            );
          })),
    );
  }
}
