import 'package:flutter/foundation.dart';

/// Simple logging utility for the app
/// In debug mode, logs are printed. In release mode, sensitive logs are suppressed.
class AppLogger {
  /// Log a debug message (only in debug mode)
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  /// Log an info message (only in debug mode)
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  /// Log a warning message (only in debug mode)
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('[WARNING] $message');
    }
  }

  /// Log an error message (always logged, but sanitized in release)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) {
        debugPrint('[ERROR] Exception: $error');
      }
      if (stackTrace != null) {
        debugPrint('[ERROR] StackTrace: $stackTrace');
      }
    } else {
      // In release mode, only log sanitized error messages
      debugPrint('[ERROR] An error occurred');
    }
  }

  /// Log success message (only in debug mode)
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('[SUCCESS] $message');
    }
  }

  /// Log data without sensitive information
  /// Automatically sanitizes IDs, tokens, and other sensitive data
  static void logData(String prefix, Map<String, dynamic> data) {
    if (kDebugMode) {
      final sanitized = _sanitizeData(data);
      debugPrint('[$prefix] $sanitized');
    }
  }

  /// Sanitize data to remove sensitive information
  static Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    final sensitiveKeys = ['id', 'Id', 'ID', 'password', 'Password', 'token', 'Token', 
                          'key', 'Key', 'secret', 'Secret', 'instructorId', 'apiKey'];
    
    for (var key in sensitiveKeys) {
      if (sanitized.containsKey(key)) {
        sanitized[key] = '***REDACTED***';
      }
    }
    
    return sanitized;
  }
}










