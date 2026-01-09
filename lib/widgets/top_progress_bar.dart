import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../event_controller.dart';

class TopProgressBar extends StatelessWidget {
  const TopProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final eventController = Get.find<EventController>();
    
    return Obx(() {
      if (!eventController.showProgressBar.value) {
        return const SizedBox.shrink();
      }
      
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    });
  }
}

