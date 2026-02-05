/// Application spacing constants.
///
/// Consistent spacing scale based on 4px base unit.
/// Use semantic names for maintainability.
class AppSpacing {
  AppSpacing._();

  // Base unit
  static const double unit = 4.0;

  // Absolute spacing values
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Component-specific spacing
  static const double cardPadding = 16.0;
  static const double cardMargin = 12.0;
  static const double listItemPadding = 16.0;
  static const double sectionSpacing = 24.0;
  static const double screenPadding = 20.0;

  // Border radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0;

  // Icon sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
  static const double iconXxl = 64.0;

  // Touch targets (minimum 48x48 for accessibility)
  static const double touchTarget = 48.0;
  static const double touchTargetLg = 56.0;
}
