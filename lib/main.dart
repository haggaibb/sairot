import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'ctx.dart';
import 'event_settings_page.dart';
import 'event_home.dart';
import 'alonka_page.dart';
import 'participants_status_page.dart';
import 'meshulash_page.dart';
import 'sakim_page.dart';
import 'bur_page.dart';
import 'grades_page.dart';
import 'performance_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'admin/admin_home.dart';
import 'admin/admin_event_report_page.dart';
import 'admin/admin_live_event_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'interview_page.dart';
import 'leadership_page.dart';
import 'theme_controller.dart';
import 'splash_screen.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final themeController = Get.put(ThemeController());
  SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
      .then((_) => runApp(GetMaterialApp(
            locale: const Locale('he', 'IL'), // Set Hebrew Locale
            supportedLocales: const [
              Locale('he', 'IL'), // Hebrew
              Locale('en', 'US'), // English (optional)
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            debugShowCheckedModeBanner: false,
            title: 'ימי סיירות',
            initialRoute: '/',
            theme: themeController.lightTheme,
            darkTheme: themeController.darkTheme,
            themeMode: themeController.isDarkMode.value
                ? ThemeMode.dark
                : ThemeMode.light,
            defaultTransition: Transition.upToDown,
            getPages: [
              GetPage(
                name: '/',
                page: () => SplashScreen(),
              ),
              GetPage(
                name: '/front_door',
                page: () => FrontDoor(),
              ),
              GetPage(
                name: '/home',
                page: () => Home(),
              ),
              GetPage(
                name: '/event_home',
                page: () => EventHome(),
              ),
              GetPage(
                name: '/event_settings/:date',
                page: () => EventSettingsPage(),
              ),
              GetPage(
                name: '/meshulash',
                page: () => MeshulashPage(),
              ),
              GetPage(
                name: '/sakim',
                page: () => SakimPage(),
              ),
              GetPage(
                name: '/alonka',
                page: () => AlonkaPage(),
              ),
              GetPage(
                name: '/bur',
                page: () => BurPage(),
              ),
              GetPage(
                name: '/participants_status',
                page: () => ParticipantsStatusPage(),
              ),
              GetPage(
                name: '/grades_page',
                page: () => GradesPage(),
              ),
              GetPage(
                name: '/performance_page/:number',
                page: () => PerformancePage(),
              ),
              GetPage(
                name: '/admin',
                page: () => AdminHome(),
              ),
              GetPage(
                name: '/admin_event_report_page',
                page: () => AdminEventReportPage(),
              ),
              GetPage(
                name: '/admin_live_event_page',
                page: () => AdminLiveEventPage(),
              ),
              GetPage(
                name: '/leadership',
                page: () => LeadershipPage(),
              ),
              GetPage(
                name: '/interview',
                page: () => InterviewPage(),
              ),
            ],
          )));
}

class FrontDoor extends StatefulWidget {
  const FrontDoor({super.key});

  @override
  State<FrontDoor> createState() => _FrontDoorState();
}

class _FrontDoorState extends State<FrontDoor> {
  final eventController = Get.put(Controller());

  @override
  Widget build(BuildContext context) {
    return Obx(() => !eventController.loggedIn.value ? LoginPage() : Home());
  }
}



