import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// KanavuMeipada design system — Clean Light (emerald accent).
///
/// Inspired by modern light UI: soft off-white canvas, pure-white rounded cards
/// with soft diffuse shadows, a bold emerald accent, and accent "hero" cards.
/// Screens reference these tokens instead of hardcoding hex so a retheme is a
/// one-file change.
class AppTheme {
  // ── Surfaces / background ────────────────────────────────────────────────
  static const Color bg = Color(0xFFF4F6FB); // soft light canvas
  static const Color surface = Color(0xFFFFFFFF); // cards
  static const Color surface2 = Color(0xFFF1F4F9); // input / pill fills
  static const Color border = Color(0xFFE9ECF3); // hairline borders

  // ── Brand (emerald) ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFF10B981); // accent / buttons / active
  static const Color primaryDim = Color(0xFF059669); // deeper emerald
  static const Color primaryDeep = Color(0xFF047857); // hero gradient end
  static const Color primaryGlow = Color(0xFF34D399); // light emerald
  static const Color primarySoft = Color(0xFFE7F7F0); // tinted emerald wash
  static const Color gold = Color(0xFFF59E0B); // coins / highlights
  static const Color goldDim = Color(0xFFD97706);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = gold;

  // Back-compat aliases (older screens referenced these names).
  static const Color secondary = primary;
  static const Color accent = primary;
  static const Color bgLight = bg;
  // Glass tokens kept for compatibility (unused in the light theme).
  static Color get glassFill => Colors.white.withValues(alpha: 0.7);
  static Color get glassFillStrong => Colors.white.withValues(alpha: 0.85);
  static Color get glassBorder => border;

  // ── Gradients ────────────────────────────────────────────────────────────
  static const Gradient brandGradient = LinearGradient(
    colors: [primary, primaryDim],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Rich accent hero (solid emerald card with white text — like the references).
  static const Gradient brandGradientDeep = LinearGradient(
    colors: [primaryDim, primaryDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient goldGradient = LinearGradient(
    colors: [gold, goldDim],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = brandGradient;

  // ── Shadows ──────────────────────────────────────────────────────────────
  /// Soft diffuse shadow for white cards on the light canvas.
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Colored glow for accent hero cards / primary CTAs.
  static List<BoxShadow> glow([Color? color]) => [
        BoxShadow(
          color: (color ?? primary).withValues(alpha: 0.28),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];

  // ── Typography ───────────────────────────────────────────────────────────
  static List<String> get _tamilFallback => [GoogleFonts.notoSansTamil().fontFamily!];

  static TextStyle _font({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = textPrimary,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      ).copyWith(fontFamilyFallback: _tamilFallback);

  static TextTheme get _textTheme => TextTheme(
        displayLarge: _font(size: 40, weight: FontWeight.w800, letterSpacing: -1),
        headlineLarge: _font(size: 30, weight: FontWeight.w800, letterSpacing: -0.5),
        headlineMedium: _font(size: 24, weight: FontWeight.w700, letterSpacing: -0.3),
        headlineSmall: _font(size: 20, weight: FontWeight.w700),
        titleLarge: _font(size: 17, weight: FontWeight.w600),
        titleMedium: _font(size: 15, weight: FontWeight.w600),
        bodyLarge: _font(size: 16, color: textPrimary, height: 1.5),
        bodyMedium: _font(size: 14, color: textSecondary, height: 1.4),
        labelSmall: _font(size: 11, weight: FontWeight.w500, color: textHint, letterSpacing: 0.3),
      );

  // ── Theme ────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: gold,
      onSecondary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: _textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _font(size: 18, weight: FontWeight.w700, letterSpacing: -0.3),
        iconTheme: const IconThemeData(color: textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: _font(size: 14, color: textHint),
        prefixIconColor: textHint,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: _font(size: 15, weight: FontWeight.w700),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: border),
          textStyle: _font(size: 15, weight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryDim),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        labelStyle: _font(size: 13, weight: FontWeight.w600),
      ),

      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: _font(size: 14, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: _font(size: 18, weight: FontWeight.w700),
        contentTextStyle: _font(size: 14, color: textSecondary, height: 1.4),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      iconTheme: const IconThemeData(color: textSecondary),
    );
  }

  // Back-compat: darkTheme returns the light theme so the app is uniformly light.
  static ThemeData get darkTheme => lightTheme;
}

/// Full-width accent CTA button (solid emerald with a soft colored shadow).
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Gradient gradient;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.gradient = AppTheme.brandGradient,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final bool isGold = gradient == AppTheme.goldGradient;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? gradient : null,
          color: enabled ? null : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: (isGold ? AppTheme.gold : AppTheme.primary).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: enabled ? Colors.white : AppTheme.textHint,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
