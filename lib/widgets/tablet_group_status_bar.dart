import 'package:flutter/material.dart';
import '../models/event.dart';

class TabletGroupStatusBar extends StatelessWidget {
  final Event event;
  TabletGroupStatusBar({super.key, required this.event});

  @override
  Color meshulashColor = Colors.black;
  Color alonkaColor = Colors.black;
  Color burColor = Colors.black;
  Color sakimColor = Colors.black;

  Widget build(BuildContext context) {
    if (event.meshulashStartTime != null) {
      if (event.meshulashEndTime != null) {
        /// its done
        meshulashColor = Colors.green;
      } else {
        /// not done yet return also calc duration?
        meshulashColor = Colors.red;
      }
    }
    if (event.alonkaStartTime != null) {
      if (event.alonkaEndTime != null) {
        /// its done
        alonkaColor = Colors.green;
      } else {
        /// not done yet return also calc duration?
        alonkaColor = Colors.red;
      }
    }
    if (event.burStartTime != null) {
      if (event.burEndTime != null) {
        /// its done
        burColor = Colors.green;
      } else {
        /// not done yet return also calc duration?
        burColor = Colors.red;
      }
    }
    if (event.sakimStartTime != null) {
      if (event.sakimEndTime != null) {
        /// its done
        sakimColor = Colors.green;
      } else {
        /// not done yet return also calc duration?
        sakimColor = Colors.red;
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Stack(children: [
          IconButton(
            icon: Image.asset(
                color: meshulashColor,
                'images/meeshulash.png'), // ✅ Use the image as an icon
            iconSize: 20, // Adjust size
            onPressed: () {},
          ),
          // 🔹 Transparent Number Overlay
          meshulashColor == Colors.red
              ? Positioned(
                  top: 5, // Adjust position
                  right: 5,
                  child: Container(
                    padding: EdgeInsets.all(5),
                    child: Text(
                      (event.meshulashRounds.length - 1)
                          .toString(), // Change this dynamically
                      style: TextStyle(
                          color: Colors.black, // ✅ Text color
                          fontWeight: FontWeight.bold,
                          fontSize: 26),
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ]),
        Stack(children: [
          IconButton(
            icon: Image.asset(
                color: alonkaColor,
                'images/alonka.png'), // ✅ Use the image as an icon
            iconSize: 20, // Adjust size
            onPressed: () {},
          ),

          // 🔹 Transparent Number Overlay
          alonkaColor == Colors.red
              ? Positioned(
                  top: 5, // Adjust position
                  right: 5,
                  child: Container(
                    padding: EdgeInsets.all(5),
                    child: Text(
                      event.alonkaSprints.length
                          .toString(), // Change this dynamically
                      style: TextStyle(
                          color: Colors.black, // ✅ Text color
                          fontWeight: FontWeight.bold,
                          fontSize: 26),
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ]),
        Stack(children: [
          IconButton(
            icon: Image.asset(
                color: burColor,
                'images/bur.png'), // ✅ Use the image as an icon
            iconSize: 20, // Adjust size
            onPressed: () {},
          ),
          // 🔹 Transparent Number Overlay
          burColor == Colors.red
              ? Positioned(
                  top: 5, // Adjust position
                  right: 5,
                  child: Container(
                    padding: EdgeInsets.all(5),
                    child: Text(
                      event
                          .getBurRunTime()
                          .toString(), // Change this dynamically
                      style: TextStyle(
                          color: Colors.black, // ✅ Text color
                          fontWeight: FontWeight.bold,
                          fontSize: 26),
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ]),
        Stack(children: [
          IconButton(
            icon: Image.asset(
                color: sakimColor,
                'images/sakim.png'), // ✅ Use the image as an icon
            iconSize: 20, // Adjust size
            onPressed: () {},
          ),
          // 🔹 Transparent Number Overlay
          sakimColor == Colors.red
              ? Positioned(
                  top: 5, // Adjust position
                  right: 5,
                  child: Container(
                    padding: EdgeInsets.all(5),
                    child: Text(
                      (event.sakimRounds.length - 1)
                          .toString(), // Change this dynamically
                      style: TextStyle(
                          color: Colors.black, // ✅ Text color
                          fontWeight: FontWeight.bold,
                          fontSize: 26),
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ]),
      ],
    );
  }
}
