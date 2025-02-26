import 'package:flutter/material.dart';
import 'package:sairot/models/grade_settings.dart';
import 'package:sairot/models/participant.dart';
import '../ctx.dart';
import 'package:get/get.dart';
import 'package:sairot/models/bur.dart';

class BurGradePanel extends StatefulWidget {
  final Bur bur;
  const BurGradePanel({super.key, required this.bur});

  @override
  State<BurGradePanel> createState() => _BurGradePanelState();
}

class _BurGradePanelState extends State<BurGradePanel> {
  final eventController = Get.put(Controller());
  TextEditingController gradeCtrl = TextEditingController();
  int burIndex=0;
  @override
  void initState() {
    burIndex = eventController
        .currentEvent.value.burGrades
        .indexWhere((Bur bur) => bur.id == widget.bur.id);
    gradeCtrl.text = eventController.currentEvent.value.burGrades[burIndex].burGrade.toString();
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
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            centerTitle: true,
            title: Text('דף ציונים לבור'),
          ),
          body: GetX<Controller>(builder: (_) {
            List<String> commentsList = eventController
                .currentEvent.value.gradeSettings.listOfCommentsBur;
            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard when tapping outside
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(widget.bur.id.toString(),
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 20),
                      Text('הערות לבחירה',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 40),
                      // ✅ Wrap inside SingleChildScrollView
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: commentsList.map((comment) {
                          bool isSelected = widget.bur.instructorComments.contains(comment);
                          return ChoiceChip(
                            label: Text(comment, style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value)),
                            selected: isSelected,
                            selectedColor: Colors.blue, // Change color when selected
                            onSelected: (bool selected) async {
                              setState(() {
                                if (selected) {
                                  widget.bur.instructorComments.add(comment);
                                } else {
                                  widget.bur.instructorComments.remove(comment);
                                }
                              });
                              eventController.currentEvent.value
                                  .burGrades[burIndex] = widget.bur;
                              await eventController.currentEvent.value.saveToFirestore();
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 10),
                          // Styled Input Field
                          Container(
                            width: 80, // Increased width for better visibility
                            height: 60,
                            child: TextField(
                              controller: gradeCtrl,
                              onTap: () {
                                gradeCtrl.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: gradeCtrl.text.length,
                                );
                              },
                              onChanged: (val) async {
                                eventController.loading.value = true;
                                widget.bur.burGrade = double.parse(val);
                                eventController.currentEvent.value
                                    .burGrades[burIndex] = widget.bur;
                                await eventController.currentEvent.value.saveToFirestore();
                                eventController.update();
                                eventController.loading.value = false;
                              },
                              textAlign: TextAlign.center, // Center align text
                              keyboardType: TextInputType.number, // Ensure numeric input
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.blue.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20), // Circular shape
                                  borderSide: BorderSide.none, // Remove default border
                                ),                                hintText: "0", // Placeholder text
                                hintStyle: TextStyle(color: Colors.grey), // Hint color
                              ),
                              style: TextStyle(fontSize: eventController.userFontSize.value, fontWeight: FontWeight.bold, color: Colors.black), // Text styling
                            ),
                          ),
                          SizedBox(width: 10), // Spacing between input and label
                          // Styled Label
                          Text(
                            'ציון סופי',
                            style: TextStyle(
                              fontSize: eventController.userFontSize.value,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 50),
                      ElevatedButton(
                          onPressed: () => {Get.back()},
                          child: Text('סגור', style: TextStyle(fontSize: eventController.userFontSize.value,fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ),
            );
          })),
    );
  }
}
