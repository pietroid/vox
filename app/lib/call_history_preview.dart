import 'package:app_ui/app_ui.dart';
import 'package:auth/auth.dart';
import 'package:call_history/call_history.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:vox/app/app.dart';
import 'package:vox/home/home_page.dart';

/// The mockup of the onboarding and the history of calls (`/create`).
/// Nothing ships from here.
///
/// `?s=<n>`:
///
/// 1. the first-run home, nothing picked;
/// 2. the same, "Apresentações" picked;
/// 3. the home right after the first call;
/// 4. the home with a history, the newest a follow-up;
/// 5. that follow-up, opened;
/// 6. the same, scrolled to its numbers.
void main() {
  final scene = int.tryParse(Uri.base.queryParameters['s'] ?? '') ?? 1;
  runApp(_PreviewApp(scene: scene));
}

const _ana = AppUser(
  id: 'preview',
  name: 'Ana Souza',
  email: 'ana@exemplo.com',
);

final _now = DateTime(2026, 11, 1, 20, 30);

final _followUp = CallRecord(
  id: 'c3',
  startedAt: DateTime(2026, 11, 1, 19, 42),
  duration: const Duration(minutes: 6, seconds: 12),
  costUsd: 0.07,
  title: 'Apresentação do resultado do trimestre',
  summary:
      'Você apresentou de novo os números do trimestre, agora abrindo pelo '
      'resultado. A fala ficou mais curta e direta; no trecho dos custos o '
      'ritmo ainda acelerou e o número principal passou rápido demais.',
  learnings: const [
    'Pausar um segundo antes do número principal',
    'Abrir pelo resultado funcionou: manter',
    'Trocar o "basicamente" por um silêncio curto',
  ],
  metrics: const CallMetrics(
    wordsPerMinute: 148,
    longPauses: 9,
    hesitations: 3,
    wordsPerMinuteDelta: -17,
    longPausesDelta: 4,
    hesitationsDelta: -5,
  ),
  subjectIndex: 2,
  seen: false,
);

final _interview = CallRecord(
  id: 'c2',
  startedAt: DateTime(2026, 10, 31, 8, 15),
  duration: const Duration(minutes: 4, seconds: 3),
  costUsd: 0.05,
  title: 'Resposta para "fale sobre você"',
  summary:
      'Ensaio de uma resposta de entrevista. Você passou por três empregos '
      'em um minuto e meio; o Vox sugeriu ficar com um só e contar o que '
      'mudou por sua causa.',
  learnings: const ['Contar uma história só, com começo, meio e fim'],
);

final _first = CallRecord(
  id: 'c1',
  startedAt: DateTime(2026, 10, 28, 21, 3),
  duration: const Duration(minutes: 5, seconds: 40),
  costUsd: 0.06,
  title: 'Apresentação do resultado do trimestre',
  summary:
      'Primeira versão da apresentação para a diretoria. Você começou pelo '
      'contexto e levou dois minutos até chegar no resultado.',
  learnings: const ['Começar pelo resultado, não pelo contexto'],
);

class _PreviewApp extends StatelessWidget {
  const _PreviewApp({required this.scene});

  final int scene;

  @override
  Widget build(BuildContext context) {
    final auth = _FakeAuthRepository();
    final history = switch (scene) {
      2 => const CallHistoryState(goal: SpeakingGoal.presentations),
      3 => CallHistoryState(
        goal: SpeakingGoal.presentations,
        calls: [
          CallRecord(
            id: 'c1',
            startedAt: DateTime(2026, 11, 1, 19, 42),
            duration: _first.duration,
            costUsd: _first.costUsd,
            title: _first.title,
            summary: _first.summary,
            learnings: _first.learnings,
            seen: false,
          ),
        ],
      ),
      4 || 5 || 6 => CallHistoryState(
        goal: SpeakingGoal.presentations,
        calls: [_followUp, _interview, _first],
      ),
      _ => const CallHistoryState(),
    };

    return RepositoryProvider<AuthRepository>.value(
      value: auth,
      child: BlocProvider(
        create: (_) => AppBloc(authRepository: auth, initialUser: _ana),
        child: BlocProvider(
          create: (_) => CallHistoryCubit(history),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.current,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: scene >= 5
                ? _ScrolledToEnd(
                    scrolled: scene == 6,
                    child: CallDetailPage(
                      call: _followUp,
                      now: _now,
                      onFollowUp: () {},
                    ),
                  )
                : HomeView(now: _now),
          ),
        ),
      ),
    );
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> get user => const Stream.empty();

  @override
  AppUser? get currentUser => _ana;

  @override
  Future<String?> token() async => null;

  @override
  Future<AppUser?> restore() async => _ana;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

/// Scrolls the first scrollable under it to its end after the first frame.
class _ScrolledToEnd extends StatefulWidget {
  const _ScrolledToEnd({required this.scrolled, required this.child});

  final bool scrolled;
  final Widget child;

  @override
  State<_ScrolledToEnd> createState() => _ScrolledToEndState();
}

class _ScrolledToEndState extends State<_ScrolledToEnd> {
  @override
  void initState() {
    super.initState();
    if (!widget.scrolled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void visit(Element element) {
        if (element is StatefulElement && element.state is ScrollableState) {
          final position = (element.state as ScrollableState).position;
          position.jumpTo(position.maxScrollExtent);
          return;
        }
        element.visitChildElements(visit);
      }

      context.visitChildElements(visit);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
