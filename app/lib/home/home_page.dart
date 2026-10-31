import 'package:app_ui/app_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:vox/app/app.dart';

/// {@template home_page}
/// The signed-in home: the way into a call with the agent.
///
/// The greeting says who is signed in, the icon beside it signs out, the
/// one accent button starts a call, and the quiet one under it opens the
/// written conversation, the fallback.
/// {@endtemplate}
class HomePage extends StatelessWidget {
  /// {@macro home_page}
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final firstName = context.select<AppBloc, String?>(
      (bloc) => bloc.state.firstName,
    );
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          firstName == null
              ? l10n.homeGreetingAnonymous
              : l10n.homeGreeting(firstName),
        ),
        actions: [
          IconButton(
            tooltip: l10n.homeSignOut,
            icon: const AppIcon(iconData: AppIcons.signOut),
            onPressed: () =>
                context.read<AppBloc>().add(const AppLogoutRequested()),
          ),
          const SizedBox(width: AppSpacing.s2),
        ],
      ),
      body: AppEmptyState(
        title: l10n.homeCallTitle,
        body: l10n.homeCallBody,
        action: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.s2,
          children: [
            AppButton.icon(
              onPressed: () => context.push('/ligacao'),
              icon: const AppIcon(
                iconData: AppIcons.call,
                color: AppColors.onAccent,
              ),
              text: l10n.homeCallStart,
            ),
            AppButton.text(
              onPressed: () => context.push('/assistente'),
              text: l10n.homeWrite,
            ),
          ],
        ),
      ),
    );
  }
}
