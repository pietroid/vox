/// The spacing, radius, and sizing tokens.
///
/// One 4pt grid, so every gap, pad, and corner in the app comes from the same
/// scale. Nothing hard-codes a number that could have come from here. The
/// shape is round and airy: pill buttons and fields, soft cards.
abstract final class AppSpacing {
  /// 4pt. Hairline gaps, icon-to-label inside a dense control.
  static const s1 = 4.0;

  /// 8pt. The gap between tightly related elements.
  static const s2 = 8.0;

  /// 12pt. Control padding and list row gaps.
  static const s3 = 12.0;

  /// 16pt. The default gutter.
  static const s4 = 16.0;

  /// 20pt. The field and card pad.
  static const s5 = 20.0;

  /// 24pt. The screen gutter.
  static const s6 = 24.0;

  /// 32pt. The gap between sections.
  static const s8 = 32.0;

  /// 48pt. The gap between a heading and the block it introduces.
  static const s12 = 48.0;

  /// 64pt. Hero breathing room.
  static const s16 = 64.0;

  /// The corner radius of a card or a sheet.
  static const cardRadius = 28.0;

  /// The corner radius of a chip, a menu, a chat bubble, or an inline
  /// surface.
  static const chipRadius = 20.0;

  /// The corner radius of a button: a pill.
  static const buttonRadius = 999.0;

  /// A fully rounded corner, for pills and tap targets.
  static const pillRadius = 999.0;

  /// The minimum tap target, per Fitts's law.
  static const tapTarget = 44.0;

  /// The height of a button.
  static const buttonHeight = 52.0;

  /// The height of the app's single-line prompt field.
  static const fieldHeight = 56.0;

  /// The corner radius of a field: a pill at one line, and soft when it
  /// grows to several.
  static const double fieldRadius = fieldHeight / 2;

  /// The round controls of a call (mute, captions, hang up): big enough to
  /// hit without looking.
  static const callControl = 64.0;

  /// The agent's presence in a call: the teal dot and the halo around it.
  static const presence = 120.0;

  /// The room a call keeps for its captions (two faded lines, three at full
  /// ink), held even when they are empty or hidden, so the presence never
  /// moves while the person looks at it.
  static const callCaptions = 120.0;

  /// The default icon size.
  static const iconSize = 24.0;

  /// A small icon, beside a caption or a chip label.
  static const iconSmall = 16.0;

  /// The round number in front of an item of a numbered list.
  static const badge = 28.0;

  /// The widest a content column ever gets, so text stays readable on web.
  static const maxContentWidth = 560.0;
}
