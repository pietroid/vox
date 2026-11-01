import 'package:app_ui/app_ui.dart';
import 'package:call_history/src/speaking_goal.dart';
import 'package:l10n/l10n.dart';

/// {@template goal_picker}
/// "O que te traz aqui?": one chip per [SpeakingGoal], and once one is
/// picked, a line saying what the first call will do about it.
///
/// Picking is optional; the first call works without it.
/// {@endtemplate}
class GoalPicker extends StatelessWidget {
  /// {@macro goal_picker}
  const GoalPicker({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// The goal picked, if any.
  final SpeakingGoal? selected;

  /// Called with the goal tapped.
  final ValueChanged<SpeakingGoal> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final goal = selected;

    return Column(
      children: [
        Text(l10n.homeGoalQuestion, style: AppTypography.title),
        const SizedBox(height: AppSpacing.s1),
        Text(
          l10n.homeGoalHint,
          textAlign: TextAlign.center,
          style: AppTypography.label,
        ),
        const SizedBox(height: AppSpacing.s4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          children: [
            for (final g in SpeakingGoal.values)
              AppChoiceChip(
                icon: g.icon,
                label: g.label(l10n),
                selected: g == goal,
                onPressed: () => onSelected(g),
              ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: goal == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppIcon(
                        iconData: AppIcons.call,
                        size: AppSpacing.iconSmall + 2,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      Expanded(
                        child: Text(
                          goal.plan(l10n),
                          style: AppTypography.label.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
