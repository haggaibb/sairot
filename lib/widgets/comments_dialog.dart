import 'package:flutter/material.dart';


class CommentsDialog extends StatefulWidget {
  final List<String> commentsList;
  final List<String>? selectedComments;
  final String? title;

  const CommentsDialog({required this.commentsList, this.selectedComments, this.title='', super.key});

  @override
  State<CommentsDialog> createState() => _CommentsDialogState();
}

class _CommentsDialogState extends State<CommentsDialog> {
  late List<String> instructorComments;

  @override
  void initState() {
    instructorComments = widget.selectedComments??[];
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(  ' בחר הערה עבור מספר ${widget.title!}'),
      content:  Wrap(
        spacing: 12,
        children: widget.commentsList.map((comment) {
          bool isSelected = instructorComments.contains(comment);
          return ChoiceChip(
            label: Text(comment),
            selected: isSelected,
            selectedColor: Colors.blue
                .withOpacity(0.3), // Change color when selected
            onSelected: (bool selected) async {
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
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, instructorComments),
          child: const Text('שמור'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('בטל'),
        ),
      ],
    );
  }
}
