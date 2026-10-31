import 'package:flutter/material.dart';

/// The color tokens.
///
/// Vox is dark and warm: a green-black page like a quiet studio, off-white
/// text, and one teal for what can be acted on and for the agent being
/// alive in a call. The neutrals lean slightly toward the teal. Screens only
/// ever read these names, so changing a value restyles every screen at once;
/// a value a screen needs that is not here becomes a new token, never a
/// literal.
abstract final class AppColors {
  /// The page background behind every screen.
  static const bg = Color(0xFF121614);

  /// The surface a sheet, a menu, or a dialog sits on.
  static const surface = Color(0xFF1A1F1C);

  /// The borderless fill that gives a field or a card its shape.
  static const fill = Color(0xFF222925);

  /// A heavier [fill], for pressed states, tracks, inactive bars, and the
  /// call's round controls.
  static const fillStrong = Color(0xFF2E3632);

  /// Hairline separators.
  static const line = Color(0xFF2A322D);

  /// Text primary. 15.9:1 on [bg].
  static const ink = Color(0xFFEEF0EA);

  /// Text secondary: labels, captions, and subtitles. 8.2:1 on [bg].
  static const ink2 = Color(0xFFA7B0AA);

  /// Text tertiary: placeholders, disabled labels, and the caption line
  /// that has just gone by. 4:1 on [bg], so never for running text.
  static const ink3 = Color(0xFF6E7872);

  /// The one colour for what can be acted on, and for the agent's presence
  /// in a call.
  static const accent = Color(0xFF4FC3A9);

  /// What is drawn on [accent]. 7.7:1.
  static const onAccent = Color(0xFF08221C);

  /// A pale [accent], behind something selected or the person's own words.
  static const accentSoft = Color(0xFF173A32);

  /// Something went well.
  static const positive = Color(0xFF8FD47A);

  /// Something went wrong, and the button that ends a call.
  static const negative = Color(0xFFF08A7E);

  /// What is drawn on [negative], such as the hang-up icon. 7.5:1.
  static const onNegative = Color(0xFF2A0B07);
}
