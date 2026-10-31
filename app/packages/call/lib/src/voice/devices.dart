import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:record/record.dart' hide IosAudioCategory;

/// {@template microphone}
/// The phone's mic, streamed as PCM16 16 kHz mono with echo cancellation,
/// so the agent doesn't hear itself and cut itself off.
/// {@endtemplate}
abstract interface class Microphone {
  /// Whether the person lets the app use the mic; asks the first time.
  Future<bool> allowed();

  /// Starts listening.
  Future<Stream<Uint8List>> start();

  /// Stops and lets the mic go.
  Future<void> stop();
}

/// {@template voice_player}
/// Plays the agent's voice as it streams in, PCM16 24 kHz mono.
/// {@endtemplate}
abstract interface class VoicePlayer {
  /// Gets the audio ready.
  Future<void> start();

  /// Queues a piece of the voice.
  void play(Uint8List pcm);

  /// Drops what is queued: the person cut in.
  Future<void> clear();

  /// Lets the audio go.
  Future<void> stop();
}

/// {@macro microphone}
class RecordMicrophone implements Microphone {
  final _recorder = AudioRecorder();

  @override
  Future<bool> allowed() => _recorder.hasPermission();

  @override
  Future<Stream<Uint8List>> start() => _recorder.startStream(
    const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      echoCancel: true,
      noiseSuppress: true,
      // A call: the voice-communication path, where Android applies its
      // echo canceller.
      androidConfig: AndroidRecordConfig(
        audioSource: AndroidAudioSource.voiceCommunication,
      ),
    ),
  );

  @override
  Future<void> stop() async {
    await _recorder.stop();
    await _recorder.dispose();
  }
}

/// {@macro voice_player}
class PcmVoicePlayer implements VoicePlayer {
  /// {@macro voice_player}
  PcmVoicePlayer({this.sampleRate = 24000});

  /// Samples per second the server sends.
  final int sampleRate;

  Future<void> _setup() => FlutterPcmSound.setup(
    sampleRate: sampleRate,
    channelCount: 1,
    // Beside the mic, on the speaker.
    iosAudioCategory: IosAudioCategory.playAndRecord,
  );

  @override
  Future<void> start() async {
    await FlutterPcmSound.setLogLevel(LogLevel.none);
    await _setup();
  }

  @override
  void play(Uint8List pcm) {
    unawaited(
      FlutterPcmSound.feed(
        PcmArrayInt16(bytes: ByteData.sublistView(pcm)),
      ),
    );
  }

  @override
  Future<void> clear() async {
    // The plugin has no flush: let it go and set it up again.
    await FlutterPcmSound.release();
    await _setup();
  }

  @override
  Future<void> stop() => FlutterPcmSound.release();
}
