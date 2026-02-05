/// Application color palette.
///
/// Semantic color system with support for light and dark themes.
/// Colors are designed for IoT monitoring with calm, professional aesthetics.
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette - calming blue-grey
  static const Color primary = Color(0xFF3D5A80);
  static const Color primaryLight = Color(0xFF5C7BA5);
  static const Color primaryDark = Color(0xFF293D5A);

  // Secondary palette - soft teal accent
  static const Color secondary = Color(0xFF48CAE4);
  static const Color secondaryLight = Color(0xFF90E0EF);
  static const Color secondaryDark = Color(0xFF0096C7);

  // Neutral palette
  static const Color neutral50 = Color(0xFFFAFAFC);
  static const Color neutral100 = Color(0xFFF4F4F7);
  static const Color neutral200 = Color(0xFFE4E5EA);
  static const Color neutral300 = Color(0xFFCFD1D9);
  static const Color neutral400 = Color(0xFF9CA0AD);
  static const Color neutral500 = Color(0xFF6B7085);
  static const Color neutral600 = Color(0xFF4A4E5E);
  static const Color neutral700 = Color(0xFF353848);
  static const Color neutral800 = Color(0xFF24262F);
  static const Color neutral900 = Color(0xFF16171D);

  // Semantic colors
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF166534);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF92400E);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFF991B1B);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1E40AF);

  // Metric colors for charts - muted, professional
  static const Color temperature = Color(0xFFE76F51);
  static const Color humidity = Color(0xFF457B9D);
  static const Color voltage = Color(0xFF2A9D8F);
  static const Color battery = Color(0xFF8AB17D);

  // Status indicator colors
  static const Color online = Color(0xFF22C55E);
  static const Color offline = Color(0xFF94A3B8);
  static const Color connecting = Color(0xFFF59E0B);
  static const Color provisioning = Color(0xFF8B5CF6);

  // Surface colors - light mode
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF8F9FC);
  static const Color backgroundLight = Color(0xFFF3F4F8);

  // Surface colors - dark mode
  static const Color surfaceDark = Color(0xFF1E1F25);
  static const Color surfaceVariantDark = Color(0xFF252630);
  static const Color backgroundDark = Color(0xFF16171D);

  // Gradient for empty state illustrations
  static const LinearGradient emptyStateGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8EEF4),
      Color(0xFFF5F7FA),
    ],
  );

  static const LinearGradient emptyStateGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF252630),
      Color(0xFF1E1F25),
    ],
  );
}
