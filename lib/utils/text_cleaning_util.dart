/// Utility class for cleaning speech-to-text output
/// Removes duplicates, normalizes text, and handles mobile web STT issues
class TextCleaningUtil {
  /// Clean text by removing duplicate words/phrases and normalizing
  static String cleanText(String text) {
    if (text.trim().isEmpty) {
      return '';
    }
    
    // Remove extra whitespace
    var cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // First, separate numbers from words (e.g., "בדיקה358" -> "בדיקה 358")
    cleaned = cleaned.replaceAllMapped(RegExp(r'([א-ת]+)(\d+)'), (match) {
      final word = match.group(1)!;
      final number = match.group(2)!;
      return '$word $number';
    });
    // Also handle number+word (e.g., "358בדיקה" -> "358 בדיקה")
    cleaned = cleaned.replaceAllMapped(RegExp(r'(\d+)([א-ת]+)'), (match) {
      final number = match.group(1)!;
      final word = match.group(2)!;
      return '$number $word';
    });
    
    // Handle repeated numbers (e.g., "358358358358" -> "358")
    // Find the smallest repeating unit by trying different lengths
    cleaned = cleaned.replaceAllMapped(RegExp(r'(\d{2,})(\1)+'), (match) {
      final firstGroup = match.group(1)!;
      
      // Try to find the smallest repeating unit
      String smallestUnit = firstGroup;
      for (int len = 1; len <= firstGroup.length ~/ 2; len++) {
        final candidate = firstGroup.substring(0, len);
        if (firstGroup.length % len == 0) {
          // Check if the entire group is made of this unit
          bool isRepeating = true;
          for (int i = 0; i < firstGroup.length; i += len) {
            if (firstGroup.substring(i, i + len) != candidate) {
              isRepeating = false;
              break;
            }
          }
          if (isRepeating) {
            smallestUnit = candidate;
            break;
          }
        }
      }
      
      return smallestUnit;
    });
    
    // Handle concatenated repeated words (e.g., "אוליאוליאולי" -> "אולי")
    // Also handle concatenated different words (e.g., "הקלטהזוהי" -> "הקלטה זוהי")
    // Process multiple passes to handle nested concatenations
    String previousCleaned = '';
    int passCount = 0;
    while (previousCleaned != cleaned && passCount < 3) {
      previousCleaned = cleaned;
      passCount++;
      final wordsBeforeSplit = cleaned.split(' ');
      final processedWords = <String>[];
      for (final word in wordsBeforeSplit) {
        if (word.isEmpty) continue;
        
        // Check if this word is a concatenated repetition (Hebrew words only)
        if (RegExp(r'^[א-ת]+$').hasMatch(word) && word.length >= 4) {
          // Try to find if this is a repeated pattern
          // Start from the smallest possible unit and work up to find the smallest repeating unit
          String? repeatedUnit;
          for (int len = 2; len <= word.length ~/ 2; len++) {
            final candidate = word.substring(0, len);
            // Check if the word is made of repetitions of this candidate
            if (word.length % len == 0) {
              int repetitions = word.length ~/ len;
              bool isRepeating = true;
              for (int i = 0; i < repetitions; i++) {
                final start = i * len;
                final end = start + len;
                final segment = word.substring(start, end);
                if (segment != candidate) {
                  isRepeating = false;
                  break;
                }
              }
              if (isRepeating) {
                repeatedUnit = candidate;
                break; // Found smallest repeating unit, stop searching
              }
            }
          }
          if (repeatedUnit != null) {
            processedWords.add(repeatedUnit);
          } else {
            // Not an exact repetition - try to detect if it's two different words concatenated
            bool wasSplit = false;
            if (word.length >= 6) {
              final maxSplitPos = word.length - 3;
              if (maxSplitPos >= 3) {
                for (int splitPos = maxSplitPos; splitPos >= 3; splitPos--) {
                  final firstPart = word.substring(0, splitPos);
                  final secondPart = word.substring(splitPos);
                  if (firstPart.length >= 3 && secondPart.length >= 3) {
                    if (!secondPart.startsWith(firstPart[firstPart.length - 1])) {
                      if (word.length >= 8 || (firstPart.length <= 6 && secondPart.length <= 6)) {
                        processedWords.add('$firstPart $secondPart');
                        wasSplit = true;
                        break;
                      }
                    }
                  }
                }
              }
            }
            if (!wasSplit) {
              processedWords.add(word);
            }
          }
        } else {
          processedWords.add(word);
        }
      }
      cleaned = processedWords.join(' ');
    }
    
    // More aggressive cleaning for mobile web issues
    // Remove repeated words/phrases (common in speech recognition errors)
    final words = cleaned.split(' ').where((w) => w.isNotEmpty).toList();
    final cleanedWords = <String>[];
    final seenWords = <String>{};
    final seenPhrases = <String>{};
    final seenNumbers = <String>{};
    String? lastWord;
    int consecutiveCount = 0;
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      
      // Skip if same word appears consecutively more than once
      if (word == lastWord) {
        consecutiveCount++;
        if (consecutiveCount > 1) {
          continue; // Skip this duplicate
        }
      } else {
        consecutiveCount = 0;
        lastWord = word;
      }
      
      // If it's a number, only keep the first occurrence
      if (RegExp(r'^\d+$').hasMatch(word)) {
        if (seenNumbers.contains(word)) {
          continue;
        }
        seenNumbers.add(word);
      }
      
      // Check for repeated 2-word phrases
      if (i >= 1) {
        final phrase = '${words[i-1]} $word';
        if (seenPhrases.contains(phrase)) {
          continue;
        }
        seenPhrases.add(phrase);
      }
      
      // Also check for non-consecutive duplicates of common command words
      final lowerWord = word.toLowerCase();
      if (lowerWord == 'הערה' || lowerWord == 'הוסף' || lowerWord == 'comment' || lowerWord == 'add') {
        if (seenWords.contains(lowerWord) && cleanedWords.length > 0) {
          // Skip if we've seen this command word before and it's not the first word
          continue;
        }
        seenWords.add(lowerWord);
      }
      
      cleanedWords.add(word);
    }
    
    final result = cleanedWords.join(' ');
    return result;
  }
}











