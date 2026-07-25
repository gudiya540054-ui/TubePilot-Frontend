import 'package:flutter/material.dart';

class AppColors {
  // Brand palette — deep teal / navy (previously purple/pink)
  static const purple = Color(0xFF0A7075);       // primary accent (was purple)
  static const purpleLight = Color(0xFF0C969C);  // lighter accent (was purpleLight)
  static const pink = Color(0xFF274D60);         // secondary / gradient end (was pink)
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
  static const diamond = Color(0xFF38BDF8);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purpleLight, pink],
  );

  // Light theme surface colors — subtle teal tint instead of purple tint
  static const lightBg = Color(0xFFF4FAFA);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCard2 = Color(0xFFE9F5F5);
  static const lightBorder = Color(0xFFD9EAEA);
  static const lightText = Color(0xFF102425);
  static const lightTextDim = Color(0xFF5C7677);

  // Dark theme surface colors — pure black background as requested
  static const darkBg = Color(0xFF000000);
  static const darkCard = Color(0xFF0D0D0D);
  static const darkCard2 = Color(0xFF1A1A1A);
  static const darkBorder = Color(0xFF262626);
  static const darkText = Color(0xFFF2F2F2);
  static const darkTextDim = Color(0xFF9AA0A6);
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