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
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('דף ציונים לבור'),
        ),
        body: GetX<Controller>(builder: (_) {
          List<String> commentsList = eventController
              .currentEvent.value.gradeSettings.listOfCommentsBur;
          return Center(
            child: Column(
              children: [
                Text(widget.bur.id.toString(),
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Text('הערות לבחירה',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 40),
                // ChoiceChip Selection
                Wrap(
                  spacing: 12,
                  children: commentsList.map((comment) {
                    bool isSelected =
                        widget.bur.instructorComments.contains(comment);
                    return ChoiceChip(
                      label: Text(comment),
                      selected: isSelected,
                      selectedColor: Colors.blue
                          .withOpacity(0.3), // Change color when selected
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
                    // Styled Input Field
                    Container(
                      width: 80, // Increased width for better visibility
                      padding: EdgeInsets.symmetric(
                          horizontal: 10), // Padding inside the container
                      decoration: BoxDecoration(
                        color: Colors.white, // Background color
                        borderRadius:
                            BorderRadius.circular(10), // Rounded corners
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5), // Shadow color
                            spreadRadius: 2,
                            blurRadius: 4,
                            offset:
                                Offset(2, 2), // Offset to make shadow visible
                          ),
                        ],
                        border: Border.all(
                            color: Colors.blue,
                            width: 2), // Border color and width
                      ),
                      child: TextField(
                        controller: gradeCtrl,
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
                        keyboardType:
                            TextInputType.number, // Ensure numeric input
                        decoration: InputDecoration(
                          border: InputBorder.none, // Remove default border
                          hintText: "0", // Placeholder text
                          hintStyle: TextStyle(
                              color: Colors.grey.shade600), // Hint color
                        ),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold), // Text styling
                      ),
                    ),

                    SizedBox(width: 10), // Spacing between input and label

                    // Styled Label
                    Text(
                      'ציון סופי',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87, // Adjusted for better contrast
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }));
  }
}
