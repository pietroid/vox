import 'package:app_ui/app_ui.dart';
import 'package:call_history/src/call_format.dart';
import 'package:call_history/src/call_record.dart';
import 'package:l10n/l10n.dart';

/// {@template call_detail_page}
/// One call, opened: its facts, the summary, what to take from it and the
/// numbers, with one button at the foot that calls again on the same
/// subject, so the agent picks up where this call left off.
/// {@endtemplate}
class CallDetailPage extends StatelessWidget {
  /// {@macro call_detail_page}
  const CallDetailPage({
    required this.call,
    required this.now,
    required this.onFollowUp,
    super.key,
  });

  /// The call.
  final CallRecord call;

  /// Today, for "Hoje" and "Ontem".
  final DateTime now;

  /// Starts a call that follows this one up.
  final VoidCallback onFollowUp;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metrics = call.metrics;

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
                Text(
                  context.callWhen(call.startedAt, now),
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(call.title, style: AppTypography.headline),
                const SizedBox(height: AppSpacing.s4),
                Wrap(
                  spacing: AppSpacing.s2,
                  runSpacing: AppSpacing.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppAvatar(
                      name: call.coach.label(l10n),
                      tag: call.coach.language.tag(l10n),
                      size: AppSpacing.badge + AppSpacing.s1,
                    ),
                    AppMeta(
                      boxed: true,
                      icon: AppIcons.duration,
                      text: context.callDuration(call.duration, seconds: true),
                    ),
                    AppMeta(
                      boxed: true,
                      icon: AppIcons.cost,
                      text: context.callCost(call.costUsd),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                _Section(title: l10n.callDetailSummary),
                Text(call.summary, style: AppTypography.body),
                if (call.learnings.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s8),
                  _Section(title: l10n.callDetailLearnings),
                  for (final (i, learning) in call.learnings.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                      child: _Learning(number: i + 1, text: learning),
                    ),
                ],
                if (metrics != null) ...[
                  const SizedBox(height: AppSpacing.s6),
                  _Section(title: l10n.callDetailNumbers),
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
                          // The one number with a good direction: pace and
                          // pauses depend on the talk, so they stay neutral.
                          lowerIsBetter: true,
                        ),
                      ),
                    ],
                  ),
                ],
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s4,
                  AppSpacing.s4,
                  AppSpacing.s4,
                ),
                child: AppButton.icon(
                  expand: true,
                  onPressed: onFollowUp,
                  icon: const AppIcon(
                    iconData: AppIcons.call,
                    color: AppColors.onAccent,
                  ),
                  text: l10n.subjectContinue(call.coach.label(l10n)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Text(title, style: AppTypography.title),
    );
  }
}

class _Learning extends StatelessWidget {
  const _Learning({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSpacing.badge,
          height: AppSpacing.badge,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.accentSoft,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: AppTypography.labelStrong.copyWith(color: AppColors.accent),
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s1 / 2),
            child: Text(text, style: AppTypography.body),
          ),
        ),
      ],
    );
  }
}
