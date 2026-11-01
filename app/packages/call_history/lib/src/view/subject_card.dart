import 'package:app_ui/app_ui.dart';
import 'package:call_history/src/call_format.dart';
import 'package:call_history/src/call_subject.dart';
import 'package:l10n/l10n.dart';

/// {@template subject_card}
/// One subject on the home: its coach, what it is about, and three facts
/// as glyphs (the last call, how many, how long in all). The whole card
/// opens the subject.
/// {@endtemplate}
class SubjectCard extends StatelessWidget {
  /// {@macro subject_card}
  const SubjectCard({
    required this.subject,
    required this.now,
    required this.onTap,
    super.key,
  });

  /// The subject.
  final CallSubject subject;

  /// Today, for "Hoje" and "Ontem".
  final DateTime now;

  /// Opens the subject's page.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final coach = subject.coach;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Row(
        children: [
          AppAvatar(
            name: coach.label(l10n),
            tag: coach.language.tag(l10n),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyStrong,
                ),
                const SizedBox(height: AppSpacing.s2),
                Wrap(
                  spacing: AppSpacing.s3,
                  runSpacing: AppSpacing.s1,
                  children: [
                    Text(
                      context.callWhen(subject.latest.startedAt, now),
                      style: AppTypography.caption,
                    ),
                    if (subject.calls.length > 1)
                      AppMeta(
                        icon: AppIcons.calls,
                        text: '${subject.calls.length}',
                      ),
                    AppMeta(
                      icon: AppIcons.duration,
                      text: context.callDuration(subject.duration),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          if (subject.hasNew)
            Semantics(
              label: l10n.callNew,
              child: const SizedBox.square(
                dimension: AppSpacing.s2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            )
          else
            const AppIcon(
              iconData: AppIcons.chevron,
              size: AppSpacing.iconSmall + 2,
              color: AppColors.ink3,
            ),
        ],
      ),
    );
  }
}
