import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'event_controller.dart';
import 'services/sync_queue_service.dart';
import 'models/event.dart';

class ConnectivityController extends GetxController {
  var isConnected = false.obs; // Tracks internet connectivity
  bool isLiveBackupDone = false; // 🔒 Prevents multiple backups per interval
  Timer? periodicTimer; // Timer for periodic internet checks
  Timer? checkInternetTimer;

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final eventController = Get.put(EventController());

  startConnectionCheckInterval(){
    print("⏲️ Start Connection Interval check...");
    checkInternetTimer = Timer.periodic(Duration(seconds: eventController.systemSettings.checkIntervalSeconds*3), (Timer checkTimer) async {
      await connectionEnabled(); // Check internet connection
      if (isConnected.value && !isLiveBackupDone) {
        print("✅ Internet available");
      } else {
        print("⚠️ No internet or!");
      }
    });

  }

  stopConnectionCheckInterval() {
    checkInternetTimer?.cancel();
    checkInternetTimer = null;
    print("⏹️ Stopped Connection Check Interval.");
  }


  /// 📡 Check for internet connectivity
  Future<void> connectionEnabled() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    // ✅ Check if there is no Wi-Fi or mobile data
    if (connectivityResult == ConnectivityResult.none) {
      print("⚠️ No network available.");
      isConnected.value = false;
      return;
    }

    // On web, skip HTTP check to avoid CORS errors
    // The connectivity_plus check is sufficient for web
    if (kIsWeb) {
      print("🌐 Web platform detected - skipping HTTP check (CORS restrictions).");
      print("✅ Internet connection assumed OK based on connectivity check.");
      final wasConnected = isConnected.value;
      isConnected.value = true;
      
      // If we just gained connection, process sync queue
      if (!wasConnected) {
        print("🔄 Connection restored, processing sync queue...");
        processSyncQueue();
      }
      return;
    }

    // ✅ Check actual internet access using an HTTP request (mobile/desktop only)
    try {
      final response =
      await http.get(Uri.parse("https://www.google.com")).timeout(
        Duration(seconds: 3), // Timeout to avoid long waiting
        onTimeout: () {
          print("⚠️ Internet request timed out.");
          return http.Response('', 500); // Simulate no response
        },
      );

      if (response.statusCode == 200) {
        print("✅ Internet connection OK.");
        final wasConnected = isConnected.value;
        isConnected.value = true;
        
        // If we just gained connection, process sync queue
        if (!wasConnected) {
          print("🔄 Connection restored, processing sync queue...");
          processSyncQueue();
        }
      } else {
        print("⚠️ No real internet access.");
        isConnected.value = false;
      }
    } catch (e) {
      print("❌ Internet check failed: $e");
      isConnected.value = false;
    }
  }

  /// Process sync queue when internet becomes available
  Future<void> processSyncQueue() async {
    if (!isConnected.value) {
      print("⚠️ Cannot process sync queue: no internet connection");
      return;
    }

    try {
      await SyncQueueService.instance.initialize();
      final pendingOperations = await SyncQueueService.instance.getPendingOperations();
      
      if (pendingOperations.isEmpty) {
        print("✅ Sync queue is empty");
        return;
      }

      print("🔄 Processing ${pendingOperations.length} pending operations...");

      for (var operation in pendingOperations) {
        try {
          final key = '${operation.timestamp.millisecondsSinceEpoch}_${operation.operationType}';
          
          switch (operation.operationType) {
            case 'saveEvent':
              final event = Event.fromJson(operation.data);
              final success = await event.saveToFirestore();
              if (success) {
                await SyncQueueService.instance.removeOperation(key);
                print("✅ Synced event: ${event.eventName} - ${event.date}");
              } else {
                await SyncQueueService.instance.incrementRetryCount(operation);
                print("⚠️ Failed to sync event, will retry: ${event.eventName} - ${event.date}");
              }
              break;

            case 'createEvent':
              final event = Event.fromJson(operation.data);
              final success = await event.createFirestoreEvent();
              if (success) {
                await SyncQueueService.instance.removeOperation(key);
                print("✅ Synced event creation: ${event.eventName} - ${event.date}");
              } else {
                await SyncQueueService.instance.incrementRetryCount(operation);
                print("⚠️ Failed to sync event creation, will retry: ${event.eventName} - ${event.date}");
              }
              break;

            case 'updateQualifiedRecruits':
              // This is handled in finalizeEventAndUpdateQualifiedRecruits
              // Queue it separately if needed, or handle in finalization
              print("⚠️ Qualified recruits update should be handled during finalization");
              await SyncQueueService.instance.removeOperation(key);
              break;

            case 'registerDevice':
              // Device registration is non-critical, can skip if queued
              print("ℹ️ Skipping queued device registration (non-critical)");
              await SyncQueueService.instance.removeOperation(key);
              break;

            default:
              print("⚠️ Unknown operation type: ${operation.operationType}");
              await SyncQueueService.instance.removeOperation(key);
          }
        } catch (e) {
          print("❌ Error processing operation ${operation.operationType}: $e");
          await SyncQueueService.instance.incrementRetryCount(operation);
        }
      }

      print("✅ Sync queue processing completed");
    } catch (e) {
      print("❌ Error processing sync queue: $e");
    }
  }


  /// ⏳ Start Live Event Backup Every `X` Minutes
  void startLiveEventUpdating() {
    String eventName = eventController.currentEventName;
    String day = eventController.currentEvent.value.date;
    String instructorId = eventController.currentEvent.value.instructorId;
    // Interval for backup check
    int minutesInterval = eventController.systemSettings.minutesInterval;
    // 🔄 Check internet every 10 seconds
    int checkIntervalSeconds = eventController.systemSettings.checkIntervalSeconds;
    // number of internet checks per interval
    int totalChecks = eventController.systemSettings.totalChecks;
    stopLiveEventUpdating(); // Ensure no duplicate timers
    print("🔄 Starting live event backup check every $minutesInterval minutes...");
    periodicTimer = Timer.periodic(Duration(minutes: minutesInterval), (Timer timer) async {
      isLiveBackupDone = false; // 🔄 Reset backup flag for the new interval
      //totalChecks = (minutesInterval * 60) ~/ checkIntervalSeconds; // Total attempts in interval
      int checkCount = 0;
      checkInternetTimer?.cancel(); // Ensure old timer is canceled before starting new cycle
      checkInternetTimer = Timer.periodic(Duration(seconds: checkIntervalSeconds), (Timer checkTimer) async {
        checkCount++;
        await connectionEnabled(); // Check internet connection
        if (isConnected.value && !isLiveBackupDone) {
          print("✅ Internet available, attempting backup...");
          bool success = await backupHiveToFirebase(eventName, day, instructorId);
          if (success) {
            isLiveBackupDone = true;
            checkInternetTimer?.cancel(); // 🛑 Stop checking once backup is done
            print("📦 Backup completed. Next backup will be attempted in $minutesInterval minutes.");
          }
        } else {
          print("⚠️ No internet or backup already done. Attempt $checkCount of $totalChecks.");
        }

        // Stop checking if we reach max attempts within the interval
        if (checkCount >= totalChecks) {
          print("⏳ Finished checking for this cycle. Waiting for next interval...");
          checkInternetTimer?.cancel();
        }
      });
    });
  }

  /// 🔥 Backup Local Hive File to Firebase
  Future<bool> backupHiveToFirebase(String eventName, String day, String instructorId) async {
    try {
      // On web, Hive backup to Firebase Storage is not supported the same way
      // Web uses IndexedDB which doesn't expose file paths
      if (kIsWeb) {
        print("⚠️ Hive backup to Firebase Storage is not supported on web platform");
        return false;
      }

      // 📂 Get local Hive file path
      final dir = await getApplicationDocumentsDirectory();
      final localFilePath = '${dir.path}/hive/$eventName/$day/$instructorId.hive';
      File hiveFile = File(localFilePath);

      if (!hiveFile.existsSync()) {
        print("❌ Hive box file not found: $localFilePath");
        return false;
      }

      // 🔥 Upload to Firebase Storage (hive/admin/live/$day/instructorId.hive)
      Reference storageRef = _storage.ref('admin/live/$eventName/$day/$instructorId.hive');
      UploadTask uploadTask = storageRef.putFile(hiveFile);
      print("📤 Upload to: ${storageRef.fullPath}");
      // ✅ Listen for Upload Progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print("📤 Upload Progress: ${progress.toStringAsFixed(2)}%");
      });

      // ⏳ Wait for completion
      await uploadTask.whenComplete(() => print("✅ Backup completed for $instructorId on $day"));

      return true; // ✅ Return success
    } catch (e) {
      print("❌ Error backing up Hive: $e");
      return false; // ❌ Return failure
    }
  }

  /// 🛑 Stop periodic live event backup
  void stopLiveEventUpdating() {
    periodicTimer?.cancel();
    periodicTimer = null;
    isLiveBackupDone = false; // 🔄 Reset backup flag
    print("⏹️ Stopped live event updating.");
  }

  /// 🚀 Auto-stop when controller is destroyed
  @override
  void onClose() {
    stopLiveEventUpdating();
    super.onClose();
  }
}