import 'package:flutter/material.dart';

class ShineEffectLogo extends StatefulWidget {
  const ShineEffectLogo({super.key});

  @override
  State<ShineEffectLogo> createState() => _ShineEffectImageState();
}

class _ShineEffectImageState extends State<ShineEffectLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset('images/wings-logo.png' , width: 250,), // Replace with your image path
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.8),
                    Colors.transparent
                  ],
                  stops: const [0.3, 0.5, 0.7],
                  begin: Alignment(-1.0 + 2.0 * _controller.value, -1.0),
                  end: Alignment(1.0 + 2.0 * _controller.value, 1.0),
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcATop,
              child: Image.asset('images/wings-logo.png' , width: 250,), // Replace with your image
            );
          },
        ),
      ],
    );
  }
}