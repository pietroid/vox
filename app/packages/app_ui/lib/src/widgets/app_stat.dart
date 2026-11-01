import 'package:app_ui/app_ui.dart';

/// {@template app_stat}
/// One number in a tile: its glyph, the value, a two-word label, and how it
/// moved, as an arrow and the change ("↘ 3"), not a sentence.
///
/// The arrow is [AppColors.positive] only when [lowerIsBetter] and the
/// number fell; every other move stays neutral, since a faster pace or
/// more pauses is neither good nor bad on its own.
/// {@endtemplate}
class AppStat extends StatelessWidget {
  /// {@macro app_stat}
  const AppStat({
    required this.icon,
    required this.value,
    required this.label,
    this.delta,
    this.lowerIsBetter = false,
    super.key,
  });

  /// The glyph that says which number this is.
  final AppIconData icon;

  /// The number, already written.
  final String value;

  /// What it counts, in two words.
  final String label;

  /// The change since the first; nothing drawn when null or zero.
  final int? delta;

  /// Whether a fall is good news.
  final bool lowerIsBetter;

  @override
  Widget build(BuildContext context) {
    final d = delta;
    final moved = d != null && d != 0;
    final color = moved && lowerIsBetter && d < 0
        ? AppColors.positive
        : AppColors.ink2;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            iconData: icon,
            size: AppSpacing.iconSmall + 2,
            color: AppColors.ink2,
          ),
          const SizedBox(height: AppSpacing.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppTypography.headline),
              if (moved) ...[
                const SizedBox(width: AppSpacing.s1 + 2),
                AppIcon(
                  iconData: d > 0 ? AppIcons.trendUp : AppIcons.trendDown,
                  size: AppSpacing.iconSmall,
                  color: color,
                ),
                const SizedBox(width: 2),
                Text(
                  '${d.abs()}',
                  style: AppTypography.labelStrong.copyWith(color: color),
                ),
              ],
            ],
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
