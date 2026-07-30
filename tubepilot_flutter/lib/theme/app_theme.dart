import 'package:flutter/material.dart';

class AppColors {
  // Brand palette — refined deep teal / navy, tuned for a more premium,
  // "latest" Material 3 feel. Property names kept identical to before so
  // every existing screen referencing AppColors.purple / .pink / etc.
  // continues to work without any other file needing changes.
  static const purple = Color(0xFF0B7A80);       // primary accent (refined teal)
  static const purpleLight = Color(0xFF12A4AC);  // lighter accent
  static const pink = Color(0xFF1F3B4D);         // secondary / gradient end (deep navy)
  static const green = Color(0xFF16A34A);
  static const red = Color(0xFFDC2626);
  static const diamond = Color(0xFF0EA5E9);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purpleLight, pink],
  );

  // Light theme surface colors — subtle teal tint, softer contrast
  static const lightBg = Color(0xFFF6FAFA);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCard2 = Color(0xFFEDF6F6);
  static const lightBorder = Color(0xFFDCEAEA);
  static const lightText = Color(0xFF0F2224);
  static const lightTextDim = Color(0xFF5E7879);

  // Dark theme surface colors — near-black background, slightly raised cards
  static const darkBg = Color(0xFF060707);
  static const darkCard = Color(0xFF121313);
  static const darkCard2 = Color(0xFF1C1E1E);
  static const darkBorder = Color(0xFF2A2D2D);
  static const darkText = Color(0xFFF3F4F4);
  static const darkTextDim = Color(0xFFA1A8A8);
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
    final isDark = brightness == Brightness.dark;

    final base = ColorScheme(
      brightness: brightness,
      primary: AppColors.purple,
      onPrimary: Colors.white,
      primaryContainer: AppColors.purple.withOpacity(isDark ? 0.24 : 0.12),
      onPrimaryContainer: isDark ? AppColors.purpleLight : AppColors.purple,
      secondary: AppColors.pink,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.pink.withOpacity(isDark ? 0.24 : 0.10),
      onSecondaryContainer: text,
      tertiary: AppColors.diamond,
      onTertiary: Colors.white,
      error: AppColors.red,
      onError: Colors.white,
      errorContainer: AppColors.red.withOpacity(isDark ? 0.20 : 0.10),
      onErrorContainer: AppColors.red,
      surface: card,
      onSurface: text,
      surfaceContainerHighest: card2,
      outline: border,
      outlineVariant: border.withOpacity(0.6),
      shadow: Colors.black,
    );

    final splash = InkSparkle.splashFactory;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: base,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Roboto',
      splashFactory: splash,
      visualDensity: VisualDensity.standard,
      splashColor: AppColors.purple.withOpacity(0.08),
      highlightColor: Colors.transparent,

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2),
        iconTheme: IconThemeData(color: text),
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(isDark ? 0.5 : 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.purple, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.red, width: 1.6),
        ),
        labelStyle: TextStyle(color: textDim, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: textDim.withOpacity(0.7)),
        counterStyle: TextStyle(color: textDim.withOpacity(0.7), fontSize: 11),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.purple.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.1),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.purple,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: text),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: card2,
        selectedColor: AppColors.purple.withOpacity(0.16),
        disabledColor: card2.withOpacity(0.5),
        labelStyle: TextStyle(color: text, fontSize: 12.5, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: AppColors.purple, fontSize: 12.5, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: border),
        ),
        side: BorderSide.none,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? Colors.white70 : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.purple;
          return border;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.purple;
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: border, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.purple;
          return textDim;
        }),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.purple,
        linearTrackColor: border,
        circularTrackColor: border,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(isDark ? 0.6 : 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(color: text, fontSize: 17, fontWeight: FontWeight.w700),
        contentTextStyle: TextStyle(color: textDim, fontSize: 13.5, height: 1.4),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        dragHandleColor: border,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkCard2 : text,
        contentTextStyle: TextStyle(color: isDark ? text : Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.purple,
        unselectedLabelColor: textDim,
        labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
        indicatorColor: AppColors.purple,
        dividerColor: border,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard2 : text,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: isDark ? text : Colors.white, fontSize: 12),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border),
        ),
        textStyle: TextStyle(color: text, fontSize: 13.5),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: textDim,
        textColor: text,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(color: text, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        displayMedium: TextStyle(color: text, fontWeight: FontWeight.w800, letterSpacing: -0.4),
        headlineLarge: TextStyle(color: text, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4),
        headlineMedium: TextStyle(color: text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        headlineSmall: TextStyle(color: text, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.2),
        titleLarge: TextStyle(color: text, fontSize: 17, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.w700),
        titleSmall: TextStyle(color: text, fontSize: 13.5, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: text, fontSize: 15, height: 1.45),
        bodyMedium: TextStyle(color: text, fontSize: 13.5, height: 1.45),
        bodySmall: TextStyle(color: textDim, fontSize: 12, height: 1.4),
        labelLarge: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: textDim, fontSize: 12, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(color: textDim, fontSize: 10.5, fontWeight: FontWeight.w600),
      ),

      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

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