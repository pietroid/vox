import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

/// {@template playback_clock}
/// Where the phone's player is in the agent's voice.
///
/// Audio arrives faster than it plays, so a caption that arrives with its
/// audio must wait until the player reaches it, and the rings must follow
/// the audio being heard, not the audio being received. The clock queues
/// both on one timeline and is advanced by the call's ticker.
/// {@endtemplate}
class PlaybackClock {
  /// {@macro playback_clock}
  PlaybackClock({this.sampleRate = 24000});

  /// Samples per second of the voice.
  final int sampleRate;

  final _queue = Queue<_Mark>();
  Duration _position = Duration.zero;
  Duration _end = Duration.zero;

  /// Whether audio is still to be heard.
  bool get playing => _position < _end;

  /// Queues a piece of the voice, PCM16 little-endian.
  void audio(Uint8List pcm) {
    final samples = pcm.length ~/ 2;
    if (samples == 0) return;
    final length = Duration(microseconds: samples * 1000000 ~/ sampleRate);
    _queue.add(_Mark(at: _end, length: length, level: levelOf(pcm)));
    _end += length;
  }

  /// Queues a caption at the end of the audio queued so far.
  void caption(String text) => _queue.add(_Mark(at: _end, caption: text));

  /// Drops everything queued: the person cut in.
  void clear() {
    _queue.clear();
    _position = _end;
  }

  /// Moves the player on by [elapsed]: the captions it reached, and the
  /// loudness where it now is (0 when nothing plays).
  ({List<String> captions, double level}) advance(Duration elapsed) {
    _position = _position + elapsed > _end ? _end : _position + elapsed;
    final captions = <String>[];
    var level = 0.0;
    while (_queue.isNotEmpty && _queue.first.at <= _position) {
      final mark = _queue.first;
      if (mark.caption != null) {
        captions.add(mark.caption!);
        _queue.removeFirst();
      } else if (mark.at + mark.length! <= _position) {
        _queue.removeFirst();
      } else {
        level = mark.level;
        break;
      }
    }
    return (captions: captions, level: playing ? level : 0);
  }
}

class _Mark {
  _Mark({required this.at, this.length, this.level = 0, this.caption});

  final Duration at;
  final Duration? length;
  final double level;
  final String? caption;
}

/// How loud a chunk of PCM16 is, 0 to 1: −50 dBFS and below is 0, −10
/// dBFS and above is 1, a voice in between.
double levelOf(Uint8List pcm) {
  final data = ByteData.sublistView(pcm);
  final samples = pcm.length ~/ 2;
  if (samples == 0) return 0;
  var energy = 0.0;
  for (var i = 0; i < samples; i++) {
    final x = data.getInt16(i * 2, Endian.little) / 32768;
    energy += x * x;
  }
  final db = 20 * math.log(math.sqrt(energy / samples) + 1e-9) / math.ln10;
  return ((db + 50) / 40).clamp(0, 1).toDouble();
}
