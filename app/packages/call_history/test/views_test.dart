import 'package:call_history/call_history.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/helpers.dart';

void main() {
  final now = DateTime(2026, 11, 1, 20, 30);

  group('GoalPicker', () {
    testWidgets('offers every goal and says what the first call does', (
      tester,
    ) async {
      SpeakingGoal? picked;
      await pumpIn(
        tester,
        GoalPicker(selected: null, onSelected: (it) => picked = it),
      );

      expect(find.text('O que te traz aqui?'), findsOneWidget);
      expect(find.text('Outra coisa'), findsOneWidget);
      await tester.tap(find.text('Entrevistas'));
      expect(picked, SpeakingGoal.interviews);

      await pumpIn(
        tester,
        GoalPicker(selected: SpeakingGoal.interviews, onSelected: (_) {}),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('O Vox faz de entrevistador'), findsOneWidget);
    });
  });

  group('CallCard', () {
    testWidgets('shows the day, the first learning, time and cost', (
      tester,
    ) async {
      var opened = false;
      await pumpIn(
        tester,
        CallCard(
          call: record(seen: false, subjectIndex: 2),
          now: now,
          onTap: () => opened = true,
        ),
      );

      expect(find.text('Hoje, 19:42'), findsOneWidget);
      expect(find.text('Nova'), findsOneWidget);
      expect(find.text('Começar pelo resultado'), findsOneWidget);
      expect(find.text('6 min'), findsOneWidget);
      expect(find.text(r'US$ 0,07'), findsOneWidget);
      expect(find.text('2ª do assunto'), findsOneWidget);

      await tester.tap(find.text('Apresentação do trimestre'));
      expect(opened, isTrue);
    });

    testWidgets('a seen call that started a subject says neither', (
      tester,
    ) async {
      await pumpIn(
        tester,
        CallCard(
          call: record(learnings: []),
          now: now,
          onTap: () {},
        ),
      );

      expect(find.text('Nova'), findsNothing);
      expect(find.textContaining('do assunto'), findsNothing);
    });
  });

  group('CallDetailPage', () {
    testWidgets('lays out the call and continues its subject', (tester) async {
      var followed = false;
      await tester.pumpWidget(
        app(
          CallDetailPage(
            call: record(
              learnings: ['Pausar antes do número', 'Abrir pelo resultado'],
              metrics: const CallMetrics(
                wordsPerMinute: 148,
                longPauses: 9,
                hesitations: 3,
                wordsPerMinuteDelta: -17,
                hesitationsDelta: -5,
              ),
            ),
            now: now,
            onFollowUp: () => followed = true,
          ),
        ),
      );

      expect(find.text('6 min 12 s'), findsOneWidget);
      expect(find.text('Resumo'), findsOneWidget);
      expect(find.text('Abrir pelo resultado'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('148'), 200);
      expect(find.text('−17 desde a 1ª'), findsOneWidget);
      expect(find.text('−5 desde a 1ª'), findsOneWidget);

      await tester.tap(find.text('Continuar este assunto'));
      expect(followed, isTrue);
    });

    testWidgets('leaves out the numbers when the call had none', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(CallDetailPage(call: record(), now: now, onFollowUp: () {})),
      );

      expect(find.text('Seus números'), findsNothing);
    });
  });
}
