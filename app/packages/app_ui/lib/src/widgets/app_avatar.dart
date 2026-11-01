import 'package:app_ui/app_ui.dart';

/// {@template app_avatar}
/// A coach, round: the initial of their name in the serif, on a fill, with
/// the language they speak in a small tag at the foot ("PT", "EN").
///
/// [selected] rings it in the accent, as the picked one among a few.
/// {@endtemplate}
class AppAvatar extends StatelessWidget {
  /// {@macro app_avatar}
  const AppAvatar({
    required this.name,
    this.tag,
    this.size = AppSpacing.avatar,
    this.selected = false,
    super.key,
  });

  /// The coach's name; its first letter is drawn.
  final String name;

  /// The short tag at the foot, the language.
  final String? tag;

  /// The diameter.
  final double size;

  /// Whether it is the one picked.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tag = this.tag;
    final initial = name.isEmpty ? '' : name.characters.first.toUpperCase();

    return SizedBox(
      width: size,
      height: size + (tag == null ? 0 : AppSpacing.s2),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.accentSoft : AppColors.fillStrong,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.accent : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              initial,
              style: AppTypography.serif(size: size * 0.46).copyWith(
                color: selected ? AppColors.accent : AppColors.ink,
              ),
            ),
          ),
          if (tag != null)
            Positioned(
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppSpacing.pillRadius),
                  ),
                  border: Border.all(color: AppColors.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s1 + 2,
                  ),
                  child: Text(
                    tag,
                    style: AppTypography.tag,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
