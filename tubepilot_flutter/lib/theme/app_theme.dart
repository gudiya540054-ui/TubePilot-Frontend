import 'package:flutter/material.dart';

class AppColors {
  static const purple = Color(0xFF7C3AED);
  static const purpleLight = Color(0xFFA78BFA);
  static const pink = Color(0xFFEC4899);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
  static const diamond = Color(0xFF38BDF8);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, pink],
  );

  // Light theme surface colors
  static const lightBg = Color(0xFFF7F6FB);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCard2 = Color(0xFFF1EEFB);
  static const lightBorder = Color(0xFFE6E1F5);
  static const lightText = Color(0xFF1B1730);
  static const lightTextDim = Color(0xFF716C8C);

  // Dark theme surface colors
  static const darkBg = Color(0xFF0D0B1A);
  static const darkCard = Color(0xFF17142B);
  static const darkCard2 = Color(0xFF1E1A38);
  static const darkBorder = Color(0xFF2A2547);
  static const darkText = Color(0xFFF5F3FF);
  static const darkTextDim = Color(0xFF9891B5);
}

class AppTheme {
  static ThemeData light = _build(
    brightness: Brightness.light,
    bg: AppColors.lightBg,
    card: AppColors.lightCard,
    card2: AppColors.lightCard2,
    border: AppColors.lightBorder,
    text: AppColors.lightText,
    textDim: AppColors.lightTextDim,
  );

  static ThemeData dark = _build(
    brightness: Brightness.dark,
    bg: AppColors.darkBg,
    card: AppColors.darkCard,
    card2: AppColors.darkCard2,
    border: AppColors.darkBorder,
    text: AppColors.darkText,
    textDim: AppColors.darkTextDim,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color card,
    required Color card2,
    required Color border,
    required Color text,
    required Color textDim,
  }) {
    final base = ColorScheme(
      brightness: brightness,
      primary: AppColors.purple,
      onPrimary: Colors.white,
      secondary: AppColors.pink,
      onSecondary: Colors.white,
      error: AppColors.red,
      onError: Colors.white,
      surface: card,
      onSurface: text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: base,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: text, fontSize: 17, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.purple, width: 1.6),
        ),
        labelStyle: TextStyle(color: textDim, fontSize: 13),
        hintStyle: TextStyle(color: textDim.withOpacity(0.7)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: text),
        bodySmall: TextStyle(color: textDim),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      extensions: [
        AppSurfaceColors(card2: card2, textDim: textDim, border: border),
      ],
    );
  }
}

/// Extra theme colors not covered by ColorScheme (card2 background, dim text, border)
class AppSurfaceColors extends ThemeExtension<AppSurfaceColors> {
  final Color card2;
  final Color textDim;
  final Color border;

  const AppSurfaceColors({required this.card2, required this.textDim, required this.border});

  @override
  AppSurfaceColors copyWith({Color? card2, Color? textDim, Color? border}) {
    return AppSurfaceColors(
      card2: card2 ?? this.card2,
      textDim: textDim ?? this.textDim,
      border: border ?? this.border,
    );
  }

  @override
  AppSurfaceColors lerp(ThemeExtension<AppSurfaceColors>? other, double t) {
    if (other is! AppSurfaceColors) return this;
    return AppSurfaceColors(
      card2: Color.lerp(card2, other.card2, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

extension AppThemeExt on BuildContext {
  AppSurfaceColors get surfaces => Theme.of(this).extension<AppSurfaceColors>()!;
}
