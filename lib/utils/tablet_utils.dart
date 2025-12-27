import 'package:flutter/material.dart';

/// Utility function to detect if the current device is a tablet
/// Uses width > 600px as the threshold (standard Flutter tablet detection)
bool isTablet(BuildContext context) {
  return MediaQuery.of(context).size.width > 600;
}

/// Get scaled font size for tablets
/// Returns fontSize * 1.3 for tablets, fontSize otherwise
double getTabletScaledFontSize(BuildContext context, double fontSize) {
  return isTablet(context) ? fontSize * 1.3 : fontSize;
}












