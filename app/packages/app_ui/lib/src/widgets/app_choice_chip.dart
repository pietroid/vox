import 'package:app_ui/app_ui.dart';

/// {@template app_choice_chip}
/// A pill to pick one answer among a few: an icon and a short label.
///
/// Unselected it sits on [AppColors.fill] with a quiet icon; selected it
/// turns [AppColors.accentSoft] with an accent edge and icon, so the
/// choice reads at a glance without a check mark.
/// {@endtemplate}
class AppChoiceChip extends StatelessWidget {
  /// {@macro app_choice_chip}
  const AppChoiceChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  /// The glyph before the label.
  final AppIconData icon;

  /// The answer, in two or three words.
  final String label;

  /// Whether this is the answer picked.
  final bool selected;

  /// Called on a tap.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.accentSoft : AppColors.fill,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.accent : Colors.transparent,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.tapTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    iconData: icon,
                    size: AppSpacing.iconSmall + 2,
                    color: selected ? AppColors.accent : AppColors.ink2,
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Text(
                    label,
                    style: AppTypography.labelStrong.copyWith(
                      color: selected ? AppColors.ink : AppColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
