import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../widgets/guideWebView.dart';
import '../utils/tablet_utils.dart';
import '../widgets/custom_grades_table.dart';
import '../widgets/wifi_settings_button.dart';
import '../mixins/event_validation_mixin.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> with EventValidationMixin {
  final eventController = Get.put(EventController());
  bool _showSystemGrades = true;
  bool _showInstructorGrades = true;
  bool _isRebuildingSystem = false;
  bool _isRebuildingInstructor = false;


  @override
  void initState() {
    super.initState();
    checkEventValidity();
    // Defer calculateGrades to avoid build phase issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        eventController.calculateGrades();
      }
    });
  }

  @override
  void dispose() {
    // Restore portrait-only orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool tablet = isTablet(context);
    
    // Allow landscape orientation for tablets
    if (tablet) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Color.fromARGB(255, 0, 66, 136)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
            appBar: AppBar(
              //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              centerTitle: true,
              title: Text(' דף ציונים לקבוצה ${eventController.currentEvent.value.groupNumber} '),
              actions: [
                // Toggle system grades visibility
                IconButton(
                  icon: _isRebuildingSystem
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : Icon(
                          Icons.calculate,
                          color: _showSystemGrades ? Colors.blue : Colors.grey,
                        ),
                  tooltip: _showSystemGrades ? 'הסתר ציוני מערכת' : 'הצג ציוני מערכת',
                  onPressed: () {
                    setState(() {
                      _isRebuildingSystem = true;
                      _showSystemGrades = !_showSystemGrades;
                    });
                    // Hide progress indicator after table rebuilds
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(Duration(milliseconds: 300), () {
                        if (mounted) {
                          setState(() {
                            _isRebuildingSystem = false;
                          });
                        }
                      });
                    });
                  },
                ),
                // Toggle instructor grades visibility
                IconButton(
                  icon: _isRebuildingInstructor
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: _showInstructorGrades ? Colors.blue : Colors.grey,
                        ),
                  tooltip: _showInstructorGrades ? 'הסתר ציוני מדריך' : 'הצג ציוני מדריך',
                  onPressed: () {
                    setState(() {
                      _isRebuildingInstructor = true;
                      _showInstructorGrades = !_showInstructorGrades;
                    });
                    // Hide progress indicator after table rebuilds
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(Duration(milliseconds: 300), () {
                        if (mounted) {
                          setState(() {
                            _isRebuildingInstructor = false;
                          });
                        }
                      });
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'מדריך למשתמש',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Directionality(
                        textDirection: TextDirection.rtl,
                        child: const ManualWebView(
                          url: 'https://docs.google.com/presentation/d/19SF_q3uXPt470mzfOKEorpoIORsOEEmQXL5_UUnelNo/preview?rm=minimal&slide=id.g384f00aea19_0_135',
                          //https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000
                        ),
                      ),
                    );
                  },
                ),
                WifiSettingsButton(),
              ],
            ),
            body: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: CustomGradesTable(
                eventController: eventController,
                isTablet: tablet,
                showSystemGrades: _showSystemGrades,
                showInstructorGrades: _showInstructorGrades,
              ),
            )),
      ),
    );
  }
}
