import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:call_history/src/call_history_repository.dart';
import 'package:call_history/src/call_record.dart';
import 'package:call_history/src/speaking_goal.dart';
import 'package:equatable/equatable.dart';

/// Where the history is in its loading.
enum CallHistoryStatus {
  /// Not read from the server yet.
  loading,

  /// Read.
  ready,

  /// The server couldn't be reached; the home offers to try again.
  failed,
}

/// {@template call_history_state}
/// The person's calls, newest first, and the goal they gave before the
/// first one.
/// {@endtemplate}
class CallHistoryState extends Equatable {
  /// {@macro call_history_state}
  const CallHistoryState({
    this.status = CallHistoryStatus.ready,
    this.calls = const [],
    this.goal,
    this.summarizing = false,
  });

  /// Whether the history has been read.
  final CallHistoryStatus status;

  /// Newest first. Empty until the first call ends: the home then shows
  /// the invitation instead of the history.
  final List<CallRecord> calls;

  /// What brought the person here, if they said.
  final SpeakingGoal? goal;

  /// A call just ended and its notes are still being written.
  final bool summarizing;

  /// Whether the person has never finished a call.
  bool get isFirstRun => calls.isEmpty;

  /// A copy with the given fields replaced.
  CallHistoryState copyWith({
    CallHistoryStatus? status,
    List<CallRecord>? calls,
    SpeakingGoal? goal,
    bool? summarizing,
  }) => CallHistoryState(
    status: status ?? this.status,
    calls: calls ?? this.calls,
    goal: goal ?? this.goal,
    summarizing: summarizing ?? this.summarizing,
  );

  @override
  List<Object?> get props => [status, calls, goal, summarizing];
}

/// {@template call_history_cubit}
/// Holds the history the home draws, read from a [CallHistoryRepository].
/// {@endtemplate}
class CallHistoryCubit extends Cubit<CallHistoryState> {
  /// {@macro call_history_cubit}
  ///
  /// After a call, the history is read again every [retryEvery], up to
  /// [retries] times, until the new call shows up: the server writes it
  /// once the model has summed it up, a few seconds after hang-up.
  CallHistoryCubit({
    required this._repository,
    this.retryEvery = const Duration(seconds: 2),
    this.retries = 8,
    CallHistoryState initial = const CallHistoryState(
      status: CallHistoryStatus.loading,
    ),
  }) : super(initial);

  final CallHistoryRepository _repository;

  /// How long to wait between reads after a call.
  final Duration retryEvery;

  /// How many reads after a call before giving up on it.
  final int retries;

  /// Reads the history.
  Future<void> load() async {
    if (state.calls.isEmpty) {
      emit(state.copyWith(status: CallHistoryStatus.loading));
    }
    try {
      final history = await _repository.load();
      if (isClosed) return;
      emit(
        CallHistoryState(
          calls: history.calls,
          // A goal picked on this screen and not yet saved stays.
          goal: history.goal ?? state.goal,
          summarizing: state.summarizing,
        ),
      );
    } on Object {
      if (isClosed) return;
      emit(state.copyWith(status: CallHistoryStatus.failed));
    }
  }

  /// A call ended: reads the history until it shows up. [connected] false
  /// means the call never got through, so there is nothing to wait for.
  Future<void> afterCall({bool connected = true}) async {
    if (!connected) return;
    final before = state.calls.isEmpty ? null : state.calls.first.id;
    emit(state.copyWith(summarizing: true));
    for (var i = 0; i < retries && !isClosed; i++) {
      if (i > 0) await Future<void>.delayed(retryEvery);
      if (isClosed) return;
      await load();
      final newest = state.calls.isEmpty ? null : state.calls.first.id;
      if (newest != null && newest != before) break;
    }
    if (!isClosed) emit(state.copyWith(summarizing: false));
  }

  /// The person picked what brought them here. It shows at once; saving
  /// it is best effort, and the first call works without it.
  Future<void> chooseGoal(SpeakingGoal goal) async {
    emit(state.copyWith(goal: goal));
    try {
      await _repository.saveGoal(goal);
    } on Object {
      // Picked again next time, or never: the call doesn't need it.
    }
  }

  /// The person opened [id]: its "Nova" goes away now, and on the server.
  Future<void> markSeen(String id) async {
    final calls = [
      for (final call in state.calls) call.id == id ? call.asSeen() : call,
    ];
    emit(state.copyWith(calls: calls));
    try {
      await _repository.markSeen(id);
    } on Object {
      // Shown as new again on the next load; nothing else depends on it.
    }
  }
}
