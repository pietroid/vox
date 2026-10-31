import 'dart:typed_data';

/// What the server says on a call, one event per message of
/// `wss /api/assistant/voice`.
sealed class VoiceEvent {
  const VoiceEvent();
}

/// Where the server's side of the call is.
enum ServerPhase {
  /// The person has the turn.
  listening,

  /// Their turn ended; the reply's first audio hasn't come.
  thinking,

  /// The reply is being spoken.
  speaking,
}

/// `{type: state}`: the server's phase changed.
class VoicePhase extends VoiceEvent {
  /// The server's phase changed to [phase].
  const VoicePhase(this.phase);

  /// The new phase.
  final ServerPhase phase;
}

/// `{type: caption}`: the sentence whose audio comes next.
class VoiceCaption extends VoiceEvent {
  /// The sentence [text], sent just before its audio.
  const VoiceCaption(this.text);

  /// The sentence.
  final String text;
}

/// A binary frame: the agent's voice, PCM16 24 kHz mono.
class VoiceAudio extends VoiceEvent {
  /// A piece of the agent's voice.
  const VoiceAudio(this.pcm);

  /// The samples, little-endian.
  final Uint8List pcm;
}

/// `{type: interrupt}`: the person cut in; drop what is queued.
class VoiceInterrupt extends VoiceEvent {
  /// The person cut in.
  const VoiceInterrupt();
}

/// The socket closed, with the server's close code when it gave one.
class VoiceClosed extends VoiceEvent {
  /// The socket closed with [code].
  const VoiceClosed(this.code);

  /// [VoiceLine.unavailable], [VoiceLine.unauthorized], 1011 when the
  /// call dropped, or null when the network went.
  final int? code;
}

/// {@template voice_line}
/// The call's socket: the mic goes out, the server's events come in.
/// {@endtemplate}
abstract interface class VoiceLine {
  /// The server has no voice to offer.
  static const unavailable = 4503;

  /// The session is gone; signing in again fixes it.
  static const unauthorized = 4401;

  /// Everything the server says, ending with [VoiceClosed].
  Stream<VoiceEvent> get events;

  /// A chunk of the mic, PCM16 16 kHz mono.
  void sendAudio(Uint8List pcm);

  /// Tells the server the mic is off, so it keeps the listener alive.
  void mute({required bool muted});

  /// Hangs up.
  Future<void> close();
}
