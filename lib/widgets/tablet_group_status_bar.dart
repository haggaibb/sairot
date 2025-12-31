import 'package:flutter/material.dart';
import '../models/event.dart';

class TabletGroupStatusBar extends StatelessWidget {
  final Event event;
  TabletGroupStatusBar({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    Color meshulashColor = Colors.black;
    Color alonkaColor = Colors.black;
    Color burColor = Colors.black;
    Color sakimColor = Colors.black;
    Color leadershipColor = Colors.black;
    Color interviewColor = Colors.black;

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

    if (event.getLeadershipStatus() == -1) {
      leadershipColor = Colors.green;
      /// done
    }
    else if (event.getLeadershipStatus() == 1) {
      /// not done yet return also calc duration?
      leadershipColor = Colors.red;
      }
    else {
        /// not done yet return also calc duration?
      leadershipColor = Colors.black;
      }
    /// Interview
    if (event.getInterviewStatus() == -1) {

      interviewColor = Colors.green;
      /// done
    }
    else if (event.getInterviewStatus() == 1) {
      /// not done yet return also calc duration?
      interviewColor = Colors.red;
    }
    else {
      /// not done yet return also calc duration?
      interviewColor = Colors.black;
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
        /// leadership
        Stack(children: [
          IconButton(
            icon: Icon(Icons.star, color: leadershipColor,), // ✅ Use the image as an icon
            iconSize: 35, // Adjust size
            onPressed: () {},
          ),
          // 🔹 Transparent Number Overlay
        ]),
        /// interview
        Stack(children: [
          IconButton(
            icon: Icon(Icons.note_alt_sharp, color: interviewColor,), // ✅ Use the image as an icon
            iconSize: 30, // Adjust size
            onPressed: () {},
          ),
          // 🔹 Transparent Number Overlay
          interviewColor == Colors.red
              ? Positioned(
            top: 5, // Adjust position
            right: 5,
            child: Container(
              padding: EdgeInsets.all(5),
              child: Text('##', // Change this dynamically
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
