import 'package:app_ui/app_ui.dart';
import 'package:call_history/src/call_format.dart';
import 'package:call_history/src/call_record.dart';
import 'package:l10n/l10n.dart';

/// {@template call_card}
/// One call in the history: when, what about, the first thing learned,
/// and how long and how much. The whole card opens the call.
/// {@endtemplate}
class CallCard extends StatelessWidget {
  /// {@macro call_card}
  const CallCard({
    required this.call,
    required this.now,
    required this.onTap,
    super.key,
  });

  /// The call.
  final CallRecord call;

  /// Today, for "Hoje" and "Ontem".
  final DateTime now;

  /// Opens the call's detail.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final learning = call.learnings.isEmpty ? null : call.learnings.first;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.callWhen(call.startedAt, now),
                style: AppTypography.caption,
              ),
              if (!call.seen) ...[
                const SizedBox(width: AppSpacing.s2),
                const _NewBadge(),
              ],
              const Spacer(),
              const AppIcon(
                iconData: AppIcons.chevron,
                size: AppSpacing.iconSmall + 2,
                color: AppColors.ink3,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            call.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyStrong,
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            call.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label,
          ),
          if (learning != null) ...[
            const SizedBox(height: AppSpacing.s3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppIcon(
                  iconData: AppIcons.learning,
                  size: AppSpacing.iconSmall + 2,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: Text(
                    learning,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelStrong,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.s4),
          Wrap(
            spacing: AppSpacing.s4,
            runSpacing: AppSpacing.s2,
            children: [
              AppMeta(
                icon: AppIcons.duration,
                text: context.callDuration(call.duration),
              ),
              AppMeta(
                icon: AppIcons.cost,
                text: context.callCost(call.costUsd),
              ),
              if (call.subjectIndex > 1)
                AppMeta(
                  icon: AppIcons.followUp,
                  text: l10n.callSubjectIndex(call.subjectIndex),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.pillRadius)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s2,
          vertical: AppSpacing.s1 / 2,
        ),
        child: Text(
          context.l10n.callNew,
          style: AppTypography.caption.copyWith(color: AppColors.onAccent),
        ),
      ),
    );
  }
}
