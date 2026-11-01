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
                  children: [
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
                    if (call.subjectIndex > 1)
                      AppMeta(
                        boxed: true,
                        icon: AppIcons.followUp,
                        text: l10n.callSubjectIndex(call.subjectIndex),
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
                        child: _Metric(
                          icon: AppIcons.pace,
                          value: metrics.wordsPerMinute,
                          label: l10n.metricPace,
                          delta: metrics.wordsPerMinuteDelta,
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          icon: AppIcons.pauses,
                          value: metrics.longPauses,
                          label: l10n.metricPauses,
                          delta: metrics.longPausesDelta,
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          icon: AppIcons.hesitations,
                          value: metrics.hesitations,
                          label: l10n.metricHesitations,
                          delta: metrics.hesitationsDelta,
                          // The one number with a good direction: pace and
                          // pauses depend on the talk, so they stay neutral.
                          fewerIsBetter: true,
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
                  AppSpacing.s6,
                  AppSpacing.s4,
                  AppSpacing.s6,
                  AppSpacing.s4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.callFollowUpNote,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    AppButton.icon(
                      expand: true,
                      onPressed: onFollowUp,
                      icon: const AppIcon(
                        iconData: AppIcons.call,
                        color: AppColors.onAccent,
                      ),
                      text: l10n.callFollowUpStart,
                    ),
                  ],
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

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.delta,
    this.fewerIsBetter = false,
  });

  final AppIconData icon;
  final int value;
  final String label;
  final int? delta;
  final bool fewerIsBetter;

  @override
  Widget build(BuildContext context) {
    final d = delta;
    final better = fewerIsBetter && d != null && d < 0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            iconData: icon,
            size: AppSpacing.iconSmall + 2,
            color: AppColors.ink2,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text('$value', style: AppTypography.headline),
          Text(label, style: AppTypography.caption),
          if (d != null && d != 0) ...[
            const SizedBox(height: AppSpacing.s1),
            Text(
              context.l10n.metricSinceFirst(d > 0 ? '+$d' : '−${-d}'),
              style: AppTypography.caption.copyWith(
                color: better ? AppColors.positive : AppColors.ink2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
