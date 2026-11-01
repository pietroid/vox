import 'package:call_history/src/call_record.dart';
import 'package:call_history/src/coach.dart';
import 'package:equatable/equatable.dart';

/// {@template call_subject}
/// A subject: the call that started it and every call that followed it up,
/// all with the same coach. The home lists these; a subject's page lists
/// its calls.
/// {@endtemplate}
class CallSubject extends Equatable {
  /// {@macro call_subject}
  const CallSubject({
    required this.id,
    required this.coach,
    required this.calls,
  });

  /// The id of the call that started it.
  final String id;

  /// Who coaches it.
  final Coach coach;

  /// Its calls, newest first; never empty.
  final List<CallRecord> calls;

  /// Groups [calls] (newest first) by subject, the subject with the newest
  /// call first.
  static List<CallSubject> group(List<CallRecord> calls) {
    final bySubject = <String, List<CallRecord>>{};
    for (final call in calls) {
      (bySubject[call.subjectId] ??= []).add(call);
    }
    return [
      for (final MapEntry(:key, :value) in bySubject.entries)
        CallSubject(id: key, coach: value.first.coach, calls: value),
    ];
  }

  /// The newest call.
  CallRecord get latest => calls.first;

  /// What it is about: the newest call's title.
  String get title => latest.title;

  /// Every call's length, added.
  Duration get duration =>
      calls.fold(Duration.zero, (sum, call) => sum + call.duration);

  /// Every call's cost, added.
  double get costUsd => calls.fold(0, (sum, call) => sum + call.costUsd);

  /// Whether a call on it hasn't been opened.
  bool get hasNew => calls.any((call) => !call.seen);

  /// The newest numbers, with their change since the subject's first call.
  CallMetrics? get metrics {
    for (final call in calls) {
      if (call.metrics != null) return call.metrics;
    }
    return null;
  }

  @override
  List<Object?> get props => [id, coach, calls];
}
