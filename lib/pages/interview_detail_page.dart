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
  late List<String> customComments;
  late List<String> instructorComments;
  TextEditingController customCommentCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Predefined comments (fixed list)
    predefinedComments = List<String>.from(widget.commentsList);

    // Load selected comments (including predefined + any custom ones)
    instructorComments = List<String>.from(widget.selectedComments ?? []);

    // Identify which selected comments are custom
    customComments = instructorComments
        .where((c) => !predefinedComments.contains(c))
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
        !customComments.contains(newComment)) {
      setState(() {
        customComments.add(newComment);
        instructorComments.add(newComment); // Add to selected comments
      });

      // Clear input field
      customCommentCtrl.clear();
    }
  }

  /// **Deletes a Custom Comment Completely**
  void deleteCustomComment(String comment) {
    setState(() {
      customComments.remove(comment);
      instructorComments.remove(comment);
    });
  }

  void _saveComments() {
    if (eventController.currentEvent.value.finalized) return;
    
    // Auto-add comment from input field if not empty
    String textInField = customCommentCtrl.text.trim();
    if (textInField.isNotEmpty &&
        !predefinedComments.contains(textInField) &&
        !customComments.contains(textInField)) {
      setState(() {
        customComments.add(textInField);
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
    List<String> allComments = [...predefinedComments, ...customComments];
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
              return ChoiceChip(
                label: Text(
                  comment,
                  style: TextStyle(
                    fontSize: eventController.userFontSize.value,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                selected: isSelected,
                selectedColor: colorScheme.primaryContainer,
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

