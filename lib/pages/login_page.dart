import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../event_controller.dart';
import 'dart:async';
import 'dart:io';
import '../widgets/logo.dart';
// import '../widgets/sonar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final eventController = Get.put(EventController());
  TextEditingController idCtrl = TextEditingController();
  late Timer _connectionTimer;

  String? _androidId;
  String? _androidIdError;
  bool _showAndroidId = false;

  Future<void> _loadAndroidIdIfNeeded() async {
    if (!Platform.isAndroid) return;
    if (_androidId != null || _androidIdError != null) return;
    try {
      final id = await MdmKiosk.getAndroidId();
      if (!mounted) return;
      setState(() {
        _androidId = id;
        _androidIdError = null;
      });
      // ignore: avoid_print
      print('Android ID: ${id ?? '<null>'}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _androidIdError = e.toString();
      });
      // ignore: avoid_print
      print('Android ID fetch failed: $e');
    }
  }

  login() async {
    if (await eventController.login(idCtrl.text)) {
      _connectionTimer.cancel();
      eventController.loading.value = true;
      await eventController.getUnfinalizedEvents();
      await eventController.fetchInstructorEvents();
      eventController.loading.value = false;
      Get.toNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            " לא נמצא מדריך עם ת.ז. " + idCtrl.text,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _connectionTimer =
        Timer.periodic(Duration(seconds: 3), (Timer timer) async {
      eventController.isConnected.value = eventController.isConnected.value;
      //if (eventController.isConnected.value) _connectionTimer.cancel();
    });
  }

  @override
  void dispose() {
    _connectionTimer.cancel(); // Stop timer when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Enforce RTL layout
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Color.fromARGB(255, 0, 66, 136)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          resizeToAvoidBottomInset:
              true, // 👈 Ensures UI adjusts for the keyboard
          appBar: AppBar(
            leading: IconButton(
                onPressed: () => MdmKiosk.openWifiPicker(),
                icon: Icon(
                  Icons.wifi_find_rounded,
                  color: Colors.grey,
                  size: 30.0,
                )),
            //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text('ימי סיירות'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            // 👈 Wrap entire content to enable scrolling
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // 👈 Prevents unnecessary stretching
                  children: [
                    const SizedBox(height: 10),
                    GestureDetector(
                        onLongPress: () =>
                            {eventController.deleteSystemHiveBox()},
                        child: ShineEffectLogo()),
                    //Image.asset('images/wings-logo.png', width: 250),
                    const SizedBox(height: 50),

                    // 🔄 Use Obx for dynamic UI updates
                    Obx(() => !eventController.loading.value
                        ? Column(
                            children: [
                              GestureDetector(
                                onLongPress: () async {
                                  if (!Platform.isAndroid) return;
                                  setState(() {
                                    _showAndroidId = !_showAndroidId;
                                  });
                                  if (_showAndroidId) {
                                    await _loadAndroidIdIfNeeded();
                                  }
                                },
                                child: Text(
                                  'מסך הזדהות של המדריך',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Device ID (Android only) - helpful for support/debug.
                              if (Platform.isAndroid && _showAndroidId)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 12.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: _androidIdError != null
                                      ? Text(
                                          'Android ID error: $_androidIdError',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.red),
                                        )
                                      : SelectableText(
                                          'Android ID: ${_androidId ?? 'loading...'}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                ),
                              const SizedBox(height: 40),

                              // 📌 TextField inside a Constrained Box
                              SizedBox(
                                width: 200,
                                child: TextField(
                                  onSubmitted: (value) async {
                                    await login();
                                  },
                                  controller: idCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: InputDecoration(
                                    labelText: "ת.ז.",
                                    labelStyle: TextStyle(
                                      fontSize: 16,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    hintText: "הזן תעודת זהות כאן",
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade500,
                                    ),
                                    prefixIcon: Icon(Icons.badge_outlined,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    filled: true,
                                    fillColor: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          width: 1.5),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                          width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          width: 2.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(
                                          color: Colors.red, width: 1.5),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 14.0, horizontal: 16.0),
                                  ),
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                                ),
                              ),
                              const SizedBox(height: 30),

                              // 📌 Login Button
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 10,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                                onPressed: () async {
                                  await login();
                                },
                                child: const Text(
                                  "הזדהות",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              const SizedBox(height: 200),
                              SizedBox(
                                  width: 150, child: LinearProgressIndicator()),
                              Text(
                                'טוען נתונים...',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MdmKiosk {
  static const _ch = MethodChannel('kiosk_settings');

  static Future<void> openKioskSettings() =>
      _ch.invokeMethod('openKioskSettings');
  static Future<void> openWifiPicker() => _ch.invokeMethod('openWifiPicker');
  static Future<String?> getAndroidId() => _ch.invokeMethod<String>('getAndroidId');
}
