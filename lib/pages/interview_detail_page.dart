import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../event_controller.dart';
import '../models/participant.dart';
import '../widgets/meshulash_charts.dart';
import '../widgets/alonka_charts.dart';
import '../widgets/bur_charts.dart';
import '../widgets/sakim_charts.dart';
import '../widgets/interview_chart.dart';
import '../widgets/leadership_chart.dart';
import '../utils/tablet_utils.dart';
import '../widgets/wifi_settings_button.dart';
import '../widgets/comment_save_confirmation_dialog.dart';

final eventController = Get.put(EventController());

class InterviewDetailPage extends StatefulWidget {
  final int participantNumber;
  final List<String> commentsList;
  final List<String>? selectedComments;

  const InterviewDetailPage({
    super.key,
    required this.participantNumber,
    required this.commentsList,
    this.selectedComments,
  });

  @override
  State<InterviewDetailPage> createState() => _InterviewDetailPageState();
}

class _InterviewDetailPageState extends State<InterviewDetailPage> {
  late List<String> predefinedComments;
  late List<String> sessionOnlyCustomComments; // Comments added in this session, not saved to profile
  late List<String> instructorSavedComments; // Comments saved to instructor's profile
  late List<String> instructorComments; // All selected comments
  TextEditingController customCommentCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Predefined comments (fixed list)
    predefinedComments = List<String>.from(widget.commentsList);

    // Load selected comments (including predefined + any custom ones)
    instructorComments = List<String>.from(widget.selectedComments ?? []);

    // Load instructor's saved custom comments
    instructorSavedComments = eventController.getInstructorCustomCommentsForExercise('interview');

    // Identify which selected comments are session-only (not in predefined, not in instructor's saved)
    sessionOnlyCustomComments = instructorComments
        .where((c) => !predefinedComments.contains(c) && !instructorSavedComments.contains(c))
        .toList();
  }

  @override
  void dispose() {
    customCommentCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// **Adds a New Custom Comment**
  void addCustomComment() {
    String newComment = customCommentCtrl.text.trim();
    if (newComment.isNotEmpty &&
        !predefinedComments.contains(newComment) &&
        !instructorSavedComments.contains(newComment) &&
        !sessionOnlyCustomComments.contains(newComment)) {
      setState(() {
        sessionOnlyCustomComments.add(newComment);
        instructorComments.add(newComment); // Add to selected comments
      });

      // Clear input field
      customCommentCtrl.clear();
    }
  }

  /// **Deletes a Session-Only Custom Comment**
  void deleteSessionOnlyComment(String comment) {
    setState(() {
      sessionOnlyCustomComments.remove(comment);
      instructorComments.remove(comment);
    });
  }

  /// **Handle long-press on comment to save/remove from instructor profile**
  Future<void> handleCommentLongPress(String comment) async {
    // Check if comment is in instructor's saved list
    final isInInstructorSaved = instructorSavedComments.contains(comment);
    
    // Check if comment is session-only (not in predefined, not in instructor's saved)
    final isSessionOnly = !predefinedComments.contains(comment) && !isInInstructorSaved;
    
    // Only allow long-press on instructor's saved comments (to remove) or session-only (to save)
    if (!isInInstructorSaved && !isSessionOnly) {
      return; // System predefined - no long-press
    }
    
    // Show confirmation dialog
    final confirmed = await CommentSaveConfirmationDialog.show(
      context,
      isRemoving: isInInstructorSaved,
      comment: comment,
    );
    
    if (confirmed == true) {
      if (isInInstructorSaved) {
        // Remove from instructor's profile
        final success = await eventController.removeInstructorCustomComment(
          'interview',
          comment,
        );
        
        if (success && mounted) {
          // Update local state
          setState(() {
            instructorSavedComments.remove(comment);
            // Reload from controller
            final updatedComments = eventController.getInstructorCustomCommentsForExercise('interview');
            instructorSavedComments = List<String>.from(updatedComments);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ההערה הוסרה מהרשימה האישית שלך'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (isSessionOnly) {
        // Save to instructor's profile
        final success = await eventController.saveInstructorCustomComment(
          'interview',
          comment,
        );
        
        if (success && mounted) {
          // Update local state
          setState(() {
            sessionOnlyCustomComments.remove(comment);
            // Reload from controller
            final updatedComments = eventController.getInstructorCustomCommentsForExercise('interview');
            instructorSavedComments = List<String>.from(updatedComments);
            if (!instructorSavedComments.contains(comment)) {
              instructorSavedComments.add(comment);
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ההערה נשמרה לרשימה האישית שלך'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _saveComments() {
    if (eventController.currentEvent.value.finalized) return;
    
    // Auto-add comment from input field if not empty
    String textInField = customCommentCtrl.text.trim();
    if (textInField.isNotEmpty &&
        !predefinedComments.contains(textInField) &&
        !instructorSavedComments.contains(textInField) &&
        !sessionOnlyCustomComments.contains(textInField)) {
      setState(() {
        sessionOnlyCustomComments.add(textInField);
        instructorComments.add(textInField);
      });
      customCommentCtrl.clear();
    }
    
    List<String> finalSelectedComments = List.from(instructorComments);
    eventController.addInterviewComments(
        finalSelectedComments, widget.participantNumber);
    Get.back();
  }

  Widget _buildCommentsSection() {
    /// **Order comments: Instructor's saved first, then predefined, then session-only**
    // Remove duplicates (instructor's saved takes precedence)
    final predefinedFiltered = predefinedComments
        .where((c) => !instructorSavedComments.contains(c))
        .toList();
    
    final allComments = [
      ...instructorSavedComments, // First: Instructor's custom comments
      ...predefinedFiltered, // Second: Predefined comments (excluding instructor's saved)
      ...sessionOnlyCustomComments, // Third: Session-only custom comments
    ];
    
    bool tablet = isTablet(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(tablet ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'בחר הערה עבור מספר ${widget.participantNumber}',
            style: TextStyle(
              fontSize: tablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12),
          // Custom Comment Input (Multi-line)
          Obx(() => TextField(
            controller: customCommentCtrl,
            maxLines: null,
            minLines: 3,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            enabled: !eventController.currentEvent.value.finalized,
            decoration: InputDecoration(
              hintText: 'הוסף הערה חדשה...',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.send,
                  color: eventController.currentEvent.value.finalized
                      ? colorScheme.onSurface.withOpacity(0.38)
                      : colorScheme.primary,
                ),
                onPressed: eventController.currentEvent.value.finalized
                    ? null
                    : addCustomComment,
              ),
            ),
            onSubmitted: eventController.currentEvent.value.finalized
                ? null
                : (_) => addCustomComment(),
          )),
          SizedBox(height: 12),
          // Comments List (Predefined & Custom)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: allComments.map((comment) {
              bool isSelected = instructorComments.contains(comment);
              final isInInstructorSaved = instructorSavedComments.contains(comment);
              final isSessionOnly = sessionOnlyCustomComments.contains(comment);
              
              // Only enable long-press for instructor's saved comments or session-only comments
              final canLongPress = isInInstructorSaved || isSessionOnly;

              Widget chip = ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isInInstructorSaved)
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                    if (isInInstructorSaved) const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        comment,
                        style: TextStyle(
                          fontSize: eventController.userFontSize.value,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: colorScheme.primaryContainer,
                backgroundColor: isInInstructorSaved
                    ? Colors.amber.withValues(alpha: 0.1) // Light amber background for saved comments
                    : null,
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
                onSelected: eventController.currentEvent.value.finalized
                    ? null
                    : (bool selected) {
                        setState(() {
                          if (selected) {
                            instructorComments.add(comment);
                          } else {
                            instructorComments.remove(comment);
                          }
                        });
                      },
              );
              
              // Wrap with GestureDetector for long-press if eligible
              if (canLongPress && !eventController.currentEvent.value.finalized) {
                chip = GestureDetector(
                  onLongPress: () => handleCommentLongPress(comment),
                  child: chip,
                );
              }
              
              return chip;
            }).toList(),
          ),
          SizedBox(height: 12),
          // Action Buttons
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: eventController.currentEvent.value.finalized
                    ? null
                    : _saveComments,
                child: Text(
                  'שמור וסגור',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: eventController.userFontSize.value,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'בטל',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: eventController.userFontSize.value,
                  ),
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    Participant p = eventController.getParticipant(widget.participantNumber);
    bool isTablet = MediaQuery.of(context).size.width > 600;
    double baseFontSize = isTablet ? 24 : 18;
    double chartHeight = isTablet ? 500 : 300;
    double chartWidth = isTablet ? 650 : 350;
    double titleFontSize = isTablet ? 28 : 22;
    double subtitleFontSize = isTablet ? 22 : 16;
    double spacing = isTablet ? 80 : 60;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [
                  colorScheme.surface,
                  colorScheme.surfaceContainerLow,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.blueAccent, const Color.fromARGB(255, 0, 66, 136)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20),
          Text(
            'ניתוח ביצועים עבור משתתף ${widget.participantNumber}',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: isDark ? colorScheme.onSurface : Colors.white,
            ),
          ),

          SizedBox(height: spacing),

          /// **Meshulash Chart**
          Text('ניתוח ביצועים - משולש',
              style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.0,
                  fontSize: baseFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurface : Colors.white)),
          Text('השוואה קבוצתית',
              style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurfaceVariant : Colors.white70)),
          Text(' ציון ${p.meshulashGrade.toStringAsFixed(2)} ',
              style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurfaceVariant : Colors.white70)),
          SizedBox(height: 10),
          SizedBox(
            height: chartHeight,
            width: chartWidth,
            child: MeshulashCharts(number: widget.participantNumber),
          ),

          SizedBox(height: spacing),

          /// **Alonka Chart**
          Text('ניתוח ביצועים - אלונקה',
              style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.0,
                  fontSize: baseFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurface : Colors.white)),
          Text('גרף ביצועים אישי',
              style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurfaceVariant : Colors.white70)),
          Text(' ציון ${p.alonkaGrade.toStringAsFixed(2)} ',
              style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurfaceVariant : Colors.white70)),
          SizedBox(
            height: chartHeight,
            width: chartWidth,
            child: AlonkaCharts(number: widget.participantNumber),
          ),

          SizedBox(height: spacing),

          /// **Bur Chart**
          Text('ניתוח ביצועים - בור',
              style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.0,
                  fontSize: baseFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurface : Colors.white)),
          Text('השוואה קבוצתית',
              style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurfaceVariant : Colors.white70)),
          Text(' ציון ${p.burGrade.toStringAsFixed(2)} ',
              style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurfaceVariant : Colors.white70)),
          SizedBox(
            height: chartHeight,
            width: chartWidth,
            child: BurCharts(number: widget.participantNumber),
          ),

          SizedBox(height: spacing),

          /// **Sakim Chart**
          Text('ניתוח ביצועים - שקים',
              style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.0,
                  fontSize: baseFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurface : Colors.white)),
          Text('גרף אישי',
              style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurfaceVariant : Colors.white70)),
          /// Grade
          Text(' ציון ${p.sakimGrade.toStringAsFixed(2)} ',
              style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurfaceVariant : Colors.white70)),
          SizedBox(height: 40),
          SizedBox(
            height: chartHeight,
            width: chartWidth,
            child: SakimCharts(number: widget.participantNumber),
          ),

          SizedBox(height: spacing),

          /// **Leadership Chart**
          Text('מנהיגות',
              style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.0,
                  fontSize: baseFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurface : Colors.white)),
          SizedBox(
            height: chartHeight / 2,
            width: chartWidth,
            child: LeadershipChart(number: widget.participantNumber),
          ),

          SizedBox(height: spacing / 2),

          /// **Interview Chart**
          Text('ראיון אישי',
              style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.0,
                  fontSize: baseFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurface : Colors.white)),
          SizedBox(
            height: chartHeight / 2,
            width: chartWidth,
            child: InterviewChart(number: widget.participantNumber),
          ),

          SizedBox(height: 10),

          /// **Performance Summary**
          Text('ניתוח הנתונים',
              style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.0,
                  fontSize: baseFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurface : Colors.white)),

          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () async {
                eventController.loading.value = true;
                p.participantAIReport = await _genAIReport(p);
                eventController.saveParticipantsAIReport(
                    widget.participantNumber, p.participantAIReport);
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
                      Text(
                        'זה עשוי לקחת כמה קדות...',
                        style: TextStyle(
                          color: isDark ? colorScheme.onSurface : Colors.white,
                        ),
                      )
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      p.participantAIReport,
                      style: TextStyle(
                        fontSize: baseFontSize,
                        height: 1.5,
                        color: isDark ? colorScheme.onSurface : Colors.white,
                      ),
                    ),
                  ),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }

  Future<String> _genAIReport(Participant p) async {
    var data = await p.fetchAndGenerateSummary(p.number.toString());
    if (data.isNotEmpty) {
      return data;
    } else {
      return "No Data";
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Get.back();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('ראיון אישי - משתתף ${widget.participantNumber}'),
          actions: [
            WifiSettingsButton(),
          ],
        ),
        body: Column(
          children: [
            // Sticky Comments Section
            _buildCommentsSection(),
            // Scrollable Performance Section
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: SizedBox(
                  width: double.infinity,
                  child: _buildPerformanceSection(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

