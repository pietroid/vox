import 'package:app_ui/app_ui.dart';
import 'package:call_history/src/coach.dart';
import 'package:l10n/l10n.dart';

/// Opens the [CoachPicker] as a sheet; answers the coach picked, or null
/// when the sheet is dismissed.
Future<Coach?> showCoachPicker(
  BuildContext context, {
  Coach? initial,
  ValueChanged<Coach>? onListen,
}) {
  return showModalBottomSheet<Coach>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (_) => CoachPicker(initial: initial, onListen: onListen),
  );
}

/// {@template coach_picker}
/// "Novo assunto": the four coaches, two by language, and one button that
/// starts the subject's first call with the one picked. A coach stays with
/// the subject: every follow-up calls them again.
/// {@endtemplate}
class CoachPicker extends StatefulWidget {
  /// {@macro coach_picker}
  const CoachPicker({this.initial, this.onListen, super.key});

  /// The coach picked when it opens: the last one used.
  final Coach? initial;

  /// Plays a coach's voice; the speaker button is hidden without it.
  final ValueChanged<Coach>? onListen;

  @override
  State<CoachPicker> createState() => _CoachPickerState();
}

class _CoachPickerState extends State<CoachPicker> {
  late Coach _coach = widget.initial ?? Coach.bianca;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s6,
          0,
          AppSpacing.s6,
          AppSpacing.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppIcon(
                  iconData: AppIcons.newSubject,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.s3),
                Text(l10n.coachPickerTitle, style: AppTypography.headline),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(l10n.coachPickerBody, style: AppTypography.label),
            for (final language in CoachLanguage.values) ...[
              const SizedBox(height: AppSpacing.s6),
              Text(
                language.label(l10n),
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppSpacing.s2),
              Row(
                spacing: AppSpacing.s3,
                children: [
                  for (final coach in Coach.values)
                    if (coach.language == language)
                      Expanded(
                        child: _CoachTile(
                          coach: coach,
                          selected: coach == _coach,
                          onPressed: () => setState(() => _coach = coach),
                          onListen: widget.onListen == null
                              ? null
                              : () => widget.onListen!(coach),
                        ),
                      ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.s8),
            AppButton.icon(
              expand: true,
              onPressed: () => Navigator.pop(context, _coach),
              icon: const AppIcon(
                iconData: AppIcons.call,
                color: AppColors.onAccent,
              ),
              text: l10n.coachPickerStart(_coach.label(l10n)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachTile extends StatelessWidget {
  const _CoachTile({
    required this.coach,
    required this.selected,
    required this.onPressed,
    required this.onListen,
  });

  final Coach coach;
  final bool selected;
  final VoidCallback onPressed;
  final VoidCallback? onListen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = coach.label(l10n);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.accentSoft : AppColors.fill,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppSpacing.chipRadius),
          ),
          side: BorderSide(
            color: selected ? AppColors.accent : Colors.transparent,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Row(
              children: [
                AppAvatar(name: name, selected: selected),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Text(
                    name,
                    style: AppTypography.labelStrong.copyWith(
                      color: selected ? AppColors.ink : AppColors.ink2,
                    ),
                  ),
                ),
                if (onListen != null)
                  IconButton(
                    tooltip: l10n.coachPickerListen(name),
                    visualDensity: VisualDensity.compact,
                    onPressed: onListen,
                    icon: AppIcon(
                      iconData: AppIcons.listen,
                      size: AppSpacing.iconSmall + 2,
                      color: selected ? AppColors.accent : AppColors.ink3,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
