import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// XpenseDesk Design System
/// Professional, calm, trustworthy finance SaaS aesthetic
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Color Palette (from HSL spec converted to Flutter Color)
  static const Color background = Color(0xFFF7F7FC); // 240 20% 98%
  static const Color foreground = Color(0xFF1F1B36); // 250 30% 15%
  static const Color card = Color(0xFFFFFFFF); // Pure white
  static const Color cardForeground = Color(0xFF1F1B36);
  static const Color primary = Color(0xFF362B71); // Deep navy-purple
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFF2F1F7); // 250 15% 95%
  static const Color mutedForeground = Color(0xFF6B6580); // 250 10% 45%
  static const Color border = Color(0xFFEEEEEE); // Very light gray for subtle borders
  static const Color destructive = Color(0xFFE63E7A); // 330 81% 60% - Pink-red
  static const Color accent = Color(0xFF9B7FA9); // 280 35% 55% - Pending badge
  static const Color success = Color(0xFF16A34A); // green-600 - Enable action
  static const Color primaryTint = Color(0xFFEBE8F2); // primary/10% - Avatar backgrounds

  // Spacing Constants
  static const double borderRadius = 12.0;
  static const double cardMaxWidth = 384.0; // 24rem
  static const double containerMaxWidth = 1280.0; // max-w-5xl

  // Theme Data
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.assistantTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.assistant().fontFamily,
      scaffoldBackgroundColor: background,
      
      colorScheme: const ColorScheme.light(
        surface: background,
        onSurface: foreground,
        primary: primary,
        onPrimary: primaryForeground,
        secondary: muted,
        onSecondary: mutedForeground,
        error: destructive,
        onError: primaryForeground,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: card,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: destructive, width: 2),
        ),
        hintStyle: TextStyle(color: mutedForeground),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          disabledBackgroundColor: muted,
          disabledForegroundColor: mutedForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: GoogleFonts.assistant(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text Button Theme (for links)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.assistant(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Filled Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          disabledBackgroundColor: muted,
          disabledForegroundColor: mutedForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          minimumSize: const Size(0, 50),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Remove extra padding
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          textStyle: GoogleFonts.assistant(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text Theme
      textTheme: textTheme.copyWith(
        headlineLarge: GoogleFonts.assistant(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        headlineMedium: GoogleFonts.assistant(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        titleLarge: GoogleFonts.assistant(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        bodyLarge: GoogleFonts.assistant(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: foreground,
        ),
        bodyMedium: GoogleFonts.assistant(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: mutedForeground,
        ),
      ),
    );
  }
}
