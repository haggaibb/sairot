import 'package:flutter/material.dart';


class LastUpdateWidget extends StatelessWidget {
  final DateTime lastUpdate;
  final DateTime now;
  const LastUpdateWidget({required this.lastUpdate,required this.now, super.key});

  @override
  Widget build(BuildContext context) {
    String lastUpdateStr = '';
    Duration difference = now.difference(lastUpdate);
    if (difference.inMinutes>=0) {
      lastUpdateStr = ' לפני ${difference.inMinutes} דקות ';
    } else {
      lastUpdateStr = ' איו מידע ';
    }
    return Text(lastUpdateStr);
  }
}
