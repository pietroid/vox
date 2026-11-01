import 'package:app_ui/app_ui.dart';
import 'package:call_history/call_history.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:vox/app/app.dart';

/// {@template home_page}
/// The signed-in home: the way into a call with the agent.
///
/// Until the first call ends it is an invitation: the agent's presence,
/// "O que te traz aqui?" and one button for the first call. From then on it
/// is the history: a call-out to call again, and every call, newest first.
/// {@endtemplate}
class HomePage extends StatelessWidget {
  /// {@macro home_page}
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CallHistoryCubit(),
      child: const HomeView(),
    );
  }
}

/// {@template home_view}
/// The home over the [CallHistoryCubit] above it.
/// {@endtemplate}
class HomeView extends StatelessWidget {
  /// {@macro home_view}
  const HomeView({this.now, super.key});

  /// Today, fixed in a preview; the clock's otherwise.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final firstName = context.select<AppBloc, String?>(
      (bloc) => bloc.state.firstName,
    );
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          firstName == null
              ? l10n.homeGreetingAnonymous
              : l10n.homeGreeting(firstName),
        ),
        actions: [
          IconButton(
            tooltip: l10n.homeOpenAssistant,
            icon: const AppIcon(iconData: AppIcons.assistant),
            onPressed: () => context.push('/assistente'),
          ),
          IconButton(
            tooltip: l10n.homeSignOut,
            icon: const AppIcon(iconData: AppIcons.signOut),
            onPressed: () =>
                context.read<AppBloc>().add(const AppLogoutRequested()),
          ),
          const SizedBox(width: AppSpacing.s2),
        ],
      ),
      body: BlocBuilder<CallHistoryCubit, CallHistoryState>(
        builder: (context, state) => state.isFirstRun
            ? _FirstCall(goal: state.goal)
            : _History(calls: state.calls, now: now ?? DateTime.now()),
      ),
    );
  }
}

class _FirstCall extends StatelessWidget {
  const _FirstCall({required this.goal});

  final SpeakingGoal? goal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
            children: [
              const SizedBox(height: AppSpacing.s4),
              const Center(
                child: AppPresence(
                  state: AppPresenceState.speaking,
                  level: 0.55,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                l10n.homeOnboardingTitle,
                textAlign: TextAlign.center,
                style: AppTypography.headline,
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                l10n.homeOnboardingBody,
                textAlign: TextAlign.center,
                style: AppTypography.label,
              ),
              const SizedBox(height: AppSpacing.s8),
              GoalPicker(
                selected: goal,
                onSelected: context.read<CallHistoryCubit>().chooseGoal,
              ),
              const SizedBox(height: AppSpacing.s6),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s6,
              AppSpacing.s2,
              AppSpacing.s6,
              AppSpacing.s4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton.icon(
                  expand: true,
                  onPressed: () => context.push('/ligacao'),
                  icon: const AppIcon(
                    iconData: AppIcons.call,
                    color: AppColors.onAccent,
                  ),
                  text: l10n.homeFirstCallStart,
                ),
                const SizedBox(height: AppSpacing.s3),
                Text(l10n.homeFirstCallNote, style: AppTypography.caption),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.calls, required this.now});

  final List<CallRecord> calls;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final last = calls.first;
    final total = calls.fold(Duration.zero, (sum, c) => sum + c.duration);
    final firstDone = calls.length == 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s2,
        AppSpacing.s6,
        AppSpacing.s8,
      ),
      children: [
        AppCard(
          tone: AppCardTone.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstDone ? l10n.homeFirstDoneTitle : l10n.homeNextTitle,
                style: AppTypography.title,
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                firstDone
                    ? l10n.homeFirstDoneBody
                    : l10n.homeNextLastLearning(last.learnings.first),
                style: AppTypography.label.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.s4),
              AppButton.icon(
                expand: true,
                onPressed: () => context.push('/ligacao'),
                icon: const AppIcon(
                  iconData: AppIcons.call,
                  color: AppColors.onAccent,
                ),
                text: l10n.homeCallStart,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(l10n.historyTitle, style: AppTypography.title),
        const SizedBox(height: AppSpacing.s1),
        Text(
          l10n.historyTotals(calls.length, context.callDuration(total)),
          style: AppTypography.caption,
        ),
        const SizedBox(height: AppSpacing.s4),
        for (final call in calls)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s3),
            child: CallCard(
              call: call,
              now: now,
              onTap: () => context.push('/ligacoes/${call.id}'),
            ),
          ),
      ],
    );
  }
}
