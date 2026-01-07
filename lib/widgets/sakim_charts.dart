import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sairot/models/participant.dart';
import 'package:sairot/models/types.dart';
import '../event_controller.dart';
import '../utils/tablet_utils.dart';

/// Custom dot painter that draws dot with label
class SakimLabeledDotPainter extends FlDotPainter {
  final String label;
  final Color dotColor;
  final Color labelColor;
  final double fontSize;

  SakimLabeledDotPainter({
    required this.label,
    this.dotColor = Colors.red,
    this.labelColor = Colors.red,
    this.fontSize = 10.0,
  });

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offset) {
    // Draw the dot
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offset, 4, paint);
    
    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(offset, 4, borderPaint);
    
    // Draw label text above the dot
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: labelColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Position label centered above the dot
    final labelOffset = Offset(
      offset.dx - textPainter.width / 2,
      offset.dy - textPainter.height - 8, // 8px above the dot
    );
    textPainter.paint(canvas, labelOffset);
  }

  @override
  Size getSize(FlSpot spot) {
    // Return size including label space above
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return Size(textPainter.width, textPainter.height + 8 + 4); // label height + spacing + dot radius
  }

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    if (a is SakimLabeledDotPainter && b is SakimLabeledDotPainter) {
      return SakimLabeledDotPainter(
        label: b.label,
        dotColor: Color.lerp(a.dotColor, b.dotColor, t) ?? b.dotColor,
        labelColor: Color.lerp(a.labelColor, b.labelColor, t) ?? b.labelColor,
        fontSize: b.fontSize,
      );
    }
    return b;
  }

  @override
  Color get mainColor => dotColor;

  @override
  List<Object?> get props => [label, dotColor, labelColor, fontSize];
}

/// Custom painter to draw bars on the chart
class SakimBarPainter extends CustomPainter {
  final List<int> rounds;
  final List<int> counts;
  final int currentRound;
  final double minX;
  final double maxX;
  final double minY; // LineChart's minY (for coordinate system)
  final double maxY; // LineChart's maxY (for coordinate system)
  final double maxCount; // Right axis max (for scaling bars)
  final double barWidth;
  final double labelChartWidth; // Width used by labels for X positioning
  final Color defaultColor;
  final Color currentRoundColor;

  SakimBarPainter({
    required this.rounds,
    required this.counts,
    required this.currentRound,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.maxCount,
    required this.barWidth,
    required this.labelChartWidth,
    this.defaultColor = Colors.black,
    this.currentRoundColor = Colors.green,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final chartHeight = size.height;

    for (int i = 0; i < rounds.length; i++) {
      final round = rounds[i];
      final count = counts[i];
      
      if (count == 0) continue;

      // Calculate X position (round number mapped to chart width)
      // Use size.width which is the actual CustomPaint width (should match LineChart width)
      // fl_chart's LineChart uses the widget's full width for coordinate mapping
      final actualWidth = size.width;
      final xRatio = (maxX - minX) > 0 
          ? (round.toDouble() - minX) / (maxX - minX)
          : 0.0; // Handle single round case
      
      // Calculate X position - compress spacing by reducing effective width by 10px per bar
      // This brings bars closer together while keeping bar width the same
      final spacingReduction = 10.0; // Reduce space between bars by 10px
      final compressedWidth = actualWidth - (spacingReduction * (rounds.length - 1));
      
      // Dynamic offset based on number of rounds
      // 40px offset is good for 11 rounds, reduce 5px for each round less than 11
      final baseOffset = 40.0;
      final baseRounds = 11;
      final offsetAdjustment = (baseRounds - rounds.length) * 5.0;
      final dynamicOffset = baseOffset - offsetAdjustment;
      
      // Shift bars to align with points
      final xPos = (xRatio * compressedWidth) + dynamicOffset;

      // Calculate Y position (count mapped to LineChart's coordinate system)
      // Limit bars to 50% of the Y-axis range so they don't stretch the full height
      // The bars should start at the X-axis (bottom of chart) and go up
      // The X-axis is at the bottom of the chart, accounting for bottom title space
      final bottomTitleSpace = 30.0;
      final drawingHeight = chartHeight - bottomTitleSpace;
      final xAxisY = drawingHeight; // X-axis is at the bottom of drawing area
      
      // Scale bars to use only 50% of the Y-axis range
      final barScaleFactor = 0.5; // Bars use 50% of the Y-axis height
      final barMaxY = minY + (barScaleFactor * (maxY - minY)); // Top of bar range
      
      // Map count (0 to maxCount) to scaled Y coordinate (minY to barMaxY)
      final countRatio = maxCount > 0 ? (count.toDouble() / maxCount) : 0.0;
      final yValue = minY + (countRatio * (barMaxY - minY));
      
      // Convert LineChart Y coordinate to pixel position (inverted: minY at bottom, maxY at top)
      final yRatio = (maxY - minY) > 0 
          ? (yValue - minY) / (maxY - minY)
          : 0.0;
      
      // Invert Y: minY at bottom, maxY at top
      // Bar top is calculated from the scaled Y value
      final barTop = (1 - yRatio) * drawingHeight;
      final clampedBarTop = barTop.clamp(0.0, drawingHeight);
      final clampedBarBottom = xAxisY; // Bars end at X-axis (bottom of drawing area)

      // Determine color
      final color = round == currentRound ? currentRoundColor : defaultColor;
      paint.color = color;

      // Draw bar rectangle
      // Clamp X position to ensure bars stay within bounds
      final clampedXPos = xPos.clamp(barWidth / 2, actualWidth - barWidth / 2);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          clampedXPos - barWidth / 2,
          clampedBarTop,
          clampedXPos + barWidth / 2,
          clampedBarBottom,
        ),
        const Radius.circular(2), // Rounded top corners
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(SakimBarPainter oldDelegate) {
    return rounds != oldDelegate.rounds ||
        counts != oldDelegate.counts ||
        currentRound != oldDelegate.currentRound ||
        minX != oldDelegate.minX ||
        maxX != oldDelegate.maxX ||
        minY != oldDelegate.minY ||
        maxY != oldDelegate.maxY ||
        maxCount != oldDelegate.maxCount ||
        labelChartWidth != oldDelegate.labelChartWidth;
  }
}

class SakimCharts extends StatelessWidget {
  final int number;

  //final List<int> rounds = [1, 2, 3, 4, 5,6,7,8,9,10,11,12]; // Rounds
  final List<int> participantCounts = [0, 0, 0, 0, 0, 0,5,3,2,1,1,1]; // Total participants in each round
  final List<int> participantPositions = [4, 3, 2, 2, 1, 1,1 ,1,1,1,1,1]; // Position of a specific participant
  final int currentRound = 12;

  SakimCharts({super.key, required this.number}); // The round where our participant is currently competing

  @override
  Widget build(BuildContext context) {
    final eventController = Get.put(EventController());
    // Filter out round 0 - only show rounds starting from 1
    final allRounds = eventController.currentEvent.value.sakimRounds;
    final List<int> rounds = allRounds.where((r) => r.round > 0).map((r) => r.round).toList();
    final List<int> participantCounts = allRounds.where((r) => r.round > 0).map((r) => r.participantsInRound.length).toList();
    Participant p = eventController.getParticipant(number);
    
    // Get positions for each filtered round
    // For each round, find if participant is in that round and calculate absolute position
    final filteredRoundsList = allRounds.where((r) => r.round > 0).toList();
    final List<int> participantPositions = filteredRoundsList.asMap().entries.map((entry) {
      int filteredIndex = entry.key;
      final round = entry.value;
      
      // Check if participant is currently in this round
      if (round.participantsInRound.contains(number)) {
        // Calculate absolute position: count participants in higher rounds + index in current round
        int participantsAhead = 0;
        for (var r in allRounds) {
          if (r.round > round.round) {
            participantsAhead += r.participantsInRound.length;
          }
        }
        final indexInRound = round.participantsInRound.indexOf(number);
        return participantsAhead + indexInRound + 1; // 1-based absolute position
      }
      
      // If not in this round, check stored positions as fallback
      final allParticipantPositions = p.sakimPositions;
      if (filteredIndex < allParticipantPositions.length) {
        final storedPosition = allParticipantPositions[filteredIndex];
        if (storedPosition > 0) {
          return storedPosition;
        }
      }
      
      return 0; // No position found
    }).toList();
    
    // Find which round the participant is currently in
    int currentRound = -1;
    for (var round in allRounds) {
      if (round.round > 0 && round.participantsInRound.contains(number)) {
        currentRound = round.round;
        break;
      }
    }
    // If not found, default to 0 (will show no green bar)
    if (currentRound == -1) currentRound = 0;
    
    int numberOfParticipants =  eventController.currentEvent.value.getParticipantsByStatus(ParticipantStatus.Active).length;
    bool tablet = isTablet(context);
    // Adjust reserved size for Y-axis based on device type - need more space on mobile
    final leftAxisReservedSize = tablet ? 40.0 : 55.0; // Reduced on mobile to match alonka and make chart wider
    
//int worstPosition = participantPositions.reduce((a, b) => a > b ? a : b);
    return Scaffold(
      body: SafeArea(
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: tablet ? 16.0 : 2.0), // Match alonka padding for maximum space
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Make column fill width
          children: [
            /// 📊 Combined Chart with Bars and Line
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate max count for right Y-axis
                  final maxCount = participantCounts.isNotEmpty 
                      ? participantCounts.reduce((a, b) => a > b ? a : b).toDouble()
                      : numberOfParticipants.toDouble();
                  
                  // Chart dimensions - reduce on mobile to make chart wider
                  final rightAxisReservedSize = tablet ? 60.0 : 35.0; // Reduced on mobile to match alonka
                  final topPadding = 20.0;
                  final bottomPadding = 50.0;
                  
                  // X-axis range - use exact round numbers to match LineChart
                  final minX = rounds.isNotEmpty ? rounds.first.toDouble() : 1.0;
                  final maxX = rounds.isNotEmpty ? rounds.last.toDouble() : 1.0;
                  
                  return Stack(
                      children: [
                        /// Line Chart with Dual Y-Axes
                      Positioned(
                        left: leftAxisReservedSize,
                        right: tablet ? (rightAxisReservedSize + 20) : rightAxisReservedSize, // Remove extra 20px on mobile
                        top: topPadding,
                        bottom: bottomPadding,
                        child: LineChart(
                          LineChartData(
                            minY: 1, // Left Y-axis: position scale
                            maxY: numberOfParticipants.toDouble(),
                            minX: rounds.isNotEmpty ? rounds.first.toDouble() : 1.0, // Use exact round numbers for LineChart
                            maxX: rounds.isNotEmpty ? rounds.last.toDouble() : 1.0,
                      lineBarsData: [
                        LineChartBarData(
                          spots: rounds.asMap().entries
                              .where((entry) {
                            int index = entry.key;
                            int round = entry.value;
                            // Exclude round 0 and include only rounds where participant has a valid position (not 0)
                            return round > 0 && index < participantPositions.length && participantPositions[index] > 0;
                          })
                              .map((entry) {
                            int index = entry.key;
                            int round = entry.value;
                            double position = participantPositions[index].toDouble();
                            // Rounds are already >= 1 after filtering, use round directly
                            return FlSpot(round.toDouble(), numberOfParticipants.toDouble() - position);
                          }).toList(),
                          isCurved: false,  // Ensure straight lines
                          color: Colors.red,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: false),
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              // Find the position for this spot
                              final round = spot.x.toInt();
                              final roundIndex = rounds.indexOf(round);
                              if (roundIndex >= 0 && roundIndex < participantPositions.length) {
                                final position = participantPositions[roundIndex];
                                // Only show label if position is valid and round > 0
                                if (position > 0 && round > 0) {
                                  return SakimLabeledDotPainter(
                                    label: position.toString(),
                                    dotColor: Colors.red,
                                    labelColor: Colors.white,
                                    fontSize: tablet ? 14.0 : 12.0,
                                  );
                                }
                              }
                              // Default dot without label
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.red,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true, // Enable native tooltips
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              // Find the position for this spot
                              final round = touchedSpot.x.toInt();
                              final spotIndex = rounds.indexOf(round);
                              if (spotIndex >= 0 && spotIndex < participantPositions.length) {
                                final position = participantPositions[spotIndex];
                                if (position > 0 && round > 0) {
                                  return LineTooltipItem(
                                    'Round $round\nPosition: $position',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }
                              }
                              return null;
                            }).where((item) => item != null).toList();
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: leftAxisReservedSize,
                            interval: tablet ? 1 : (numberOfParticipants > 10 ? 2 : 1), // Larger interval on mobile if many participants
                            getTitlesWidget: (value, meta) {
                              // Skip 0 and only show integers greater than 0
                              if (value > 0 && value % 1 == 0 && value <= numberOfParticipants.toDouble()) {
                                return Padding(
                                  padding: EdgeInsets.only(right: tablet ? 4.0 : 12.0),
                                  child: Text(
                                    '${(numberOfParticipants - value).toInt()}',
                                    style: TextStyle(fontSize: tablet ? 12 : 10),
                                    textAlign: TextAlign.right,
                                  ),
                                );
                              }
                              return SizedBox.shrink();
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: rightAxisReservedSize,
                            interval: 1, // Will be filtered to show only specific values
                            getTitlesWidget: (value, meta) {
                              // value is in LineChart's coordinate system (1 to numberOfParticipants)
                              // Bars are scaled to 50% of the Y-axis range
                              // Map Y coordinate to count value (0 to maxCount) within the scaled range
                              final chartMinY = 1.0;
                              final chartMaxY = numberOfParticipants.toDouble();
                              final barScaleFactor = 0.5; // Bars use 50% of the Y-axis height
                              final barMaxY = chartMinY + (barScaleFactor * (chartMaxY - chartMinY));
                              
                              // Only show labels within the bar range (minY to barMaxY)
                              if (value >= chartMinY && value <= barMaxY) {
                                final yRatio = (barMaxY - chartMinY) > 0 
                                    ? (value - chartMinY) / (barMaxY - chartMinY)
                                    : 0.0;
                                final countValue = (yRatio * maxCount).round();
                                
                                // Only show labels for specific values: 2, 4, 6, 8, 12
                                final allowedValues = [2, 4, 6, 8, 12];
                                if (allowedValues.contains(countValue)) {
                                  return Padding(
                                    padding: EdgeInsets.only(left: tablet ? 14.0 : 18.0), // Increased by 10px to move labels further right
                                    child: Text(
                                      '$countValue',
                                      style: TextStyle(fontSize: tablet ? 12 : 10, color: Colors.white),
                                      textAlign: TextAlign.left,
                                    ),
                                  );
                                }
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30, // Reserve space for X-axis labels
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              // Exclude round 0 - only show rounds >= 1
                              if (value > 0 && value % 1 == 0 && rounds.isNotEmpty && 
                                  value >= rounds.first.toDouble() && value <= rounds.last.toDouble()) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '${value.toInt()}',
                                    style: TextStyle(color: Colors.white, fontSize: tablet ? 12 : 10),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: true,
                        horizontalInterval: tablet ? 1 : (numberOfParticipants > 10 ? 2 : 1), // Match Y-axis interval
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.3),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.3),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                        ),
                      ),
                      
                      /// Custom Bars Overlay
                      Positioned(
                        left: leftAxisReservedSize,
                        right: tablet ? (rightAxisReservedSize + 20) : rightAxisReservedSize, // Remove extra 20px on mobile
                        top: topPadding,
                        bottom: bottomPadding,
                        child: GestureDetector(
                          onTapDown: (TapDownDetails details) {
                            // Calculate which bar was tapped
                            final tapX = details.localPosition.dx;
                            
                            // Find which bar was tapped
                            for (int i = 0; i < rounds.length; i++) {
                              final round = rounds[i];
                              final count = participantCounts[i];
                              
                              if (count == 0) continue;
                              
                              // Calculate bar position (same logic as SakimBarPainter)
                              final actualWidth = constraints.maxWidth - leftAxisReservedSize - (tablet ? (rightAxisReservedSize + 20) : rightAxisReservedSize);
                              final xRatio = (maxX - minX) > 0 
                                  ? (round.toDouble() - minX) / (maxX - minX)
                                  : 0.0;
                              
                              final spacingReduction = 10.0;
                              final compressedWidth = actualWidth - (spacingReduction * (rounds.length - 1));
                              
                              final baseOffset = 40.0;
                              final baseRounds = 11;
                              final offsetAdjustment = (baseRounds - rounds.length) * 5.0;
                              final dynamicOffset = baseOffset - offsetAdjustment;
                              
                              final barX = (xRatio * compressedWidth) + dynamicOffset;
                              final barWidth = tablet ? 20.0 : 16.0;
                              
                              // Check if tap is within bar bounds
                              if (tapX >= barX - barWidth / 2 && tapX <= barX + barWidth / 2) {
                                // Find the round object to get participant numbers
                                final roundObject = allRounds.firstWhere(
                                  (r) => r.round == round,
                                  orElse: () => allRounds.first,
                                );
                                final participantNumbers = roundObject.participantsInRound;
                                
                                // Calculate positions for each participant
                                final participantsWithPositions = participantNumbers.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final participantNumber = entry.value;
                                  
                                  // Calculate absolute position: count participants in higher rounds + index in current round
                                  int participantsAhead = 0;
                                  for (var r in allRounds) {
                                    if (r.round > round) {
                                      participantsAhead += r.participantsInRound.length;
                                    }
                                  }
                                  final position = participantsAhead + index + 1; // 1-based position
                                  
                                  return MapEntry(participantNumber, position);
                                }).toList();
                                
                                // Show dialog with recruits count and list
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: Text(
                                        'סיבוב $round',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'מספר המסיימים: $count',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'מספרי המסיימים:',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: participantsWithPositions.map((entry) {
                                                  final number = entry.key;
                                                  final position = entry.value;
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: Colors.grey[400]!),
                                                    ),
                                                    child: Text(
                                                      '$number ($position)',
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: Text(
                                            'סגור',
                                            style: TextStyle(color: Colors.blue),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                break;
                              }
                            }
                          },
                          child: CustomPaint(
                            painter: SakimBarPainter(
                              rounds: rounds,
                              counts: participantCounts,
                              currentRound: currentRound,
                              minX: minX,
                              maxX: maxX,
                              minY: 1.0, // Use LineChart's coordinate system
                              maxY: numberOfParticipants.toDouble(), // Use LineChart's coordinate system
                              maxCount: maxCount, // Right axis max for scaling
                              labelChartWidth: constraints.maxWidth - leftAxisReservedSize - (tablet ? (rightAxisReservedSize + 20) : rightAxisReservedSize),
                              barWidth: tablet ? 20.0 : 16.0,
                            ),
                            child: Container(), // Empty container for sizing
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 4), // Match alonka spacing to maximize chart height
            /// 📃 Instructor Comments Section
            p.sakimInstructorComments.isNotEmpty?const Text(
              'הערות המדריך',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ):SizedBox.shrink(),
            Container(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: p.sakimInstructorComments.map((comment) {
                  return Chip(
                    label: Text(comment),
                    backgroundColor: Colors.grey.shade200,
                    labelStyle: TextStyle(color: Colors.black),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}