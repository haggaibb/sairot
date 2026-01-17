import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../event_controller.dart';
import '../models/participant.dart';
import '../models/types.dart';
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
  final TextEditingController _finalInstructorGradeController =
      TextEditingController();
  final FocusNode _finalGradeFocusNode = FocusNode();
  late List<String> predefinedComments;
  late List<String>
      sessionOnlyCustomComments; // Comments added in this session, not saved to profile
  late List<String>
      instructorSavedComments; // Comments saved to instructor's profile
  late List<String>
      instructorSavedCommentsInterview; // Interview-specific saved comments
  late List<String> instructorSavedCommentsGeneric; // Generic saved comments
  late List<String> instructorComments; // All selected comments
  TextEditingController customCommentCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Comments summary state (for Tab 3)
  bool _isGeneratingCommentsSummary = false;
  String? _commentsSummary;

  @override
  void initState() {
    super.initState();

    // Predefined comments (fixed list)
    predefinedComments = List<String>.from(widget.commentsList);

    // Load selected comments (including predefined + any custom ones)
    instructorComments = List<String>.from(widget.selectedComments ?? []);

    // Load instructor's saved custom comments (both interview and generic)
    instructorSavedComments =
        eventController.getInstructorCustomCommentsForExercise('interview');

    // Separate interview and generic comments for proper removal
    instructorSavedCommentsInterview = List<String>.from(
        eventController.instructorCustomComments['interview'] ?? []);
    instructorSavedCommentsGeneric = List<String>.from(
        eventController.instructorCustomComments['generic'] ?? []);

    // Identify which selected comments are session-only (not in predefined, not in instructor's saved)
    sessionOnlyCustomComments = instructorComments
        .where((c) =>
            !predefinedComments.contains(c) &&
            !instructorSavedComments.contains(c))
        .toList();

    // Load comments summary in background (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCommentsSummary();
    });
  }

  Future<void> _loadCommentsSummary() async {
    Participant p = eventController.getParticipant(widget.participantNumber);

    // Only generate summary if sakim grade is available (indicates sufficient data)
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
    Participant p = eventController.getParticipant(widget.participantNumber);

    // Only allow refresh if sakim grade is available
    if (p.sakimGrade <= 0) {
      return;
    }

    // Clear cached summary to force regeneration
    p.commentsSummary = null;

    // Regenerate
    await _loadCommentsSummary();
  }

  @override
  void dispose() {
    _finalInstructorGradeController.dispose();
    _finalGradeFocusNode.dispose();
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
    final isSessionOnly =
        !predefinedComments.contains(comment) && !isInInstructorSaved;

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
        // Determine which exercise type the comment belongs to
        String exerciseType = 'interview';
        if (instructorSavedCommentsGeneric.contains(comment) &&
            !instructorSavedCommentsInterview.contains(comment)) {
          exerciseType = 'generic';
        }

        // Remove from instructor's profile
        final success = await eventController.removeInstructorCustomComment(
          exerciseType,
          comment,
        );

        if (success && mounted) {
          // Update local state
          setState(() {
            instructorSavedComments.remove(comment);
            if (exerciseType == 'interview') {
              instructorSavedCommentsInterview.remove(comment);
            } else {
              instructorSavedCommentsGeneric.remove(comment);
            }
            // Reload from controller
            final updatedComments = eventController
                .getInstructorCustomCommentsForExercise('interview');
            instructorSavedComments = List<String>.from(updatedComments);
            instructorSavedCommentsInterview = List<String>.from(
                eventController.instructorCustomComments['interview'] ?? []);
            instructorSavedCommentsGeneric = List<String>.from(
                eventController.instructorCustomComments['generic'] ?? []);
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
            final updatedComments = eventController
                .getInstructorCustomCommentsForExercise('interview');
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

  void _saveFinalInstructorGrade(String value) {
    if (eventController.currentEvent.value.finalized) return;

    final grade = double.tryParse(value) ?? 0.0;
    final roundedGrade =
        double.parse(grade.clamp(0.0, 10.0).toStringAsFixed(2));

    eventController.setParticipantsGrade(
        widget.participantNumber, roundedGrade);

    // Update controller text to show saved value
    _finalInstructorGradeController.text = roundedGrade > 0
        ? roundedGrade.toStringAsFixed(
            roundedGrade == roundedGrade.roundToDouble() ? 0 : 2)
        : '';

    // Unfocus
    _finalGradeFocusNode.unfocus();

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ציון מדריך נשמר: ${roundedGrade.toStringAsFixed(2)}'),
        duration: Duration(seconds: 2),
      ),
    );

    // Refresh UI
    setState(() {});
  }

  void _saveComments() {
    if (eventController.currentEvent.value.finalized) return;

    // Save final instructor grade if it was entered but not saved
    final gradeText = _finalInstructorGradeController.text.trim();
    if (gradeText.isNotEmpty) {
      final enteredGrade = double.tryParse(gradeText) ?? 0.0;
      final participant =
          eventController.getParticipant(widget.participantNumber);
      final savedGrade = participant.instructorGrade;

      // Check if the entered grade differs from the saved grade
      if ((enteredGrade - savedGrade).abs() > 0.01) {
        _saveFinalInstructorGrade(gradeText);
      }
    }

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
      padding: EdgeInsets.all(tablet ? 16 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tablet) ...[
            Text(
              'בחר הערה עבור מספר ${widget.participantNumber}',
              style: TextStyle(
                fontSize: tablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12),
          ],
          // Custom Comment Input (Single-line)
          Obx(() => TextField(
                controller: customCommentCtrl,
                maxLines: 1,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.text,
                enabled: !eventController.currentEvent.value.finalized,
                decoration: InputDecoration(
                  hintText: 'הוסף הערה חדשה...',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: tablet ? 16 : 12),
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
          SizedBox(height: tablet ? 12 : 8),
          // Comments List (Predefined & Custom)
          Wrap(
            spacing: tablet ? 12 : 8,
            runSpacing: tablet ? 12 : 8,
            children: allComments.map((comment) {
              bool isSelected = instructorComments.contains(comment);
              final isInInstructorSaved =
                  instructorSavedComments.contains(comment);
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
                    ? Colors.amber.withValues(
                        alpha: 0.1) // Light amber background for saved comments
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
              if (canLongPress &&
                  !eventController.currentEvent.value.finalized) {
                chip = GestureDetector(
                  onLongPress: () => handleCommentLongPress(comment),
                  child: chip,
                );
              }

              return chip;
            }).toList(),
          ),
          SizedBox(height: tablet ? 12 : 8),
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
                        fontSize: tablet
                            ? eventController.userFontSize.value
                            : (eventController.userFontSize.value * 0.9),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'בטל',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: tablet
                            ? eventController.userFontSize.value
                            : (eventController.userFontSize.value * 0.9),
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
                colors: [
                  Colors.blueAccent,
                  const Color.fromARGB(255, 0, 66, 136)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            SizedBox(height: 10),
            Container(
              color: isDark ? colorScheme.surface : Colors.blueAccent,
              child: TabBar(
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'גרפים',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: isTablet ? 6 : 4),
                        Icon(Icons.bar_chart, size: isTablet ? 18 : 16),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'טבלת ציונים',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: isTablet ? 6 : 4),
                        Icon(Icons.table_chart, size: isTablet ? 18 : 16),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'סיכום הערות',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: isTablet ? 6 : 4),
                        Icon(Icons.summarize, size: isTablet ? 18 : 16),
                      ],
                    ),
                  ),
                ],
                labelColor: isDark ? colorScheme.primary : Colors.white,
                unselectedLabelColor: isDark
                    ? colorScheme.onSurface.withOpacity(0.6)
                    : Colors.white70,
                indicatorSize: TabBarIndicatorSize.tab,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Graphs
                  _buildGraphsTab(
                      p,
                      isTablet,
                      baseFontSize,
                      chartHeight,
                      chartWidth,
                      subtitleFontSize,
                      spacing,
                      isDark,
                      colorScheme),
                  // Tab 2: Grades Table
                  _buildGradesTableTab(p, isTablet, isDark, colorScheme),
                  // Tab 3: Comments Summary
                  _buildCommentsSummaryTab(
                      p, baseFontSize, subtitleFontSize, isDark, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphsTab(
      Participant p,
      bool isTablet,
      double baseFontSize,
      double chartHeight,
      double chartWidth,
      double subtitleFontSize,
      double spacing,
      bool isDark,
      ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show generic comments if available
          if (p.genericInstructorComments.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
                      color: isDark ? colorScheme.onSurface : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: p.genericInstructorComments.map((comment) {
                        return Chip(
                          label: Text(
                            comment,
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              color:
                                  isDark ? colorScheme.onSurface : Colors.black,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          backgroundColor: Colors.white
                              .withValues(alpha: isDark ? 0.2 : 0.7),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                  color:
                      isDark ? colorScheme.onSurfaceVariant : Colors.white70)),
          Text(' ציון ${p.meshulashGrade.toStringAsFixed(2)} ',
              style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? colorScheme.onSurfaceVariant : Colors.white70)),
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
                  color:
                      isDark ? colorScheme.onSurfaceVariant : Colors.white70)),
          Text(' ציון ${p.alonkaGrade.toStringAsFixed(2)} ',
              style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? colorScheme.onSurfaceVariant : Colors.white70)),
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
                  color:
                      isDark ? colorScheme.onSurfaceVariant : Colors.white70)),
          Text(' ציון ${p.burGrade.toStringAsFixed(2)} ',
              style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? colorScheme.onSurfaceVariant : Colors.white70)),
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
                  color:
                      isDark ? colorScheme.onSurfaceVariant : Colors.white70)),

          /// Grade
          Text(' ציון ${p.sakimGrade.toStringAsFixed(2)} ',
              style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? colorScheme.onSurfaceVariant : Colors.white70)),
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

          SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildGradesTableTab(
      Participant p, bool isTablet, bool isDark, ColorScheme colorScheme) {
    final allRanks =
        eventController.getAllExerciseRanks(widget.participantNumber);
    final groupStrength = eventController.currentEvent.value.groupStrength;

    // Helper function to get adjusted grade
    double getAdjustedGrade(double baseGrade, GroupStrength strength) {
      switch (strength) {
        case GroupStrength.weak:
          return (baseGrade - 1.0).clamp(0.0, 10.0);
        case GroupStrength.strong:
          return (baseGrade + 1.0).clamp(0.0, 10.0);
        case GroupStrength.normal:
          return baseGrade;
      }
    }

    // Calculate adjusted system grade (handle null values)
    double adjustedMeshulash =
        getAdjustedGrade(p.meshulashGrade ?? 0.0, groupStrength);
    double adjustedAlonka =
        getAdjustedGrade(p.alonkaGrade ?? 0.0, groupStrength);
    double adjustedSakim = getAdjustedGrade(p.sakimGrade ?? 0.0, groupStrength);
    double burGrade = p.burGrade;

    final adjustedSystemGrade = eventController.calculateWeightedGrade(
      param1: adjustedMeshulash,
      param2: adjustedAlonka,
      param3: adjustedSakim,
      param4: burGrade,
      weight1: eventController.gradesData.weighted['meshulash'] ?? 0.25,
      weight2: eventController.gradesData.weighted['alonka'] ?? 0.25,
      weight3: eventController.gradesData.weighted['sakim'] ?? 0.25,
      weight4: eventController.gradesData.weighted['bur'] ?? 0.25,
    );

    // Get Bur comments
    List<String> burComments = [];
    try {
      int participantBurIndex = eventController.currentEvent.value.burGrades
          .indexWhere((bur) => bur.id == p.number);
      if (participantBurIndex >= 0) {
        burComments = eventController.currentEvent.value
            .burGrades[participantBurIndex].instructorComments;
      }
    } catch (e) {
      // Ignore error
    }

    final rows = [
      {
        'exercise': 'משולש',
        'systemGrade': adjustedMeshulash.toStringAsFixed(2),
        'instructorGrade': p.instructorMeshulashGrade > 0
            ? p.instructorMeshulashGrade.toStringAsFixed(2)
            : null,
        'rank':
            '${allRanks['meshulash']!['rank']}/${allRanks['meshulash']!['total']}',
        'comments': p.meshulashInstructorComments,
      },
      {
        'exercise': 'אלונקה',
        'systemGrade': adjustedAlonka.toStringAsFixed(2),
        'instructorGrade': p.instructorAlonkaGrade > 0
            ? p.instructorAlonkaGrade.toStringAsFixed(2)
            : null,
        'rank':
            '${allRanks['alonka']!['rank']}/${allRanks['alonka']!['total']}',
        'comments': p.alonkaInstructorComments,
      },
      {
        'exercise': 'בור',
        'systemGrade': burGrade.toStringAsFixed(2),
        'instructorGrade':
            null, // Bur doesn't have instructor grade in the same way
        'rank': '${allRanks['bur']!['rank']}/${allRanks['bur']!['total']}',
        'comments': burComments,
      },
      {
        'exercise': 'שקים',
        'systemGrade': adjustedSakim.toStringAsFixed(2),
        'instructorGrade': p.instructorSakimGrade > 0
            ? p.instructorSakimGrade.toStringAsFixed(2)
            : null,
        'rank': '${allRanks['sakim']!['rank']}/${allRanks['sakim']!['total']}',
        'comments': p.sakimInstructorComments,
      },
      {
        'exercise': 'כללי',
        'systemGrade': '-',
        'instructorGrade': null,
        'rank': '-',
        'comments': p.genericInstructorComments,
      },
    ];

    // Initialize final instructor grade controller if not already set
    if (_finalInstructorGradeController.text.isEmpty ||
        (p.instructorGrade > 0 &&
            _finalInstructorGradeController.text !=
                p.instructorGrade.toStringAsFixed(
                    p.instructorGrade == p.instructorGrade.roundToDouble()
                        ? 0
                        : 2))) {
      _finalInstructorGradeController.text = p.instructorGrade > 0
          ? p.instructorGrade.toStringAsFixed(
              p.instructorGrade == p.instructorGrade.roundToDouble() ? 0 : 2)
          : '';
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 16 : 12,
                      vertical: isTablet ? 8 : 6),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'מערכת: ${adjustedSystemGrade.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 18 : 14,
                      vertical: isTablet ? 9 : 7),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue[300]!, width: 1),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'מדריך: ',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(
                          width: isTablet ? 60 : 50,
                          child: TextField(
                            controller: _finalInstructorGradeController,
                            focusNode: _finalGradeFocusNode,
                            textAlign: TextAlign.center,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            enabled:
                                !eventController.currentEvent.value.finalized,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.1,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                color: Colors.white70,
                                fontSize: isTablet ? 16 : 14,
                                height: 1.1,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 2),
                              isDense: true,
                            ),
                            onSubmitted: (value) {
                              _saveFinalInstructorGrade(value);
                            },
                            onChanged: (value) {
                              // Auto-save on change
                              if (value.isNotEmpty &&
                                  !eventController
                                      .currentEvent.value.finalized) {
                                final grade = double.tryParse(value);
                                if (grade != null &&
                                    grade >= 0 &&
                                    grade <= 10) {
                                  // Debounce: save after user stops typing
                                  Future.delayed(Duration(milliseconds: 500),
                                      () {
                                    if (_finalInstructorGradeController.text ==
                                            value &&
                                        mounted) {
                                      _saveFinalInstructorGrade(value);
                                    }
                                  });
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'פירוט לפי תרגילים:',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: isDark ? colorScheme.onSurface : Colors.white,
              ),
            ),
            SizedBox(height: 10),
            _buildGradesTable(rows, isTablet, true, isDark, colorScheme,
                p), // Always show instructor grade column
          ],
        ),
      ),
    );
  }

  Widget _buildGradesTable(
      List<Map<String, dynamic>> rows,
      bool isTablet,
      bool hasInstructorGrades,
      bool isDark,
      ColorScheme colorScheme,
      Participant p) {
    final firstColumnWidth = isTablet ? 120.0 : 100.0;
    final cellHeight = 60.0; // Increased for comments
    final commentsColumnWidth = isTablet ? 200.0 : 150.0;

    Widget buildTableCell(String text, bool isTablet,
        {bool isHeader = false, Color? backgroundColor, int? maxLines}) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        decoration: backgroundColor != null
            ? BoxDecoration(color: backgroundColor)
            : null,
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            color: isHeader
                ? Colors.white
                : (isDark ? colorScheme.onSurface : Colors.white),
          ),
        ),
      );
    }

    Widget buildCommentsCell(List<String> comments, bool isTablet) {
      if (comments.isEmpty) {
        return buildTableCell('-', isTablet);
      }
      // Join comments with comma, truncate if too long
      String commentsText = comments.join(', ');
      if (commentsText.length > 50) {
        commentsText = commentsText.substring(0, 50) + '...';
      }
      return Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey[300]!, width: 1),
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        child: Tooltip(
          message: comments.join('\n'),
          child: Text(
            commentsText,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: isDark ? colorScheme.onSurface : Colors.white,
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frozen first column
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: firstColumnWidth,
              height: cellHeight,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                border: Border(
                  right: BorderSide(color: Colors.grey[300]!, width: 1),
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: buildTableCell('תרגיל', isTablet, isHeader: true),
            ),
            // Data rows
            ...rows.map((row) => Container(
                  width: firstColumnWidth,
                  height: cellHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey[300]!, width: 1),
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  child: buildTableCell(row['exercise']!, isTablet),
                )),
          ],
        ),
        // Scrollable columns
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row (RTL order: instructor grade, system grade, rank, comments)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: isTablet ? 120.0 : 100.0,
                      height: cellHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!, width: 1),
                          bottom:
                              BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: buildTableCell('מדריך', isTablet, isHeader: true),
                    ),
                    Container(
                      width: isTablet ? 120.0 : 100.0,
                      height: cellHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!, width: 1),
                          bottom:
                              BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: buildTableCell('מערכת', isTablet, isHeader: true),
                    ),
                    Container(
                      width: isTablet ? 120.0 : 100.0,
                      height: cellHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!, width: 1),
                          bottom:
                              BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: buildTableCell('דירוג', isTablet, isHeader: true),
                    ),
                    Container(
                      width: commentsColumnWidth,
                      height: cellHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!, width: 1),
                          bottom:
                              BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: buildTableCell('הערות', isTablet, isHeader: true),
                    ),
                  ],
                ),
                // Data rows (RTL order: instructor grade, system grade, rank, comments)
                ...rows.map((row) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isTablet ? 120.0 : 100.0,
                          height: cellHeight,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                  color: Colors.grey[300]!, width: 1),
                              bottom: BorderSide(
                                  color: Colors.grey[300]!, width: 1),
                            ),
                          ),
                          child: buildTableCell(
                            row['instructorGrade'] ?? '-',
                            isTablet,
                          ),
                        ),
                        Container(
                          width: isTablet ? 120.0 : 100.0,
                          height: cellHeight,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                  color: Colors.grey[300]!, width: 1),
                              bottom: BorderSide(
                                  color: Colors.grey[300]!, width: 1),
                            ),
                          ),
                          child: buildTableCell(row['systemGrade']!, isTablet),
                        ),
                        Container(
                          width: isTablet ? 120.0 : 100.0,
                          height: cellHeight,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                  color: Colors.grey[300]!, width: 1),
                              bottom: BorderSide(
                                  color: Colors.grey[300]!, width: 1),
                            ),
                          ),
                          child: buildTableCell(row['rank']!, isTablet),
                        ),
                        Container(
                          width: commentsColumnWidth,
                          height: cellHeight,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                  color: Colors.grey[300]!, width: 1),
                              bottom: BorderSide(
                                  color: Colors.grey[300]!, width: 1),
                            ),
                          ),
                          child: buildCommentsCell(
                              row['comments'] as List<String>, isTablet),
                        ),
                      ],
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSummaryTab(Participant p, double baseFontSize,
      double subtitleFontSize, bool isDark, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comments Summary Section (AI-generated) - Only show if summary exists or is generating
            if (_commentsSummary != null || _isGeneratingCommentsSummary) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.1 : 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.blue.withOpacity(0.4), width: 2),
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
                            color:
                                isDark ? colorScheme.onSurface : Colors.white,
                          ),
                        ),
                        if (_commentsSummary != null &&
                            _commentsSummary != "שגיאה ביצירת סיכום הערות." &&
                            !_isGeneratingCommentsSummary)
                          IconButton(
                            icon: Icon(Icons.refresh,
                                size: 20,
                                color: isDark
                                    ? colorScheme.onSurface
                                    : Colors.white),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? colorScheme.primary : Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'מייצר סיכום הערות...',
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              fontStyle: FontStyle.italic,
                              color:
                                  isDark ? colorScheme.onSurface : Colors.white,
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
                          color: isDark ? colorScheme.onSurface : Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'סיכום הערות יופיע כאן כאשר יהיו מספיק נתונים',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: isDark
                          ? colorScheme.onSurface.withOpacity(0.6)
                          : Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
            // Performance Section with tabs (each tab handles its own scrolling)
            Expanded(
              child: _buildPerformanceSection(),
            ),
          ],
        ),
      ),
    );
  }
}
