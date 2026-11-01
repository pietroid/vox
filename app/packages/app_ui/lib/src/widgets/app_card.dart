import 'package:app_ui/app_ui.dart';

/// How a card stands off the page.
enum AppCardTone {
  /// The borderless [AppColors.fill]: a row of a list.
  plain,

  /// The pale [AppColors.accentSoft]: the one card that invites an action.
  accent,
}

/// {@template app_card}
/// A soft, borderless card: the shape a list item or a call-out takes.
///
/// With [onTap] the whole card is the tap target and ripples.
/// {@endtemplate}
class AppCard extends StatelessWidget {
  /// {@macro app_card}
  const AppCard({
    required this.child,
    this.onTap,
    this.tone = AppCardTone.plain,
    this.padding = const EdgeInsets.all(AppSpacing.s5),
    super.key,
  });

  /// What the card holds.
  final Widget child;

  /// Called when the card is tapped; null leaves it still.
  final VoidCallback? onTap;

  /// How the card stands off the page.
  final AppCardTone tone;

  /// The room inside the card's edge.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: switch (tone) {
        AppCardTone.plain => AppColors.fill,
        AppCardTone.accent => AppColors.accentSoft,
      },
      borderRadius: const BorderRadius.all(
        Radius.circular(AppSpacing.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
