import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'ctx.dart';
import 'dart:async';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final eventController = Get.put(Controller());
  TextEditingController idCtrl = TextEditingController();
  late Timer _connectionTimer;

  @override
  void initState()  {
      _connectionTimer = Timer.periodic(Duration(seconds: 3), (Timer timer) async {
        eventController.isConnected.value = eventController.isConnected.value;
        //if (eventController.isConnected.value) _connectionTimer.cancel();
      });
    super.initState();
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
      child: Scaffold(
        resizeToAvoidBottomInset: true,  // 👈 Ensures UI adjusts for the keyboard
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: GestureDetector(
            child: Text('ימי סיירות'),
            onLongPress: () => {Get.toNamed('/admin')},
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(  // 👈 Wrap entire content to enable scrolling
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,  // 👈 Prevents unnecessary stretching
                children: [
                  const SizedBox(height: 10),
                  Image.asset('images/wings-logo.png', width: 250),
                  const SizedBox(height: 50),

                  // 🔄 Use Obx for dynamic UI updates
                  Obx(() => !eventController.loading.value
                      ? Column(
                    children: [
                      Text(
                        'מסך הזדהות של המדריך',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 40),

                      // 📌 TextField inside a Constrained Box
                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: idCtrl,
                          keyboardType: TextInputType.number, // Show number keyboard
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Restrict input to numbers
                          decoration: InputDecoration(
                            labelText: "ת.ז.",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // 📌 Login Button
                      ElevatedButton(
                        onPressed: () async {
                          if (await eventController.login(idCtrl.text)) {
                            _connectionTimer.cancel();
                            Get.toNamed('/home');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("❌ No instructor found with ID: ${idCtrl.text}"),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: const Text("הזדהות"),
                      ),
                    ],
                  )
                      : Column(
                    children: [
                      const SizedBox(height: 200),
                      SizedBox(width: 150, child: LinearProgressIndicator()),
                      Text('מחפש חיבור לרשת...'),
                    ],
                  )
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


}

