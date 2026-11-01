import 'package:app_ui/app_ui.dart';
import 'package:call_history/call_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

/// [child] in the app's theme and strings.
Widget app(Widget child) => MaterialApp(
  theme: AppTheme.current,
  locale: const Locale('pt', 'BR'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

/// Pumps [child] inside a Scaffold and returns its context.
Future<BuildContext> pumpIn(WidgetTester tester, [Widget? child]) async {
  late BuildContext context;
  await tester.pumpWidget(
    app(
      Scaffold(
        body: Builder(
          builder: (it) {
            context = it;
            return child ?? const SizedBox();
          },
        ),
      ),
    ),
  );
  return context;
}

/// A call, with every fact set.
CallRecord record({
  String id = 'c1',
  List<String> learnings = const ['Começar pelo resultado'],
  CallMetrics? metrics,
  int subjectIndex = 1,
  bool seen = true,
  String? subject,
  Coach coach = Coach.bianca,
  DateTime? startedAt,
}) => CallRecord(
  id: id,
  startedAt: startedAt ?? DateTime(2026, 11, 1, 19, 42),
  duration: const Duration(minutes: 6, seconds: 12),
  costUsd: 0.07,
  title: 'Apresentação do trimestre',
  summary: 'Você apresentou os números do trimestre.',
  learnings: learnings,
  metrics: metrics,
  subjectIndex: subjectIndex,
  seen: seen,
  subject: subject,
  coach: coach,
);

/// The server, in memory: every call recorded.
class FakeHistoryRepository implements CallHistoryRepository {
  FakeHistoryRepository({this.calls = const [], this.goal});

  List<CallRecord> calls;
  SpeakingGoal? goal;
  Object? fails;
  int loads = 0;
  final seen = <String>[];
  final goals = <SpeakingGoal>[];

  /// Called before each load answers: a test adds a call here.
  void Function(int load)? onLoad;

  @override
  Future<CallHistory> load() async {
    loads++;
    onLoad?.call(loads);
    if (fails != null) throw fails!;
    return CallHistory(calls: calls, goal: goal);
  }

  @override
  Future<CallRecord> call(String id) async =>
      calls.firstWhere((it) => it.id == id);

  @override
  Future<void> markSeen(String id) async => seen.add(id);

  @override
  Future<void> saveGoal(SpeakingGoal goal) async => goals.add(goal);
}
