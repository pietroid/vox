import 'package:app_ui/app_ui.dart';
import 'package:l10n/l10n.dart';

/// How a call's facts are written: its day, its length, its cost.
///
/// `now` is passed in, never read, so a test or a preview fixes the day.
extension CallFormat on BuildContext {
  /// "Hoje, 19:42", "Ontem, 08:15" or "28 de out., 21:03".
  String callWhen(DateTime at, DateTime now) {
    final time =
        '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}';
    final day = DateTime(at.year, at.month, at.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(day).inDays;
    if (days == 0) return l10n.callToday(time);
    if (days == 1) return l10n.callYesterday(time);
    return l10n.callOnDay(
      MaterialLocalizations.of(this).formatShortMonthDay(at),
      time,
    );
  }

  /// "6 min" in a list; "6 min 12 s" with [seconds].
  String callDuration(Duration duration, {bool seconds = false}) {
    final minutes = duration.inMinutes;
    if (!seconds || duration.inSeconds % 60 == 0) {
      // A call under a minute still reads as one.
      return l10n.callMinutes(minutes < 1 ? 1 : minutes);
    }
    return l10n.callMinutesSeconds(minutes, duration.inSeconds % 60);
  }

  /// "US$ 0,07", always two decimals, with the Brazilian comma.
  String callCost(double usd) {
    final cents = usd < 0.01 && usd > 0 ? 0.01 : usd;
    return l10n.callCost(cents.toStringAsFixed(2).replaceAll('.', ','));
  }
}
