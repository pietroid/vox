import 'package:app_ui/app_ui.dart';
import 'package:call_history/src/call_format.dart';
import 'package:call_history/src/call_record.dart';
import 'package:call_history/src/call_subject.dart';
import 'package:l10n/l10n.dart';

/// {@template subject_page}
/// One subject, opened: what it is about, who coaches it, how the numbers
/// moved since its first call, and its calls, newest first. One button at
/// the foot calls the same coach again on it.
/// {@endtemplate}
class SubjectPage extends StatelessWidget {
  /// {@macro subject_page}
  const SubjectPage({
    required this.subject,
    required this.now,
    required this.onOpenCall,
    required this.onContinue,
    super.key,
  });

  /// The subject.
  final CallSubject subject;

  /// Today, for "Hoje" and "Ontem".
  final DateTime now;

  /// Opens one of its calls.
  final ValueChanged<CallRecord> onOpenCall;

  /// Starts a call that follows the newest one up, with the same coach.
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final coach = subject.coach;
    final coachName = coach.label(l10n);
    final metrics = subject.metrics;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const AppIcon(iconData: AppIcons.back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s6,
                AppSpacing.s2,
                AppSpacing.s6,
                AppSpacing.s8,
              ),
              children: [
                Text(subject.title, style: AppTypography.headline),
                const SizedBox(height: AppSpacing.s4),
                Row(
                  children: [
                    AppAvatar(
                      name: coachName,
                      tag: coach.language.tag(l10n),
                      size: AppSpacing.badge + AppSpacing.s1,
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    Text(coachName, style: AppTypography.labelStrong),
                    const Spacer(),
                    AppMeta(
                      boxed: true,
                      icon: AppIcons.calls,
                      text: '${subject.calls.length}',
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    AppMeta(
                      boxed: true,
                      icon: AppIcons.duration,
                      text: context.callDuration(subject.duration),
                    ),
                  ],
                ),
                if (metrics != null) ...[
                  const SizedBox(height: AppSpacing.s6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.s2,
                    children: [
                      Expanded(
                        child: AppStat(
                          icon: AppIcons.pace,
                          value: '${metrics.wordsPerMinute}',
                          label: l10n.metricPace,
                          delta: metrics.wordsPerMinuteDelta,
                        ),
                      ),
                      Expanded(
                        child: AppStat(
                          icon: AppIcons.pauses,
                          value: '${metrics.longPauses}',
                          label: l10n.metricPauses,
                          delta: metrics.longPausesDelta,
                        ),
                      ),
                      Expanded(
                        child: AppStat(
                          icon: AppIcons.hesitations,
                          value: '${metrics.hesitations}',
                          label: l10n.metricHesitations,
                          delta: metrics.hesitationsDelta,
                          lowerIsBetter: true,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.s8),
                Text(l10n.subjectCallsTitle, style: AppTypography.title),
                const SizedBox(height: AppSpacing.s3),
                for (final call in subject.calls)
                  _CallRow(
                    call: call,
                    now: now,
                    onTap: () => onOpenCall(call),
                  ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.bg,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: AppButton.icon(
                  expand: true,
                  onPressed: onContinue,
                  icon: const AppIcon(
                    iconData: AppIcons.call,
                    color: AppColors.onAccent,
                  ),
                  text: l10n.subjectContinue(coachName),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One call of the subject: which one it is, its title, when and how long.
class _CallRow extends StatelessWidget {
  const _CallRow({required this.call, required this.now, required this.onTap});

  final CallRecord call;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(
        Radius.circular(AppSpacing.chipRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
        child: Row(
          children: [
            Container(
              width: AppSpacing.badge,
              height: AppSpacing.badge,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: call.seen ? AppColors.fill : AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Text(
                context.l10n.callSubjectIndexShort(call.subjectIndex),
                style: AppTypography.caption.copyWith(
                  color: call.seen ? AppColors.ink2 : AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    call.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelStrong,
                  ),
                  const SizedBox(height: AppSpacing.s1 / 2),
                  Wrap(
                    spacing: AppSpacing.s3,
                    children: [
                      Text(
                        context.callWhen(call.startedAt, now),
                        style: AppTypography.caption,
                      ),
                      AppMeta(
                        icon: AppIcons.duration,
                        text: context.callDuration(call.duration),
                      ),
                      if (call.learnings.isNotEmpty)
                        AppMeta(
                          icon: AppIcons.learning,
                          text: '${call.learnings.length}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const AppIcon(
              iconData: AppIcons.chevron,
              size: AppSpacing.iconSmall + 2,
              color: AppColors.ink3,
            ),
          ],
        ),
      ),
    );
  }
}
