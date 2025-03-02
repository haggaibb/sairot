import 'package:flutter/material.dart';
import '../models/event.dart';
import 'package:get/get.dart';
import '../event_controller.dart';
import 'yes_no.dart';


class UnfinalizedPanel extends StatelessWidget {
  final Event event;
  UnfinalizedPanel({required this.event,super.key});

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(Controller());
    return Padding(
      padding: const EdgeInsets.only(left:20.0, right: 10),
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: 20, vertical: 10),
        padding: EdgeInsets.only(
            left: 60, right: 60, top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest, // 🆕
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 20.0, top: 5),
              child: Center(
                  child: Text('ארוע פעיל',
                      style: const TextStyle(
                          fontSize: 22,
                          color: Colors.green,
                          fontWeight: FontWeight.bold))),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: 15,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(' תאריך: ',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text(
                      event.date,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: 20,
                bottom: 30
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(' מספר קבוצה: ',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text(
                      event.groupNumber.toString(),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 10,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary,
                    foregroundColor: Theme.of(context)
                        .colorScheme
                        .onPrimary,
                  ),
                  onPressed: () async {
                    eventController.loading.value =
                    true;
                    var res = await showDialog(
                      context: context,
                      builder:
                          (BuildContext context) {
                        return YesNoDialog();
                      },
                    );
                    if (res) {
                      eventController
                          .unfinalizedLoading
                          .value = true;
                      await eventController.delEvent(event);
                      eventController
                          .unfinalizedEvents
                          .clear();
                      await eventController
                          .getUnfinalizedEvents();
                    } else {

                    }
                    eventController.loading.value =
                    false;
                    eventController.currentEvent.value = Event(date: '', instructorId: '', eventName: '');
                    eventController
                        .unfinalizedLoading
                        .value = false;
                  },
                  child: const Text('מחק',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 10,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary,
                    foregroundColor: Theme.of(context)
                        .colorScheme
                        .onPrimary,
                  ),
                  onPressed: () async {
                    eventController.loading.value =
                    true;
                    eventController
                        .currentEvent.value =
                    event;
                    eventController.loading.value =
                    false;
                    Get.toNamed('/event_home');
                  },
                  child: const Text('טען',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              mainAxisAlignment:
              MainAxisAlignment.spaceAround,
            ),
            /// participants count
          ],
        ),
      ),
    );
  }
}
