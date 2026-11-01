import 'package:app_ui/app_ui.dart';
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
      expect(find.text('17'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      await tester.tap(find.text('Continuar com Bianca'));
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

  group('CoachPicker', () {
    testWidgets('offers four coaches by language and answers the one picked', (
      tester,
    ) async {
      Coach? picked;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => picked = await showCoachPicker(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Português'), findsOneWidget);
      expect(find.text('Inglês'), findsOneWidget);
      for (final name in ['Bianca', 'Bruno', 'Haley', 'Marcus']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('Começar com Bianca'), findsOneWidget);

      await tester.tap(find.text('Marcus'));
      await tester.pump();
      await tester.tap(find.text('Começar com Marcus'));
      await tester.pumpAndSettle();
      expect(picked, Coach.marcus);
    });
  });

  group('SubjectPage', () {
    testWidgets('lists its calls newest first and continues with its coach', (
      tester,
    ) async {
      final subject = CallSubject.group([
        record(
          id: 'c2',
          subject: 'c1',
          subjectIndex: 2,
          seen: false,
          coach: Coach.haley,
        ),
        record(coach: Coach.haley),
      ]).single;
      CallRecord? opened;
      var continued = false;
      await tester.pumpWidget(
        app(
          SubjectPage(
            subject: subject,
            now: now,
            onOpenCall: (call) => opened = call,
            onContinue: () => continued = true,
          ),
        ),
      );

      expect(find.text('Haley'), findsOneWidget);
      expect(find.text('2ª'), findsOneWidget);
      expect(find.text('1ª'), findsOneWidget);
      await tester.tap(find.text('2ª'));
      expect(opened?.id, 'c2');
      await tester.tap(find.text('Continuar com Haley'));
      expect(continued, isTrue);
    });
  });
}
