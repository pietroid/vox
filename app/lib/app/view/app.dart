import 'package:analytics/analytics.dart';
import 'package:app_ui/app_ui.dart';
import 'package:auth/auth.dart';
import 'package:call/call.dart';
import 'package:call_history/call_history.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:vox/app/app.dart';
import 'package:vox/assistant/assistant.dart';
import 'package:vox/home/call_detail_route.dart';
import 'package:vox/home/home_page.dart';
import 'package:vox/home/subject_route.dart';

/// {@template app}
/// The root widget: the router, the theme and the strings.
/// {@endtemplate}
class App extends StatelessWidget {
  /// {@macro app}
  ///
  /// Each route has a `name`, which is the screen PostHog reports.
  App({
    required String initialLocation,
    this.analytics = const NoAnalytics(),
    super.key,
  }) : _router = GoRouter(
         initialLocation: initialLocation,
         observers: analytics.navigatorObservers,
         routes: [
           GoRoute(
             path: '/',
             name: 'Home',
             builder: (context, state) => const HomePage(),
           ),
           GoRoute(
             path: '/ligacao',
             name: 'Ligação',
             builder: (context, state) => CallPage(
               follows: state.uri.queryParameters['follows'],
               coach: state.uri.queryParameters['coach'],
             ),
           ),
           GoRoute(
             path: '/assuntos/:id',
             name: 'Assunto',
             builder: (context, state) => SubjectRoute(
               id: state.pathParameters['id']!,
               subject: state.extra is CallSubject
                   ? state.extra! as CallSubject
                   : null,
             ),
           ),
           GoRoute(
             path: '/ligacoes/:id',
             name: 'Ligação anterior',
             builder: (context, state) => CallDetailRoute(
               id: state.pathParameters['id']!,
               call: state.extra is CallRecord
                   ? state.extra! as CallRecord
                   : null,
             ),
           ),
           GoRoute(
             path: '/assistente',
             name: 'Assistente',
             builder: (context, state) => const AssistantPage(),
           ),
           GoRoute(
             path: '/auth',
             name: 'Entrada',
             builder: (context, state) => AuthScreen(
               authRepository: context.read<AuthRepository>(),
               onAuthenticated: () => context.go('/'),
             ),
           ),
         ],
       );

  /// Where screens are reported, and what wraps the app for replays.
  final Analytics analytics;

  final GoRouter _router;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppBloc, AppState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) => _router.go(
        state.status == AppStatus.authenticated ? '/' : '/auth',
      ),
      child: analytics.wrap(
        MaterialApp.router(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => context.l10n.appName,
          theme: AppTheme.current,
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: _router,
        ),
      ),
    );
  }
}
