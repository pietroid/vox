import 'package:api_client/api_client.dart';
import 'package:call_history/src/call_record.dart';
import 'package:call_history/src/speaking_goal.dart';

/// {@template call_history}
/// What `GET /calls` answers: the goal, if picked, and the calls.
/// {@endtemplate}
class CallHistory {
  /// {@macro call_history}
  const CallHistory({required this.calls, this.goal});

  /// Newest first.
  final List<CallRecord> calls;

  /// What brought the person here, if they said.
  final SpeakingGoal? goal;
}

/// {@template call_history_repository}
/// The person's calls and goal, kept by the server.
/// {@endtemplate}
abstract interface class CallHistoryRepository {
  /// The goal and every call, newest first.
  Future<CallHistory> load();

  /// One call, for a detail opened without the history behind it.
  Future<CallRecord> call(String id);

  /// The person opened [id]: it stops being new.
  Future<void> markSeen(String id);

  /// The person picked [goal] before the first call.
  Future<void> saveGoal(SpeakingGoal goal);
}

/// {@template api_call_history_repository}
/// [CallHistoryRepository] over `/api/calls` and `/api/users/me/goal`.
/// {@endtemplate}
class ApiCallHistoryRepository implements CallHistoryRepository {
  /// {@macro api_call_history_repository}
  const ApiCallHistoryRepository({required ApiClient apiClient})
    : _api = apiClient;

  final ApiClient _api;

  @override
  Future<CallHistory> load() async {
    final response = await _api.get<Map<String, dynamic>>('/calls');
    final data = response.data ?? const {};
    return CallHistory(
      goal: SpeakingGoal.fromKey(data['goal'] as String?),
      calls: [
        for (final it in data['calls'] as List<dynamic>? ?? const [])
          CallRecord.fromJson(it as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<CallRecord> call(String id) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/calls/${Uri.encodeComponent(id)}',
    );
    return CallRecord.fromJson(response.data!);
  }

  @override
  Future<void> markSeen(String id) =>
      _api.post<void>('/calls/${Uri.encodeComponent(id)}/seen');

  @override
  Future<void> saveGoal(SpeakingGoal goal) =>
      _api.put<void>('/users/me/goal', data: {'goal': goal.name});
}
