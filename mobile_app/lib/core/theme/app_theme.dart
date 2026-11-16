import 'package:flutter/material.dart';

/// الهوية البصرية لتطبيق HS للنقل البري.
///
/// بذرة لون أخضر داكن مائل للزرقة (teal) تليق بتطبيق نقل سعودي عصري،
/// مع خلفية داكنة فاخرة للسائقين ووضع فاتح نظيف للراكب. الخط: Cairo.
class HSColors {
  HSColors._();

  /// البذرة الأساسية للهوية.
  static const Color seed = Color(0xFF00A98F);

  /// الأخضر الأساسي (لون العلامة).
  static const Color brand = Color(0xFF00A98F);

  /// لون داكن ثانوي للتدرجات.
  static const Color brandDark = Color(0xFF00695C);

  /// لون خلفية شاشة البداية الداكنة.
  static const Color darkBg = Color(0xFF0E2A26);

  /// لون تحذيري (رفض/إلغاء).
  static const Color danger = Color(0xFFE53935);

  /// لون النجاح والقبول.
  static const Color success = Color(0xFF2E7D32);

  /// ذهبي لعناصر VIP.
  static const Color vip = Color(0xFFB7912A);

  /// لون نص ثانوي.
  static const Color subtleText = Color(0xFF607D8B);
}

/// بناء سمتَي الفاتح والداكن من البذرة.
ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: HSColors.seed,
    brightness: brightness,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Cairo',
    scaffoldBackgroundColor:
        brightness == Brightness.light ? const Color(0xFFF6F8F8) : const Color(0xFF101414),
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: brightness == Brightness.light ? scheme.surface : scheme.surface,
      foregroundColor: brightness == Brightness.light ? scheme.onSurface : scheme.onSurface,
      titleTextStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      displayMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      displaySmall: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: brightness == Brightness.light ? Colors.white : const Color(0xFF1A1F1F),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: brightness == Brightness.light ? Colors.white : const Color(0xFF1A1F1F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(.5)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      backgroundColor: Colors.white,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );
}
