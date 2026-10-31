import 'package:app_ui/src/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The type tokens.
///
/// Instrument Sans everywhere, a calm grotesque; its sister face, Instrument
/// Serif, only for the two largest styles (the greeting, the app's name,
/// screen headings), which is where the warmth comes from. Weight and size
/// carry the rest of the hierarchy, and tracking tightens as the size grows
/// so a headline and a 12pt caption sit on the same optical rhythm.
abstract final class AppTypography {
  /// The face of everything but [display] and [headline].
  static TextStyle face({
    required double size,
    required FontWeight weight,
    double height = 1.3,
    double tracking = -0.01,
    Color color = AppColors.ink,
  }) {
    return GoogleFonts.instrumentSans(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: size * tracking,
      color: color,
    );
  }

  /// The serif, for [display] and [headline] only. It has one weight, and
  /// sets a step larger than the sans because it reads lighter.
  static TextStyle serif({
    required double size,
    double height = 1.1,
    Color color = AppColors.ink,
  }) {
    return GoogleFonts.instrumentSerif(
      fontSize: size,
      fontWeight: FontWeight.w400,
      height: height,
      color: color,
    );
  }

  /// Serif 44. Billboard headings.
  static TextStyle get display => serif(size: 44, height: 1.05);

  /// Serif 32. Screen headings, the greeting, the app's name.
  static TextStyle get headline => serif(size: 32);

  /// Serif 26. The title in the top bar: the greeting, a screen's name.
  static TextStyle get barTitle => serif(size: 26, height: 1.2);

  /// 20/600. Section headers.
  static TextStyle get title =>
      face(size: 20, weight: FontWeight.w600, height: 1.2);

  /// 16/400. The default: running text and input values.
  static TextStyle get body =>
      face(size: 16, weight: FontWeight.w400, height: 1.5);

  /// 16/600. Button labels, and a title with something written under it.
  ///
  /// The tighter line height comes with the weight: this sets one line that
  /// leads something else, not a paragraph.
  static TextStyle get bodyStrong =>
      face(size: 16, weight: FontWeight.w600, height: 1.25);

  /// 14/400. Labels, subtitles, and the prompt caption.
  static TextStyle get label =>
      face(size: 14, weight: FontWeight.w400, color: AppColors.ink2);

  /// 14/600. Chip and control labels.
  static TextStyle get labelStrong => face(size: 14, weight: FontWeight.w600);

  /// 12/500. Captions and tab labels.
  static TextStyle get caption => face(
    size: 12,
    weight: FontWeight.w500,
    color: AppColors.ink2,
  );

  /// The Material text theme, built from the scale above.
  static TextTheme get textTheme => TextTheme(
    displayLarge: display,
    displayMedium: display,
    displaySmall: display,
    headlineLarge: headline,
    headlineMedium: headline,
    headlineSmall: title,
    titleLarge: title,
    titleMedium: bodyStrong,
    titleSmall: labelStrong,
    bodyLarge: body,
    bodyMedium: label,
    bodySmall: caption,
    labelLarge: bodyStrong,
    labelMedium: labelStrong,
    labelSmall: caption,
  );
}
