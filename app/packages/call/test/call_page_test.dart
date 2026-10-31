import 'package:app_ui/app_ui.dart';
import 'package:call/call.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'helpers/fakes.dart';

Widget _app(CallService service) => RepositoryProvider<CallService>.value(
  value: service,
  child: MaterialApp(
    theme: AppTheme.current,
    locale: const Locale('pt', 'BR'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CallPage()),
        ),
        child: const Text('ligar'),
      ),
    ),
  ),
);

void main() {
  testWidgets('listens, mutes, and hangs up', (tester) async {
    final service = FakeCallService();
    await tester.pumpWidget(_app(service));
    await tester.tap(find.text('ligar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Ouvindo'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Desligar o microfone'));
    await tester.pump();
    expect(find.text('Microfone desligado'), findsOneWidget);
    expect(service.line.mutes, [true]);

    await tester.tap(find.byTooltip('Encerrar ligação'));
    await tester.pumpAndSettle();
    expect(find.text('ligar'), findsOneWidget);
    expect(service.line.closed, isTrue);
  });

  testWidgets('says the call is unavailable, with only the hang-up', (
    tester,
  ) async {
    await tester.pumpWidget(_app(FakeCallService(supported: false)));
    await tester.tap(find.text('ligar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.textContaining('A ligação não está disponível'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Desligar o microfone'), findsNothing);
    expect(find.bySemanticsLabel('Encerrar ligação'), findsOneWidget);
  });
}
