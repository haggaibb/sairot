import 'package:flutter/material.dart';
import 'package:sairot/models/types.dart';


class ParticipantActionDialog extends StatelessWidget {
  const ParticipantActionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('בחר פעולה'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, ParticipantStatus.Droped),
          child: const Text('פרש'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ParticipantStatus.Active),
          child: const Text('פעיל'),
        ),
      ],
    );
  }
}