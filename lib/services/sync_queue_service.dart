import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

/// Represents a pending Firestore operation
class SyncOperation {
  final String operationType; // 'saveEvent', 'createEvent', 'updateQualifiedRecruits', 'registerDevice'
  final Map<String, dynamic> data;
  final DateTime timestamp;
  int retryCount;

  SyncOperation({
    required this.operationType,
    required this.data,
    DateTime? timestamp,
    this.retryCount = 0,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'operationType': operationType,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      operationType: json['operationType'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }
}

/// Service for managing sync queue of Firestore operations
class SyncQueueService {
  static SyncQueueService? _instance;
  static SyncQueueService get instance {
    _instance ??= SyncQueueService._();
    return _instance!;
  }

  SyncQueueService._();

  Box<dynamic>? _syncQueueBox;
  static const int maxRetries = 3;

  /// Initialize Hive box for sync queue
  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        _syncQueueBox = await Hive.openBox('sync_queue');
      } else {
        var dir = await getApplicationDocumentsDirectory();
        _syncQueueBox = await Hive.openBox('sync_queue', path: dir.path);
      }
    } catch (e) {
      print('❌ Error initializing SyncQueueService: $e');
    }
  }

  /// Add a Firestore operation to the sync queue
  Future<bool> queueFirestoreOperation(String operationType, Map<String, dynamic> data) async {
    try {
      if (_syncQueueBox == null) await initialize();

      final operation = SyncOperation(
        operationType: operationType,
        data: data,
      );

      // Generate unique key based on timestamp and operation type
      final key = '${operation.timestamp.millisecondsSinceEpoch}_${operation.operationType}';
      
      await _syncQueueBox!.put(key, jsonEncode(operation.toJson()));
      
      print('✅ Operation queued: $operationType (key: $key)');
      return true;
    } catch (e) {
      print('❌ Error queueing operation: $e');
      return false;
    }
  }

  /// Get all pending operations from the queue
  Future<List<SyncOperation>> getPendingOperations() async {
    try {
      if (_syncQueueBox == null) await initialize();

      List<SyncOperation> operations = [];

      for (var key in _syncQueueBox!.keys) {
        try {
          final operationData = _syncQueueBox!.get(key);
          if (operationData != null) {
            final operationJson = jsonDecode(operationData as String) as Map<String, dynamic>;
            operations.add(SyncOperation.fromJson(operationJson));
          }
        } catch (e) {
          print('❌ Error parsing sync operation $key: $e');
          continue;
        }
      }

      // Sort by timestamp (oldest first)
      operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return operations;
    } catch (e) {
      print('❌ Error getting pending operations: $e');
      return [];
    }
  }

  /// Remove a completed operation from the queue
  Future<bool> removeOperation(String key) async {
    try {
      if (_syncQueueBox == null) await initialize();
      await _syncQueueBox!.delete(key);
      return true;
    } catch (e) {
      print('❌ Error removing operation: $e');
      return false;
    }
  }

  /// Increment retry count for a failed operation
  Future<bool> incrementRetryCount(SyncOperation operation) async {
    try {
      if (_syncQueueBox == null) await initialize();

      // Find the operation in the box
      for (var key in _syncQueueBox!.keys) {
        final operationData = _syncQueueBox!.get(key);
        if (operationData != null) {
          final opJson = jsonDecode(operationData as String) as Map<String, dynamic>;
          final op = SyncOperation.fromJson(opJson);
          
          // Match by timestamp and operation type
          if (op.timestamp == operation.timestamp && 
              op.operationType == operation.operationType) {
            op.retryCount++;
            
            // If max retries reached, remove from queue
            if (op.retryCount >= maxRetries) {
              await _syncQueueBox!.delete(key);
              print('⚠️ Operation removed after max retries: ${operation.operationType}');
            } else {
              await _syncQueueBox!.put(key, jsonEncode(op.toJson()));
            }
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print('❌ Error incrementing retry count: $e');
      return false;
    }
  }

  /// Clear all completed operations from the queue
  Future<void> clearSyncQueue() async {
    try {
      if (_syncQueueBox != null) {
        await _syncQueueBox!.clear();
        print('✅ Sync queue cleared');
      }
    } catch (e) {
      print('❌ Error clearing sync queue: $e');
    }
  }

  /// Get count of pending operations
  Future<int> getPendingCount() async {
    try {
      if (_syncQueueBox == null) await initialize();
      return _syncQueueBox!.length;
    } catch (e) {
      print('❌ Error getting pending count: $e');
      return 0;
    }
  }
}










