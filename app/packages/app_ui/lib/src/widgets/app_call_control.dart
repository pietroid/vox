import 'package:app_ui/src/app_icons/app_icon_data.dart';
import 'package:app_ui/src/app_icons/app_icon_widget.dart';
import 'package:app_ui/src/theme/app_colors.dart';
import 'package:app_ui/src/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// {@template app_call_control}
/// One of a call's round buttons: big enough to hit without looking.
///
/// A plain control sits on [AppColors.fillStrong]. When [on] (the mic
/// muted, the captions hidden: a setting moved away from its default) it
/// turns to [AppColors.ink], the way a phone shows a toggled call button.
/// [AppCallControl.hangUp] is the one red thing on the screen.
/// {@endtemplate}
class AppCallControl extends StatelessWidget {
  /// {@macro app_call_control}
  const AppCallControl({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.on = false,
    super.key,
  }) : _hangUp = false;

  /// {@macro app_call_control}
  const AppCallControl.hangUp({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  }) : on = false,
       _hangUp = true;

  /// The glyph.
  final AppIconData icon;

  /// What the button does, read by screen readers and shown on a long
  /// press.
  final String label;

  /// Called on a tap.
  final VoidCallback? onPressed;

  /// Whether a toggle is moved from its default.
  final bool on;

  final bool _hangUp;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _hangUp
        ? (AppColors.negative, AppColors.onNegative)
        : on
        ? (AppColors.ink, AppColors.bg)
        : (AppColors.fillStrong, AppColors.ink);

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        toggled: _hangUp ? null : on,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: background,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: AppSpacing.callControl,
              child: Center(
                child: AppIcon(
                  iconData: icon,
                  color: foreground,
                  size: _hangUp ? AppSpacing.iconSize + 4 : AppSpacing.iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
