import 'package:app_ui/app_ui.dart';
import 'package:call/src/call_cubit.dart';
import 'package:call/src/call_service.dart';
import 'package:call/src/call_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

/// {@template call_page}
/// A call with the agent: you talk, it answers when you stop. No button
/// ends a turn; the pipeline decides, and Pensando shows that it did.
///
/// Hanging up pops the route with whether the call got through.
/// {@endtemplate}
class CallPage extends StatelessWidget {
  /// {@macro call_page}
  const CallPage({this.follows, super.key});

  /// The id of the call this one continues: the agent remembers it.
  final String? follows;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CallCubit(
        service: context.read<CallService>(),
        follows: follows,
      )..start().ignore(),
      child: const CallView(),
    );
  }
}

/// {@template call_view}
/// The call screen, below its [CallCubit]: who and how long at the top,
/// the agent's presence in the middle, its captions and three round
/// controls at the bottom.
/// {@endtemplate}
class CallView extends StatelessWidget {
  /// {@macro call_view}
  const CallView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<CallCubit>().state;
    final cubit = context.read<CallCubit>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s6,
                  AppSpacing.s8,
                  AppSpacing.s6,
                  AppSpacing.s6,
                ),
                child: Column(
                  children: [
                    Text(l10n.callTitle, style: AppTypography.barTitle),
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      _clock(state.elapsed),
                      style: AppTypography.caption.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Expanded(
                      child: Center(child: _Stage(state: state)),
                    ),
                    SizedBox(
                      height: AppSpacing.callCaptions,
                      child: state.captionsOn && state.live
                          // While the person has the turn, the agent's
                          // last sentence stays, faded.
                          ? state.phase == CallPhase.speaking
                                ? _Captions(
                                    caption: state.caption,
                                    previous: state.previousCaption,
                                  )
                                : _Captions(
                                    caption: null,
                                    previous:
                                        state.caption ?? state.previousCaption,
                                  )
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: AppSpacing.s5,
                      children: [
                        if (state.live) ...[
                          AppCallControl(
                            icon: state.muted
                                ? AppIcons.microphoneOff
                                : AppIcons.microphone,
                            label: state.muted
                                ? l10n.callUnmute
                                : l10n.callMute,
                            on: state.muted,
                            onPressed: cubit.toggleMute,
                          ),
                          AppCallControl(
                            icon: state.captionsOn
                                ? AppIcons.captions
                                : AppIcons.captionsOff,
                            label: state.captionsOn
                                ? l10n.callCaptionsHide
                                : l10n.callCaptionsShow,
                            on: !state.captionsOn,
                            onPressed: cubit.toggleCaptions,
                          ),
                        ],
                        AppCallControl.hangUp(
                          icon: AppIcons.hangUp,
                          label: l10n.callHangUp,
                          onPressed: () async {
                            await cubit.hangUp();
                            if (context.mounted) {
                              await Navigator.of(
                                context,
                              ).maybePop(cubit.connected);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _clock(Duration elapsed) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(elapsed.inMinutes)}:${two(elapsed.inSeconds % 60)}';
  }
}

/// The presence and the word under it, or why there is no call.
class _Stage extends StatelessWidget {
  const _Stage({required this.state});

  final CallState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final refusal = switch (state.phase) {
      CallPhase.unavailable => l10n.callUnavailable,
      CallPhase.dropped => l10n.callDropped,
      CallPhase.microphoneDenied => l10n.callMicrophoneDenied,
      _ => null,
    };
    if (refusal != null) {
      return Text(
        refusal,
        textAlign: TextAlign.center,
        style: AppTypography.body.copyWith(color: AppColors.ink2),
      );
    }

    final (presence, word) = switch (state.phase) {
      CallPhase.connecting => (AppPresenceState.muted, l10n.callConnecting),
      _ when state.muted && state.phase == CallPhase.listening => (
        AppPresenceState.muted,
        l10n.callMuted,
      ),
      CallPhase.listening => (AppPresenceState.listening, l10n.callListening),
      CallPhase.thinking => (AppPresenceState.thinking, l10n.callThinking),
      _ => (AppPresenceState.speaking, l10n.callSpeaking),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.s2,
      children: [
        AppPresence(state: presence, level: state.level),
        Text(word, style: AppTypography.caption),
      ],
    );
  }
}

/// The agent's captions: the sentence it says now at full ink, the one
/// before faded, so they read as speech going by, not as a transcript.
class _Captions extends StatelessWidget {
  const _Captions({required this.caption, required this.previous});

  final String? caption;
  final String? previous;

  @override
  Widget build(BuildContext context) {
    final previous = this.previous;
    final caption = this.caption;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      spacing: AppSpacing.s2,
      children: [
        if (previous != null)
          Text(
            previous,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(color: AppColors.ink3),
          ),
        if (caption != null)
          Text(
            caption,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body,
          ),
      ],
    );
  }
}
