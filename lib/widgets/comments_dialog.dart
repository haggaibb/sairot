import 'package:flutter/material.dart';
import 'package:sairot/performance_page.dart';


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
    return SingleChildScrollView(
      child: AlertDialog(
        title: Text(  ' בחר הערה עבור מספר ${widget.title!}'),
        content:  Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.commentsList.map((comment) {
            bool isSelected = instructorComments.contains(comment);
            return ChoiceChip(
              label: Text(comment,
                style: TextStyle(
                  fontSize: eventController.userFontSize.value,
                    fontWeight: FontWeight.bold
                ),
              ),
              selected: isSelected,
              selectedColor: Color.fromARGB(
                  (0.3 * 255).toInt(),  // Alpha value (opacity 30%)
                  Colors.blue.computeLuminance() > 0.5 ? 0 : 255, // Red channel
                  Colors.blue.computeLuminance() > 0.5 ? 0 : 255, // Green channel
                  Colors.blue.computeLuminance() > 0.5 ? 0 : 255  // Blue channel
              ), // Change color when selected
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
            child: Text('שמור',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('בטל',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: eventController.userFontSize.value),
            ),
          ),
        ],
      ),
    );
  }
}
