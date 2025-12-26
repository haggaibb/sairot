import 'package:flutter/material.dart';
import '../services/push_to_talk_service.dart';
import '../services/user_preferences_service.dart';
import '../services/exercise_context_service.dart';
import '../event_controller.dart';
import '../models/participant.dart';
import '../models/types.dart';
import '../utils/text_cleaning_util.dart';
import 'package:get/get.dart';

class FloatingPttButton extends StatefulWidget {
  final String instructorId;
  final bool enabled; // Whether PTT service should be initialized
  final bool showButton; // Whether to show the floating button UI

  const FloatingPttButton({
    super.key,
    required this.instructorId,
    required this.enabled,
    this.showButton = true,
  });

  @override
  State<FloatingPttButton> createState() => _FloatingPttButtonState();
}

class _FloatingPttButtonState extends State<FloatingPttButton> {
  final PushToTalkService _pttService = PushToTalkService();
  final EventController _eventController = Get.find<EventController>();
  bool _isInitialized = false;
  int? _currentParticipantNumber;
  bool _isProcessing = false;
  bool _isShowingDialog = false; // Prevent duplicate dialogs
  Offset _buttonPosition = Offset.zero; // Button position (will be set after layout)
  bool _isDragging = false; // Track if button is being dragged
  bool _positionLoaded = false; // Track if position has been loaded
  static const double _buttonSize = 56.0; // FloatingActionButton default size

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _initializePtt();
    }
    // Update volume button PTT state when preferences change
    _updateVolumeButtonPttState();
    // Load saved button position after first frame (when MediaQuery is available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadButtonPosition();
      }
    });
  }

  @override
  void didUpdateWidget(FloatingPttButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_isInitialized) {
      _initializePtt();
    } else if (!widget.enabled && _isInitialized) {
      _disposePtt();
    } else if (widget.enabled && _isInitialized) {
      // Widget is enabled and already initialized, update volume button state
      _updateVolumeButtonPttState();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload position when screen size changes (e.g., rotation)
    // This ensures the button position adapts to the new screen dimensions
    if (mounted && _positionLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadButtonPosition();
      });
    }
  }

  Future<void> _updateVolumeButtonPttState() async {
    if (!_isInitialized) {
      return;
    }
    
    final volumeButtonPttEnabled = await UserPreferencesService.getVolumeButtonPtt();
    
    if (volumeButtonPttEnabled) {
      await _pttService.enableAudioMode();
    } else {
      await _pttService.disableAudioMode();
    }
  }

  Future<void> _initializePtt() async {
    if (_isInitialized) return;

    _pttService.onResult = (text) async {
      // Prevent duplicate processing
      if (_isShowingDialog) {
        return;
      }
      
      // Clear processing state when result is received
      print('🎤 Result received - clearing processing state');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        // Small delay to ensure UI updates
        await Future.delayed(const Duration(milliseconds: 50));
        
        if (mounted && !_isShowingDialog) {
          await _handlePttResult(text);
        }
      }
    };
    _pttService.onError = _handlePttError;
    _pttService.onRecordingStarted = () {
      print('🎤 Recording started');
      if (mounted) {
        setState(() {
          _isProcessing = false; // Clear processing when new recording starts
        });
      }
    };
    _pttService.onRecordingStopped = () {
      print('🎤 Recording stopped');
      if (mounted) setState(() {});
    };
    _pttService.onProcessingStarted = () {
      // Don't start processing if we're already showing a dialog
      if (mounted && !_isShowingDialog && _pttService.shouldShowProcessingIndicator) {
        print('🎤 Processing started - showing indicator');
        setState(() {
          _isProcessing = true;
        });
      }
    };
    _pttService.onProcessingStopped = () {
      // Clear processing state when service reports it's stopped
      print('🎤 Processing stopped - hiding indicator');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    };

    await _pttService.initialize();
    _isInitialized = true;
    
    // Update volume button PTT state after initialization
    await _updateVolumeButtonPttState();
  }

  void _disposePtt() {
    if (!_isInitialized) return;
    _pttService.dispose();
    _isInitialized = false;
  }

  Future<void> _handlePttResult(String text) async {
    // Prevent duplicate dialogs
    if (_isShowingDialog) {
      return;
    }
    
    // Processing state is already cleared by onResult wrapper before this is called
    if (text.trim().isEmpty) {
      return;
    }

    // If participant is already in context, save directly
    if (_currentParticipantNumber != null) {
      await _saveComment(text, _currentParticipantNumber!);
      return;
    }

    // Ensure processing is cleared
    if (mounted && _isProcessing) {
      setState(() {
        _isProcessing = false;
      });
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Try to extract participant number and comment from Hebrew text
    final extracted = _extractParticipantNumberAndComment(text);
    
    int? extractedParticipantNumber;
    String commentText = text;
    
    if (extracted != null && extracted['participantNumber'] != null && extracted['comment'] != null) {
      extractedParticipantNumber = int.tryParse(extracted['participantNumber']!);
      commentText = extracted['comment']!;
      print('🎤 Successfully extracted participant number: $extractedParticipantNumber, comment: "$commentText"');
    } else {
      print('🎤 Could not extract participant number from text: "$text"');
    }
    
    // Always show selection dialog, but pre-select participant if number was found
    if (mounted && !_isShowingDialog) {
      _isShowingDialog = true;
      try {
        await _showParticipantSelectionDialog(commentText, preselectedParticipantNumber: extractedParticipantNumber);
      } finally {
        _isShowingDialog = false;
      }
    }
  }

  /// Extract participant number and comment from Hebrew text
  /// Patterns supported:
  /// - "הערה ל 222" or "comment to 222" followed by comment
  /// - "222 הוסף הערה ל" followed by comment
  /// - Number followed by comment (e.g., "222 הוא עצלן")
  /// - "הוסף" followed by number (e.g., "הוסף 222 הוא עצלן")
  /// - "הערה" followed by number and comment (e.g., "הערה 222 הוא עצלן")
  /// Returns map with 'participantNumber' and 'comment', or null if no pattern matches
  Map<String, String>? _extractParticipantNumberAndComment(String text) {
    // Clean the text first to remove duplicates and ensure numbers are separated from words
    // This is especially important for web STT which may concatenate numbers with words
    final cleaned = TextCleaningUtil.cleanText(text);
    final trimmed = cleaned.trim();
    
    // Debug logging to help diagnose extraction issues
    print('🎤 Extracting participant number from text: "$trimmed"');
    
    if (trimmed.isEmpty) {
      return null;
    }

    // First, handle cases where STT splits multi-digit numbers (e.g., "2 7" should be "27")
    // Replace patterns like "2 7" or "3 5 8" with combined numbers "27" or "358"
    String normalizedText = trimmed;
    // Match sequences of digits separated by single spaces (e.g., "2 7", "3 5 8")
    // Also handle cases where a single digit is followed by Hebrew text that might be another digit
    // Pattern: digit, space, Hebrew word that might be a digit, space, more digits
    normalizedText = normalizedText.replaceAllMapped(RegExp(r'\b(\d+)(?:\s+(\d+))+\b'), (match) {
      // Combine all digits in the sequence
      final allDigits = match.group(0)!.replaceAll(RegExp(r'\s+'), '');
      print('🎤 Combined split number: "${match.group(0)}" -> "$allDigits"');
      return allDigits;
    });
    
    // Also try to detect if a single digit at the start might be part of a larger number
    // Check if there's a pattern like "4 זו" where "זו" might be misrecognized digits
    // This is a heuristic - if we have a single digit followed by very short Hebrew text, 
    // it might be a misrecognized multi-digit number
    final singleDigitAtStart = RegExp(r'^(\d)\s+([א-ת]{1,3})\s').firstMatch(normalizedText);
    if (singleDigitAtStart != null) {
      final firstDigit = singleDigitAtStart.group(1)!;
      final nextText = singleDigitAtStart.group(2)!;
      // Check if there are more digits later in the text that might be part of the number
      final remainingText = normalizedText.substring(singleDigitAtStart.end);
      final moreDigits = RegExp(r'^\s*(\d+)').firstMatch(remainingText);
      if (moreDigits != null) {
        // Found pattern like "4 זו 4" - might be "44" split
        final combined = '$firstDigit${moreDigits.group(1)!}';
        print('🎤 Detected possible split number: "$firstDigit $nextText ${moreDigits.group(1)!}" -> "$combined"');
        normalizedText = normalizedText.replaceFirst(
          RegExp(r'^(\d)\s+([א-ת]{1,3})\s+(\d+)'),
          combined,
        );
      }
    }
    
    if (normalizedText != trimmed) {
      print('🎤 Normalized text: "$trimmed" -> "$normalizedText"');
    }

    // Now try to extract all numbers from the normalized text
    final allNumbers = RegExp(r'\d+').allMatches(normalizedText);
    
    if (allNumbers.isEmpty) {
      return null;
    }

    // Use the first number found as the participant number
    final firstNumberMatch = allNumbers.first;
    final firstNumber = firstNumberMatch.group(0)!;
    final numberIndex = normalizedText.indexOf(firstNumber);
    
    // Get text after the number
    final afterNumber = normalizedText.substring(numberIndex + firstNumber.length).trim();
    
    // Pattern 1: "הערה ל 222" or "comment to 222" followed by comment
    var match = RegExp(r'^(?:הערה\s+ל|comment\s+to)\s+(\d+)\s+(.+)$', caseSensitive: false).firstMatch(normalizedText);
    if (match != null && match.group(1) == firstNumber) {
      return {
        'participantNumber': match.group(1)!,
        'comment': match.group(2)!.trim(),
      };
    }

    // Pattern 2: "222 הוסף הערה ל" followed by comment
    match = RegExp(r'^(\d+)\s+הוסף\s+הערה\s+ל\s+(.+)$').firstMatch(normalizedText);
    if (match != null && match.group(1) == firstNumber) {
      return {
        'participantNumber': match.group(1)!,
        'comment': match.group(2)!.trim(),
      };
    }

    // Pattern 3: Number at start followed by comment (most common)
    // Example: "222 הוא עצלן" or "358 הוא עצלן"
    if (numberIndex == 0 && afterNumber.isNotEmpty) {
      // Remove command words from the comment part
      String comment = afterNumber;
      comment = comment.replaceAll(RegExp(r'^(?:הערה\s+ל|comment\s+to|הוסף\s+הערה\s+ל|הוסף|הערה)\s*', caseSensitive: false), '');
      comment = comment.trim();
      
      if (comment.isNotEmpty && !comment.startsWith(firstNumber)) {
        return {
          'participantNumber': firstNumber,
          'comment': comment,
        };
      }
    }

    // Pattern 4: "הוסף" followed by number and comment
    match = RegExp(r'^הוסף\s+(\d+)\s+(.+)$').firstMatch(normalizedText);
    if (match != null && match.group(1) == firstNumber) {
      return {
        'participantNumber': match.group(1)!,
        'comment': match.group(2)!.trim(),
      };
    }

    // Pattern 5: "הערה" followed by number and comment
    match = RegExp(r'^הערה\s+(\d+)\s+(.+)$').firstMatch(normalizedText);
    if (match != null && match.group(1) == firstNumber) {
      return {
        'participantNumber': match.group(1)!,
        'comment': match.group(2)!.trim(),
      };
    }

    // Fallback: If we found a number and there's text after it, use it
    if (afterNumber.length >= 2) {
      // Remove command words from the comment part
      String comment = afterNumber;
      comment = comment.replaceAll(RegExp(r'^(?:הערה\s+ל|comment\s+to|הוסף\s+הערה\s+ל|הוסף|הערה)\s*', caseSensitive: false), '');
      comment = comment.trim();
      
      if (comment.isNotEmpty) {
        print('🎤 Extracted participant number (fallback): $firstNumber, comment: "$comment"');
        return {
          'participantNumber': firstNumber,
          'comment': comment,
        };
      }
    }

    print('🎤 No participant number extracted from text: "$trimmed"');
    return null;
  }

  void _handlePttError(String error) {
    // Clear processing state on error
    print('🎤 Error occurred - clearing processing state: $error');
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בהקלטה: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveComment(String comment, int participantNumber) async {
    try {
      // Get current exercise context
      final exerciseContext = ExerciseContextService().getCurrentExercise();
      
      // Save to appropriate field based on exercise context
      switch (exerciseContext) {
        case 'meshulash':
          // Get existing comments and add new one
          final existingComments = _eventController.currentEvent.value.participants
              .firstWhere((p) => p.number == participantNumber)
              .meshulashInstructorComments;
          if (!existingComments.contains(comment)) {
            existingComments.add(comment);
            _eventController.addMeshulashComments(existingComments, participantNumber);
          }
          break;
          
        case 'alonka':
          final existingComments = _eventController.currentEvent.value.participants
              .firstWhere((p) => p.number == participantNumber)
              .alonkaInstructorComments;
          if (!existingComments.contains(comment)) {
            existingComments.add(comment);
            _eventController.addAlonkaComments(existingComments, participantNumber);
          }
          break;
          
        case 'sakim':
          final existingComments = _eventController.currentEvent.value.participants
              .firstWhere((p) => p.number == participantNumber)
              .sakimInstructorComments;
          if (!existingComments.contains(comment)) {
            existingComments.add(comment);
            _eventController.addSakimComments(existingComments, participantNumber);
          }
          break;
          
        case 'bur':
          // Bur uses a different structure - comments are on the Bur object itself
          _eventController.addBurComment(comment, participantNumber);
          break;
          
        case 'leadership':
          final existingComments = _eventController.currentEvent.value.participants
              .firstWhere((p) => p.number == participantNumber)
              .leadershipInstructorComments;
          if (!existingComments.contains(comment)) {
            existingComments.add(comment);
            _eventController.addLeadershipComments(existingComments, participantNumber);
          }
          break;
          
        case 'interview':
          final existingComments = _eventController.currentEvent.value.participants
              .firstWhere((p) => p.number == participantNumber)
              .interviewInstructorComments;
          if (!existingComments.contains(comment)) {
            existingComments.add(comment);
            _eventController.addInterviewComments(existingComments, participantNumber);
          }
          break;
          
        default:
          // Fallback to interview comments (general comments) if no context or unknown context
          final existingComments = _eventController.currentEvent.value.participants
              .firstWhere((p) => p.number == participantNumber)
              .interviewInstructorComments;
          if (!existingComments.contains(comment)) {
            existingComments.add(comment);
            _eventController.addInterviewComments(existingComments, participantNumber);
          }
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('הערה נשמרה בהצלחה למשתתף $participantNumber'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת הערה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show dialog to select participant
  /// preselectedParticipantNumber: If provided, pre-select this participant in the dropdown
  Future<void> _showParticipantSelectionDialog(String commentText, {int? preselectedParticipantNumber}) async {
    // Load participants for dropdown
    final participants = _eventController.currentEvent.value.participants
        .where((p) => p.status == ParticipantStatus.Active)
        .toList();
    
    participants.sort((a, b) => a.number.compareTo(b.number));

    // Find preselected participant if number was provided
    Participant? preselectedParticipant;
    if (preselectedParticipantNumber != null) {
      print('🎤 Looking for participant number: $preselectedParticipantNumber');
      print('🎤 Available participants: ${participants.map((p) => p.number).toList()}');
      
      // Try exact match first
      preselectedParticipant = participants.firstWhere(
        (p) => p.number == preselectedParticipantNumber,
        orElse: () => Participant(number: -1, name: ''),
      );
      
      if (preselectedParticipant.number == -1) {
        print('🎤 Participant number $preselectedParticipantNumber not found in active participants');
        
        // Try to find a similar number (e.g., if extracted "4" but user might have said "44")
        // Check if any participant number contains the extracted number as a substring
        final similarParticipants = participants.where((p) => 
          p.number.toString().contains(preselectedParticipantNumber.toString()) ||
          preselectedParticipantNumber.toString().contains(p.number.toString())
        ).toList();
        
        if (similarParticipants.isNotEmpty) {
          // Use the first similar participant (prefer exact substring match)
          final similar = similarParticipants.firstWhere(
            (p) => p.number.toString().startsWith(preselectedParticipantNumber.toString()),
            orElse: () => similarParticipants.first,
          );
          print('🎤 Found similar participant: ${similar.number} (extracted: $preselectedParticipantNumber)');
          preselectedParticipant = similar;
        } else {
          preselectedParticipant = null; // Participant not found
        }
      } else {
        print('🎤 Found preselected participant: ${preselectedParticipant.number}');
      }
    } else {
      print('🎤 No preselected participant number provided');
    }

    if (mounted) {
      final selectedParticipantNotifier = ValueNotifier<Participant?>(preselectedParticipant);
      
      final result = await showDialog<int>(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setState) {
              return ValueListenableBuilder<Participant?>(
                valueListenable: selectedParticipantNotifier,
                builder: (context, selectedParticipant, _) => AlertDialog(
                  title: const Text('בחר משתתף'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('הערה:'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          commentText,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (participants.isNotEmpty) ...[
                        const Text('בחר משתתף:'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Participant>(
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
                            selectedParticipantNotifier.value = value;
                          },
                        ),
                      ] else ...[
                        const Text('אין משתתפים פעילים'),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('ביטול'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedParticipant != null) {
                          Navigator.of(context).pop(selectedParticipant.number);
                        }
                      },
                      child: const Text('שמור'            ),
          ),
        ],
      ),
    );
  },
          ),
        ),
      );

      if (result != null) {
        await _saveComment(commentText, result);
      }
      
      selectedParticipantNotifier.dispose();
    }
  }

  /// Load saved button position from preferences
  Future<void> _loadButtonPosition() async {
    if (!mounted) return;
    
    final savedPosition = await UserPreferencesService.getFloatingPttButtonPosition();
    final screenSize = MediaQuery.of(context).size;
    final constraints = _getButtonConstraints();
    
    Offset newPosition;
    
    if (savedPosition != null) {
      // Convert percentage to absolute position
      newPosition = Offset(
        savedPosition.dx * screenSize.width,
        savedPosition.dy * screenSize.height,
      );
      // Ensure saved position is within bounds
      newPosition = Offset(
        newPosition.dx.clamp(constraints.minX, constraints.maxX),
        newPosition.dy.clamp(constraints.minY, constraints.maxY),
      );
    } else {
      // Use default position (bottom center)
      newPosition = _getDefaultPosition(context);
    }
    
    if (mounted) {
      setState(() {
        _buttonPosition = newPosition;
        _positionLoaded = true;
      });
      print('🎤 Floating button position set to: x=${_buttonPosition.dx}, y=${_buttonPosition.dy}');
    }
  }

  /// Calculate default button position (bottom center)
  Offset _getDefaultPosition(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final safeBottom = padding.bottom;
    
    // Calculate position: center horizontally, near bottom with safe area
    final x = (screenSize.width / 2) - (_buttonSize / 2);
    final y = screenSize.height - safeBottom - _buttonSize - 16;
    
    // Ensure position is within bounds
    final minX = padding.left;
    final maxX = screenSize.width - _buttonSize - padding.right;
    final minY = padding.top + 56; // AppBar height
    final maxY = screenSize.height - _buttonSize - safeBottom;
    
    return Offset(
      x.clamp(minX, maxX),
      y.clamp(minY, maxY),
    );
  }

  /// Get button position constraints based on screen bounds and safe areas
  ({double minX, double maxX, double minY, double maxY}) _getButtonConstraints() {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final appBarHeight = 56.0; // Standard AppBar height
    
    return (
      minX: padding.left,
      maxX: screenSize.width - _buttonSize - padding.right,
      minY: padding.top + appBarHeight,
      maxY: screenSize.height - _buttonSize - padding.bottom,
    );
  }

  /// Handle drag update - move button to new position
  void _handlePanUpdate(DragUpdateDetails details) {
    if (!mounted) return;
    
    final constraints = _getButtonConstraints();
    
    // Calculate new position
    double newX = _buttonPosition.dx + details.delta.dx;
    double newY = _buttonPosition.dy + details.delta.dy;
    
    // Clamp to screen bounds
    newX = newX.clamp(constraints.minX, constraints.maxX);
    newY = newY.clamp(constraints.minY, constraints.maxY);
    
    setState(() {
      _buttonPosition = Offset(newX, newY);
      _isDragging = true;
    });
  }

  /// Handle drag end - save position to preferences
  void _handlePanEnd(DragEndDetails details) async {
    if (!mounted) return;
    
    setState(() {
      _isDragging = false;
    });
    
    // Save position as percentage of screen size
    final screenSize = MediaQuery.of(context).size;
    final xPercent = (_buttonPosition.dx / screenSize.width).clamp(0.0, 1.0);
    final yPercent = (_buttonPosition.dy / screenSize.height).clamp(0.0, 1.0);
    
    await UserPreferencesService.saveFloatingPttButtonPosition(xPercent, yPercent);
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _disposePtt();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }

    // Always ensure position is set - calculate default if not loaded
    if (!_positionLoaded || _buttonPosition == Offset.zero) {
      final defaultPos = _getDefaultPosition(context);
      _buttonPosition = defaultPos;
      _positionLoaded = true;
      print('🎤 Floating button default position: x=${_buttonPosition.dx}, y=${_buttonPosition.dy}');
      // Load saved position asynchronously (will override default if exists)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadButtonPosition();
        }
      });
    }

    // Ensure current position is within bounds
    final constraints = _getButtonConstraints();
    final screenSize = MediaQuery.of(context).size;
    print('🎤 Screen size: ${screenSize.width}x${screenSize.height}, Button position: x=${_buttonPosition.dx}, y=${_buttonPosition.dy}');
    
    if (_buttonPosition.dx < constraints.minX || 
        _buttonPosition.dx > constraints.maxX ||
        _buttonPosition.dy < constraints.minY || 
        _buttonPosition.dy > constraints.maxY) {
      // Position is out of bounds, reset to default
      _buttonPosition = _getDefaultPosition(context);
      print('🎤 Floating button position was out of bounds, reset to: x=${_buttonPosition.dx}, y=${_buttonPosition.dy}');
    }
    
    // Debug: Print button visibility info
    if (widget.showButton) {
      print('🎤 Floating button SHOULD BE VISIBLE at: x=${_buttonPosition.dx}, y=${_buttonPosition.dy}, enabled=${widget.enabled}, showButton=${widget.showButton}');
    } else {
      print('🎤 Floating button HIDDEN: showButton=${widget.showButton}, enabled=${widget.enabled}');
    }

    // Return a Stack that fills the parent and positions the button
    // Use Positioned.fill to ensure it covers the entire screen
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
      children: [
        // Floating button (only shown if showButton is true)
        if (widget.showButton)
          Positioned(
            left: _buttonPosition.dx,
            top: _buttonPosition.dy,
            child: Material(
              elevation: 8.0,
              borderRadius: BorderRadius.circular(28.0),
              shadowColor: Colors.black.withOpacity(0.5),
              child: GestureDetector(
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: Opacity(
                  opacity: _isDragging ? 0.8 : 1.0,
                  child: Container(
                    width: 56.0,
                    height: 56.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _pttService.isRecording ? Colors.red : Colors.blue,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8.0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _pttService.isRecording
                          ? () {
                              _pttService.stopRecording();
                            }
                          : () {
                              _pttService.startRecording();
                            },
                      icon: Icon(
                        _pttService.isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Recording/Processing indicator overlay (ALWAYS on top, shown when recording or processing)
        if (_pttService.isRecording || (_isProcessing && _pttService.shouldShowProcessingIndicator))
          Positioned(
            top: MediaQuery.of(context).padding.top + 56 + 8, // Status bar + AppBar height + margin
            right: 16,
            child: Material(
              elevation: 8.0,
              borderRadius: BorderRadius.circular(28.0),
              child: _buildIndicator(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(BuildContext context) {
    if (!_pttService.isRecording && !_isProcessing) {
      return const SizedBox.shrink();
    }

    if (_pttService.isRecording) {
      return _RecordingIndicator();
    } else if (_isProcessing && _pttService.shouldShowProcessingIndicator) {
      return _ProcessingIndicator();
    }

    return const SizedBox.shrink();
  }
}

class _RecordingIndicator extends StatefulWidget {
  @override
  State<_RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<_RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.mic,
              color: Colors.white,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}

class _ProcessingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(12.0),
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}

