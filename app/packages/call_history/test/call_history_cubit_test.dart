import 'package:bloc_test/bloc_test.dart';
import 'package:call_history/call_history.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/helpers.dart';

void main() {
  group('CallHistoryCubit', () {
    late FakeHistoryRepository repository;

    setUp(() => repository = FakeHistoryRepository());

    CallHistoryCubit cubit() => CallHistoryCubit(
      repository: repository,
      retryEvery: Duration.zero,
      retries: 3,
    );

    blocTest<CallHistoryCubit, CallHistoryState>(
      'loads the calls and the goal',
      setUp: () {
        repository
          ..calls = [record()]
          ..goal = SpeakingGoal.calm;
      },
      build: cubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const CallHistoryState(status: CallHistoryStatus.loading),
        CallHistoryState(calls: [record()], goal: SpeakingGoal.calm),
      ],
    );

    blocTest<CallHistoryCubit, CallHistoryState>(
      'says when it could not load',
      setUp: () => repository.fails = Exception('offline'),
      build: cubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const CallHistoryState(status: CallHistoryStatus.loading),
        const CallHistoryState(status: CallHistoryStatus.failed),
      ],
    );

    blocTest<CallHistoryCubit, CallHistoryState>(
      'shows a picked goal at once and saves it',
      build: cubit,
      act: (cubit) => cubit.chooseGoal(SpeakingGoal.interviews),
      expect: () => [
        const CallHistoryState(
          status: CallHistoryStatus.loading,
          goal: SpeakingGoal.interviews,
        ),
      ],
      verify: (_) => expect(repository.goals, [SpeakingGoal.interviews]),
    );

    blocTest<CallHistoryCubit, CallHistoryState>(
      'an opened call stops being new, here and on the server',
      build: cubit,
      seed: () => CallHistoryState(calls: [record(seen: false)]),
      act: (cubit) => cubit.markSeen('c1'),
      expect: () => [
        CallHistoryState(calls: [record()]),
      ],
      verify: (_) => expect(repository.seen, ['c1']),
    );

    test('after a call, reads until the new call shows up', () async {
      // The server writes the call on the second read after hang-up.
      repository.onLoad = (load) {
        if (load == 2) repository.calls = [record(id: 'c2'), record()];
      };
      final history = CallHistoryCubit(
        repository: repository,
        retryEvery: Duration.zero,
        initial: CallHistoryState(calls: [record()]),
      );
      final states = <CallHistoryState>[];
      final sub = history.stream.listen(states.add);

      await history.afterCall();

      expect(repository.loads, 2);
      expect(states.first.summarizing, isTrue);
      expect(history.state.summarizing, isFalse);
      expect(history.state.calls.map((it) => it.id), ['c2', 'c1']);
      await sub.cancel();
      await history.close();
    });

    test('gives up after its reads when no call was kept', () async {
      final history = cubit();

      await history.afterCall();

      expect(repository.loads, 3);
      expect(history.state.summarizing, isFalse);
      await history.close();
    });

    test('waits for nothing when the call never got through', () async {
      final history = cubit();

      await history.afterCall(connected: false);

      expect(repository.loads, 0);
      await history.close();
    });
  });

  group('CallRecord', () {
    test('reads the server\'s JSON', () {
      final call = CallRecord.fromJson(const {
        'id': 'c2',
        'startedAt': '2026-11-01T22:42:00.000Z',
        'durationMs': 372000,
        'costUsd': 0.0612,
        'title': 'Apresentação',
        'summary': 'Resumo.',
        'learnings': ['Pausar'],
        'metrics': {
          'wordsPerMinute': 148,
          'longPauses': 9,
          'hesitations': 3,
          'wordsPerMinuteDelta': -17,
        },
        'subjectIndex': 2,
        'seen': false,
      });

      expect(call.startedAt.toUtc(), DateTime.utc(2026, 11, 1, 22, 42));
      expect(call.startedAt.isUtc, isFalse);
      expect(call.duration, const Duration(minutes: 6, seconds: 12));
      expect(call.learnings, ['Pausar']);
      expect(call.metrics?.wordsPerMinuteDelta, -17);
      expect(call.metrics?.longPausesDelta, isNull);
      expect(call.subjectIndex, 2);
      expect(call.seen, isFalse);
      expect(call.asSeen().seen, isTrue);
    });

    test('a call with no numbers has none', () {
      final call = CallRecord.fromJson(const {
        'id': 'c1',
        'startedAt': '2026-11-01T22:42:00.000Z',
        'durationMs': 1000,
        'costUsd': 0,
        'title': 'Ligação',
        'summary': 'Resumo.',
        'learnings': <String>[],
        'metrics': null,
      });

      expect(call.metrics, isNull);
      expect(call.subjectIndex, 1);
    });

    test('a goal is read back from its key', () {
      expect(SpeakingGoal.fromKey('calm'), SpeakingGoal.calm);
      expect(SpeakingGoal.fromKey('singing'), isNull);
      expect(SpeakingGoal.fromKey(null), isNull);
    });
  });
}
