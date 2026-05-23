// lib/core/theme/app_spacing.dart
// UAE Stats Design System — Spacing & Radius Tokens

/// Spacing scale (8px base).
abstract final class AppSpacing {
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 16;
  static const double lg   = 20;   // ← primary side padding
  static const double xl   = 24;
  static const double xxl  = 32;
  static const double xxxl = 40;
  static const double huge = 48;

  // ─── Border radii ────────────────────────────────────────────────────────
  static const double radiusXs   = 10;
  static const double radiusSm   = 12;
  static const double radiusMd   = 14;  // buttons, search bar, inputs
  static const double radiusLg   = 16;  // small cards, sheet rows
  static const double radiusXl   = 20;  // main cards, tiles
  static const double radiusXxl  = 24;  // hero cards, large elements
  static const double radiusPill = 999; // fully rounded chips/pills
  static const double radiusSheet = 28; // bottom sheet top corners

  // ─── Fixed component dimensions ──────────────────────────────────────────
  static const double appBarHeight       = 56;
  static const double bottomNavHeight    = 84;
  static const double flagStripeHeight   = 3;
  static const double heroHeight         = 220;
  static const double keyCardWidth       = 160;
  static const double keyCardHeight      = 140;
  static const double tileGridGap        = 12;
  static const double tileSideGap        = 20; // same as lg
  static const double searchBarHeight    = 48;
  static const double actionChipHeight   = 40;
  static const double tabBarItemWidth    = 80;
  static const double iconContainerLg    = 44;
  static const double iconContainerMd    = 40;
  static const double iconContainerSm    = 32;
  static const double iconContainerXs    = 28;
  static const double sheetHandleW       = 40;
  static const double sheetHandleH       = 4;
}
