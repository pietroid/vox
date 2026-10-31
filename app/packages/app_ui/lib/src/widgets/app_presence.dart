import 'dart:async';

import 'package:app_ui/src/theme/app_colors.dart';
import 'package:app_ui/src/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// What the agent in a call is doing, as [AppPresence] draws it.
enum AppPresenceState {
  /// The person has the turn: a hollow ring, with a faint halo that follows
  /// the person's voice.
  listening,

  /// The turn has ended and the reply has not started: the dot breathes and
  /// nothing else moves.
  thinking,

  /// The agent is talking: filled, with teal rings that swell with its
  /// voice.
  speaking,

  /// The person's microphone is off: the hollow ring, still, with no halo.
  muted,
}

/// {@template app_presence}
/// The agent's presence in a call: the dot from the mark, made a voice.
///
/// [level] is the loudness of whoever is talking (the person while
/// [AppPresenceState.listening], the agent while
/// [AppPresenceState.speaking]), from 0 (silence) to 1, measured on the
/// phone about twenty times a second. The halo grows with it, so the
/// person sees they are heard without a meter.
///
/// With reduced motion on, the dot does not breathe; the halo still
/// follows the voice, since that is information rather than decoration.
/// {@endtemplate}
class AppPresence extends StatefulWidget {
  /// {@macro app_presence}
  const AppPresence({
    required this.state,
    this.level = 0,
    super.key,
  });

  /// What the agent is doing.
  final AppPresenceState state;

  /// The loudness of the voice the halo follows, 0 to 1.
  final double level;

  @override
  State<AppPresence> createState() => _AppPresenceState();
}

class _AppPresenceState extends State<AppPresence>
    with SingleTickerProviderStateMixin {
  // The breath of Pensando: 2.4 s a cycle, as in the design system.
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBreath();
  }

  @override
  void didUpdateWidget(AppPresence oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBreath();
  }

  void _syncBreath() {
    final breathe =
        widget.state == AppPresenceState.thinking &&
        !MediaQuery.disableAnimationsOf(context);
    if (breathe && !_breath.isAnimating) {
      unawaited(_breath.repeat());
    } else if (!breathe && _breath.isAnimating) {
      _breath
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final level = widget.level.clamp(0.0, 1.0);
    final hollow =
        state == AppPresenceState.listening || state == AppPresenceState.muted;
    final hasHalo =
        state == AppPresenceState.listening ||
        state == AppPresenceState.speaking;
    // The person's halo is the ink, quiet; the agent's rings are teal.
    final haloColor = state == AppPresenceState.speaking
        ? AppColors.accent
        : AppColors.ink;

    return SizedBox.square(
      dimension: AppSpacing.presence,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasHalo) ...[
            _Ring(
              scale: _dotShare + (1 - _dotShare) * level,
              color: haloColor.withValues(alpha: 0.10),
            ),
            _Ring(
              scale: _dotShare + (1 - _dotShare) * level * 0.7,
              color: haloColor.withValues(alpha: 0.14),
            ),
          ],
          AnimatedBuilder(
            animation: _breath,
            builder: (context, child) {
              // 1 → 0.82 → 1 in scale, 1 → 0.7 → 1 in opacity.
              final t = Curves.easeInOut.transform(
                1 - (2 * _breath.value - 1).abs(),
              );
              return Opacity(
                opacity: 1 - 0.3 * t,
                child: Transform.scale(scale: 1 - 0.18 * t, child: child),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _dot,
              height: _dot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hollow ? Colors.transparent : AppColors.accent,
                border: hollow
                    ? Border.all(
                        color: state == AppPresenceState.muted
                            ? AppColors.ink3
                            : AppColors.accent,
                        width: 2,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// The dot is 56 of the 120 the presence takes; the halo grows from the
// dot's edge to the presence's.
const _dot = 56.0;
const double _dotShare = _dot / AppSpacing.presence;

class _Ring extends StatelessWidget {
  const _Ring({required this.scale, required this.color});

  final double scale;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 90),
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: const SizedBox.expand(),
      ),
    );
  }
}
