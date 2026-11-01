import 'package:app_ui/app_ui.dart';
import 'package:call_history/call_history.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

/// {@template call_detail_route}
/// `/ligacoes/:id`: the call the home handed over, or, opened without it
/// (a reload on the web), read from the server.
///
/// "Continuar este assunto" pops `true` to the home, which starts the
/// follow-up and reloads the history after it.
/// {@endtemplate}
class CallDetailRoute extends StatefulWidget {
  /// {@macro call_detail_route}
  const CallDetailRoute({required this.id, this.call, super.key});

  /// The call's id, from the path.
  final String id;

  /// The call, when the home had it.
  final CallRecord? call;

  @override
  State<CallDetailRoute> createState() => _CallDetailRouteState();
}

class _CallDetailRouteState extends State<CallDetailRoute> {
  late Future<CallRecord> _call = _read();

  Future<CallRecord> _read() async {
    final call = widget.call;
    if (call != null) return call;
    final repository = context.read<CallHistoryRepository>();
    final read = await repository.call(widget.id);
    repository.markSeen(widget.id).ignore();
    return read;
  }

  void _followUp(CallRecord call) {
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(
        Uri(path: '/ligacao', queryParameters: {'follows': call.id}).toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CallRecord>(
      future: _call,
      builder: (context, snapshot) {
        final call = snapshot.data;
        if (call != null) {
          return CallDetailPage(
            call: call,
            now: DateTime.now(),
            onFollowUp: () => _followUp(call),
          );
        }
        return Scaffold(
          appBar: AppBar(),
          body: snapshot.hasError
              ? AppEmptyState(
                  title: context.l10n.callLoadFailed,
                  action: AppButton.text(
                    onPressed: () => setState(() => _call = _read()),
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
