import 'dart:async';
import 'dart:typed_data';

import 'package:call/call.dart';

/// The server's end, driven by the test.
class FakeVoiceLine implements VoiceLine {
  final controller = StreamController<VoiceEvent>();
  final sent = <Uint8List>[];
  final mutes = <bool>[];
  bool closed = false;

  @override
  Stream<VoiceEvent> get events => controller.stream;

  @override
  void sendAudio(Uint8List pcm) => sent.add(pcm);

  @override
  void mute({required bool muted}) => mutes.add(muted);

  @override
  Future<void> close() async => closed = true;
}

class FakeMicrophone implements Microphone {
  FakeMicrophone({this.allow = true});

  final bool allow;
  final controller = StreamController<Uint8List>();
  bool stopped = false;

  @override
  Future<bool> allowed() async => allow;

  @override
  Future<Stream<Uint8List>> start() async => controller.stream;

  @override
  Future<void> stop() async => stopped = true;
}

class FakeVoicePlayer implements VoicePlayer {
  final played = <Uint8List>[];
  int clears = 0;
  bool stopped = false;

  @override
  Future<void> start() async {}

  @override
  void play(Uint8List pcm) => played.add(pcm);

  @override
  Future<void> clear() async => clears++;

  @override
  Future<void> stop() async => stopped = true;
}

class FakeCallService implements CallService {
  FakeCallService({this.supported = true, bool allowMic = true, this.fails})
    : mic = FakeMicrophone(allow: allowMic);

  @override
  final bool supported;
  final Exception? fails;
  final line = FakeVoiceLine();
  final FakeMicrophone mic;
  final speaker = FakeVoicePlayer();

  @override
  Future<VoiceLine> dial() async {
    if (fails != null) throw fails!;
    return line;
  }

  @override
  Microphone microphone() => mic;

  @override
  VoicePlayer player() => speaker;
}

/// [seconds] of a 24 kHz voice at a steady loudness.
Uint8List voice(double seconds, {int amplitude = 8000, int rate = 24000}) {
  final samples = (seconds * rate).round();
  final data = ByteData(samples * 2);
  for (var i = 0; i < samples; i++) {
    data.setInt16(i * 2, i.isEven ? amplitude : -amplitude, Endian.little);
  }
  return data.buffer.asUint8List();
}
