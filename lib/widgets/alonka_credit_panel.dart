import 'package:flutter/material.dart';
import 'package:sairot/models/types.dart';
import '../utils/tablet_utils.dart';


class AlonkaCreditPanel extends StatelessWidget {
  final int participantNumber;
  const AlonkaCreditPanel({super.key, required this.participantNumber});

  @override
  Widget build(BuildContext context) {
    bool tablet = isTablet(context);
    double iconSize = tablet ? 93.6 : 60.0; // 56% bigger total (60 * 1.3 * 1.2 = 93.6)
    double imageWidth = tablet ? 93.6 : 60.0; // 56% bigger total (60 * 1.3 * 1.2 = 93.6)
    double titleFontSize = tablet ? 31.2 : 20.0; // 56% bigger total (20 * 1.3 * 1.2 = 31.2)
    
    return AlertDialog(
      title: Text('בחר פעולה - $participantNumber',
        style: TextStyle(fontSize: titleFontSize),
      ),
      actions: <Widget>[
        IconButton(
            iconSize: iconSize,
            onPressed: () =>
                Navigator.pop(
                    context,
                    AlonkaCreditTypes
                        .Alonka),
            icon: Image.asset(
                color: Theme.of(context).brightness == Brightness.dark?Theme.of(context).colorScheme.primary:Colors.black,
                width: imageWidth,
                'images/alonka.png')
        ),
        IconButton(
            iconSize: iconSize,
            onPressed: () =>
                Navigator.pop(
                    context,
                    AlonkaCreditTypes
                        .Gerikan),
            icon: Image.asset(
                color: Theme.of(context).brightness == Brightness.dark?Theme.of(context).colorScheme.primary:Colors.black,
                width: imageWidth,
                'images/gerikan.png')
        ),
        IconButton(
            iconSize: iconSize,
            onPressed: () =>
                Navigator.pop(
                    context,
                    AlonkaCreditTypes
                        .Runner),
            icon: Image.asset(
                color: Theme.of(context).brightness == Brightness.dark?Theme.of(context).colorScheme.primary:Colors.black,
                width: imageWidth,
                'images/run.png')
        ),
      ],
    );
  }
}