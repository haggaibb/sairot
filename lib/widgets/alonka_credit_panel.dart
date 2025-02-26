import 'package:flutter/material.dart';
import 'package:sairot/models/types.dart';


class AlonkaCreditPanel extends StatelessWidget {
  const AlonkaCreditPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('בחר פעולה'),
      actions: <Widget>[
        IconButton(
            iconSize: 60,
            onPressed: () =>
                Navigator.pop(
                    context,
                    AlonkaCreditTypes
                        .Alonka),
            icon: Image.asset(
                color: Theme.of(context).brightness == Brightness.dark?Theme.of(context).colorScheme.primary:Colors.black,
                width: 60,
                'images/alonka.png')
        ),
        IconButton(
            iconSize: 60,
            onPressed: () =>
                Navigator.pop(
                    context,
                    AlonkaCreditTypes
                        .Gerikan),
            icon: Image.asset(
                color: Theme.of(context).brightness == Brightness.dark?Theme.of(context).colorScheme.primary:Colors.black,
                width: 60,
                'images/gerikan.png')
        ),
        IconButton(
            iconSize: 60,
            onPressed: () =>
                Navigator.pop(
                    context,
                    AlonkaCreditTypes
                        .Runner),
            icon: Image.asset(
                color: Theme.of(context).brightness == Brightness.dark?Theme.of(context).colorScheme.primary:Colors.black,
                width: 60,
                'images/run.png')
        ),
      ],
    );
  }
}