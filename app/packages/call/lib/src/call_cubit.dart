import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:call/src/call_service.dart';
import 'package:call/src/call_state.dart';
import 'package:call/src/voice/devices.dart';
import 'package:call/src/voice/playback_clock.dart';
import 'package:call/src/voice/voice_line.dart';

/// {@template call_cubit}
/// One call: the socket's `state` and `caption` messages move
/// [CallState.phase] and the captions; the mic's loudness and the played
/// voice's feed [CallState.level].
///
/// The phase is the server's, except that the phone says Falando for as
/// long as its player has the agent's voice to play, and a caption shows
/// when its audio starts playing, not when it arrives.
/// {@endtemplate}
class CallCubit extends Cubit<CallState> {
  /// {@macro call_cubit}
  CallCubit({
    required this._service,
    CallState initial = const CallState(),
  }) : super(initial);

  /// How often the clock, the rings and the timer move: ~20 times a second.
  static const tick = Duration(milliseconds: 50);

  final CallService _service;
  final _clock = PlaybackClock();
  final _started = Stopwatch();
  VoiceLine? _line;
  Microphone? _mic;
  VoicePlayer? _player;
  StreamSubscription<VoiceEvent>? _events;
  StreamSubscription<Uint8List>? _mic$;
  Timer? _ticker;
  ServerPhase _server = ServerPhase.listening;
  double _micLevel = 0;
  bool _ended = false;

  /// Dials: asks for the mic, opens the socket, starts listening.
  Future<void> start() async {
    if (!_service.supported) {
      emit(state.copyWith(phase: CallPhase.unavailable));
      return;
    }
    final mic = _service.microphone();
    _mic = mic;
    if (!await mic.allowed()) {
      emit(state.copyWith(phase: CallPhase.microphoneDenied));
      return;
    }
    try {
      final line = await _service.dial();
      if (_ended) {
        await line.close();
        return;
      }
      _line = line;
      _events = line.events.listen(_onEvent);
      final player = _service.player();
      _player = player;
      await player.start();
      _mic$ = (await mic.start()).listen(_onMic);
    } on Object {
      if (!_ended) emit(state.copyWith(phase: CallPhase.dropped));
      await _release();
      return;
    }
    _started.start();
    _ticker = Timer.periodic(tick, (_) => _onTick());
    emit(state.copyWith(phase: CallPhase.listening));
  }

  /// Turns the microphone off or back on. The server keeps listening to
  /// silence meanwhile, so the call stays up.
  void toggleMute() {
    if (!state.live) return;
    final muted = !state.muted;
    _line?.mute(muted: muted);
    emit(state.copyWith(muted: muted));
  }

  /// Hides or shows the agent's captions.
  void toggleCaptions() => emit(state.copyWith(captionsOn: !state.captionsOn));

  /// A new sentence from the agent: the one before fades.
  void captioned(String sentence) => emit(
    state.copyWith(
      previousCaption: () => state.caption,
      caption: () => sentence,
    ),
  );

  /// Ends the call: the socket, the mic and the speaker all let go.
  Future<void> hangUp() async {
    _ended = true;
    await _release();
  }

  void _onMic(Uint8List pcm) {
    if (state.muted) {
      _micLevel = 0;
      return;
    }
    _line?.sendAudio(pcm);
    _micLevel = levelOf(pcm);
  }

  void _onEvent(VoiceEvent event) {
    switch (event) {
      case VoicePhase(:final phase):
        _server = phase;
      case VoiceCaption(:final text):
        _clock.caption(text);
      case VoiceAudio(:final pcm):
        _clock.audio(pcm);
        _player?.play(pcm);
      case VoiceInterrupt():
        _clock.clear();
        unawaited(_player?.clear());
      case VoiceClosed(:final code):
        if (_ended) return;
        _ended = true;
        unawaited(_release());
        emit(
          state.copyWith(
            phase: code == VoiceLine.unavailable
                ? CallPhase.unavailable
                : CallPhase.dropped,
            level: 0,
          ),
        );
        return;
    }
    _onTick(Duration.zero);
  }

  void _onTick([Duration elapsed = tick]) {
    if (_ended || isClosed) return;
    final played = _clock.advance(elapsed);
    played.captions.forEach(captioned);
    final phase = _clock.playing
        ? CallPhase.speaking
        : switch (_server) {
            ServerPhase.listening => CallPhase.listening,
            ServerPhase.thinking => CallPhase.thinking,
            // Between two sentences: the next one's audio is on its way.
            ServerPhase.speaking => CallPhase.speaking,
          };
    final level = switch (phase) {
      CallPhase.speaking => played.level,
      CallPhase.listening when !state.muted => _micLevel,
      _ => 0.0,
    };
    emit(
      state.copyWith(
        phase: phase,
        level: level,
        elapsed: Duration(seconds: _started.elapsed.inSeconds),
      ),
    );
  }

  Future<void> _release() async {
    _ticker?.cancel();
    _started.stop();
    unawaited(_mic$?.cancel());
    unawaited(_events?.cancel());
    final line = _line;
    final mic = _mic;
    final player = _player;
    _line = null;
    _mic = null;
    _player = null;
    await Future.wait([
      if (line != null) line.close(),
      if (mic != null) mic.stop(),
      if (player != null) player.stop(),
    ]);
  }

  @override
  Future<void> close() async {
    _ended = true;
    await _release();
    return super.close();
  }
}
