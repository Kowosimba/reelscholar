import 'package:flutter/material.dart';

/// Design tokens — mirrors the wireframe :root CSS vars exactly.
/// --p: #0D9488  --acc: #6366F1  --bg: #F0FDF9  --ff: Sora  --ff2: DM Sans
class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0D9488); // --p
  static const Color primaryLight = Color(0xFF14B8A6); // --p2
  static const Color primarySubtle = Color(0xFFCCFBF1); // --p3

  static const Color secondary = Color(0xFF6366F1); // --acc
  static const Color secondaryLight = Color(0xFF818CF8); // --acc2

  // ── Semantic ─────────────────────────────────────────────────────────────────
  static const Color warning = Color(0xFFF59E0B); // --warn
  static const Color error = Color(0xFFEF4444); // --err
  static const Color success = Color(0xFF22C55E); // --succ
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);

  static const LinearGradient onboardGradient1 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF6366F1)],
    stops: [0.0, 0.4, 1.0],
  );

  static const LinearGradient onboardGradient2 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF0D9488)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient onboardGradient3 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF92400E), Color(0xFFD97706), Color(0xFF0D9488)],
    stops: [0.0, 0.5, 1.0],
  );

  // ── Backgrounds ──────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFFF0FDF9); // --bg  teal-tinted
  static const Color white = Color(0xFFFFFFFF); // --bg2
  static const Color surface = white;
  static const Color background = bg;
  static const Color backgroundWhite = white;
  static const Color backgroundMuted = muted;
  static const Color muted = Color(0xFFF8FAFC); // --bg3

  // ── Borders ──────────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0); // --border
  static const Color borderMedium = Color(0xFFCBD5E1); // --border2

  // ── Text ────────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A); // --txt
  static const Color textSecondary = Color(0xFF475569); // --txt2
  static const Color textTertiary = Color(0xFF94A3B8); // --txt3

  // ── Dark surfaces (reels, chat, drawer overlay) ──────────────────────────────
  static const Color dark = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkMuted = Color(0xFF64748B);

  // ── Gradients ───────────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F766E), Color(0xFF1E293B), Color(0xFF0F172A)],
    stops: [0.0, 0.55, 1.0],
  );

  // FAB gradient — matches wireframe .bnav-home
  static const LinearGradient fabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  // Sidebar header gradient
  static const LinearGradient drawerHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF6366F1)],
    stops: [0.0, 0.4, 1.0],
  );
}

/// Typography helpers
class AppFonts {
  AppFonts._();
  static const String sora = 'Sora'; // --ff  headings/brand
  static const String dmSans = 'DM Sans'; // --ff2 body
}
