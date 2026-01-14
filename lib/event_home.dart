import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/types.dart';
import 'event_controller.dart';
import 'widgets/yes_no.dart';
import 'theme_controller.dart';
import 'widgets/strobe_button.dart';
import 'models/system.dart';
import 'widgets/guideWebView.dart';
import 'utils/tablet_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'services/user_preferences_service.dart';
import 'widgets/floating_ptt_button.dart';
import 'widgets/wifi_settings_button.dart';
import 'mixins/event_validation_mixin.dart';
import 'models/participant.dart';
import 'widgets/comments_dialog.dart';

class EventHome extends StatefulWidget {
  const EventHome({super.key});

  @override
  State<EventHome> createState() => _EventHomeState();
}

class _EventHomeState extends State<EventHome> with EventValidationMixin {
  final eventController = Get.put(EventController());
  final themeController = Get.put(ThemeController());
  bool _floatingPttEnabled = false;
  bool _volumeButtonPttEnabled = false;
  bool _gradesButtonLoading = false;

  Widget _buildShiningButton(BuildContext context, dynamic icon, String title, VoidCallback onTap) {
    bool tablet = isTablet(context);
    double fontSize = tablet ? 28.8 : 15.36; // 24.0 * 1.2 = 28.8 (tablet, 20% increase), mobile stays at 15.36
    double iconSize = tablet ? 100.0 : 76.8; // 64.0 * 1.2 = 76.8 (20% bigger for mobile)
    double imageScale = tablet ? 5.0 : 6.25; // 7.5 / 1.2 = 6.25 (20% bigger image for mobile)
    
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ShiningButton(
        onPressed: onTap,
        borderColor: Colors.black,
        noneActiveColor: Get.theme.colorScheme.primary,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            icon is String
                ? Image.asset(icon, scale: imageScale, color: Colors.black)
                : Icon(icon, size: iconSize, color: Colors.black),
            Text(title, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    checkEventValidity();
    _loadSttPreferences();
  }

  Future<void> _loadSttPreferences() async {
    final floatingEnabled = await UserPreferencesService.getFloatingPttButton();
    final volumeEnabled = await UserPreferencesService.getVolumeButtonPtt();
    if (mounted) {
      setState(() {
        _floatingPttEnabled = floatingEnabled;
        _volumeButtonPttEnabled = volumeEnabled;
      });
    }
  }

  Future<void> _saveFloatingPttButton(bool value) async {
    setState(() {
      _floatingPttEnabled = value;
    });
    await UserPreferencesService.saveFloatingPttButton(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'כפתור מיקרופון מופעל' : 'כפתור מיקרופון מושבת'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveVolumeButtonPtt(bool value) async {
    setState(() {
      _volumeButtonPttEnabled = value;
    });
    await UserPreferencesService.saveVolumeButtonPtt(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'כפתורי עוצמת קול מופעלים' : 'כפתורי עוצמת קול מושבתים'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show dialog to add generic comments for a participant
  Future<void> _showAddGenericCommentDialog(BuildContext context) async {
    // Load participants for dropdown
    final participants = eventController.currentEvent.value.participants
        .where((p) => p.status == ParticipantStatus.Active)
        .toList();
    
    participants.sort((a, b) => a.number.compareTo(b.number));

    if (participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אין משתתפים פעילים'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Participant? selectedParticipant = participants.first;

    // First, show participant selection dialog
    final participantResult = await showDialog<Participant>(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('בחר משתתף'),
                content: DropdownButtonFormField<Participant>(
                  value: selectedParticipant,
                  decoration: const InputDecoration(
                    labelText: 'מספר משתתף',
                    border: OutlineInputBorder(),
                  ),
                  items: participants.map((participant) {
                    return DropdownMenuItem<Participant>(
                      value: participant,
                      child: Text('${participant.number}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedParticipant = value;
                    });
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ביטול'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedParticipant != null) {
                        Navigator.of(context).pop(selectedParticipant);
                      }
                    },
                    child: const Text('המשך'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (participantResult == null) return;

    // Then show CommentsDialog for the selected participant
    final commentsResult = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return CommentsDialog(
          commentsList: eventController.gradesData.listOfCommentsInterview,
          selectedComments: participantResult.genericInstructorComments,
          title: participantResult.number.toString(),
          exerciseType: ExerciseType.generic,
          instructorCustomComments: eventController.getInstructorCustomCommentsForExercise('generic'),
        );
      },
    );

    if (commentsResult != null) {
      eventController.addGenericComments(commentsResult, participantResult.number);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הערות כלליות נשמרו בהצלחה'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Stack(
          children: [
            Scaffold(
          drawer: Drawer(
            child: ListView(
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(),
                  padding: EdgeInsets.only(
                    bottom: isTablet(context) ? 4.0 : 8.0,
                    top: isTablet(context) ? 4.0 : 8.0,
                    left: 16.0,
                    right: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Text('תפריט',
                      //     style: TextStyle(
                      //         fontWeight: FontWeight.bold, fontSize: 20)),
                      Obx(() => eventController.currentEvent.value.finalized
                          ? Text('הארוע נסגר',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTablet(context) ? 14.0 : 16.0))
                          : Text(
                              'הארוע פעיל',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTablet(context) ? 14.0 : 16.0),
                            )),
                      SizedBox(
                        height: isTablet(context) ? 8.0 : 12.0,
                      ),
                      Obx(() => Text(
                          '${eventController.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active).length} משתתפים אקטיבים ',
                          style: TextStyle(fontSize: isTablet(context) ? 14.0 : 16.0))),
                      Text(
                          'גירסת ציונים: ${eventController.currentEvent.value.gradeSettings.version} ',
                          style: TextStyle(fontSize: isTablet(context) ? 14.0 : 16.0)),
                      IconButton(
                          icon: Icon(Icons.info_outline, size: isTablet(context) ? 20.0 : 24.0),
                          tooltip: 'מדריך למשתמש',
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => Directionality(
                                textDirection: TextDirection.rtl,
                                child: const ManualWebView(
                                  url: 'https://docs.google.com/presentation/d/19SF_q3uXPt470mzfOKEorpoIORsOEEmQXL5_UUnelNo/preview?rm=minimal&slide=id.g384f00aea19_0_156',
                                  //https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000
                                ),
                              ),
                            );
                          },
                        )
                    ],
                  ),
                ),
                /// Back to Home Page
                ListTile(
                  title: Row(
                    children: [
                      Icon(Icons.calendar_month_sharp),
                      SizedBox(
                        width: 10,
                      ),
                      const Text('חזרה לתפריט ראשי'),
                    ],
                  ),
                  onTap: () async {
                    // Save playground normally when going back to main menu (don't delete it)
                    // Use non-blocking save to prevent delay when offline
                    if (!eventController.currentEvent.value.finalized) {
                      eventController.saveEventWithOfflineSupport(
                        eventController.currentEvent.value
                      );
                    }
                    await eventController.getUnfinalizedEvents();
                    Get.toNamed('/home');
                  },
                ),
                /// Loading
                Obx(() => eventController.loading.value
                    ? SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(),
                      )
                    : SizedBox.shrink()),
                /// Close Event
                Obx(() => eventController.currentEvent.value.finalized
                    ? SizedBox.shrink()
                    : ListTile(
                        title: Row(
                          children: [
                            Icon(Icons.save),
                            SizedBox(
                              width: 10,
                            ),
                            const Text('שמירה וסגירת הארוע'),
                          ],
                        ),
                        onTap: () async {
                          final isPlayground = eventController.currentEvent.value.eventName == 'playground';
                          
                          if (isPlayground) {
                            // For playground: skip all validation and reset the playground
                            var res = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return YesNoDialog();
                              },
                            );
                            if (res) {
                              eventController.loading.value = true;
                              
                              // Delete/reset the playground (this prepares it for a fresh start)
                              await eventController.deletePlaygroundEvent();
                              
                              showCustomMessageAlert(context, "הצלחה",
                                  "מגרש המשחקים אופס", Icons.check);
                              
                              eventController.loading.value = false;
                              
                              // Navigate back to home
                              await eventController.getUnfinalizedEvents();
                              Get.toNamed('/home');
                            }
                          } else {
                            // For real events: normal finalization process with validation
                            if (eventController.gradesCanBeFinalized()) {
                              var res = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return YesNoDialog();
                                },
                              );
                              if (res) {
                                // Check connectivity before finalization - refresh connectivity status first
                                await eventController.connectionEnabled();
                                if (!eventController.isConnected.value) {
                                  showCustomMessageAlert(
                                    context,
                                    "תקלה",
                                    "אינטרנט נדרש לסיום ושמירת האירוע",
                                    Icons.wifi_off,
                                  );
                                  return;
                                }
                                
                                eventController.loading.value = true;
                                
                                // Debug: Log instructorGrade values before finalization
                                print('🔍 Before finalization - instructorGrade values:');
                                for (var p in eventController.currentEvent.value.participants) {
                                  if (p.status == ParticipantStatus.Active) {
                                    print('  Participant ${p.number}: instructorGrade = ${p.instructorGrade}');
                                  }
                                }
                                
                                // Save qualified recruits to Firestore FIRST (while grades are definitely in memory)
                                try {
                                  await eventController.finalizeEventAndUpdateQualifiedRecruits();
                                } catch (e) {
                                  print('❌ Error saving qualified recruits: $e');
                                  // Don't block finalization if qualified recruits save fails
                                }
                                
                                // NOW set finalized flag
                                eventController.currentEvent.value.finalized = true;
                                eventController.currentEvent.refresh();
                                
                                // Debug: Verify instructorGrade values are still present before saving
                                print('🔍 Before saving finalized event - instructorGrade values:');
                                for (var p in eventController.currentEvent.value.participants) {
                                  if (p.status == ParticipantStatus.Active) {
                                    print('  Participant ${p.number}: instructorGrade = ${p.instructorGrade}');
                                  }
                                }
                                
                                // Save the event with finalized flag AND all instructorGrade values
                                // Save locally first (immediate), then try Firebase in background
                                final localSuccess = await eventController.currentEvent.value.saveToLocal();
                                if (localSuccess) {
                                  // Show success immediately after local save
                                  showCustomMessageAlert(context, "הצלחה",
                                      "הארוע נסגר בהצלחה", Icons.check);
                                  // Try Firebase in background (non-blocking)
                                  eventController.saveEventWithOfflineSupport(
                                    eventController.currentEvent.value
                                  );
                                  // Trigger cleanup of old finalized events (non-blocking)
                                  eventController.cleanupOldFinalizedEvents().catchError((e) {
                                    print('⚠️ Error during cleanup after finalization (non-critical): $e');
                                  });
                                } else {
                                  showCustomMessageAlert(context, "תקלה",
                                      "שגיאה בשמירת האירוע", Icons.error);
                                }
                              } else {

                              }
                              eventController.loading.value = false;
                              }
                            else {
                              showCustomMessageAlert(context, "תקלה",
                                  "לא ניתנו ציונים סופיים", Icons.check);
                            }
                          }
                        },
                      )),
                /// Edit Event Settings
                Obx(() => eventController.currentEvent.value.finalized
                    ? SizedBox.shrink()
                    : ListTile(
                        title: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(
                              width: 10,
                            ),
                            const Text('עריכת הגדרות הארוע'),
                          ],
                        ),
                        onTap: () async {
                          Get.toNamed(
                              '/event_settings/${eventController.currentEvent.value.date}');
                        },
                      )),
                /// Dark Mode
                Obx(() => SwitchListTile(
                  title: Text(
                    themeController.isDarkMode.value
                        ? 'מצב לילה'
                        : 'מצב יום',
                    style: TextStyle(fontSize: 18),
                  ),
                  secondary: Icon(
                    themeController.isDarkMode.value
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  value: themeController.isDarkMode.value,
                  onChanged: (value) {
                    eventController.toggleTheme(value);
                  },
                )),
                /// Accessibility
                Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('גודל גופן וכפתורים', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Obx(() {
                        double sliderValue;
                        switch (eventController.system.value.accessibility) {
                          case Accessibility.normal:
                            sliderValue = 0;
                            break;
                          case Accessibility.big:
                            sliderValue = 1;
                            break;
                          case Accessibility.biggest:
                            sliderValue = 2;
                            break;
                        }

                        return Column(
                          children: [
                            Slider(
                              value: eventController.system.value.accessibility.index.toDouble(),
                              min: 0,
                              max: 2,
                              divisions: 2,
                              label: sliderValue == 0
                                  ? "רגיל"
                                  : sliderValue == 1
                                  ? "גדול"
                                  : "הכי גדול",
                              onChanged: (double value) {
                                Accessibility newSize;
                                if (value == 0) {
                                  newSize = Accessibility.normal;
                                } else if (value == 1) {
                                  newSize = Accessibility.big;
                                } else {
                                  newSize = Accessibility.biggest;
                                }
                                eventController.system.value.accessibility = newSize;
                                eventController.setUserAccessibility(newSize);
                              },
                            ),

                            // 📌 Text to indicate sizes
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("רגיל", style: TextStyle(fontSize: 14)),
                                Text("גדול", style: TextStyle(fontSize: 16)),
                                Text("הכי גדול", style: TextStyle(fontSize: 18)),
                              ],
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                /// Floating PTT Button
                SwitchListTile(
                  title: const Text('כפתור מיקרופון צף'),
                  subtitle: const Text('הצג כפתור מיקרופון צף להוספת הערות קוליות'),
                  value: _floatingPttEnabled,
                  onChanged: _saveFloatingPttButton,
                ),
                /// Volume Button PTT
                SwitchListTile(
                  title: const Text('כפתורי עוצמת קול'),
                  subtitle: Text(
                    'השתמש בכפתורי עוצמת הקול להקלטה קולית${kIsWeb ? '' : '\nזמין באפליקציה בלבד (לא בדפדפן)'}',
                    style: kIsWeb ? TextStyle(color: Colors.grey[600], fontSize: 12) : TextStyle(color: Colors.orange[700], fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                  value: _volumeButtonPttEnabled,
                  onChanged: kIsWeb ? null : _saveVolumeButtonPtt, // Disable on web
                ),
              ],
            ),
          ),
          appBar: AppBar(
            //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Center(
              child: Obx(() {
                if (eventController.backgroundLoading.value) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('ימי סיירות'),
                    ],
                  );
                }
                return Text('ימי סיירות');
              }),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.comment),
                tooltip: 'הוסף הערה לרשימה הכללית',
                onPressed: () => _showAddGenericCommentDialog(context),
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
                        url: 'https://docs.google.com/presentation/d/e/2PACX-1vR_qVfJhzZnG9WvPAzHheB5S-0oYeDFfH_8xuEfWdEhncZ8sVvry2Hl_7updw4P-6O_VbR83aAQ07CK/pub?start=false&loop=false&delayms=60000&slide=id.g384f00aea19_0_19',
                      ),
                    ),
                  );
                },
              ),
              WifiSettingsButton(),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                /// Group Data
                Column(
                  children: [
                    Text(
                      ' קבוצה ${eventController.currentEvent.value.groupNumber} ',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${eventController.currentEvent.value.date}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${eventController.currentInstructor.firstName} ${eventController.currentInstructor.lastName}',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      eventController.currentInstructor.id,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),

                /// **Push Content Down**
                SizedBox(height: 20),

                /// **Events Grid**
                Obx(() {
                  if (eventController.loading.value) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: isTablet(context) ? 1.5 : 1.25, // 1.5 / 1.2 = 1.25 (20% bigger buttons for mobile)
                      physics: NeverScrollableScrollPhysics(), // 🔹 Prevents internal scrolling
                      shrinkWrap: true, // 🔹 Allows it to wrap only required space
                      children: [
                        _buildShiningButton(context, 'images/meeshulash.png', 'משולש', () => Get.toNamed('/meshulash')),
                        _buildShiningButton(context, 'images/alonka.png', 'אלונקה', () {
                          eventController.currentAlonkaRound.value = eventController.currentEvent.value.alonkaSprints.length;
                          Get.toNamed('/alonka');
                        }),
                        _buildShiningButton(context, 'images/bur.png', 'בור', () => Get.toNamed('/bur')),
                        _buildShiningButton(context, 'images/sakim.png', 'שקים', () => Get.toNamed('/sakim')),
                        _buildShiningButton(context, Icons.star, 'מנהיגות', () => Get.toNamed('/leadership')),
                        _buildShiningButton(context, Icons.note_alt_sharp, 'ראיון אישי', () => Get.toNamed('/interview')),
                      ],
                    ),
                  );
                }),


                /// Grades and Status Buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Obx(() {
                    bool tablet = isTablet(context);
                    double buttonFontSize = tablet 
                        ? getTabletScaledFontSize(context, eventController.userFontSize.value) - 5
                        : eventController.userFontSize.value - 5;
                    double buttonHeight = tablet ? 150.0 : 100.0;
                    
                    return SizedBox(
                      height: buttonHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: tablet ? Size(200, 70) : null,
                              ),
                              onPressed: _gradesButtonLoading ? null : () {
                                // First, show the progress indicator immediately
                                setState(() {
                                  _gradesButtonLoading = true;
                                });
                                // Wait for UI to update, then navigate
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  // Navigate to grades page after UI has updated
                                  Get.toNamed('/grades_page')?.then((_) {
                                    // Hide progress indicator when user returns from grades page
                                    if (mounted) {
                                      setState(() {
                                        _gradesButtonLoading = false;
                                      });
                                    }
                                  });
                                  // Hide progress indicator after page loads (give time for table to render)
                                  Future.delayed(Duration(milliseconds: 800), () {
                                    if (mounted) {
                                      setState(() {
                                        _gradesButtonLoading = false;
                                      });
                                    }
                                  });
                                });
                              },
                              child: Text(
                                _gradesButtonLoading ? 'טוען...' : 'ציונים',
                                style: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.bold),
                              )),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: tablet ? Size(200, 70) : null,
                              ),
                              onPressed: () => Get.toNamed('/participants_status'),
                              child: Text('סטטוס חניכים',
                                  style: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    );
                  }),
                ),

                SizedBox(height: 30,)
                  ],
                ),
              ),
            ],
          ),
        ),
            // Floating PTT Button - OUTSIDE Scaffold, on top of everything
            if (_floatingPttEnabled || _volumeButtonPttEnabled)
              FloatingPttButton(
                instructorId: eventController.currentInstructor.id,
                enabled: _floatingPttEnabled || _volumeButtonPttEnabled,
                showButton: _floatingPttEnabled,
              ),
          ],
        ),
      ),
    );
  }
}
