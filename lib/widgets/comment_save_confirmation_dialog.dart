import 'package:flutter/material.dart';

/// Confirmation dialog for saving or removing comments from instructor's profile
class CommentSaveConfirmationDialog extends StatelessWidget {
  final bool isRemoving; // true if removing, false if saving
  final String comment;

  const CommentSaveConfirmationDialog({
    super.key,
    required this.isRemoving,
    required this.comment,
  });

  static Future<bool?> show(BuildContext context, {required bool isRemoving, required String comment}) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CommentSaveConfirmationDialog(
          isRemoving: isRemoving,
          comment: comment,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isRemoving ? 'הסרת הערה' : 'שמירת הערה',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRemoving
                ? 'האם להסיר את ההערה הבאה מהרשימה האישית שלך?'
                : 'האם לשמור את ההערה הבאה לרשימה האישית שלך?',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              comment,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87, // Dark text for visibility on light background
              ),
            ),
          ),
        ],
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
          child: Text(
            isRemoving ? 'הסר' : 'שמור',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isRemoving ? Colors.red : Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}

