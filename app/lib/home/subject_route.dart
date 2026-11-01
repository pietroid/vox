import 'package:app_ui/app_ui.dart';
import 'package:call_history/call_history.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

/// {@template subject_route}
/// `/assuntos/:id`: the subject the home handed over, or, opened without it
/// (a reload on the web), read from the server.
///
/// Opening a call marks it seen here and on the server. "Continuar com …",
/// here or on one of its calls, pops `true` to the home, which starts the
/// follow-up of the newest call and reloads the history after it.
/// {@endtemplate}
class SubjectRoute extends StatefulWidget {
  /// {@macro subject_route}
  const SubjectRoute({required this.id, this.subject, super.key});

  /// The id of the subject's first call, from the path.
  final String id;

  /// The subject, when the home had it.
  final CallSubject? subject;

  @override
  State<SubjectRoute> createState() => _SubjectRouteState();
}

class _SubjectRouteState extends State<SubjectRoute> {
  late Future<CallSubject> _subject = _read();

  Future<CallSubject> _read() async {
    final subject = widget.subject;
    if (subject != null) return subject;
    final history = await context.read<CallHistoryRepository>().load();
    return CallSubject.group(
      history.calls,
    ).firstWhere((it) => it.id == widget.id);
  }

  Future<void> _openCall(CallSubject subject, CallRecord call) async {
    if (!call.seen) {
      context.read<CallHistoryRepository>().markSeen(call.id).ignore();
      final seen = CallSubject(
        id: subject.id,
        coach: subject.coach,
        calls: [
          for (final it in subject.calls) it.id == call.id ? it.asSeen() : it,
        ],
      );
      setState(() => _subject = Future.value(seen));
    }
    final followUp = await context.push<bool>(
      '/ligacoes/${call.id}',
      extra: call.asSeen(),
    );
    if (followUp == true && mounted) _followUp(subject);
  }

  void _followUp(CallSubject subject) {
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(
        Uri(
          path: '/ligacao',
          queryParameters: {'follows': subject.latest.id},
        ).toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CallSubject>(
      future: _subject,
      builder: (context, snapshot) {
        final subject = snapshot.data;
        if (subject != null) {
          return SubjectPage(
            subject: subject,
            now: DateTime.now(),
            onOpenCall: (call) => _openCall(subject, call),
            onContinue: () => _followUp(subject),
          );
        }
        return Scaffold(
          appBar: AppBar(),
          body: snapshot.hasError
              ? AppEmptyState(
                  title: context.l10n.callLoadFailed,
                  action: AppButton.text(
                    onPressed: () => setState(() => _subject = _read()),
                    text: context.l10n.historyRetry,
                  ),
                )
              : const Center(
                  child: SizedBox.square(
                    dimension: AppSpacing.s5,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
        );
      },
    );
  }
}
