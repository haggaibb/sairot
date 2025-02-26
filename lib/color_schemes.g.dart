import 'package:flutter/material.dart';

/// 🌞 Light Theme - Hi-Tech Style
const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF007AFF), // Vibrant neon blue
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE0F2FF),
  onPrimaryContainer: Color(0xFF00274D),
  secondary: Color(0xFF00D1FF), // Aqua blue
  onSecondary: Color(0xFF002639),
  secondaryContainer: Color(0xFFB3EFFF),
  onSecondaryContainer: Color(0xFF002639),
  tertiary: Color(0xFF00E676), // Neon green
  onTertiary: Color(0xFF003312),
  tertiaryContainer: Color(0xFFC8FFD4),
  onTertiaryContainer: Color(0xFF002110),
  error: Color(0xFFFF1744),
  errorContainer: Color(0xFFFFD7D7),
  onError: Color(0xFF410002),
  onErrorContainer: Color(0xFFFFF5F5),
  surface: Color(0xFFF9FBFF), // Replaces background
  onSurface: Color(0xFF202124), // Replaces onBackground
  surfaceContainerHighest: Color(0xFFE3F2FD),
  surfaceContainerHigh: Color(0xFFDCEEFF),
  surfaceContainer: Color(0xFFCDE7FF),
  surfaceContainerLow: Color(0xFFB0D5FF),
  surfaceContainerLowest: Color(0xFFE6F4FF),
  onSurfaceVariant: Color(0xFF616161),
  outline: Color(0xFF90CAF9),
  outlineVariant: Color(0xFFB3E5FC),
  onInverseSurface: Color(0xFFE0F7FA),
  inverseSurface: Color(0xFF303030),
  inversePrimary: Color(0xFF80D8FF),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFF007AFF),
);

/// 🌙 Dark Theme - Cyberpunk Style
const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF00E5FF),
  onPrimary: Colors.black, // Improved contrast
  primaryContainer: Color(0xFF004F5D),
  onPrimaryContainer: Color(0xFFB3F8FF),
  secondary: Color(0xFF00FF9D),
  onSecondary: Color(0xFF003A29),
  secondaryContainer: Color(0xFF007A5C),
  onSecondaryContainer: Color(0xFFCFFFE0),
  tertiary: Color(0xFFFF4081),
  onTertiary: Color(0xFF52002D),
  tertiaryContainer: Color(0xFF8E004D),
  onTertiaryContainer: Color(0xFFFFE0F2),
  error: Color(0xFFFF5252),
  errorContainer: Color(0xFF7F0000),
  onError: Color(0xFFFFE0E0),
  onErrorContainer: Color(0xFF410002),

  // Background and Surface
  surface: Color(0xFF1A1A2E), // Deep navy for modern look
  onSurface: Color(0xFFE0E0E0), // Bright text for contrast
  surfaceContainerHighest: Color(0xFF22243D),
  surfaceContainerHigh: Color(0xFF292B48),
  surfaceContainer: Color(0xFF30324F),
  surfaceContainerLow: Color(0xFF3B3D5C),
  surfaceContainerLowest: Color(0xFF4A4C6E),

  // Surface Variant and Outline
  onSurfaceVariant: Color(0xFFB0BEC5),
  outline: Color(0xFF64FFDA),
  outlineVariant: Color(0xFF00E5FF),

  // Inverse Colors
  onInverseSurface: Color(0xFF121212),
  inverseSurface: Color(0xFF90CAF9),
  inversePrimary: Color(0xFF00E5FF),

  // Misc
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFF00E5FF),
);