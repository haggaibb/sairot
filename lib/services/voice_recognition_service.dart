import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class VoiceRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String _lastResult = '';
  String _accumulatedResult = ''; // Track accumulated text for mobile
  bool _disableCleaning = false; // When true, return raw STT output without cleaning
  String _lastPartialResult = ''; // Track last partial result to detect new words only
  
  // Callbacks
  Function(String)? onResult;
  Function(String)? onError;
  Function()? onListeningStarted;
  Function()? onListeningStopped;
  
  /// Disable text cleaning - return raw STT output
  void disableCleaning() {
    _disableCleaning = true;
  }
  
  /// Enable text cleaning (default)
  void enableCleaning() {
    _disableCleaning = false;
  }
  
  /// Check if cleaning is disabled
  bool get isCleaningDisabled => _disableCleaning;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get lastResult => _lastResult;

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    // On web, skip permission request - browser handles it natively
    if (!kIsWeb) {
      // Request microphone permission on mobile
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _isAvailable = false;
        return false;
      }
    }

    // Initialize speech to text
    _isAvailable = await _speech.initialize(
      onError: (error) {
        _isListening = false;
        onError?.call(error.errorMsg);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          onListeningStopped?.call();
        }
      },
    );

    return _isAvailable;
  }

  /// Detect if running on mobile web
  bool _detectMobileWeb() {
    if (!kIsWeb) return false;
    // Simple detection - can be enhanced with User-Agent if needed
    // For now, assume web is mobile if on web platform
    return true;
  }

  /// Extract only new words from partial result (smart accumulation)
  /// This helps avoid the mobile web STT accumulation bug
  String _extractNewWords(String currentResult, String lastResult) {
    if (lastResult.isEmpty) {
      // First partial result - return as is
      return currentResult;
    }
    
    // Find where the last result ends in the current result
    final lastIndex = currentResult.indexOf(lastResult);
    if (lastIndex == -1) {
      // Last result not found - might be completely new text
      // Try to find common prefix
      final currentWords = currentResult.split(' ');
      final lastWords = lastResult.split(' ');
      
      // Find how many words match from the start
      int matchingWords = 0;
      for (int i = 0; i < currentWords.length && i < lastWords.length; i++) {
        if (currentWords[i] == lastWords[i]) {
          matchingWords++;
        } else {
          break;
        }
      }
      
      // Return words after the matching prefix
      if (matchingWords < currentWords.length) {
        return currentWords.sublist(matchingWords).join(' ');
      }
      return '';
    }
    
    // Extract text after the last result
    final newText = currentResult.substring(lastIndex + lastResult.length).trim();
    return newText;
  }

  /// Clean text specifically for mobile web issues
  String _cleanMobileText(String text) {
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
                if (word.substring(start, end) != candidate) {
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
    
    // Remove repeated words/phrases (more aggressive for mobile)
    final words = cleaned.split(' ').where((w) => w.isNotEmpty).toList();
    final cleanedWords = <String>[];
    final seenPhrases = <String>{};
    final seenNumbers = <String>{};
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      
      // Skip if this word was just seen
      if (i > 0 && word == words[i - 1]) {
        continue;
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
      
      cleanedWords.add(word);
    }
    
    final result = cleanedWords.join(' ');
    return result;
  }

  /// Start listening for speech input in Hebrew
  Future<void> startListening() async {
    if (!_isAvailable) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Speech recognition not available');
        return;
      }
    }

    if (_isListening) {
      return;
    }

    _lastResult = '';
    _accumulatedResult = ''; // Reset accumulated result
    _lastPartialResult = ''; // Reset last partial result
    _isListening = true;
    onListeningStarted?.call();

    // Use dictation mode for mobile web, confirmation for desktop
    final isMobileWeb = kIsWeb && _detectMobileWeb();
    final listenMode = isMobileWeb 
        ? stt.ListenMode.dictation 
        : stt.ListenMode.confirmation;

    await _speech.listen(
      onResult: (result) {
        // For mobile web, the speech engine already accumulates text, so we just clean it
        if (isMobileWeb) {
          if (result.finalResult) {
            // When cleaning is disabled (comment dialogs), return raw STT output
            // When cleaning is enabled (floating PTT), apply _cleanMobileText
            final cleanedFinal = _disableCleaning 
                ? result.recognizedWords  // Raw STT for comment dialogs - they'll apply TextCleaningUtil.cleanText
                : _cleanMobileText(result.recognizedWords);  // Full cleaning for floating PTT
            
            // For comment dialogs with raw STT, use accumulated if available (it's also raw)
            if (_disableCleaning && _accumulatedResult.isNotEmpty) {
              // Use accumulated result if it's available (it's raw STT, same as final)
              _lastResult = _accumulatedResult;
            } else {
              _lastResult = cleanedFinal;
            }
            
            _accumulatedResult = '';
            onResult?.call(_lastResult);
            _isListening = false;
            onListeningStopped?.call();
          } else {
            // For partial results, use smart accumulation for mobile web
            // The engine accumulates incorrectly, so we extract only new words
            final rawPartial = result.recognizedWords;
            
            if (_disableCleaning) {
              // For comment dialogs: Use raw STT, extract new words from raw text
              // No cleaning here - TextCleaningUtil.cleanText will be applied in the dialog
              final newWords = _extractNewWords(rawPartial, _lastPartialResult);
              if (newWords.isNotEmpty) {
                _accumulatedResult = _accumulatedResult.isEmpty 
                    ? newWords 
                    : '$_accumulatedResult $newWords';
              }
              _lastPartialResult = rawPartial;
            } else {
              // For floating PTT: Clean and use smart extraction
              final cleaned = _cleanMobileText(rawPartial);
              final newWords = _extractNewWords(cleaned, _lastPartialResult);
              if (newWords.isNotEmpty) {
                _accumulatedResult = _accumulatedResult.isEmpty 
                    ? newWords 
                    : '$_accumulatedResult $newWords';
              }
              _lastPartialResult = cleaned;
            }
          }
        } else {
          // Desktop web behavior - clean text like mobile web to ensure number extraction works
          if (result.finalResult) {
            // Apply cleaning for desktop web too to ensure participant numbers are extractable
            final cleanedFinal = _disableCleaning 
                ? result.recognizedWords  // Raw STT for comment dialogs
                : _cleanMobileText(result.recognizedWords);  // Clean for floating PTT
            
            _lastResult = cleanedFinal;
            onResult?.call(_lastResult);
            _isListening = false;
            onListeningStopped?.call();
          } else {
            // For partial results on desktop, also clean and accumulate like mobile
            final rawPartial = result.recognizedWords;
            
            if (_disableCleaning) {
              // For comment dialogs: Use raw STT, extract new words from raw text
              final newWords = _extractNewWords(rawPartial, _lastPartialResult);
              if (newWords.isNotEmpty) {
                _accumulatedResult = _accumulatedResult.isEmpty 
                    ? newWords 
                    : '$_accumulatedResult $newWords';
              }
              _lastPartialResult = rawPartial;
            } else {
              // For floating PTT: Clean and use smart extraction
              final cleaned = _cleanMobileText(rawPartial);
              final newWords = _extractNewWords(cleaned, _lastPartialResult);
              if (newWords.isNotEmpty) {
                _accumulatedResult = _accumulatedResult.isEmpty 
                    ? newWords 
                    : '$_accumulatedResult $newWords';
              }
              _lastPartialResult = cleaned;
            }
          }
        }
      },
      localeId: 'he-IL', // Hebrew (Israel) locale
      listenOptions: stt.SpeechListenOptions(
        listenMode: listenMode,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  /// Stop listening for speech input
  Future<void> stopListening() async {
    if (!_isListening) {
      return;
    }
    
    final isMobileWeb = kIsWeb && _detectMobileWeb();
    
    // For mobile web, wait a bit for final result before using accumulated
    // The speech engine will send a final result after stop
    await _speech.stop();
    _isListening = false;
    
    // Wait longer for final result to arrive (speech engine may take time)
    if (isMobileWeb) {
      // Check if we have accumulated result first
      if (_accumulatedResult.isNotEmpty && _lastResult.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        // If still no final result, use accumulated (already cleaned or raw based on _disableCleaning)
        if (_lastResult.isEmpty && _accumulatedResult.isNotEmpty) {
          _lastResult = _accumulatedResult;
          onResult?.call(_lastResult);
          _accumulatedResult = '';
        } else if (_lastResult.isEmpty && _accumulatedResult.isEmpty) {
          // No result at all - call onResult with empty string to reset state
          // This will stop the processing indicator
          onResult?.call('');
        }
      } else if (_accumulatedResult.isEmpty && _lastResult.isEmpty) {
        // No accumulated result and no final result - stop processing immediately
        // Wait a short time in case final result is still coming
        await Future.delayed(const Duration(milliseconds: 300));
        if (_lastResult.isEmpty) {
          // No result - call onResult with empty string to stop processing indicator
          onResult?.call('');
        }
      }
    } else if (!isMobileWeb) {
      // For desktop web, if no result was received, call onResult with empty string
      // This ensures the UI resets properly even if no text was recognized
      await Future.delayed(const Duration(milliseconds: 300));
      if (_lastResult.isEmpty) {
        onResult?.call('');
      }
    }
    
    // Always call onListeningStopped to ensure UI state is reset
    // The final result callback might not always fire, especially for empty results
    onListeningStopped?.call();
  }

  /// Cancel current listening session
  Future<void> cancel() async {
    if (!_isListening) {
      return;
    }

    await _speech.cancel();
    _isListening = false;
    _lastResult = '';
    onListeningStopped?.call();
  }

  /// Check if microphone permission is granted
  Future<bool> checkPermission() async {
    if (kIsWeb) {
      // On web, assume permission is available (browser will prompt)
      return true;
    }
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      // On web, assume permission is available (browser will prompt)
      return true;
    }
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Dispose resources
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _isListening = false;
  }
}

