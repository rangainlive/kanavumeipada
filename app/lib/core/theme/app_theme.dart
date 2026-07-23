import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// KanavuMeipada design system — Premium Dark (Deep Teal + Gold).
///
/// The whole app runs on a single dark [ThemeData]. All colors below are dark-mode
/// tokens; screens should reference these rather than hardcoding hex literals so a
/// future retheme is a one-file change.
class AppTheme {
  // ── Surfaces / background ────────────────────────────────────────────────
  static const Color bg = Color(0xFF060D0C); // scaffold — near-black teal (aurora canvas)
  static const Color surface = Color(0xFF10201E); // solid cards, app bars
  static const Color surface2 = Color(0xFF17302C); // elevated cards, sheets, inputs
  static const Color border = Color(0xFF244742); // hairline borders / dividers

  // Glass tokens (used with BackdropFilter for the Aurora-Glass look).
  static Color get glassFill => Colors.white.withValues(alpha: 0.07);
  static Color get glassFillStrong => Colors.white.withValues(alpha: 0.10);
  static Color get glassBorder => Colors.white.withValues(alpha: 0.16);

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF14B8A6); // brand teal
  static const Color primaryDim = Color(0xFF0D9488); // gradient partner / pressed
  static const Color primaryGlow = Color(0xFF2DD4BF); // bright teal for glows + active
  static const Color gold = Color(0xFFF5C451); // accent — coins, achievements, highlights
  static const Color goldDim = Color(0xFFD9A441);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFEAF2F0);
  static const Color textSecondary = Color(0xFF9DB2AD);
  static const Color textHint = Color(0xFF5F736F);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFF87171);
  static const Color warning = gold;

  // Back-compat aliases (older screens referenced these names).
  static const Color secondary = primaryGlow;
  static const Color accent = gold;
  static const Color bgLight = bg;

  // ── Gradients ────────────────────────────────────────────────────────────
  static const Gradient brandGradient = LinearGradient(
    colors: [primaryDim, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient brandGradientDeep = LinearGradient(
    colors: [Color(0xFF0B3B37), primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient goldGradient = LinearGradient(
    colors: [gold, goldDim],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = goldGradient;

  // ── Shadows ──────────────────────────────────────────────────────────────
  /// Neutral drop shadow for standard cards on the dark background.
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// Teal "glow" for hero cards and primary CTAs.
  static List<BoxShadow> glow([Color? color]) => [
        BoxShadow(
          color: (color ?? primary).withValues(alpha: 0.28),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // ── Typography ───────────────────────────────────────────────────────────
  // Plus Jakarta Sans for Latin, Noto Sans Tamil as a fallback so bilingual
  // (English / தமிழ்) text renders consistently on every device.
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
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: primary,
      onPrimary: Color(0xFF04120F),
      secondary: gold,
      onSecondary: Color(0xFF231A05),
      error: error,
      onError: Color(0xFF2A0A0A),
      surface: surface,
      onSurface: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: _textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _font(size: 18, weight: FontWeight.w700, letterSpacing: -0.3),
        iconTheme: const IconThemeData(color: textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
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
          foregroundColor: const Color(0xFF04120F),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: _font(size: 15, weight: FontWeight.w700),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: border),
          textStyle: _font(size: 15, weight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryGlow),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: _font(size: 13, weight: FontWeight.w600),
      ),

      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface2,
        contentTextStyle: _font(size: 14, color: textPrimary),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: _font(size: 18, weight: FontWeight.w700),
        contentTextStyle: _font(size: 14, color: textSecondary, height: 1.4),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      iconTheme: const IconThemeData(color: textSecondary),
    );
  }

  // Back-compat: some code may still reference lightTheme; return the dark theme
  // so the app is uniformly dark regardless of which getter is wired up.
  static ThemeData get lightTheme => darkTheme;
}

/// Full-width gradient CTA button. Defaults to the brand teal gradient; pass
/// [gradient] = [AppTheme.goldGradient] for a gold "premium" variant.
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
    final Color fg = isGold ? const Color(0xFF231A05) : const Color(0xFF04120F);
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? gradient : null,
          color: enabled ? null : AppTheme.surface2,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: (isGold ? AppTheme.gold : AppTheme.primary).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: enabled ? fg : AppTheme.textHint,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
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
