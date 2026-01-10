import 'package:flutter/material.dart';
import 'package:sairot/models/participant.dart';
import '../event_controller.dart';
import 'package:get/get.dart';
import '../widgets/meshulash_charts.dart';
import '../widgets/alonka_charts.dart';
import '../widgets/bur_charts.dart';
import '../widgets/sakim_charts.dart';
import '../widgets/interview_chart.dart';
import '../widgets/leadership_chart.dart';
import '../widgets/wifi_settings_button.dart';

final eventController = Get.put(EventController());

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  bool _isGeneratingCommentsSummary = false;
  String? _commentsSummary;

  @override
  void initState() {
    super.initState();
    // Load comments summary in background (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCommentsSummary();
    });
  }

  Future<void> _loadCommentsSummary() async {
    int number = int.parse(Get.parameters['number'] ?? '0');
    Participant p = eventController.getParticipant(number);
    
    // Only generate summary if sakim grade is available (indicates sufficient data)
    // If sakim grade not available, don't show anything (return without setting _commentsSummary)
    if (p.sakimGrade <= 0) {
      return;
    }
    
    // Check if cached summary exists
    if (p.commentsSummary != null && p.commentsSummary!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _commentsSummary = p.commentsSummary;
        });
      }
      return;
    }
    
    // Count comments (excluding bur comments)
    int commentCount = p.meshulashInstructorComments.length +
        p.alonkaInstructorComments.length +
        p.sakimInstructorComments.length +
        p.leadershipInstructorComments.length +
        p.interviewInstructorComments.length +
        p.genericInstructorComments.length;
    
    // Need at least 3 comments (excluding bur) to generate summary
    // If threshold not met, don't show anything (return without setting _commentsSummary)
    if (commentCount < 3) {
      return;
    }
    
    // Generate summary in background
    if (mounted) {
      setState(() {
        _isGeneratingCommentsSummary = true;
      });
    }
    
    try {
      String summary = await p.generateCommentsSummary();
      if (mounted) {
        setState(() {
          _commentsSummary = summary;
          _isGeneratingCommentsSummary = false;
        });
      }
    } catch (e) {
      print("❌ Error generating comments summary: $e");
      if (mounted) {
        setState(() {
          _commentsSummary = "שגיאה ביצירת סיכום הערות.";
          _isGeneratingCommentsSummary = false;
        });
      }
    }
  }

  Future<void> _refreshCommentsSummary() async {
    int number = int.parse(Get.parameters['number'] ?? '0');
    Participant p = eventController.getParticipant(number);
    
    // Only allow refresh if sakim grade is available
    if (p.sakimGrade <= 0) {
      return;
    }
    
    // Clear cached summary to force regeneration
    p.commentsSummary = null;
    
    // Regenerate
    await _loadCommentsSummary();
  }

  Future<String> GenAIReport(Participant p) async {
    var data = await p.fetchAndGenerateSummary(p.number.toString());
    if (data.isNotEmpty) {
      return data;
    } else {
      return "No Data";
    }
  }

  void _navigateToParticipant(int participantNumber) {
    Get.offNamed('/performance_page/$participantNumber');
  }

  /// Get next participant number (returns null if at end)
  int? _getNextParticipantNumber(int currentNumber) {
    List<Participant> activeParticipants = eventController.getSortedActiveParticipants();
    if (activeParticipants.isEmpty) return null;
    
    int currentIndex = activeParticipants.indexWhere((p) => p.number == currentNumber);
    if (currentIndex == -1 || currentIndex >= activeParticipants.length - 1) return null;
    
    return activeParticipants[currentIndex + 1].number;
  }

  /// Get previous participant number (returns null if at start)
  int? _getPreviousParticipantNumber(int currentNumber) {
    List<Participant> activeParticipants = eventController.getSortedActiveParticipants();
    if (activeParticipants.isEmpty) return null;
    
    int currentIndex = activeParticipants.indexWhere((p) => p.number == currentNumber);
    if (currentIndex == -1 || currentIndex <= 0) return null;
    
    return activeParticipants[currentIndex - 1].number;
  }

  void _handleSwipe(DragEndDetails details) {
    int currentNumber = int.parse(Get.parameters['number'] ?? '0');
    
    // Get all active participants sorted according to grades page order
    List<Participant> activeParticipants = eventController.getSortedActiveParticipants();
    if (activeParticipants.isEmpty) return;
    
    // Find current participant index
    int currentIndex = activeParticipants.indexWhere((p) => p.number == currentNumber);
    if (currentIndex == -1) return;
    
    // Determine swipe direction (negative velocity = swipe left = previous, positive = swipe right = next)
    double velocity = details.velocity.pixelsPerSecond.dx;
    
    if (velocity < -500) {
      // Swipe left - previous participant
      int? prevNumber = _getPreviousParticipantNumber(currentNumber);
      if (prevNumber != null) {
        _navigateToParticipant(prevNumber);
      }
    } else if (velocity > 500) {
      // Swipe right - next participant
      int? nextNumber = _getNextParticipantNumber(currentNumber);
      if (nextNumber != null) {
        _navigateToParticipant(nextNumber);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    int number = int.parse(Get.parameters['number'] ?? '0');
    Participant p = eventController.getParticipant(number);
    // 📏 **Detect Tablet or Mobile**
    bool isTablet = MediaQuery.of(context).size.width > 600;
    // 🎨 **Dynamic Sizes for Mobile vs. Tablet**
    double baseFontSize = isTablet ? 24 : 18;
    double chartHeight = isTablet ? 500 : 450; // Original mobile height
    double chartWidth = isTablet ? 650 : 350;
    double titleFontSize = isTablet ? 28 : 22;
    double subtitleFontSize = isTablet ? 22 : 16;
    double spacing = isTablet ? 80 : 60;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, const Color.fromARGB(255, 0, 66, 136)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Obx(() {
            int? prevNumber = _getPreviousParticipantNumber(number);
            int? nextNumber = _getNextParticipantNumber(number);
            
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous arrow (left side in RTL)
                prevNumber != null
                    ? IconButton(
                        icon: Icon(Icons.arrow_back_ios, size: 20),
                        onPressed: () => _navigateToParticipant(prevNumber),
                        tooltip: 'משתתף קודם',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      )
                    : SizedBox(width: 24), // Spacer when no previous
                SizedBox(width: 8),
                Text('ניתוח ביצועים - משתתף $number'),
                SizedBox(width: 8),
                // Next arrow (right side in RTL)
                nextNumber != null
                    ? IconButton(
                        icon: Icon(Icons.arrow_forward_ios, size: 20),
                        onPressed: () => _navigateToParticipant(nextNumber),
                        tooltip: 'משתתף הבא',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      )
                    : SizedBox(width: 24), // Spacer when no next
              ],
            );
          }),
          actions: [
            WifiSettingsButton(),
          ],
        ),
        body: GestureDetector(
          onHorizontalDragEnd: _handleSwipe,
          child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Text(
                  'ניתוח ביצועים עבור משתתף $number',
                  style: TextStyle(
                      fontSize: titleFontSize, fontWeight: FontWeight.bold),
                ),
                // Show final grade if available
                if (p.instructorGrade > 0)
                  Text(
                    'ציון סופי: ${p.instructorGrade.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: subtitleFontSize, fontWeight: FontWeight.bold),
                  ),
                SizedBox(height: 10),
                
                // Comments Summary Section (AI-generated) - Only show if summary exists or is generating
                if (_commentsSummary != null || _isGeneratingCommentsSummary) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.4), width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'סיכום הערות (AI):',
                              style: TextStyle(
                                fontSize: baseFontSize,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            if (_commentsSummary != null && 
                                _commentsSummary != "אין הערות זמינות לסיכום." &&
                                _commentsSummary != "שגיאה ביצירת סיכום הערות." &&
                                !_isGeneratingCommentsSummary)
                              IconButton(
                                icon: Icon(Icons.refresh, size: 20),
                                onPressed: _refreshCommentsSummary,
                                tooltip: 'רענן סיכום',
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_isGeneratingCommentsSummary)
                          Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'מייצר סיכום הערות...',
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          )
                        else if (_commentsSummary != null)
                          Text(
                            _commentsSummary!,
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              height: 1.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                ],
                
                // Show generic comments if available
                if (p.genericInstructorComments.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'הערות כלליות:',
                          style: TextStyle(
                            fontSize: baseFontSize,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: p.genericInstructorComments.map((comment) {
                            return Chip(
                              label: Text(
                                comment,
                                style: TextStyle(fontSize: subtitleFontSize),
                              ),
                              backgroundColor: Colors.white.withOpacity(0.3),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],

                SizedBox(height: spacing),

                /// **Meshulash Chart**
                Text('ניתוח ביצועים - משולש',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.0,
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold)),
                Text('השוואה קבוצתית',
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold)),
                Text(' ציון ${p.meshulashGrade.toStringAsFixed(2)} ',
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                SizedBox(
                  height: chartHeight,
                  width: chartWidth,
                  child: MeshulashCharts(number: number),
                ),

                SizedBox(height: spacing),

                /// **Alonka Chart**
                Text('ניתוח ביצועים - אלונקה',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.0,
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold)),
                Text('גרף ביצועים אישי',
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold)),
                Text(' ציון ${p.alonkaGrade.toStringAsFixed(2)} ',
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold)),
                SizedBox(
                  height: chartHeight,
                  width: chartWidth,
                  child: AlonkaCharts(number: number),
                ),

                SizedBox(height: spacing),

                /// **Bur Chart**
                Text('ניתוח ביצועים - בור',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.0,
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold)),
                Text('השוואה קבוצתית',
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold)),
                Text(' ציון ${p.burGrade.toStringAsFixed(2)} ',
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold)),
                SizedBox(
                  height: chartHeight,
                  width: chartWidth,
                  child: BurCharts(number: number),
                ),

                SizedBox(height: spacing),

                /// **Sakim Chart**
                Text('ניתוח ביצועים - שקים',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.0,
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold)),
                Text('גרף אישי',
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold)),
                /// Grade
                Text(' ציון ${p.sakimGrade.toStringAsFixed(2)} ',
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 40),
                SizedBox(
                  height: chartHeight,
                  width: chartWidth,
                  child: SakimCharts(number: number),
                ),

                SizedBox(height: spacing),

                /// **Leadership Chart**
                Text('מנהיגות',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.0,
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold)),
                SizedBox(
                  height: chartHeight / 2,
                  width: chartWidth,
                  child: LeadershipChart(number: number),
                ),

                SizedBox(height: spacing / 2),

                /// **Interview Chart**
                Text('ראיון אישי',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.0,
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold)),
                SizedBox(
                  height: chartHeight / 2,
                  width: chartWidth,
                  child: InterviewChart(number: number),
                ),

                SizedBox(height: 10),

                /// **Performance Summary**
                Text('ניתוח הנתונים',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.0,
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold)),

                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () async {
                      eventController.loading.value = true;
                      p.participantAIReport = await GenAIReport(p);
                      eventController.saveParticipantsAIReport(p.number, p.participantAIReport);
                      eventController.loading.value = false;
                    },
                    child: Text(
                      'עריכה אוטומטית',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: eventController.userFontSize.value),
                    )),
                // AI Results
                Obx(
                  () => eventController.loading.value
                      ? Column(
                        children: [
                          SizedBox(
                              child: CircularProgressIndicator(),
                              width: 50,
                              height: 50,
                            ),
                          Text('זה עשוי לקחת כמה קדות...')
                        ],
                      )
                      : Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                            p.participantAIReport,
                            style: TextStyle(
                              fontSize: baseFontSize,
                              height: 1.5,
                            ),
                          ),
                      ),
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
