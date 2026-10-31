import 'dart:typed_data';

import 'package:call/call.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  group('PlaybackClock', () {
    test('shows a caption when its audio starts playing, not before', () {
      final clock = PlaybackClock()
        ..caption('Primeira.')
        ..audio(voice(1))
        ..caption('Segunda.')
        ..audio(voice(1));

      expect(clock.advance(Duration.zero).captions, ['Primeira.']);
      expect(clock.playing, isTrue);
      expect(
        clock.advance(const Duration(milliseconds: 900)).captions,
        isEmpty,
      );
      expect(
        clock.advance(const Duration(milliseconds: 200)).captions,
        ['Segunda.'],
      );
      clock.advance(const Duration(seconds: 1));
      expect(clock.playing, isFalse);
    });

    test('follows the loudness of what is playing', () {
      final clock = PlaybackClock()
        ..audio(voice(0.5, amplitude: 300))
        ..audio(voice(0.5, amplitude: 16000));

      final quiet = clock.advance(const Duration(milliseconds: 100)).level;
      final loud = clock.advance(const Duration(milliseconds: 500)).level;

      expect(loud, greaterThan(quiet));
      expect(clock.advance(const Duration(seconds: 1)).level, 0);
    });

    test('drops everything queued when the person cuts in', () {
      final clock = PlaybackClock()
        ..audio(voice(2))
        ..caption('Nunca dita.')
        ..clear();

      expect(clock.playing, isFalse);
      expect(clock.advance(const Duration(seconds: 3)).captions, isEmpty);
    });
  });

  test('levelOf: silence is 0, a full-scale voice 1', () {
    expect(levelOf(Uint8List(100)), 0);
    expect(levelOf(voice(0.1, amplitude: 32000)), 1);
  });
}
