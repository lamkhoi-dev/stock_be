import 'package:flutter/material.dart';

/// Custom color extension for stock-specific colors.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.priceUp,
    required this.priceDown,
    required this.priceNeutral,
    required this.volumeUp,
    required this.volumeDown,
    required this.gold,
    required this.surfaceHover,
    required this.border,
    required this.chartLine,
  });

  final Color priceUp;
  final Color priceDown;
  final Color priceNeutral;
  final Color volumeUp;
  final Color volumeDown;
  final Color gold;
  final Color surfaceHover;
  final Color border;
  final Color chartLine;

  // Dark theme colors (from STITCH_PROMPT design system)
  static const dark = AppColors(
    priceUp: Color(0xFF22C55E),
    priceDown: Color(0xFFEF4444),
    priceNeutral: Color(0xFF8B8FA3),
    volumeUp: Color(0x6622C55E), // 40% opacity
    volumeDown: Color(0x66EF4444),
    gold: Color(0xFFF59E0B),
    surfaceHover: Color(0xFF1C1F2E),
    border: Color(0xFF2A2D3A),
    chartLine: Color(0xFF3B82F6),
  );

  // Light theme colors
  static const light = AppColors(
    priceUp: Color(0xFF16A34A),
    priceDown: Color(0xFFDC2626),
    priceNeutral: Color(0xFF6B7280),
    volumeUp: Color(0x6616A34A),
    volumeDown: Color(0x66DC2626),
    gold: Color(0xFFD97706),
    surfaceHover: Color(0xFFF3F4F6),
    border: Color(0xFFE5E7EB),
    chartLine: Color(0xFF2563EB),
  );

  @override
  AppColors copyWith({
    Color? priceUp,
    Color? priceDown,
    Color? priceNeutral,
    Color? volumeUp,
    Color? volumeDown,
    Color? gold,
    Color? surfaceHover,
    Color? border,
    Color? chartLine,
  }) {
    return AppColors(
      priceUp: priceUp ?? this.priceUp,
      priceDown: priceDown ?? this.priceDown,
      priceNeutral: priceNeutral ?? this.priceNeutral,
      volumeUp: volumeUp ?? this.volumeUp,
      volumeDown: volumeDown ?? this.volumeDown,
      gold: gold ?? this.gold,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      border: border ?? this.border,
      chartLine: chartLine ?? this.chartLine,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      priceUp: Color.lerp(priceUp, other.priceUp, t)!,
      priceDown: Color.lerp(priceDown, other.priceDown, t)!,
      priceNeutral: Color.lerp(priceNeutral, other.priceNeutral, t)!,
      volumeUp: Color.lerp(volumeUp, other.volumeUp, t)!,
      volumeDown: Color.lerp(volumeDown, other.volumeDown, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      border: Color.lerp(border, other.border, t)!,
      chartLine: Color.lerp(chartLine, other.chartLine, t)!,
    );
  }
}

/// App theme configuration matching STITCH design system.
class AppTheme {
  AppTheme._();

  // ─── Dark Theme (Primary) ───────────────────────────
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF0B0D17),
    colorScheme: const ColorScheme.dark(
      surface: Color(0xFF141620),
      primary: Color(0xFF3B82F6),
      onPrimary: Colors.white,
      secondary: Color(0xFF8B8FA3),
      onSecondary: Colors.white,
      error: Color(0xFFEF4444),
      onSurface: Color(0xFFE8EAED),
      outline: Color(0xFF2A2D3A),
    ),
    fontFamily: 'Inter',
    textTheme: _darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0B0D17),
      foregroundColor: Color(0xFFE8EAED),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF141620),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2A2D3A), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF141620),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2D3A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2D3A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF4E5263)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFE8EAED),
        side: const BorderSide(color: Color(0xFF2A2D3A)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0B0D17),
      selectedItemColor: Color(0xFF3B82F6),
      unselectedItemColor: Color(0xFF4E5263),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2A2D3A),
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF141620),
      selectedColor: const Color(0xFF3B82F6),
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFFE8EAED)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: const BorderSide(color: Color(0xFF2A2D3A)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF141620),
      contentTextStyle: const TextStyle(color: Color(0xFFE8EAED)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    extensions: const [AppColors.dark],
  );

  // ─── Light Theme ────────────────────────────────────
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF8F9FB),
    colorScheme: const ColorScheme.light(
      surface: Color(0xFFFFFFFF),
      primary: Color(0xFF2563EB),
      onPrimary: Colors.white,
      secondary: Color(0xFF6B7280),
      onSecondary: Colors.white,
      error: Color(0xFFDC2626),
      onSurface: Color(0xFF111827),
      outline: Color(0xFFE5E7EB),
    ),
    fontFamily: 'Inter',
    textTheme: _lightTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF8F9FB),
      foregroundColor: Color(0xFF111827),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF111827),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFF8F9FB),
      selectedItemColor: Color(0xFF2563EB),
      unselectedItemColor: Color(0xFF9CA3AF),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE5E7EB),
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF2563EB),
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.white,
      contentTextStyle: const TextStyle(color: Color(0xFF111827)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    extensions: const [AppColors.light],
  );

  // ─── Text Themes ────────────────────────────────────
  static const _darkTextTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Color(0xFFE8EAED),
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE8EAED),
      letterSpacing: -0.3,
    ),
    titleLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE8EAED),
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE8EAED),
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.normal,
      color: Color(0xFFE8EAED),
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Color(0xFF8B8FA3),
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE8EAED),
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Color(0xFF8B8FA3),
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: Color(0xFF4E5263),
    ),
  );

  static const _lightTextTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Color(0xFF111827),
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Color(0xFF111827),
      letterSpacing: -0.3,
    ),
    titleLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: Color(0xFF111827),
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Color(0xFF111827),
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.normal,
      color: Color(0xFF111827),
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Color(0xFF6B7280),
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Color(0xFF111827),
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Color(0xFF6B7280),
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: Color(0xFF9CA3AF),
    ),
  );
}
