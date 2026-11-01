import 'package:call_history/call_history.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/helpers.dart';

void main() {
  final now = DateTime(2026, 11, 1, 20, 30);

  testWidgets('says the day: today, yesterday, or the date', (tester) async {
    final context = await pumpIn(tester);

    expect(context.callWhen(DateTime(2026, 11, 1, 8, 5), now), 'Hoje, 08:05');
    expect(
      context.callWhen(DateTime(2026, 10, 31, 23, 59), now),
      'Ontem, 23:59',
    );
    expect(
      context.callWhen(DateTime(2026, 10, 28, 21, 3), now),
      startsWith('28 de out'),
    );
  });

  testWidgets('says how long, in minutes or to the second', (tester) async {
    final context = await pumpIn(tester);
    const call = Duration(minutes: 6, seconds: 12);

    expect(context.callDuration(call), '6 min');
    expect(context.callDuration(call, seconds: true), '6 min 12 s');
    expect(context.callDuration(const Duration(seconds: 20)), '1 min');
    expect(
      context.callDuration(const Duration(minutes: 4), seconds: true),
      '4 min',
    );
  });

  testWidgets('says the cost in dollars with the Brazilian comma', (
    tester,
  ) async {
    final context = await pumpIn(tester);

    expect(context.callCost(0.0612), r'US$ 0,06');
    expect(context.callCost(0.076), r'US$ 0,08');
    // A call that cost something never reads as free.
    expect(context.callCost(0.003), r'US$ 0,01');
    expect(context.callCost(0), r'US$ 0,00');
  });
}
