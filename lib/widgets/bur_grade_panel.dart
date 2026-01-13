import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/bur.dart';
import '../event_controller.dart';
import 'comment_save_confirmation_dialog.dart';

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
  late List<String> sessionOnlyCustomComments; // Comments added in this session, not saved to profile
  late List<String> instructorSavedComments; // Comments saved to instructor's profile
  late List<String> instructorComments; // All selected comments
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

    // Load instructor's saved custom comments
    instructorSavedComments = eventController.getInstructorCustomCommentsForExercise('bur');

    // Identify which selected comments are session-only (not in predefined, not in instructor's saved)
    sessionOnlyCustomComments = instructorComments
        .where((comment) => !predefinedComments.contains(comment) && !instructorSavedComments.contains(comment))
        .toList();
  }

  /// **Adds a New Custom Comment**
  void addCustomComment() {
    String newComment = customCommentCtrl.text.trim();
    if (newComment.isNotEmpty &&
        !predefinedComments.contains(newComment) &&
        !instructorSavedComments.contains(newComment) &&
        !sessionOnlyCustomComments.contains(newComment)) {
      setState(() {
        sessionOnlyCustomComments.add(newComment);
        instructorComments.add(newComment);
      });

      // Save updated comments to Firestore (non-blocking)
      saveToFirestore();

      // Clear input field
      customCommentCtrl.clear();
    }
  }

  /// **Deletes a Session-Only Custom Comment**
  void deleteSessionOnlyComment(String comment) {
    setState(() {
      sessionOnlyCustomComments.remove(comment);
      instructorComments.remove(comment);
    });

    // Save updated comments to Firestore (non-blocking)
    saveToFirestore();
  }

  /// **Handle long-press on comment to save/remove from instructor profile**
  Future<void> handleCommentLongPress(String comment) async {
    // Check if comment is in instructor's saved list
    final isInInstructorSaved = instructorSavedComments.contains(comment);
    
    // Check if comment is session-only (not in predefined, not in instructor's saved)
    final isSessionOnly = !predefinedComments.contains(comment) && !isInInstructorSaved;
    
    // Only allow long-press on instructor's saved comments (to remove) or session-only (to save)
    if (!isInInstructorSaved && !isSessionOnly) {
      return; // System predefined - no long-press
    }
    
    // Show confirmation dialog
    final confirmed = await CommentSaveConfirmationDialog.show(
      context,
      isRemoving: isInInstructorSaved,
      comment: comment,
    );
    
    if (confirmed == true) {
      if (isInInstructorSaved) {
        // Remove from instructor's profile
        final success = await eventController.removeInstructorCustomComment(
          'bur',
          comment,
        );
        
        if (success && mounted) {
          // Update local state
          setState(() {
            instructorSavedComments.remove(comment);
            // Reload from controller
            final updatedComments = eventController.getInstructorCustomCommentsForExercise('bur');
            instructorSavedComments = List<String>.from(updatedComments);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ההערה הוסרה מהרשימה האישית שלך'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (isSessionOnly) {
        // Save to instructor's profile
        final success = await eventController.saveInstructorCustomComment(
          'bur',
          comment,
        );
        
        if (success && mounted) {
          // Update local state
          setState(() {
            sessionOnlyCustomComments.remove(comment);
            // Reload from controller
            final updatedComments = eventController.getInstructorCustomCommentsForExercise('bur');
            instructorSavedComments = List<String>.from(updatedComments);
            if (!instructorSavedComments.contains(comment)) {
              instructorSavedComments.add(comment);
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ההערה נשמרה לרשימה האישית שלך'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// **Saves Instructor Comments to Firestore**
  void saveToFirestore() {
    widget.bur.instructorComments = List.from(instructorComments);
    eventController.currentEvent.value.burGrades[burIndex] = widget.bur;
    // Use non-blocking save to prevent delays when offline
    eventController.saveEventWithOfflineSupport(eventController.currentEvent.value);
  }

  @override
  Widget build(BuildContext context) {
    /// **Order comments: Instructor's saved first, then predefined, then session-only**
    // Remove duplicates (instructor's saved takes precedence)
    final predefinedFiltered = predefinedComments
        .where((c) => !instructorSavedComments.contains(c))
        .toList();
    
    final allComments = [
      ...instructorSavedComments, // First: Instructor's custom comments
      ...predefinedFiltered, // Second: Predefined comments (excluding instructor's saved)
      ...sessionOnlyCustomComments, // Third: Session-only custom comments
    ];

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
                        final isInInstructorSaved = instructorSavedComments.contains(comment);
                        final isSessionOnly = sessionOnlyCustomComments.contains(comment);
                        
                        // Only enable long-press for instructor's saved comments or session-only comments
                        final canLongPress = isInInstructorSaved || isSessionOnly;

                        Widget chip = ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isInInstructorSaved)
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              if (isInInstructorSaved) const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  comment,
                                  style: TextStyle(
                                    fontSize: eventController.userFontSize.value,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: Colors.blue.withValues(alpha: 0.3),
                          backgroundColor: isInInstructorSaved
                              ? Colors.amber.withValues(alpha: 0.1) // Light amber background for saved comments
                              : null,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                instructorComments.add(comment);
                              } else {
                                instructorComments.remove(comment);
                              }
                            });
                            saveToFirestore();
                          },
                        );
                        
                        // Wrap with GestureDetector for long-press if eligible
                        if (canLongPress) {
                          chip = GestureDetector(
                            onLongPress: () => handleCommentLongPress(comment),
                            child: chip,
                          );
                        }
                        
                        return chip;
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
                              // Trigger refresh so grid updates
                              eventController.currentEvent.refresh();
                              eventController.update();
                              // Use non-blocking save to prevent delays when offline
                              eventController.saveEventWithOfflineSupport(
                                eventController.currentEvent.value
                              );
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