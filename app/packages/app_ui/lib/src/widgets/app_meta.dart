import 'package:app_ui/app_ui.dart';

/// {@template app_meta}
/// One fact about a thing, small: an icon and a few words ("6 min",
/// "US$ 0,07").
///
/// Bare it sits in a row of facts under a title; [boxed] gives it a pill of
/// [AppColors.fill], for the facts at the head of a detail page.
/// {@endtemplate}
class AppMeta extends StatelessWidget {
  /// {@macro app_meta}
  const AppMeta({
    required this.icon,
    required this.text,
    this.boxed = false,
    this.color = AppColors.ink2,
    super.key,
  });

  /// The glyph that says which fact this is.
  final AppIconData icon;

  /// The fact.
  final String text;

  /// Whether it sits in a pill of its own.
  final bool boxed;

  /// The colour of the icon and the words.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(iconData: icon, size: AppSpacing.iconSmall, color: color),
        const SizedBox(width: AppSpacing.s1 + 2),
        Text(text, style: AppTypography.caption.copyWith(color: color)),
      ],
    );
    if (!boxed) return row;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.pillRadius)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s2,
        ),
        child: row,
      ),
    );
  }
}
