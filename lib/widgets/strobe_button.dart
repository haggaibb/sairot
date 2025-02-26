import 'package:flutter/material.dart';

class ShiningButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color borderColor;
  final Color noneActiveColor;

  const ShiningButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.borderColor,
    required this.noneActiveColor,
  });

  @override
  _ShiningButtonState createState() => _ShiningButtonState();
}

class _ShiningButtonState extends State<ShiningButton>
    with TickerProviderStateMixin {
  late final AnimationController _borderController;
  late final AnimationController _backgroundController;
  late final Animation<Color?> _borderAnimation;
  late final Animation<Color?> _backgroundAnimation;

  @override
  void initState() {
    super.initState();

    // 🟢 Always initialize controllers
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // 🎨 Define animations
    _borderAnimation = ColorTween(
      begin: Colors.red,
      end: Colors.white,
    ).animate(_borderController);

    _backgroundAnimation = ColorTween(
      begin: Colors.greenAccent,
      end: Colors.white.withOpacity(0.3),
    ).animate(_backgroundController);

    // 🔄 Start or stop animation based on the initial color
    _updateAnimations();
  }

  /// 🔄 Start animations if the border color is red
  void _updateAnimations() {
    if (widget.borderColor == Colors.red) {
      _borderController.repeat(reverse: true);
      _backgroundController.repeat(reverse: true);
    } else {
      _borderController.stop();
      _backgroundController.stop();
    }
  }

  @override
  void didUpdateWidget(covariant ShiningButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🔄 Update animation if the border color changes
    if (oldWidget.borderColor != widget.borderColor) {
      _updateAnimations();
    }
  }

  @override
  void dispose() {
    _borderController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_borderController, _backgroundController]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(70.0),
            color: widget.borderColor == Colors.red
                ? _backgroundAnimation.value
                : widget.noneActiveColor,
          ),
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
              elevation: WidgetStateProperty.all(20),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(70.0),
                  side: BorderSide(
                    width: 5,
                    color: widget.borderColor == Colors.red
                        ? _borderAnimation.value ?? Colors.red
                        : widget.borderColor,
                  ),
                ),
              ),
            ),
            onPressed: widget.onPressed,
            child: widget.child,
          ),
        );
      },
    );
  }
}