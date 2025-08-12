import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../event_controller.dart';
import 'admin_login_page.dart';
import '../admin/admin_home.dart';
import '../theme_controller.dart';
import '../widgets/logo.dart';

class AdminSplashScreen extends StatefulWidget {
  const AdminSplashScreen({super.key});

  @override
  State<AdminSplashScreen> createState() => _AdminSplashScreenState();
}

class _AdminSplashScreenState extends State<AdminSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final eventController = Get.put(EventController());
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
          return AdminLoginPage();
        } else {
          return AdminHome();
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
                child: ShineEffectLogo(),
              ),
            ),
          ),
        ),
      );
    });

  }
}