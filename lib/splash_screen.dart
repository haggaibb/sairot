import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ctx.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'theme_controller.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final eventController = Get.put(Controller());
  final themeController = Get.put(ThemeController());


  @override
  void initState() {
    super.initState();

    // 🌟 Animation setup
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context)  {
    final bool isDarkMode = themeController.isDarkMode.value;
    return Obx(() {
      if (!eventController.loading.value) {
        if (!eventController.loggedIn.value) {
          return LoginPage();
        } else {
          return Home();
        }
      }
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Color.fromARGB(255, 0, 66, 136)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _animation,
              child: GestureDetector(
                onLongPress: () => {
                  eventController.deleteSystemHiveBox()
                },
                child: Image.asset(
                  'images/wings-logo.png',
                  width: 250,
                  height: 250,
                ),
              ),
            ),
          ),
        ),
      );
    });

  }
}