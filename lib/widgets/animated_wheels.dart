import 'package:flutter/material.dart';

class AnimatedWheels extends StatefulWidget {
  @override
  _AnimatedWheelsState createState() => _AnimatedWheelsState();
}

class _AnimatedWheelsState extends State<AnimatedWheels>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4), // Smooth rainbow transition
    )..repeat(reverse: true); // Infinite color transition

    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(tween: ColorTween(begin: Colors.red, end: Colors.orange), weight: 1),
      TweenSequenceItem(tween: ColorTween(begin: Colors.orange, end: Colors.yellow), weight: 1),
      TweenSequenceItem(tween: ColorTween(begin: Colors.yellow, end: Colors.green), weight: 1),
      TweenSequenceItem(tween: ColorTween(begin: Colors.green, end: Colors.blue), weight: 1),
      TweenSequenceItem(tween: ColorTween(begin: Colors.blue, end: Colors.indigo), weight: 1),
      TweenSequenceItem(tween: ColorTween(begin: Colors.indigo, end: Colors.purple), weight: 1),
      TweenSequenceItem(tween: ColorTween(begin: Colors.purple, end: Colors.red), weight: 1),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ColorFiltered(
            colorFilter: ColorFilter.mode(
              _colorAnimation.value ?? Colors.white, // Animated color
              BlendMode.srcATop, // Apply color over the image
            ),
            child: Image.asset(
              'images/wheels.png', // Ensure this is in your assets folder
              width: 100, // Adjust as needed
              height: 100,
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}