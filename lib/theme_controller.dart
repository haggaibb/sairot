import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'color_schemes.g.dart'; // Your existing color schemes

class ThemeController extends GetxController {
  var isDarkMode = true.obs;
  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        scaffoldBackgroundColor: Color(0xFFD0F9FF),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(lightColorScheme.primary),
            foregroundColor:
                WidgetStateProperty.all(lightColorScheme.onPrimary),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.onPrimaryContainer,
          foregroundColor: lightColorScheme.onPrimary,
          elevation: 4,
          shadowColor: Colors.black.withAlpha(51)
        ) // 20% opacity
      );

  ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (states) {
              if (states.contains(WidgetState.pressed)) {
                return darkColorScheme.primaryContainer; // Pressed state
              }
              if (states.contains(WidgetState.disabled)) {
                return darkColorScheme.surfaceContainer; // Disabled state
              }
              return darkColorScheme.primary; // Default state
            },
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (states) {
              if (states.contains(WidgetState.disabled)) {
                return darkColorScheme.onSurface.withAlpha(38);
              }
              return darkColorScheme.onPrimary; // Default text/icon color
            },
          ),
          shadowColor: WidgetStateProperty.all(Colors.black..withAlpha(51)),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevation: WidgetStateProperty.all(6),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.surfaceContainerHighest,
        foregroundColor: darkColorScheme.onSurfaceVariant,
        elevation: 4,
        //shadowColor: Colors.black
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor:
              WidgetStateProperty.all(darkColorScheme.surfaceContainer),
          shadowColor:
              WidgetStateProperty.all(Colors.black.withValues(alpha: 128.0)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textStyle: TextStyle(color: darkColorScheme.onSurface),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkColorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkColorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkColorScheme.primary),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ));

  void toggleTheme(bool isDark) {
    isDarkMode.value = isDark;
    Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
