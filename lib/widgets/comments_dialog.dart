import 'package:flutter/material.dart';
import '../models/types.dart';
import '../event_controller.dart';
import 'comment_save_confirmation_dialog.dart';
import 'package:get/get.dart';

class CommentsDialog extends StatefulWidget {
  final List<String> commentsList; // Predefined comments
  final List<String>? selectedComments; // Instructor-selected comments
  final String? title;
  final ExerciseType? exerciseType; // Exercise type for saving comments
  final List<String>? instructorCustomComments; // Instructor's saved custom comments

  const CommentsDialog({
    required this.commentsList,
    this.selectedComments,
    this.title = '',
    this.exerciseType,
    this.instructorCustomComments,
    super.key,
  });

  @override
  State<CommentsDialog> createState() => _CommentsDialogState();
}

class _CommentsDialogState extends State<CommentsDialog> {
  late List<String> predefinedComments;
  late List<String> sessionOnlyCustomComments; // Comments added in this session, not saved to profile
  late List<String> instructorSavedComments; // Comments saved to instructor's profile
  late List<String> instructorComments; // All selected comments
  TextEditingController customCommentCtrl = TextEditingController();
  final eventController = Get.put(EventController());

  @override
  void initState() {
    super.initState();

    // Predefined comments (fixed list from GradeSettings)
    predefinedComments = List<String>.from(widget.commentsList);

    // Instructor's saved custom comments (from profile)
    instructorSavedComments = List<String>.from(widget.instructorCustomComments ?? []);

    // Load selected comments (including predefined + any custom ones)
    instructorComments = List<String>.from(widget.selectedComments ?? []);

    // Identify which selected comments are session-only (not in predefined, not in instructor's saved)
    sessionOnlyCustomComments = instructorComments
        .where((c) => !predefinedComments.contains(c) && !instructorSavedComments.contains(c))
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
        instructorComments.add(newComment); // Add to selected comments
      });

      // Clear input field
      customCommentCtrl.clear();
    }
  }

  /// **Deletes a Session-Only Custom Comment Completely**
  void deleteSessionOnlyComment(String comment) {
    setState(() {
      sessionOnlyCustomComments.remove(comment);
      instructorComments.remove(comment);
    });
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
    
    if (widget.exerciseType == null) {
      return; // Can't save without exercise type
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
          widget.exerciseType!.name,
          comment,
        );
        
        if (success && mounted) {
          // Update local state
          setState(() {
            instructorSavedComments.remove(comment);
            // Reload from controller
            final updatedComments = eventController.getInstructorCustomCommentsForExercise(widget.exerciseType!.name);
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
          widget.exerciseType!.name,
          comment,
        );
        
        if (success && mounted) {
          // Update local state
          setState(() {
            sessionOnlyCustomComments.remove(comment);
            // Reload from controller (this will include the newly saved comment after loadInstructorCustomComments is called)
            // Use a small delay to ensure the observable has updated
            Future.microtask(() {
              if (mounted) {
                setState(() {
                  final updatedComments = eventController.getInstructorCustomCommentsForExercise(widget.exerciseType!.name);
                  // Remove duplicates just in case
                  instructorSavedComments = updatedComments.toSet().toList();
                });
              }
            });
            // Also update immediately (the comment should be there after saveInstructorCustomComment calls loadInstructorCustomComments)
            final updatedComments = eventController.getInstructorCustomCommentsForExercise(widget.exerciseType!.name);
            instructorSavedComments = updatedComments.toSet().toList();
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

    return SingleChildScrollView(
      child: AlertDialog(
        title: Text('בחר הערה עבור מספר ${widget.title!}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// **Custom Comment Input (Multi-line)**
            TextField(
              controller: customCommentCtrl,
              maxLines: null,
              minLines: 3,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
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
            const SizedBox(height: 10),
            /// **Comments List (Instructor's saved first, then predefined, then session-only)**
            Wrap(
              spacing: 12,
              runSpacing: 12,
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
                  selectedColor: Colors.blue.withValues(alpha: 0.3), // Light blue for selection
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
            const SizedBox(height: 10),
          ],

        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              // Auto-add comment from input field if not empty
              String textInField = customCommentCtrl.text.trim();
              if (textInField.isNotEmpty &&
                  !predefinedComments.contains(textInField) &&
                  !instructorSavedComments.contains(textInField) &&
                  !sessionOnlyCustomComments.contains(textInField)) {
                setState(() {
                  sessionOnlyCustomComments.add(textInField);
                  instructorComments.add(textInField);
                });
                customCommentCtrl.clear();
              }
              
              // ✅ Ensure custom comments are included when saving
              // Remove duplicates to prevent issues when comments are moved from session-only to saved
              List<String> finalSelectedComments = instructorComments.toSet().toList();

              // ✅ Ensure Firestore saves the custom comments
              Navigator.pop(context, finalSelectedComments);
            },
            child: Text(
              'שמור',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              'בטל',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Show warning dialog before dropping participant
              final confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text(
                      'אזהרה',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    content: const Text(
                      'פעולה זו היא סופית ולא ניתנת לביטול.\n\n'
                      'אם המשתתף רק הלך למרפאה, אל תסיר אותו - פשוט התעלם ממספרו בתרגיל.',
                      style: TextStyle(fontSize: 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'ביטול',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'אישור',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
              
              if (confirm == true) {
                Navigator.pop(context, [ParticipantStatus.Droped.name]);
              }
            },
            child: Text(
              'פרש',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: eventController.userFontSize.value),
            ),
          ),
        ],
      ),
    );
  }
}