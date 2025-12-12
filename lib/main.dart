import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'event_controller.dart';
import 'pages/event_settings_page.dart';
import 'event_home.dart';
import 'pages/alonka_page.dart';
import 'pages/participants_status_page.dart';
import 'pages/meshulash_page.dart';
import 'pages/sakim_page.dart';
import 'pages/bur_page.dart';
import 'pages/grades_page.dart';
import 'pages/performance_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/login_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/interview_page.dart';
import 'pages/leadership_page.dart';
import 'theme_controller.dart';
import 'pages/splash_screen.dart';
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
  final eventController = Get.put(EventController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => !eventController.loggedIn.value ? LoginPage() : Home());
  }
}

/*
manual
https://docs.google.com/document/d/e/2PACX-1vRLJ-Ody7H6kibADbH6JEgmy5ZKFnzBSp-H3_fewsqhYcIP9R7V6pdLpcmr7CHaS0MifS9kWHcrqZ-s/pub
 */

