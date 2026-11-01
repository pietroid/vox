import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:auth/auth.dart';
import 'package:call_history/call_history.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vox/app/app.dart';
import 'package:vox/home/home_page.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _FakeHistory implements CallHistoryRepository {
  _FakeHistory([this.calls = const []]);

  final List<CallRecord> calls;

  @override
  Future<CallHistory> load() async => CallHistory(calls: calls);

  @override
  Future<CallRecord> call(String id) async => calls.first;

  @override
  Future<void> markSeen(String id) async {}

  @override
  Future<void> saveGoal(SpeakingGoal goal) async {}
}

Widget _home(AuthRepository auth, CallHistoryRepository history) =>
    RepositoryProvider.value(
      value: history,
      child: BlocProvider(
        create: (_) => AppBloc(
          authRepository: auth,
          initialUser: const AppUser(id: 'user-1', name: 'Ana Souza'),
        ),
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomePage(),
        ),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('greets the person by first name and signs them out', (
    tester,
  ) async {
    final auth = _MockAuthRepository();
    final users = StreamController<AppUser?>();
    addTearDown(users.close);
    when(() => auth.user).thenAnswer((_) => users.stream);
    when(auth.signOut).thenAnswer((_) async {});

    await tester.pumpWidget(_home(auth, _FakeHistory()));
    await tester.pump();

    expect(find.text('Olá, Ana'), findsOneWidget);
    // Before the first call, the home invites it and asks for a goal.
    expect(find.text('Fazer minha primeira ligação'), findsOneWidget);
    expect(find.text('O que te traz aqui?'), findsOneWidget);
    expect(find.byTooltip('Conversar por escrito'), findsOneWidget);

    await tester.tap(find.byTooltip('Sair'));
    await tester.pump();

    verify(auth.signOut).called(1);
  });

  testWidgets('after the first call, the home is the history', (
    tester,
  ) async {
    final auth = _MockAuthRepository();
    when(() => auth.user).thenAnswer((_) => const Stream.empty());
    final call = CallRecord(
      id: 'c1',
      startedAt: DateTime(2026, 10, 28, 21, 3),
      duration: const Duration(minutes: 5, seconds: 40),
      costUsd: 0.06,
      title: 'Apresentação do trimestre',
      summary: 'Primeira versão da apresentação.',
      learnings: const ['Começar pelo resultado'],
      seen: false,
    );

    await tester.pumpWidget(_home(auth, _FakeHistory([call])));
    await tester.pump();

    expect(find.text('Primeira ligação feita'), findsOneWidget);
    expect(find.text('Suas ligações'), findsOneWidget);
    expect(find.text('Apresentação do trimestre'), findsOneWidget);
    expect(find.text('Nova'), findsOneWidget);
    expect(find.text('Fazer minha primeira ligação'), findsNothing);
  });
}
