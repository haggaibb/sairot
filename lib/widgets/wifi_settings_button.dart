import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/platform_service.dart';

/// Reusable WiFi settings button widget
/// Can be added to AppBar actions or used standalone
class WifiSettingsButton extends StatelessWidget {
  final PlatformService platformService;
  final Color? iconColor;
  final double? iconSize;

  WifiSettingsButton({
    super.key,
    PlatformService? platformService,
    this.iconColor,
    this.iconSize,
  }) : platformService = platformService ?? PlatformService.create();

  @override
  Widget build(BuildContext context) {
    // Only show on mobile (not web)
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: () async {
        if (await platformService.canOpenKioskSettings()) {
          await platformService.openWifiPicker();
        }
      },
      icon: Icon(
        Icons.wifi_find_rounded,
        color: iconColor ?? Colors.grey,
        size: iconSize ?? 30.0,
      ),
      tooltip: 'הגדרות WiFi',
    );
  }
}

