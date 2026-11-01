import 'package:bloc/bloc.dart';
import 'package:call_history/src/call_record.dart';
import 'package:call_history/src/speaking_goal.dart';
import 'package:equatable/equatable.dart';

/// {@template call_history_state}
/// The person's calls, newest first, and the goal they gave before the
/// first one.
/// {@endtemplate}
class CallHistoryState extends Equatable {
  /// {@macro call_history_state}
  const CallHistoryState({this.calls = const [], this.goal});

  /// Newest first. Empty until the first call ends: the home then shows
  /// the invitation instead of the history.
  final List<CallRecord> calls;

  /// What brought the person here, if they said.
  final SpeakingGoal? goal;

  /// Whether the person has never finished a call.
  bool get isFirstRun => calls.isEmpty;

  /// A copy with [calls] or [goal] replaced.
  CallHistoryState copyWith({List<CallRecord>? calls, SpeakingGoal? goal}) =>
      CallHistoryState(calls: calls ?? this.calls, goal: goal ?? this.goal);

  @override
  List<Object?> get props => [calls, goal];
}

/// {@template call_history_cubit}
/// Holds the history the home draws.
///
/// The mockup seeds it directly; the build gives it a repository that
/// loads the calls from the server and saves the goal.
/// {@endtemplate}
class CallHistoryCubit extends Cubit<CallHistoryState> {
  /// {@macro call_history_cubit}
  CallHistoryCubit([super.initialState = const CallHistoryState()]);

  /// The person picked what brought them here.
  void chooseGoal(SpeakingGoal goal) => emit(state.copyWith(goal: goal));
}
