import 'package:bloc/bloc.dart';
import 'package:call/src/call_state.dart';

/// {@template call_cubit}
/// The call screen's state.
///
/// The design session seeds it directly; the build connects it to the
/// voice socket, whose `state` and `caption` messages move [CallState.phase]
/// and the captions, while the phone's recorder and player feed
/// [CallState.level].
/// {@endtemplate}
class CallCubit extends Cubit<CallState> {
  /// {@macro call_cubit}
  CallCubit({CallState initial = const CallState()}) : super(initial);

  /// Turns the microphone off or back on.
  void toggleMute() => emit(state.copyWith(muted: !state.muted));

  /// Hides or shows the agent's captions.
  void toggleCaptions() => emit(state.copyWith(captionsOn: !state.captionsOn));

  /// A new sentence from the agent: the one before fades.
  void captioned(String sentence) => emit(
    state.copyWith(
      previousCaption: () => state.caption,
      caption: () => sentence,
    ),
  );
}
