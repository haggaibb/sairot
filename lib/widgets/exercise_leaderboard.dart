import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../event_controller.dart';
import '../models/participant.dart';
import '../models/types.dart';
import '../utils/tablet_utils.dart';

class ExerciseLeaderboard extends StatefulWidget {
  final String exerciseType; // 'meshulash' or 'sakim'
  final bool inOrderOfArrival;

  const ExerciseLeaderboard({
    super.key,
    required this.exerciseType,
    required this.inOrderOfArrival,
  });

  @override
  State<ExerciseLeaderboard> createState() => _ExerciseLeaderboardState();
}

class _ExerciseLeaderboardState extends State<ExerciseLeaderboard> {
  final eventController = Get.put(EventController());
  // Track previous positions to calculate changes
  Map<int, int> _previousPositions = {};
  bool _hasInitialized = false;
  List<int> _lastTop10Numbers = [];
  bool _isExpanded = false; // Leaderboard starts collapsed

  @override
  void initState() {
    super.initState();
    // Initialize previous positions on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final top10 = _getTop10Participants();
        _lastTop10Numbers = top10.map((p) => p.number).toList();
        _updatePreviousPositions();
        setState(() {
          _hasInitialized = true;
        });
      }
    });
  }

  void _updatePreviousPositions() {
    // Store current positions as previous for next update
    final top10 = _getTop10Participants();
    final currentNumbers = top10.map((p) => p.number).toList();
    
    // Only update if the top 10 list has changed
    if (_hasInitialized && currentNumbers.toString() != _lastTop10Numbers.toString()) {
      // Positions changed, update previous positions
      final newPreviousPositions = <int, int>{};
      for (int i = 0; i < top10.length; i++) {
        newPreviousPositions[top10[i].number] = i + 1;
      }
      _previousPositions = newPreviousPositions;
      _lastTop10Numbers = currentNumbers;
    } else if (!_hasInitialized) {
      // First time - initialize
      final newPreviousPositions = <int, int>{};
      for (int i = 0; i < top10.length; i++) {
        newPreviousPositions[top10[i].number] = i + 1;
      }
      _previousPositions = newPreviousPositions;
      _lastTop10Numbers = currentNumbers;
    }
  }

  List<Participant> _getTop10Participants() {
    final activeParticipants = eventController.currentEvent.value
        .getParticipantsByStatus(ParticipantStatus.Active);
    
    if (activeParticipants.isEmpty) return [];

    // Filter out participants in round 0 - only show round 1 and above
    final filteredParticipants = activeParticipants.where((participant) {
      final roundNumber = _getParticipantRound(participant.number);
      return roundNumber != null && roundNumber > 0;
    }).toList();

    if (filteredParticipants.isEmpty) return [];

    // Sort by exercise grade (descending)
    final sorted = List<Participant>.from(filteredParticipants);
    if (widget.exerciseType == 'meshulash') {
      sorted.sort((a, b) => eventController.getMeshulashGrade(b.number)
          .compareTo(eventController.getMeshulashGrade(a.number)));
    } else if (widget.exerciseType == 'sakim') {
      sorted.sort((a, b) => eventController.getSakimGrade(b.number)
          .compareTo(eventController.getSakimGrade(a.number)));
    }

    // Return top 10 (or less if fewer than 10 exist)
    return sorted.take(10).toList();
  }

  int? _getPositionChange(int participantNumber, int currentPosition) {
    if (!_hasInitialized || _previousPositions.isEmpty) return null; // Not initialized yet
    final previousPosition = _previousPositions[participantNumber];
    if (previousPosition == null) {
      // Participant wasn't in top 10 before, now they are - treat as new entry
      return null;
    }
    if (previousPosition == currentPosition) return 0; // No change
    return previousPosition - currentPosition; // Positive = moved up, Negative = moved down
  }

  int? _getParticipantRound(int participantNumber) {
    if (widget.exerciseType == 'meshulash') {
      for (var round in eventController.currentEvent.value.meshulashRounds) {
        if (round.participantsInRound.contains(participantNumber)) {
          return round.round;
        }
      }
    } else if (widget.exerciseType == 'sakim') {
      for (var round in eventController.currentEvent.value.sakimRounds) {
        if (round.participantsInRound.contains(participantNumber)) {
          return round.round;
        }
      }
    }
    return null; // Not found in any round
  }

  String _getExerciseName() {
    switch (widget.exerciseType) {
      case 'meshulash':
        return 'משולש';
      case 'sakim':
        return 'שקים';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool tablet = isTablet(context);
    final double scaledFontSize = getTabletScaledFontSize(context, eventController.userFontSize.value);
    
    return GetX<EventController>(
      builder: (_) {
        final top10 = _getTop10Participants();
        
        if (top10.isEmpty) {
          return SizedBox.shrink();
        }

        // Update previous positions after build (for next comparison)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _updatePreviousPositions();
          }
        });

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact Header with collapse button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'לוח מובילים - ${_getExerciseName()}',
                    style: TextStyle(
                      fontSize: tablet ? scaledFontSize - 1 : scaledFontSize - 3,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Top 10',
                        style: TextStyle(
                          fontSize: tablet ? scaledFontSize - 2 : scaledFontSize - 4,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(width: 4),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        icon: Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: tablet ? 20 : 18,
                          color: Colors.blue[700],
                        ),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (_isExpanded) ...[
                SizedBox(height: 2),
                Divider(color: Colors.grey[300], height: 0.5),
                SizedBox(height: 1),
                // Compact single-column list
                ...top10.asMap().entries.map((entry) {
                final index = entry.key;
                final participant = entry.value;
                final position = index + 1;
                final roundNumber = _getParticipantRound(participant.number);
                // Only show position change for round 1 and above
                final positionChange = (roundNumber != null && roundNumber > 0) 
                    ? _getPositionChange(participant.number, position)
                    : null;
                
                // Medal colors for top 3
                Color? positionColor;
                IconData? positionIcon;
                if (position == 1) {
                  positionColor = Colors.amber;
                  positionIcon = Icons.emoji_events;
                } else if (position == 2) {
                  positionColor = Colors.grey[400];
                  positionIcon = Icons.emoji_events;
                } else if (position == 3) {
                  positionColor = Colors.brown[300];
                  positionIcon = Icons.emoji_events;
                }

                return GestureDetector(
                  onTap: () {
                    // Show position change when clicked (optional - now always visible)
                    if (positionChange != null) {
                      String changeText;
                      Color changeColor;
                      if (positionChange > 0) {
                        changeText = '+$positionChange';
                        changeColor = Colors.green;
                      } else if (positionChange < 0) {
                        changeText = '$positionChange';
                        changeColor = Colors.red;
                      } else {
                        changeText = '-';
                        changeColor = Colors.grey;
                      }
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'משתתף ${participant.number}: $changeText',
                            style: TextStyle(
                              fontSize: scaledFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: changeColor,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 1),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: position <= 3 ? (positionColor?.withValues(alpha: 0.1)) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: position <= 3 ? (positionColor ?? Colors.grey[300]!) : Colors.grey[300]!,
                        width: position <= 3 ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Position and icon
                        Row(
                          children: [
                            if (positionIcon != null && position <= 3)
                              Icon(
                                positionIcon,
                                color: positionColor,
                                size: tablet ? 16 : 14,
                              )
                            else
                              Container(
                                width: tablet ? 22 : 20,
                                height: tablet ? 22 : 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue[100],
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$position',
                                      style: TextStyle(
                                        fontSize: tablet ? scaledFontSize - 5 : scaledFontSize - 6,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900],
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(width: 6),
                            Text(
                              'משתתף ${participant.number}${roundNumber != null ? ' (סיבוב $roundNumber)' : ''}',
                              style: TextStyle(
                                fontSize: tablet ? scaledFontSize - 2 : scaledFontSize - 4,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        // Position change indicator - always show
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: positionChange != null
                                ? (positionChange > 0
                                    ? Colors.green[100]
                                    : positionChange < 0
                                        ? Colors.red[100]
                                        : Colors.grey[200])
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            positionChange != null
                                ? (positionChange > 0
                                    ? '+$positionChange'
                                    : positionChange < 0
                                        ? '$positionChange'
                                        : '-')
                                : '-',
                            style: TextStyle(
                              fontSize: tablet ? scaledFontSize - 4 : scaledFontSize - 6,
                              fontWeight: FontWeight.bold,
                              color: positionChange != null
                                  ? (positionChange > 0
                                      ? Colors.green[800]
                                      : positionChange < 0
                                          ? Colors.red[800]
                                          : Colors.grey[700])
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              ],
            ],
          ),
        );
      },
    );
  }
}
