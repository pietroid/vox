import 'dart:async';
import 'dart:typed_data';

import 'package:call/call.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  group('CallCubit', () {
    test('dials, listens and sends the mic', () async {
      final service = FakeCallService();
      final cubit = CallCubit(service: service);
      addTearDown(cubit.close);

      await cubit.start();
      service.mic.controller.add(Uint8List(320));
      await pumpEventQueue();

      expect(cubit.state.phase, CallPhase.listening);
      expect(service.line.sent, hasLength(1));
      expect(cubit.connected, isTrue);
      expect(service.dialed, [null]);
    });

    test('a follow-up dials with the call it continues', () async {
      final service = FakeCallService();
      final cubit = CallCubit(service: service, follows: 'c1');
      addTearDown(cubit.close);

      await cubit.start();

      expect(service.dialed, ['c1']);
    });

    test('the socket says which call a follow-up continues', () {
      final service = ServerCallService(
        apiBaseUrl: 'https://vox.example/api',
        token: () async => null,
      );

      expect(
        service.uri(follows: 'c1').toString(),
        'wss://vox.example/api/assistant/voice?follows=c1',
      );
      expect(
        service.uri().toString(),
        'wss://vox.example/api/assistant/voice',
      );
    });

    test('says why there is no call', () async {
      for (final (service, phase) in [
        (FakeCallService(supported: false), CallPhase.unavailable),
        (FakeCallService(allowMic: false), CallPhase.microphoneDenied),
        (FakeCallService(fails: Exception('offline')), CallPhase.dropped),
      ]) {
        final cubit = CallCubit(service: service);
        await cubit.start();
        expect(cubit.state.phase, phase);
        expect(cubit.connected, isFalse);
        await cubit.close();
      }
    });

    test('follows the server: Pensando, then Falando while the voice plays, '
        'each caption with its audio', () {
      fakeAsync((async) {
        final service = FakeCallService();
        final cubit = CallCubit(service: service);
        unawaited(cubit.start());
        async.flushMicrotasks();
        final line = service.line.controller
          ..add(const VoicePhase(ServerPhase.thinking));
        async.flushMicrotasks();
        expect(cubit.state.phase, CallPhase.thinking);

        line
          ..add(const VoicePhase(ServerPhase.speaking))
          ..add(const VoiceCaption('Você falou rápido.'))
          ..add(VoiceAudio(voice(1)))
          ..add(const VoiceCaption('Vamos de novo?'))
          ..add(VoiceAudio(voice(1)))
          // The server is done long before the phone has played it all.
          ..add(const VoicePhase(ServerPhase.listening));
        async.flushMicrotasks();
        expect(cubit.state.phase, CallPhase.speaking);
        expect(cubit.state.caption, 'Você falou rápido.');
        expect(cubit.state.level, greaterThan(0));
        expect(service.speaker.played, hasLength(2));

        async.elapse(const Duration(milliseconds: 1100));
        expect(cubit.state.caption, 'Vamos de novo?');
        expect(cubit.state.previousCaption, 'Você falou rápido.');

        async.elapse(const Duration(seconds: 1));
        expect(cubit.state.phase, CallPhase.listening);
        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('stops the voice when the person cuts in', () {
      fakeAsync((async) {
        final service = FakeCallService();
        final cubit = CallCubit(service: service);
        unawaited(cubit.start());
        async.flushMicrotasks();

        service.line.controller
          ..add(const VoicePhase(ServerPhase.speaking))
          ..add(VoiceAudio(voice(3)))
          ..add(const VoiceInterrupt())
          ..add(const VoicePhase(ServerPhase.listening));
        async.flushMicrotasks();

        expect(service.speaker.clears, 1);
        expect(cubit.state.phase, CallPhase.listening);
        unawaited(cubit.close());
        async.flushMicrotasks();
      });
    });

    test('muted, sends nothing and tells the server', () async {
      final service = FakeCallService();
      final cubit = CallCubit(service: service);
      addTearDown(cubit.close);
      await cubit.start();

      cubit.toggleMute();
      service.mic.controller.add(Uint8List(320));
      await pumpEventQueue();

      expect(cubit.state.muted, isTrue);
      expect(service.line.mutes, [true]);
      expect(service.line.sent, isEmpty);
    });

    test(
      'shows the call unavailable or dropped when the server closes it',
      () async {
        for (final (code, phase) in [
          (VoiceLine.unavailable, CallPhase.unavailable),
          (1011, CallPhase.dropped),
          (null, CallPhase.dropped),
        ]) {
          final service = FakeCallService();
          final cubit = CallCubit(service: service);
          await cubit.start();

          service.line.controller.add(VoiceClosed(code));
          await pumpEventQueue();

          expect(cubit.state.phase, phase);
          expect(service.mic.stopped, isTrue);
          await cubit.close();
        }
      },
    );

    test('hanging up lets the socket, the mic and the speaker go', () async {
      final service = FakeCallService();
      final cubit = CallCubit(service: service);
      addTearDown(cubit.close);
      await cubit.start();

      await cubit.hangUp();

      expect(service.line.closed, isTrue);
      expect(service.mic.stopped, isTrue);
      expect(service.speaker.stopped, isTrue);
    });
  });
}
