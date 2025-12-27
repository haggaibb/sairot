import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import '../event_controller.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../widgets/logo.dart';
import '../services/platform_service.dart';
import '../utils/tablet_utils.dart';
// import '../widgets/sonar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final eventController = Get.put(EventController());
  final platformService = PlatformService.create();
  TextEditingController idCtrl = TextEditingController();
  late Timer _connectionTimer;

  String? _androidId;
  String? _androidIdError;
  String? _deviceName;
  String? _deviceNameError;
  bool _showAndroidId = false;
  bool _didDumpDeviceInfoToConsole = false;
  bool _deviceRegistered = false;
  String? _deviceNumber;
  bool _hasLoadedDeviceRegistration = false; // Prevent multiple calls to _loadDeviceRegistration

  void _dumpAndroidDeviceInfoToConsole(AndroidDeviceInfo info) {
    final pretty = const JsonEncoder.withIndent('  ').convert(info.data);
    // debugPrint chunks long messages automatically, so this won't get truncated as easily.
    debugPrint('=== device_info_plus: AndroidDeviceInfo ===');
    debugPrint(pretty);
    debugPrint('=== end AndroidDeviceInfo ===');
  }

  Future<void> _loadDeviceInfoIfNeeded() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      if (_deviceName == null && _deviceNameError == null) {
        final info = await DeviceInfoPlugin().androidInfo;

        if (!_didDumpDeviceInfoToConsole) {
          _dumpAndroidDeviceInfoToConsole(info);
          if (mounted) {
            setState(() {
              _didDumpDeviceInfoToConsole = true;
            });
          } else {
            _didDumpDeviceInfoToConsole = true;
          }
        }

        final name = '${info.manufacturer} ${info.model}'.trim();
        if (!mounted) return;
        setState(() {
          _deviceName = name;
          _deviceNameError = null;
        });
        // ignore: avoid_print
        print('Device name: $name');
      }

      if (_androidId == null && _androidIdError == null) {
        final id = await platformService.getDeviceId();
        if (!mounted) return;
        setState(() {
          _androidId = id;
          _androidIdError = null;
        });
        // ignore: avoid_print
        print('Android ID: ${id ?? '<null>'}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final msg = e.toString();
        _deviceNameError ??= msg;
        _androidIdError ??= msg;
      });
      // ignore: avoid_print
      print('Device info fetch failed: $e');
    }
  }

  /// Check device registration and show dialog if needed
  Future<bool> _checkDeviceRegistration() async {
    // Device registration is required only for tablets, not phones or web
    if (kIsWeb) {
      return true; // Skip device registration on web
    }
    
    // Check if device is a tablet - only tablets require device registration
    if (!isTablet(context)) {
      return true; // Skip device registration on phones
    }
    
    // For tablets, check if device registration is required
    if (!platformService.requiresDeviceRegistration()) {
      return true; // Skip if service says not required
    }
    
    if (_androidId == null || _androidId!.isEmpty) {
      // Get Android ID if not already loaded
      try {
        final id = await platformService.getDeviceId();
        if (id == null || id.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('לא ניתן לקבל מזהה מכשיר'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        setState(() {
          _androidId = id;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בקבלת מזהה מכשיר'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    // Check if device is registered
    final deviceDoc = await eventController.getDeviceDocument(_androidId!);
    if (deviceDoc != null && deviceDoc['deviceNumber'] != null) {
      setState(() {
        _deviceRegistered = true;
        _deviceNumber = deviceDoc['deviceNumber'] as String?;
      });
      return true; // Device already registered
    }

    // Device not registered, show dialog
    return await _showDeviceNumberDialog();
  }

  /// Show dialog to input device number
  Future<bool> _showDeviceNumberDialog() async {
    final deviceNumberController = TextEditingController();

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('הזנת מספר מכשיר'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'מספר המכשיר מופיע על גב הטאבלט',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: deviceNumberController,
                  decoration: InputDecoration(
                    labelText: 'מספר מכשיר',
                    hintText: 'הזן מספר מכשיר',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('ביטול'),
              ),
              TextButton(
                onPressed: () async {
                  final deviceNumber = deviceNumberController.text.trim();
                  if (deviceNumber.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('אנא הזן מספר מכשיר'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Check if device number is already registered
                  final isRegistered = await eventController.isDeviceNumberRegistered(deviceNumber);
                  if (isRegistered) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('מספר מכשיר זה כבר רשום במערכת'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Register device number
                  final success = await eventController.registerDeviceNumber(_androidId!, deviceNumber);
                  if (success) {
                    setState(() {
                      _deviceRegistered = true;
                      _deviceNumber = deviceNumber;
                    });
                    Navigator.of(context).pop(true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('שגיאה ברישום מספר מכשיר'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text('אישור'),
              ),
            ],
          ),
        );
      },
    ) ?? false;
  }

  login() async {
    // First check device registration
    final deviceValid = await _checkDeviceRegistration();
    if (!deviceValid) {
      return; // Don't proceed if device number wasn't validated
    }

    // Now proceed with instructor login
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load device registration status after dependencies are available
    // This is called after initState and when MediaQuery is available
    // Only load once to prevent multiple calls
    if (!_hasLoadedDeviceRegistration) {
      _hasLoadedDeviceRegistration = true;
      _loadDeviceRegistration();
    }
  }

  /// Load device registration status from Firestore
  Future<void> _loadDeviceRegistration() async {
    // Device registration is required only for tablets, not phones or web
    if (kIsWeb) {
      return; // Skip device registration on web
    }
    
    // Check if device is a tablet - only tablets require device registration
    if (!mounted || !isTablet(context)) {
      return; // Skip device registration on phones
    }
    
    // For tablets, check if device registration is required
    if (!platformService.requiresDeviceRegistration()) {
      return; // Skip if service says not required
    }

    try {
      // Get Android ID
      final androidId = await platformService.getDeviceId();
      if (androidId == null || androidId.isEmpty) {
        return;
      }

      setState(() {
        _androidId = androidId;
      });

      // Check if device is registered
      final deviceDoc = await eventController.getDeviceDocument(androidId);
      if (deviceDoc != null && deviceDoc['deviceNumber'] != null) {
        setState(() {
          _deviceRegistered = true;
          _deviceNumber = deviceDoc['deviceNumber'] as String?;
        });
      }
    } catch (e) {
      print('Error loading device registration: $e');
    }
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
            leading: kIsWeb ? null : IconButton(
                onPressed: () async {
                  if (await platformService.canOpenKioskSettings()) {
                    await platformService.openWifiPicker();
                  }
                },
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
                                  if (kIsWeb || !Platform.isAndroid) return;
                                  setState(() {
                                    _showAndroidId = !_showAndroidId;
                                  });
                                  if (_showAndroidId) {
                                    await _loadDeviceInfoIfNeeded();
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
                              // Device info (Android only) - helpful for support/debug.
                              if (!kIsWeb && Platform.isAndroid && _showAndroidId)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 12.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: (_androidIdError != null ||
                                          _deviceNameError != null)
                                      ? Text(
                                          'Device info error: ${_deviceNameError ?? _androidIdError}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.red),
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SelectableText(
                                              'Device: ${_deviceName ?? 'loading...'}',
                                              style: const TextStyle(
                                                  fontSize: 12),
                                            ),
                                            SelectableText(
                                              'Android ID: ${_androidId ?? 'loading...'}',
                                              style: const TextStyle(
                                                  fontSize: 12),
                                            ),
                                          ],
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

