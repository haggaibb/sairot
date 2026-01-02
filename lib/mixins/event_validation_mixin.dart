import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../event_controller.dart';

/// Mixin to validate that event is properly loaded (groupNumber != 0)
/// Redirects to home page if event is invalid (e.g., on web refresh)
mixin EventValidationMixin<T extends StatefulWidget> on State<T> {
  /// Check if group number is 0 (invalid) and redirect to home if needed
  void checkEventValidity() {
    final eventController = Get.put(EventController());
    // Use a post-frame callback to ensure the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait a bit to allow any async loading to complete, then check
      Future.delayed(Duration(milliseconds: 100), () {
        if (!mounted) return;
        // Check if group number is 0 (invalid) - this happens on web refresh when event isn't loaded
        if (eventController.currentEvent.value.groupNumber == 0) {
          // Group number is 0, which means the event wasn't loaded properly
          // Redirect to home page to reload the event
          Get.offAllNamed('/home');
        }
      });
    });
  }
}

