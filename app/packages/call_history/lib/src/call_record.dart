import 'package:equatable/equatable.dart';

/// {@template call_metrics}
/// A call's numbers, measured in code on the person's takes
/// (`speech-metrics.ts`), and how each moved since the first call on the
/// same subject.
/// {@endtemplate}
class CallMetrics extends Equatable {
  /// {@macro call_metrics}
  const CallMetrics({
    required this.wordsPerMinute,
    required this.longPauses,
    required this.hesitations,
    this.wordsPerMinuteDelta,
    this.longPausesDelta,
    this.hesitationsDelta,
  });

  /// The pace, in words a minute.
  final int wordsPerMinute;

  /// Pauses long enough to be heard as a stop.
  final int longPauses;

  /// Voiced time with no word in it ("é…", "hum").
  final int hesitations;

  /// The change in pace since the subject's first call; null on the first.
  final int? wordsPerMinuteDelta;

  /// The change in long pauses since the subject's first call.
  final int? longPausesDelta;

  /// The change in hesitations since the subject's first call.
  final int? hesitationsDelta;

  @override
  List<Object?> get props => [
    wordsPerMinute,
    longPauses,
    hesitations,
    wordsPerMinuteDelta,
    longPausesDelta,
    hesitationsDelta,
  ];
}

/// {@template call_record}
/// One finished call, as the history keeps it: when, how long, what it
/// cost, and what the agent made of it.
/// {@endtemplate}
class CallRecord extends Equatable {
  /// {@macro call_record}
  const CallRecord({
    required this.id,
    required this.startedAt,
    required this.duration,
    required this.costUsd,
    required this.title,
    required this.summary,
    required this.learnings,
    this.metrics,
    this.subjectIndex = 1,
    this.seen = true,
  });

  /// The server's id.
  final String id;

  /// When the call started.
  final DateTime startedAt;

  /// How long it lasted.
  final Duration duration;

  /// What it cost in speech and model calls, in US dollars.
  final double costUsd;

  /// The subject, in a few words, written by the agent.
  final String title;

  /// A paragraph on what was talked about.
  final String summary;

  /// What to take from it, most important first.
  final List<String> learnings;

  /// The numbers, when the call had a take long enough to measure.
  final CallMetrics? metrics;

  /// Which call on its subject this is: 1 for a call started fresh, 2 for
  /// the first follow-up, and so on.
  final int subjectIndex;

  /// Whether the person has opened it.
  final bool seen;

  @override
  List<Object?> get props => [
    id,
    startedAt,
    duration,
    costUsd,
    title,
    summary,
    learnings,
    metrics,
    subjectIndex,
    seen,
  ];
}
