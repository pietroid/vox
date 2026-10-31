import 'package:equatable/equatable.dart';

/// Where a call is. Every phase is an event the voice pipeline already
/// has; the screen infers nothing on its own.
enum CallPhase {
  /// The socket to the server is opening.
  connecting,

  /// The person has the turn (Flux STT's start of turn).
  listening,

  /// The turn ended (Flux STT's end of turn) and the reply's first audio
  /// has not arrived.
  thinking,

  /// The agent's audio is playing; back to [listening] when it drains.
  speaking,

  /// The server has no voice to offer (it closed with 4503), or this
  /// platform can't call yet.
  unavailable,

  /// The person didn't let the app use the mic.
  microphoneDenied,

  /// The connection fell mid-call.
  dropped,
}

/// {@template call_state}
/// What the call screen draws.
/// {@endtemplate}
class CallState extends Equatable {
  /// {@macro call_state}
  const CallState({
    this.phase = CallPhase.connecting,
    this.muted = false,
    this.captionsOn = true,
    this.caption,
    this.previousCaption,
    this.elapsed = Duration.zero,
    this.level = 0,
  });

  /// Where the call is.
  final CallPhase phase;

  /// Whether the person's microphone is off. The server keeps the
  /// listener alive meanwhile.
  final bool muted;

  /// Whether the agent's captions show.
  final bool captionsOn;

  /// The sentence the agent is saying now, as sent to its voice.
  final String? caption;

  /// The sentence the agent said before [caption], fading.
  final String? previousCaption;

  /// How long the call has lasted.
  final Duration elapsed;

  /// The loudness of whoever is talking, 0 to 1, about twenty times a
  /// second, measured on the phone.
  final double level;

  /// Whether the call is up and the controls work.
  bool get live =>
      phase == CallPhase.listening ||
      phase == CallPhase.thinking ||
      phase == CallPhase.speaking;

  /// A copy with the given fields replaced.
  CallState copyWith({
    CallPhase? phase,
    bool? muted,
    bool? captionsOn,
    String? Function()? caption,
    String? Function()? previousCaption,
    Duration? elapsed,
    double? level,
  }) {
    return CallState(
      phase: phase ?? this.phase,
      muted: muted ?? this.muted,
      captionsOn: captionsOn ?? this.captionsOn,
      caption: caption != null ? caption() : this.caption,
      previousCaption: previousCaption != null
          ? previousCaption()
          : this.previousCaption,
      elapsed: elapsed ?? this.elapsed,
      level: level ?? this.level,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    muted,
    captionsOn,
    caption,
    previousCaption,
    elapsed,
    level,
  ];
}
