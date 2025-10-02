import 'package:flutter/material.dart';
import 'dart:math';

class SonarLogo extends StatefulWidget {
  const SonarLogo({Key? key}) : super(key: key);

  @override
  _SonarLogoState createState() => _SonarLogoState();
}

class _SonarLogoState extends State<SonarLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          painter: SonarPainter(_controller.value),
          size: Size(200, 200),
        );
      },
    );
  }
}

class SonarPainter extends CustomPainter {
  final double sweep;

  SonarPainter(this.sweep);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.greenAccent.withOpacity(0.3);

    // Draw concentric circles
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, paint);
    }

    // Draw sweep line
    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 0.3,
        colors: [Colors.greenAccent.withOpacity(0.7), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final angle = sweep * 2 * 3.14159;
    final sweepEnd = Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );

    canvas.drawLine(center, sweepEnd, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant SonarPainter oldDelegate) =>
      oldDelegate.sweep != sweep;
}