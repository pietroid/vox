import 'package:call_history/call_history.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/helpers.dart';

void main() {
  group('CallSubject.group', () {
    test('groups calls by subject, the newest subject first', () {
      final subjects = CallSubject.group([
        record(id: 'c3', subject: 'c1', subjectIndex: 2, seen: false),
        record(id: 'c2', coach: Coach.marcus),
        record(),
      ]);

      expect(subjects.map((it) => it.id), ['c1', 'c2']);
      final first = subjects.first;
      expect(first.calls.map((it) => it.id), ['c3', 'c1']);
      expect(first.latest.id, 'c3');
      expect(first.hasNew, isTrue);
      expect(first.duration, const Duration(minutes: 12, seconds: 24));
      expect(subjects.last.coach, Coach.marcus);
      expect(subjects.last.hasNew, isFalse);
    });
  });

  group('CallRecord.fromJson', () {
    Map<String, Object?> json(Map<String, Object?> over) => {
      'id': 'c2',
      'startedAt': '2026-11-01T22:42:00Z',
      'durationMs': 372000,
      'costUsd': 0.07,
      'title': 'Entrevista',
      'summary': '',
      'learnings': <String>[],
      'metrics': null,
      'subjectIndex': 2,
      'seen': true,
      ...over,
    };

    test('reads the coach and the subject', () {
      final call = CallRecord.fromJson(
        json({'coach': 'haley', 'subjectId': 'c1'}),
      );
      expect(call.coach, Coach.haley);
      expect(call.coach.language, CoachLanguage.en);
      expect(call.subjectId, 'c1');
    });

    test('an older server: Bianca, and its own subject', () {
      final call = CallRecord.fromJson(json({}));
      expect(call.coach, Coach.bianca);
      expect(call.subjectId, 'c2');
    });
  });
}
