import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../event_controller.dart';
import 'login_page.dart';
import '../home_page.dart';
import '../theme_controller.dart';
import '../widgets/logo.dart';
import '../services/platform_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final eventController = Get.put(EventController());
  final themeController = Get.put(ThemeController());
  final PlatformService _platformService = PlatformService.create();


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
          child: Stack(
            children: [
              Center(
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
              // WiFi configuration icon - only show on mobile (not web)
              if (!kIsWeb)
                Positioned(
                  top: MediaQuery.of(context).padding.top,
                  left: 0,
                  child: SafeArea(
                    child: IconButton(
                      onPressed: () async {
                        if (await _platformService.canOpenKioskSettings()) {
                          await _platformService.openWifiPicker();
                        }
                      },
                      icon: Icon(
                        Icons.wifi_find_rounded,
                        color: Colors.grey,
                        size: 30.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });

  }
}