import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF0B0D14);
  static const surface = Color(0xFF161929);
  static const card = Color(0xFF1C1F2E);
  static const primary = Color(0xFF8B5CF6);
  static const primaryDark = Color(0xFF6D28D9);
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);
  static const blue = Color(0xFF3B82F6);
  static const orange = Color(0xFFF97316);
  static const red = Color(0xFFEF4444);
  static const teal = Color(0xFF06B6D4);
  static const pink = Color(0xFFEC4899);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF6B7280);
  static const divider = Color(0xFF1F2333);
  static const border = Color(0xFF2D3148);

  static const tagMap = {
    'Work': blue,
    'Personal': orange,
    'Health': green,
    'Learning': primary,
    'Finance': amber,
    'AI': teal,
    'Flutter': blue,
  };

  static Color tagColor(String tag) => tagMap[tag] ?? primary;

  static const topicPalette = [green, amber, primary, blue, orange, teal, pink, red];

  static Color topicColor(int index) => topicPalette[index % topicPalette.length];
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.green,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          surfaceContainerHighest: AppColors.card,
          onSurfaceVariant: AppColors.textSecondary,
          outline: AppColors.border,
          error: AppColors.red,
          onError: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        cardTheme: const CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: AppColors.textSecondary),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.2),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary, size: 22);
            }
            return const IconThemeData(color: AppColors.textMuted, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.inter(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              );
            }
            return GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11);
          }),
          elevation: 0,
          height: 68,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          dividerColor: Colors.transparent,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 0.5,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.card,
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          side: const BorderSide(color: AppColors.border, width: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: AppColors.card,
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
          labelStyle:
              GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary;
            return Colors.transparent;
          }),
          side: const BorderSide(color: AppColors.textMuted, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
      );
}
