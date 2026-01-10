import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:path_provider/path_provider.dart';
import '../event_controller.dart';
import 'package:get/get.dart';

/// Service for OCR processing using ML Kit (offline) with Vertex AI fallback
class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final EventController _eventController = Get.find<EventController>();
  final _vertexAIModel = FirebaseVertexAI.instance.generativeModel(model: 'gemini-2.0-flash-001');

  /// Process image with ML Kit (offline OCR)
  /// Note: ML Kit is not available on web, so this will throw on web platform
  Future<RecognizedText> processImageWithMLKit(Uint8List imageBytes) async {
    // ML Kit doesn't work well on web, skip it
    if (kIsWeb) {
      throw UnsupportedError("ML Kit is not supported on web platform");
    }

    // Save bytes to temporary file and use file-based API (more reliable)
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/ocr_temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    try {
      // Write bytes to temp file
      await tempFile.writeAsBytes(imageBytes);
      
      // Create InputImage from file path
      final InputImage inputImage = InputImage.fromFilePath(tempFile.path);
      
      // Process image
      final result = await _textRecognizer.processImage(inputImage);
      
      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (e) {
        // Ignore cleanup errors
        print("⚠️ Could not delete temp file: $e");
      }
      
      return result;
    } catch (e) {
      // Clean up temp file on error
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
      rethrow;
    }
  }

  /// Process image with Vertex AI (online OCR with structured output)
  Future<String> processImageWithVertexAI(Uint8List imageBytes) async {
    final prompt = TextPart("extract the data into json");
    final imagePart = InlineDataPart('image/jpeg', imageBytes);

    final response = await _vertexAIModel.generateContent(
      generationConfig: GenerationConfig(
        responseMimeType: "application/json",
      ),
      [Content.multi([prompt, imagePart])]
    );

    return response.text ?? '';
  }

  /// Parse ML Kit recognized text into structured participant data
  /// Returns JSON string matching the expected format
  Map<String, dynamic>? parseMLKitText(RecognizedText recognizedText) {
    try {
      String? groupNumber;
      List<Map<String, dynamic>> participants = [];

      // Combine all text blocks into a single string for easier parsing
      String fullText = '';
      List<String> allLines = [];
      
      for (TextBlock block in recognizedText.blocks) {
        fullText += block.text + '\n';
        // Also collect individual lines from each block
        for (TextLine line in block.lines) {
          allLines.add(line.text.trim());
        }
      }

      // Debug: Print recognized text (first 500 chars to avoid spam)
      print("📄 ML Kit recognized text (first 500 chars): ${fullText.length > 500 ? fullText.substring(0, 500) + '...' : fullText}");
      print("📄 Total lines: ${allLines.length}");

      // Extract group number - more flexible patterns
      // First try Hebrew patterns
      final groupPatterns = [
        RegExp(r'מספר\s*קבוצה[:\s]*(\d+)', caseSensitive: false),
        RegExp(r'קבוצה[:\s]*(\d+)', caseSensitive: false),
        RegExp(r'קבוצה\s*(\d+)', caseSensitive: false),
        RegExp(r'(\d+)\s*קבוצה', caseSensitive: false), // Number before "קבוצה"
      ];

      for (var pattern in groupPatterns) {
        final match = pattern.firstMatch(fullText);
        if (match != null) {
          groupNumber = match.group(1);
          print("✅ Found group number: $groupNumber");
          break;
        }
      }
      
      // If not found, look for numbers in the first line (might be garbled OCR)
      if (groupNumber == null && allLines.isNotEmpty) {
        final firstLine = allLines[0];
        // Look for 1-2 digit numbers in the first line (group numbers are usually small)
        final numbers = RegExp(r'\d+').allMatches(firstLine).map((m) => m.group(0)!).toList();
        for (String num in numbers) {
          if (num.length <= 2 && int.tryParse(num) != null) {
            int value = int.parse(num);
            // Group numbers are usually 1-20
            if (value >= 1 && value <= 20) {
              groupNumber = num;
              print("✅ Found group number (from first line): $groupNumber");
              break;
            }
          }
        }
      }

      // More flexible participant extraction
      // Strategy 1: Look for explicit patterns with labels
      for (String line in allLines) {
        if (line.isEmpty) continue;
        
        // Pattern: "מספר רץ: 123" or "רץ: 123" or "רץ 123"
        final recruitPatterns = [
          RegExp(r'מספר\s*רץ[:\s]*(\d+)', caseSensitive: false),
          RegExp(r'רץ[:\s]*(\d+)', caseSensitive: false),
        ];
        
        String? recruitNum;
        for (var pattern in recruitPatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            recruitNum = match.group(1);
            break;
          }
        }
        
        // Pattern: "תעודת זהות: 456789" or "ת.ז: 456789" or "זהות: 456789"
        final idPatterns = [
          RegExp(r'תעודת\s*זהות[:\s]*(\d+)', caseSensitive: false),
          RegExp(r'ת\.?\s*ז[:\s]*(\d+)', caseSensitive: false),
          RegExp(r'זהות[:\s]*(\d+)', caseSensitive: false),
        ];
        
        String? idNum;
        for (var pattern in idPatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            idNum = match.group(1);
            break;
          }
        }
        
        // If we found both in the same line
        if (recruitNum != null && idNum != null) {
          participants.add({
            'מספר רץ': recruitNum,
            'תעודת זהות': idNum,
          });
          print("✅ Found participant: רץ=$recruitNum, ת.ז=$idNum");
          continue;
        }
        
        // If we found recruit number, look for ID in next lines
        if (recruitNum != null && idNum == null) {
          int lineIndex = allLines.indexOf(line);
          // Check next 2 lines for ID
          for (int i = lineIndex + 1; i < allLines.length && i <= lineIndex + 2; i++) {
            for (var pattern in idPatterns) {
              final match = pattern.firstMatch(allLines[i]);
              if (match != null) {
                idNum = match.group(1);
                participants.add({
                  'מספר רץ': recruitNum,
                  'תעודת זהות': idNum,
                });
                print("✅ Found participant (multi-line): רץ=$recruitNum, ת.ז=$idNum");
                break;
              }
            }
            if (idNum != null) break;
          }
        }
      }

      // Strategy 2: Row-based format - Each row has ID (9 digits), Group (1-25, identical), Shirt ID (1-600, unique)
      // Extract ONLY numbers from all lines - clean everything
      List<String> allNumbers = []; // All numbers found, in order
      List<String> idNumbers = []; // 9 digit numbers
      List<String> groupNumbers = []; // 1-25 numbers
      List<String> shirtIds = []; // 1-600 numbers (excluding group number)
      
      // Extract all numbers from all lines, cleaning out all non-numeric characters
      Set<String> processedNumbers = {}; // Track numbers we've already processed to avoid duplicates
      
      for (String line in allLines) {
        // Remove pipe characters first
        String cleaned = line.replaceAll('|', '').trim();
        if (cleaned.isEmpty) continue;
        
        // Skip lines that are mostly non-numeric (garbled text like "nyi27 h90n Y n900")
        // If a line has less than 60% digits and contains letters, skip it
        String digitsOnly = cleaned.replaceAll(RegExp(r'[^\d]'), '');
        String lettersOnly = cleaned.replaceAll(RegExp(r'[^a-zA-Z]'), '');
        if (digitsOnly.length < cleaned.length * 0.6 && lettersOnly.length > 2 && cleaned.length > 5) {
          // Line is mostly non-numeric with significant letters, skip it
          print("⚠️ Skipping garbled line: $cleaned");
          continue;
        }
        
        // Handle concatenated numbers (e.g., "33086339523" = "330863395" + "23")
        // First, try to split concatenated 9-digit IDs followed by group numbers
        // Pattern: 9 digits followed by 1-2 digits (likely group number)
        final concatenatedPattern = RegExp(r'(\d{9})(\d{1,2})');
        final concatenatedMatch = concatenatedPattern.firstMatch(cleaned);
        if (concatenatedMatch != null) {
          String idPart = concatenatedMatch.group(1)!;
          String groupPart = concatenatedMatch.group(2)!;
          int? groupValue = int.tryParse(groupPart);
          
          // If the second part is a valid group number (1-25), split them
          if (groupValue != null && groupValue >= 1 && groupValue <= 25) {
            if (!processedNumbers.contains(idPart)) {
              idNumbers.add(idPart);
              processedNumbers.add(idPart);
              // Add group number but DON'T add to processedNumbers - we want to count all occurrences
              groupNumbers.add(groupPart);
              print("✅ Found concatenated ID+Group: '${concatenatedMatch.group(0)}' -> ID='$idPart', Group='$groupPart'");
              // Remove the concatenated number from the line
              cleaned = cleaned.replaceFirst(concatenatedMatch.group(0)!, ' ');
            }
          }
        }
        
        // First, try to find 9-digit IDs that might be split by spaces
        // Pattern: digits, space, more digits that together form 9 digits
        // Example: "329490 122" should become "329490122"
        String lineForIdExtraction = cleaned.replaceAll(RegExp(r'[^\d\s]'), ' '); // Keep only digits and spaces
        lineForIdExtraction = lineForIdExtraction.replaceAll(RegExp(r'\s+'), ' '); // Normalize spaces
        
        // Try to find split 9-digit IDs (e.g., "329490 122" -> "329490122")
        // Look for patterns where digits + space + digits = 9 total digits
        final splitIdPattern = RegExp(r'(\d{6,8})\s+(\d{1,3})');
        final splitIdMatch = splitIdPattern.firstMatch(lineForIdExtraction);
        
        if (splitIdMatch != null) {
          String part1 = splitIdMatch.group(1)!;
          String part2 = splitIdMatch.group(2)!;
          String combined = part1 + part2;
          
          // If combined is exactly 9 digits, it's likely a split ID
          if (combined.length == 9 && !processedNumbers.contains(combined)) {
            idNumbers.add(combined);
            processedNumbers.add(combined);
            processedNumbers.add(part1); // Mark parts as processed so we don't count them separately
            processedNumbers.add(part2);
            print("✅ Found split ID: '$part1 $part2' -> '$combined'");
            // Remove this from the line so we don't process the parts separately
            cleaned = cleaned.replaceAll('$part1 $part2', ' ').replaceAll('$part1$part2', ' ');
          }
        }
        
        // Extract ALL numbers from the cleaned line (removes pipes, letters, etc.)
        final numbers = RegExp(r'\d+').allMatches(cleaned).map((m) => m.group(0)!).toList();
        
        for (String num in numbers) {
          int? numValue = int.tryParse(num);
          if (numValue == null) continue;
          
          // Categorize by type
          if (num.length == 9) {
            // ID number (exactly 9 digits) - skip if already processed (avoid duplicates)
            if (processedNumbers.contains(num)) continue;
            idNumbers.add(num);
            processedNumbers.add(num);
            allNumbers.add(num);
          } else if (numValue >= 1 && numValue <= 25) {
            // Group number (1-25) - ADD EVERY TIME (we want to count occurrences)
            // Don't skip duplicates - the group number should appear once per row
            groupNumbers.add(num);
            allNumbers.add(num);
            // Also add to shirtIds if not already processed (numbers 1-25 can be both group numbers AND shirt IDs)
            // The group number will be filtered out later, but other 1-25 numbers should be kept as shirt IDs
            if (!processedNumbers.contains(num)) {
              shirtIds.add(num);
              processedNumbers.add(num); // Mark as processed for shirtIds to avoid duplicates
            }
            // Don't add group number to processedNumbers for group counting - we want to count all occurrences
          } else if (numValue >= 1 && numValue <= 600) {
            // Shirt ID (1-600) - skip if already processed (avoid duplicates)
            if (processedNumbers.contains(num)) continue;
            shirtIds.add(num);
            processedNumbers.add(num);
            allNumbers.add(num);
          }
        }
      }
      
      // Remove duplicate IDs (in case we found both split and non-split versions)
      idNumbers = idNumbers.toSet().toList();
      
      print("📊 Extracted ${allNumbers.length} total numbers");
      print("📊 Found ${idNumbers.length} IDs, ${groupNumbers.length} group numbers, ${shirtIds.length} shirt IDs");
      
      // Determine group number (should be identical for all rows, so find most frequent 1-25 number)
      if (groupNumbers.isNotEmpty) {
        Map<String, int> groupCounts = {};
        for (String g in groupNumbers) {
          groupCounts[g] = (groupCounts[g] ?? 0) + 1;
        }
        
        if (groupCounts.isNotEmpty) {
          String mostCommonGroup = groupCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
          groupNumber = mostCommonGroup;
          print("✅ Determined group number: $groupNumber (appeared ${groupCounts[mostCommonGroup]} times)");
        }
      }
      
      // Filter out group number from shirt IDs
      List<String> filteredShirtIds = shirtIds
          .where((num) => num != groupNumber)
          .toList();
      
      print("📊 Shirt IDs before filtering: ${shirtIds.length} (${shirtIds.join(', ')})");
      print("📊 After filtering group number '$groupNumber': ${filteredShirtIds.length} shirt IDs (${filteredShirtIds.join(', ')})");
      
      // Get unique shirt IDs (remove duplicates, keep order)
      List<String> uniqueShirtIds = [];
      Set<String> seenShirts = {};
      for (String shirtId in filteredShirtIds) {
        if (!seenShirts.contains(shirtId)) {
          uniqueShirtIds.add(shirtId);
          seenShirts.add(shirtId);
        }
      }
      
      print("📊 Unique shirt IDs: ${uniqueShirtIds.length}");
      
      // CRITICAL: We need exactly as many IDs, group numbers, and shirt IDs
      // Each row has: ID, Group (same for all), Shirt ID
      int expectedRows = idNumbers.length;
      
      print("📊 Expected rows: $expectedRows");
      print("📊 Group numbers found: ${groupNumbers.length} (should be $expectedRows, all identical: $groupNumber)");
      print("📊 Shirt IDs found: ${uniqueShirtIds.length} (should be $expectedRows)");
      
      // SAFEGUARD: If number of IDs doesn't match number of unique shirt IDs, parsing failed
      if (idNumbers.length != uniqueShirtIds.length) {
        print("❌ Parsing failed: Mismatch between IDs (${idNumbers.length}) and shirt IDs (${uniqueShirtIds.length})");
        print("⚠️ Each ID must have a unique shirt ID - parsing is incomplete or incorrect");
        return null;
      }
      
      // Match by position: row 1 = ID[0], Group[0], ShirtID[0], etc.
      if (uniqueShirtIds.length >= expectedRows && expectedRows > 0) {
        // Take exactly as many shirt IDs as we have IDs
        List<String> matchedShirtIds = uniqueShirtIds.take(expectedRows).toList();
        
        print("✅ Matching $expectedRows IDs with ${matchedShirtIds.length} shirt IDs");
        
        for (int i = 0; i < expectedRows; i++) {
          final idNum = idNumbers[i];
          final shirtId = matchedShirtIds[i];
          
          participants.add({
            'מספר רץ': shirtId,
            'תעודת זהות': idNum,
          });
          print("✅ Found participant (row ${i + 1}): רץ=$shirtId, ת.ז=$idNum, קבוצה=$groupNumber");
        }
      } else {
        print("❌ Cannot match: Need $expectedRows rows but found ${uniqueShirtIds.length} shirt IDs");
        if (uniqueShirtIds.length < expectedRows) {
          print("⚠️ Missing ${expectedRows - uniqueShirtIds.length} shirt IDs");
        }
      }
      
      // Strategy 2b: Table format - lines with just numbers (recruit number, ID on same line)
      // Look for lines that contain only numbers (2-3 numbers per line)
      for (String line in allLines) {
        line = line.trim();
        if (line.isEmpty) continue;
        
        // Skip lines with Hebrew text (already processed above)
        if (line.contains(RegExp(r'[א-ת]'))) continue;
        
        // Extract all numbers from line
        final numbers = RegExp(r'\d+').allMatches(line).map((m) => m.group(0)!).toList();
        
        // If line has 2-3 numbers and no Hebrew, assume it's a data row
        // First number is usually recruit number, second is ID
        if (numbers.length >= 2 && numbers.length <= 3) {
          // Validate: recruit numbers are usually 1-3 digits, IDs are usually 6-9 digits
          final recruitNum = numbers[0];
          final idNum = numbers[1];
          
          // Basic validation: ID should be longer than recruit number
          if (idNum.length >= recruitNum.length && idNum.length >= 6) {
            // Check if we already have this recruit number
            bool exists = participants.any((p) => p['מספר רץ'] == recruitNum);
            if (!exists) {
              participants.add({
                'מספר רץ': recruitNum,
                'תעודת זהות': idNum,
              });
              print("✅ Found participant (table format): רץ=$recruitNum, ת.ז=$idNum");
            }
          }
        }
      }

      // Strategy 3: Look for pairs of numbers in blocks (more flexible)
      for (TextBlock block in recognizedText.blocks) {
        String blockText = block.text;
        
        // Extract all numbers from block
        final numbers = RegExp(r'\d+').allMatches(blockText).map((m) => m.group(0)!).toList();
        
        // If block has multiple numbers and contains relevant keywords
        if (numbers.length >= 2 && 
            (blockText.contains(RegExp(r'[רץ|זהות|מספר|ת\.?ז]', caseSensitive: false)))) {
          // Try to pair numbers: assume first is recruit, second is ID
          for (int i = 0; i < numbers.length - 1; i++) {
            final recruitNum = numbers[i];
            final idNum = numbers[i + 1];
            
            // Basic validation
            if (idNum.length >= recruitNum.length) {
              bool exists = participants.any((p) => p['מספר רץ'] == recruitNum);
              if (!exists) {
                participants.add({
                  'מספר רץ': recruitNum,
                  'תעודת זהות': idNum,
                });
                print("✅ Found participant (block format): רץ=$recruitNum, ת.ז=$idNum");
              }
            }
          }
        }
      }

      // Remove duplicates based on recruit number
      final uniqueParticipants = <String, Map<String, dynamic>>{};
      for (var participant in participants) {
        final recruitNumber = participant['מספר רץ'] as String;
        if (!uniqueParticipants.containsKey(recruitNumber)) {
          uniqueParticipants[recruitNumber] = participant;
        }
      }
      participants = uniqueParticipants.values.toList();

      print("📊 Parsed ${participants.length} participants");

      // If we found participants, create the result
      if (participants.isNotEmpty) {
        // Add group number to first participant if found
        if (groupNumber != null && participants.isNotEmpty) {
          participants[0]['מספר קבוצה'] = groupNumber;
        }

        return {
          'success': true,
          'data': participants,
          'groupNumber': groupNumber,
        };
      }

      print("⚠️ No participants found in recognized text");
      return null;
    } catch (e) {
      print("❌ Error parsing ML Kit text: $e");
      return null;
    }
  }

  /// Main method: Process image with ML Kit first, fallback to Vertex AI if needed
  /// Returns result with 'method' field indicating 'mlkit' or 'vertexai'
  Future<Map<String, dynamic>?> processImage(Uint8List imageBytes) async {
    // On web, skip ML Kit and use Vertex AI directly (web always has internet)
    if (kIsWeb) {
      print("🌐 Web platform detected - using Vertex AI directly...");
      if (_eventController.isConnected.value) {
        try {
          final vertexAIResponse = await processImageWithVertexAI(imageBytes);
          String cleanedResponse = vertexAIResponse;
          if (cleanedResponse.startsWith("```json")) {
            cleanedResponse = cleanedResponse.replaceFirst("```json", "").trim();
          }
          if (cleanedResponse.endsWith("```")) {
            cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3).trim();
          }

          final jsonData = jsonDecode(cleanedResponse) as List;
          if (jsonData.isNotEmpty) {
            print("✅ Vertex AI OCR successful (web)");
            return {
              'success': true,
              'data': jsonData,
              'groupNumber': jsonData[0]['מספר קבוצה']?.toString(),
              'method': 'vertexai',
            };
          }
        } catch (e) {
          print("❌ Vertex AI failed on web: $e");
        }
      }
      return null;
    }

    // On mobile: Try ML Kit first, fallback to Vertex AI
    try {
      // Step 1: Try ML Kit (offline)
      print("📱 Attempting ML Kit OCR (offline)...");
      final recognizedText = await processImageWithMLKit(imageBytes);
      
      // Step 2: Parse ML Kit output
      final parsedData = parseMLKitText(recognizedText);
      
      // Step 3: Check if parsing was successful
      if (parsedData != null && 
          parsedData['success'] == true && 
          (parsedData['data'] as List).isNotEmpty) {
        print("✅ ML Kit OCR successful");
        return {
          ...parsedData,
          'method': 'mlkit',
        };
      }

      // Step 4: Fallback to Vertex AI if online
      if (_eventController.isConnected.value) {
        print("⚠️ ML Kit parsing failed or insufficient data, falling back to Vertex AI...");
        try {
          final vertexAIResponse = await processImageWithVertexAI(imageBytes);
          
          // Parse Vertex AI JSON response
          String cleanedResponse = vertexAIResponse;
          if (cleanedResponse.startsWith("```json")) {
            cleanedResponse = cleanedResponse.replaceFirst("```json", "").trim();
          }
          if (cleanedResponse.endsWith("```")) {
            cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3).trim();
          }

          final jsonData = jsonDecode(cleanedResponse) as List;
          if (jsonData.isNotEmpty) {
            print("✅ Vertex AI OCR successful");
            return {
              'success': true,
              'data': jsonData,
              'groupNumber': jsonData[0]['מספר קבוצה']?.toString(),
              'method': 'vertexai',
            };
          }
        } catch (e) {
          print("❌ Vertex AI fallback failed: $e");
        }
      } else {
        print("⚠️ ML Kit parsing failed and device is offline - cannot use Vertex AI fallback");
      }

      return {
        'success': false,
        'method': 'mlkit',
        'error': 'ML Kit parsing failed',
      };
    } catch (e) {
      print("❌ Error in OCR processing: $e");
      
      // If ML Kit failed and we're online, try Vertex AI
      if (_eventController.isConnected.value) {
        print("⚠️ ML Kit failed, trying Vertex AI fallback...");
        try {
          final vertexAIResponse = await processImageWithVertexAI(imageBytes);
          String cleanedResponse = vertexAIResponse;
          if (cleanedResponse.startsWith("```json")) {
            cleanedResponse = cleanedResponse.replaceFirst("```json", "").trim();
          }
          if (cleanedResponse.endsWith("```")) {
            cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3).trim();
          }

          final jsonData = jsonDecode(cleanedResponse) as List;
          if (jsonData.isNotEmpty) {
            print("✅ Vertex AI OCR successful (after ML Kit error)");
            return {
              'success': true,
              'data': jsonData,
              'groupNumber': jsonData[0]['מספר קבוצה']?.toString(),
              'method': 'vertexai',
            };
          }
        } catch (e2) {
          print("❌ Vertex AI also failed: $e2");
        }
      }
      
      return {
        'success': false,
        'method': 'mlkit',
        'error': e.toString(),
      };
    }
  }
  
  /// Process image with Vertex AI only (for retry)
  Future<Map<String, dynamic>?> processImageWithVertexAIOnly(Uint8List imageBytes) async {
    if (!_eventController.isConnected.value) {
      return {
        'success': false,
        'method': 'vertexai',
        'error': 'No internet connection',
      };
    }
    
    try {
      final vertexAIResponse = await processImageWithVertexAI(imageBytes);
      String cleanedResponse = vertexAIResponse;
      if (cleanedResponse.startsWith("```json")) {
        cleanedResponse = cleanedResponse.replaceFirst("```json", "").trim();
      }
      if (cleanedResponse.endsWith("```")) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3).trim();
      }

      final jsonData = jsonDecode(cleanedResponse) as List;
      if (jsonData.isNotEmpty) {
        print("✅ Vertex AI OCR successful (retry)");
        return {
          'success': true,
          'data': jsonData,
          'groupNumber': jsonData[0]['מספר קבוצה']?.toString(),
          'method': 'vertexai',
        };
      }
    } catch (e) {
      print("❌ Vertex AI retry failed: $e");
      return {
        'success': false,
        'method': 'vertexai',
        'error': e.toString(),
      };
    }
    
    return {
      'success': false,
      'method': 'vertexai',
      'error': 'No data extracted',
    };
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
