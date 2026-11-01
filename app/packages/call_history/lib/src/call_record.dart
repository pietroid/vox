import 'package:call_history/src/coach.dart';
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

  /// As `GET /calls` sends it.
  factory CallMetrics.fromJson(Map<String, dynamic> json) => CallMetrics(
    wordsPerMinute: (json['wordsPerMinute'] as num).round(),
    longPauses: (json['longPauses'] as num).round(),
    hesitations: (json['hesitations'] as num).round(),
    wordsPerMinuteDelta: (json['wordsPerMinuteDelta'] as num?)?.round(),
    longPausesDelta: (json['longPausesDelta'] as num?)?.round(),
    hesitationsDelta: (json['hesitationsDelta'] as num?)?.round(),
  );

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
    this.coach = Coach.bianca,
    this._subject,
  });

  /// As `GET /calls` sends it. The start comes in UTC and is shown in the
  /// phone's zone.
  factory CallRecord.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'];
    return CallRecord(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String).toLocal(),
      duration: Duration(milliseconds: (json['durationMs'] as num).round()),
      costUsd: (json['costUsd'] as num).toDouble(),
      title: json['title'] as String,
      summary: json['summary'] as String,
      learnings: [
        for (final it in json['learnings'] as List<dynamic>) it as String,
      ],
      metrics: metrics is Map<String, dynamic>
          ? CallMetrics.fromJson(metrics)
          : null,
      subjectIndex: (json['subjectIndex'] as num?)?.round() ?? 1,
      seen: json['seen'] as bool? ?? true,
      coach: Coach.fromKey(json['coach'] as String?),
      subject: json['subjectId'] as String?,
    );
  }

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

  /// Who coached it: the coach its subject started with.
  final Coach coach;

  final String? _subject;

  /// The id of the call that started its subject; its own on a fresh call.
  String get subjectId => _subject ?? id;

  /// The same call, opened.
  CallRecord asSeen() => seen
      ? this
      : CallRecord(
          id: id,
          startedAt: startedAt,
          duration: duration,
          costUsd: costUsd,
          title: title,
          summary: summary,
          learnings: learnings,
          metrics: metrics,
          subjectIndex: subjectIndex,
          coach: coach,
          subject: _subject,
        );

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
    coach,
    subjectId,
  ];
}
