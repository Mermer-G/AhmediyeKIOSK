import 'package:flutter/material.dart';

class AppTheme {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primary = Color(0xFF34495E);
  static const Color primaryDark = Color(0xFF2C3E50);

  static const Color background = Color(0xFFF5F6F8);
  static const Color surface = Colors.white;

  static const Color text = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color border = Color(0xFFE0E3E7);

  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFFD99024);
  static const Color error = Color(0xFFC94C4C);

  // ============================================================
  // SPACING
  // ============================================================

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // ============================================================
  // RADIUS
  // ============================================================

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;

  // ============================================================
  // THEME
  // ============================================================

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,

      // ----------------------------------------------------------
      // GENERAL
      // ----------------------------------------------------------

      scaffoldBackgroundColor: background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: primary,
        onPrimary: Colors.white,

        secondary: primaryDark,
        onSecondary: Colors.white,

        surface: surface,
        onSurface: text,

        error: error,
        onError: Colors.white,
      ),

      // ----------------------------------------------------------
      // APP BAR
      // ----------------------------------------------------------

      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,

        centerTitle: true,

        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),

        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),

      // ----------------------------------------------------------
      // TEXT
      // ----------------------------------------------------------

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: text,
        ),

        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: text,
        ),

        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: text,
        ),

        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: text,
        ),

        bodyLarge: TextStyle(
          fontSize: 16,
          color: text,
        ),

        bodyMedium: TextStyle(
          fontSize: 14,
          color: text,
        ),

        bodySmall: TextStyle(
          fontSize: 12,
          color: textSecondary,
        ),
      ),

      // ----------------------------------------------------------
      // CARDS
      // ----------------------------------------------------------

      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        margin: EdgeInsets.zero,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(
            color: border,
          ),
        ),
      ),

      // ----------------------------------------------------------
      // INPUT FIELDS
      // ----------------------------------------------------------

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: md,
          vertical: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(
            color: border,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(
            color: border,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(
            color: primary,
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(
            color: error,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(
            color: error,
            width: 2,
          ),
        ),

        labelStyle: const TextStyle(
          color: textSecondary,
        ),

        hintStyle: const TextStyle(
          color: textSecondary,
        ),
      ),

      // ----------------------------------------------------------
      // ELEVATED BUTTON
      // ----------------------------------------------------------

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,

          elevation: 0,

          minimumSize: const Size(0, 48),

          padding: const EdgeInsets.symmetric(
            horizontal: lg,
            vertical: md,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),

          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ----------------------------------------------------------
      // OUTLINED BUTTON
      // ----------------------------------------------------------

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,

          minimumSize: const Size(0, 48),

          padding: const EdgeInsets.symmetric(
            horizontal: lg,
            vertical: md,
          ),

          side: const BorderSide(
            color: border,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),

          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ----------------------------------------------------------
      // TEXT BUTTON
      // ----------------------------------------------------------

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,

          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ----------------------------------------------------------
      // ICON
      // ----------------------------------------------------------

      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),

      // ----------------------------------------------------------
      // DIVIDER
      // ----------------------------------------------------------

      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // ----------------------------------------------------------
      // DIALOG
      // ----------------------------------------------------------

      dialogTheme: DialogThemeData(
        backgroundColor: surface,

        elevation: 8,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),

        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: text,
        ),

        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
      ),

      // ----------------------------------------------------------
      // SNACKBAR
      // ----------------------------------------------------------

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,

        backgroundColor: primaryDark,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),

        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }
}