import 'package:flutter/material.dart';


class AlonkaCreditDialog extends StatelessWidget {
  const AlonkaCreditDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('בחר פעולה'),
          content: const Text('AlertDialog description'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'אלונקה'),
              child: const Text('אלונקה'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'גריקן'),
              child: const Text('גריקן'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'ריצה'),
              child: const Text('ריצה'),
            ),
          ],
        ),
      ),
      child: const Text('Show Dialog'),
    );
  }
}