import 'package:flutter/material.dart';


class YesNoDialog extends StatelessWidget {
  const YesNoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('האם אתה בטוח'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('כן'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('לא'),
        ),
      ],
    );
  }
}

void showCustomMessageAlert(BuildContext context, String title, String message, IconData icon) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Directionality(
        textDirection: TextDirection.rtl, // Enforce RTL
        child: AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: Colors.red), // Custom Icon
              SizedBox(width: 10),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("אישור"),
            ),
          ],
        ),
      );
    },
  );
}