import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/bur.dart';
import '../event_controller.dart';

class BurGradePanel extends StatefulWidget {
  final Bur bur;
  const BurGradePanel({super.key, required this.bur});

  @override
  State<BurGradePanel> createState() => _BurGradePanelState();
}

class _BurGradePanelState extends State<BurGradePanel> {
  final eventController = Get.put(EventController());
  TextEditingController gradeCtrl = TextEditingController();
  TextEditingController customCommentCtrl = TextEditingController();

  late List<String> predefinedComments;
  late List<String> customComments;
  late List<String> instructorComments;
  int burIndex = 0;

  @override
  void initState() {
    super.initState();

    burIndex = eventController.currentEvent.value.burGrades
        .indexWhere((Bur bur) => bur.id == widget.bur.id);

    gradeCtrl.text =
        eventController.currentEvent.value.burGrades[burIndex].burGrade.toString();

    instructorComments = List.from(widget.bur.instructorComments);

    predefinedComments = List<String>.from(eventController.currentEvent.value.gradeSettings.listOfCommentsBur);

    // **Identify which selected comments are custom**
    customComments = instructorComments.where((comment) => !predefinedComments.contains(comment)).toList();
  }

  /// **Adds a New Custom Comment**
  void addCustomComment() {
    String newComment = customCommentCtrl.text.trim();
    if (newComment.isNotEmpty &&
        !predefinedComments.contains(newComment) &&
        !customComments.contains(newComment)) {
      setState(() {
        customComments.add(newComment);
        instructorComments.add(newComment);
      });

      // Save updated comments to Firestore (non-blocking)
      saveToFirestore();

      // Clear input field
      customCommentCtrl.clear();
    }
  }

  /// **Deletes a Custom Comment**
  void deleteCustomComment(String comment) {
    setState(() {
      customComments.remove(comment);
      instructorComments.remove(comment);
    });

    // Save updated comments to Firestore (non-blocking)
    saveToFirestore();
  }

  /// **Saves Instructor Comments to Firestore**
  void saveToFirestore() {
    widget.bur.instructorComments = List.from(instructorComments);
    eventController.currentEvent.value.burGrades[burIndex] = widget.bur;
    eventController.currentEvent.value.saveToFirestore();
  }

  @override
  Widget build(BuildContext context) {
    /// **Combine Predefined & Custom Comments for UI Display**
    List<String> allComments = [...predefinedComments, ...customComments];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, const Color.fromARGB(255, 0, 66, 136)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          centerTitle: true,
          title: const Text('דף ציונים לבור'),
        ),
        body: GetX<EventController>(builder: (_) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      widget.bur.id.toString(),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    const Text('הערות לבחירה', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    /// **Unified Comments List (Predefined + Custom)**
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: allComments.map((comment) {
                        bool isSelected = instructorComments.contains(comment);
                        bool isCustom = customComments.contains(comment);

                        return GestureDetector(
                          onLongPress: isCustom
                              ? () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("מחיקת הערה"),
                                content: Text("האם למחוק את ההערה \"$comment\"?"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      deleteCustomComment(comment);
                                      Navigator.pop(context);
                                    },
                                    child: const Text("מחק"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("ביטול"),
                                  ),
                                ],
                              ),
                            );
                          }
                              : null,
                          child: ChoiceChip(
                            label: Text(
                              comment,
                              style: TextStyle(
                                fontSize: eventController.userFontSize.value,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: isCustom ? Colors.blue.withValues(alpha: 0.3) : Colors.blue,
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  instructorComments.add(comment);
                                } else {
                                  instructorComments.remove(comment);
                                  if (isCustom) {
                                    customComments.remove(comment);
                                  }
                                }
                              });
                              print(customComments);
                              saveToFirestore();
                            },
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    /// **Custom Comment Input**
                    TextField(
                      controller: customCommentCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'הוסף הערה חדשה...',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: addCustomComment,
                        ),
                      ),
                      onSubmitted: (_) => addCustomComment(),
                    ),

                    const SizedBox(height: 30),

                    /// **Final Grade Input**
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 10),
                        Container(
                          width: 80,
                          height: 60,
                          child: TextField(
                            controller: gradeCtrl,
                            onTap: () {
                              gradeCtrl.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: gradeCtrl.text.length,
                              );
                            },
                            onChanged: (val) {
                              widget.bur.burGrade = double.parse(val);
                              eventController.currentEvent.value.burGrades[burIndex] = widget.bur;
                              eventController.currentEvent.value.saveToFirestore();
                              eventController.update();
                            },
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.blue.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              hintText: "0",
                              hintStyle: const TextStyle(color: Colors.grey),
                            ),
                            style: TextStyle(
                                fontSize: eventController.userFontSize.value,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'ציון סופי',
                          style: TextStyle(
                            fontSize: eventController.userFontSize.value,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 50),

                    /// **Close Button**
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'סגור',
                        style: TextStyle(
                            fontSize: eventController.userFontSize.value,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}