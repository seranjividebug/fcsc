// lib/core/theme/app_colors.dart
// UAE Stats Design System — Color Tokens
// Extracted pixel-perfect from approved HTML mockups

import 'package:flutter/material.dart';

/// All color constants for the UAE Stats app.
/// Never use raw hex values in widgets — always reference AppColors.
abstract final class AppColors {
  // ─── Primary ────────────────────────────────────────────────────────────
  static const Color emiratesGreen = Color(0xFF00594C);
  static const Color deepForest    = Color(0xFF003D33);
  static const Color sageMist      = Color(0xFFE8F1EE);
  static const Color champagneGold = Color(0xFFC8973A);
  static const Color royalSand     = Color(0xFFF5E9D3);

  // ─── Neutrals ────────────────────────────────────────────────────────────
  static const Color white         = Color(0xFFFFFFFF);
  static const Color offWhite      = Color(0xFFFAFBFC);
  static const Color pearlGray     = Color(0xFFF3F5F7);
  static const Color pearlGraySoft = Color(0xFFF8F9FB);
  static const Color silver        = Color(0xFFE5E7EB);
  static const Color slate300      = Color(0xFFCBD5E1);
  static const Color slate400      = Color(0xFF9CA3AF);
  static const Color slate600      = Color(0xFF4B5563);
  static const Color slate900      = Color(0xFF0F172A);

  // ─── Semantic ────────────────────────────────────────────────────────────
  static const Color success       = Color(0xFF059669);
  static const Color successBg     = Color(0xFFECFDF5);
  static const Color error         = Color(0xFFDC2626);
  static const Color errorBg       = Color(0xFFFEE2E2);
  static const Color warning       = Color(0xFFD97706);
  static const Color info          = Color(0xFF2563EB);

  // ─── UAE Flag ────────────────────────────────────────────────────────────
  static const Color flagRed       = Color(0xFFEF3340);
  static const Color flagBlack     = Color(0xFF000000);
  static const Color flagGreen     = Color(0xFF009639);
  // flagWhite = white (alias)

  // ─── Category accents ────────────────────────────────────────────────────
  static const Color teal          = Color(0xFF0891B2);
  static const Color tealTint      = Color(0xFFE0F2FE);

  // ─── Charts (sequential palette) ─────────────────────────────────────────
  static const Color chart01       = Color(0xFF00594C); // Demography / primary
  static const Color chart02       = Color(0xFF1A6FA8);
  static const Color chart03       = Color(0xFFC8973A); // Economy
  static const Color chart04       = Color(0xFFB45309);
  static const Color chart05       = Color(0xFF7C3AED);
  static const Color chart06       = Color(0xFFDC2626);
  static const Color chart07       = Color(0xFF0891B2); // Environment
  static const Color chart08       = Color(0xFF65A30D);

  // ─── Gradients ───────────────────────────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
    colors: [deepForest, emiratesGreen],
  );

  static const LinearGradient heroGradientDetail = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
    colors: [emiratesGreen, deepForest],
  );

  // ─── Dark mode surfaces (Economy / Social / Environment pages) ───────────
  static const Color darkBg        = Color(0xFF000000);
  static const Color darkSurface   = Color(0xFF0D0D14);
  static const Color darkBorder    = Color(0xFF1E1E2E);
  static const Color darkText      = Color(0xFFFFFFFF);
  static const Color darkTextSub   = Color(0xFF9CA3AF);
  static const Color darkTextDim   = Color(0xFF6B7280);

  // ─── Economy accent (soft steel-blue) ────────────────────────────────────
  static const Color economyAccent     = Color(0xFF6BAED6);
  static const Color economyBannerStart = Color(0xFF3D6A99);
  static const Color economyBannerEnd   = Color(0xFF5B8EC5);

  // ─── Social accent (soft lavender / purple) ───────────────────────────────
  static const Color socialAccent      = Color(0xFFB4A8CC);
  static const Color socialBannerStart = Color(0xFF5D4D70);
  static const Color socialBannerEnd   = Color(0xFF7A6A8E);

  // ─── Environment accent (soft sage-green) ────────────────────────────────
  static const Color envAccent         = Color(0xFF8DB87A);
  static const Color envBannerStart    = Color(0xFF3D6B32);
  static const Color envBannerEnd      = Color(0xFF5A8F4A);

  // ─── Box shadows ─────────────────────────────────────────────────────────
  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowElevated = [
    BoxShadow(
      color: Color(0x1A0F172A),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> shadowSheet = [
    BoxShadow(
      color: Color(0x2D0F172A),
      blurRadius: 40,
      offset: Offset(0, -8),
    ),
  ];
}
