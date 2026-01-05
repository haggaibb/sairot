import 'package:flutter/material.dart';
import 'package:sairot/pages/performance_page.dart';
import '../models/types.dart';

class CommentsDialog extends StatefulWidget {
  final List<String> commentsList; // Predefined comments
  final List<String>? selectedComments; // Instructor-selected comments
  final String? title;

  const CommentsDialog({
    required this.commentsList,
    this.selectedComments,
    this.title = '',
    super.key,
  });

  @override
  State<CommentsDialog> createState() => _CommentsDialogState();
}

class _CommentsDialogState extends State<CommentsDialog> {
  late List<String> predefinedComments;
  late List<String> customComments;
  late List<String> instructorComments;
  TextEditingController customCommentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Predefined comments (fixed list)
    predefinedComments = List<String>.from(widget.commentsList);

    // Load selected comments (including predefined + any custom ones)
    instructorComments = List<String>.from(widget.selectedComments ?? []);

    // Identify which selected comments are custom
    customComments = instructorComments.where((c) => !predefinedComments.contains(c)).toList();
  }

  /// **Adds a New Custom Comment**
  void addCustomComment() {
    String newComment = customCommentCtrl.text.trim();
    if (newComment.isNotEmpty &&
        !predefinedComments.contains(newComment) &&
        !customComments.contains(newComment)) {
      setState(() {
        customComments.add(newComment);
        instructorComments.add(newComment); // Add to selected comments
      });

      // Clear input field
      customCommentCtrl.clear();
    }
  }

  /// **Deletes a Custom Comment Completely**
  void deleteCustomComment(String comment) {
    setState(() {
      customComments.remove(comment);
      instructorComments.remove(comment);
    });
  }

  @override
  Widget build(BuildContext context) {
    /// **Combine Predefined & Custom Comments for UI Display**
    List<String> allComments = [...predefinedComments, ...customComments];

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
            /// **Comments List (Predefined & Custom)**
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: allComments.map((comment) {
                bool isSelected = instructorComments.contains(comment);
                //bool isCustom = customComments.contains(comment);
                return ChoiceChip(
                  label: Text(
                    comment,
                    style: TextStyle(
                      fontSize: eventController.userFontSize.value,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.blue.withValues(alpha: 0.3), // Light blue for selection
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
                  !customComments.contains(textInField)) {
                setState(() {
                  customComments.add(textInField);
                  instructorComments.add(textInField);
                });
                customCommentCtrl.clear();
              }
              
              // ✅ Ensure custom comments are included when saving
              List<String> finalSelectedComments = List.from(instructorComments);

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
            onPressed: () {
              Navigator.pop(context, [ParticipantStatus.Droped.name] );
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