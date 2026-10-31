import 'package:app_ui/app_ui.dart';
import 'package:auth/auth.dart';
import 'package:call/call.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:vox/app/app.dart';
import 'package:vox/home/home_page.dart';

/// The voice call's mockup, against fixed data. Nothing ships from here.
///
/// `?s=<n>`:
///
/// 1. the home, with the call as its one action;
/// 2. Ouvindo: the person mid-talk, the halo up with their voice;
/// 3. Pensando: the talk ended on a long pause, the phone's fixed phrase;
/// 4. Falando: the agent's feedback, sentence by sentence, with numbers;
/// 5. the mic muted and the captions hidden.
void main() {
  final scene = int.tryParse(Uri.base.queryParameters['s'] ?? '') ?? 1;
  runApp(_PreviewApp(scene: scene));
}

const _ana = AppUser(
  id: 'preview',
  name: 'Ana Souza',
  email: 'ana@exemplo.com',
);

const _question =
    'Pode começar quando quiser. Apresente o projeto como faria na banca.';

final _scenes = <int, CallState>{
  2: const CallState(
    phase: CallPhase.listening,
    previousCaption: _question,
    elapsed: Duration(minutes: 2, seconds: 47),
    level: 0.72,
  ),
  3: const CallState(
    phase: CallPhase.thinking,
    previousCaption: _question,
    caption: 'Boa! Deixa eu ver seus números…',
    elapsed: Duration(minutes: 6, seconds: 3),
  ),
  4: const CallState(
    phase: CallPhase.speaking,
    previousCaption: 'Você falou a 168 palavras por minuto, bem acima das '
        'suas primeiras falas.',
    caption: 'Na parte dos resultados, faça uma pausa antes de cada número. '
        'Vamos repetir só esse trecho?',
    elapsed: Duration(minutes: 6, seconds: 21),
    level: 0.55,
  ),
  5: const CallState(
    phase: CallPhase.listening,
    muted: true,
    captionsOn: false,
    previousCaption: _question,
    elapsed: Duration(minutes: 7, seconds: 9),
  ),
};

class _PreviewApp extends StatelessWidget {
  const _PreviewApp({required this.scene});

  final int scene;

  @override
  Widget build(BuildContext context) {
    final auth = _FakeAuthRepository();
    final seeded = _scenes[scene];

    return RepositoryProvider<AuthRepository>.value(
      value: auth,
      child: BlocProvider(
        create: (_) => AppBloc(authRepository: auth, initialUser: _ana),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.current,
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Still prints: the breath of Pensando holds at rest.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: seeded == null
              ? const HomePage()
              : BlocProvider(
                  create: (_) => CallCubit(initial: seeded),
                  child: const CallView(),
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
