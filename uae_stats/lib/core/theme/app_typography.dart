// lib/core/theme/app_typography.dart
// UAE Stats Design System — Typography
// Fonts: Plus Jakarta Sans (display), Inter (body), IBM Plex Sans Arabic (AR)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uae_stats/core/theme/app_colors.dart';

abstract final class AppTypography {
  // ─── Display (Plus Jakarta Sans) ─────────────────────────────────────────

  static TextStyle get displayXl => GoogleFonts.plusJakartaSans(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: AppColors.white,
      );

  static TextStyle get displayL => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.32,
        color: AppColors.slate900,
      );

  // ─── Hero value (indicator detail screen — 58px) ─────────────────────────
  static TextStyle get heroValue => GoogleFonts.plusJakartaSans(
        fontSize: 58,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.45,
        height: 1.0,
        color: AppColors.white,
      );

  // ─── Tile / KPI values ───────────────────────────────────────────────────
  static TextStyle get tileValue => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.44,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: AppColors.emiratesGreen,
      );

  static TextStyle get kpiValue => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.48,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: AppColors.slate900,
      );

  static TextStyle get sheetRowValue => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: AppColors.emiratesGreen,
      );

  static TextStyle get statChipValue => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: AppColors.slate900,
      );

  // ─── Headings (Plus Jakarta Sans) ────────────────────────────────────────

  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.48,
        color: AppColors.white,
      );

  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.44,
        color: AppColors.slate900,
      );

  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: AppColors.slate900,
      );

  /// App bar title
  static TextStyle get h4 => GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.34,
        color: AppColors.slate900,
      );

  static TextStyle get sectionTitle => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.36,
        color: AppColors.slate900,
      );

  // ─── Body (Inter) ────────────────────────────────────────────────────────

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.slate900,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.slate900,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.slate600,
      );

  static TextStyle get bodySmMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.slate600,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.slate600,
      );

  static TextStyle get captionSm => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.slate400,
      );

  static TextStyle get nano => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.08,
        color: AppColors.slate400,
      );

  /// Overline — uppercase label
  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.10,
        color: AppColors.slate400,
      ).copyWith(
        fontFeatures: const [FontFeature.enable('c2sc')],
      );

  // ─── Tile-specific ───────────────────────────────────────────────────────
  static TextStyle get tileName => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: AppColors.slate900,
      );

  static TextStyle get tileDesc => GoogleFonts.inter(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        color: AppColors.slate600,
      );

  // ─── Sheet row ───────────────────────────────────────────────────────────
  static TextStyle get sheetRowName => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.16,
        color: AppColors.slate900,
      );

  static TextStyle get sheetRowPeriod => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.slate400,
      );

  // ─── Action chips / tabs ─────────────────────────────────────────────────
  static TextStyle get chipLabel => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.emiratesGreen,
      );

  static TextStyle get tabLabel => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.slate400,
      );

  static TextStyle get tabLabelActive => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.emiratesGreen,
      );

  // ─── Arabic overrides ────────────────────────────────────────────────────
  /// Returns IBM Plex Sans Arabic for AR locale, falls back to Inter.
  static TextStyle arabicBody({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.slate900,
  }) =>
      GoogleFonts.ibmPlexSansArabic(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  static TextStyle arabicDisplay({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.white,
  }) =>
      GoogleFonts.ibmPlexSansArabic(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
}
