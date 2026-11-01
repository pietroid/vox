import 'package:app_ui/app_ui.dart';
import 'package:l10n/l10n.dart';

/// What brought the person to Vox, asked before the first call. The first
/// call opens on it, and every later one remembers it.
enum SpeakingGoal {
  /// Presenting at work.
  presentations(AppIcons.goalPresentations),

  /// Job interviews.
  interviews(AppIcons.goalInterviews),

  /// Speaking up in meetings.
  meetings(AppIcons.goalMeetings),

  /// Teaching a class.
  teaching(AppIcons.goalTeaching),

  /// Recording a podcast or a video.
  recording(AppIcons.goalRecording),

  /// Speaking more calmly.
  calm(AppIcons.goalCalm),

  /// Anything else: the agent asks.
  other(AppIcons.goalOther);

  const SpeakingGoal(this.icon);

  /// The glyph on its chip.
  final AppIconData icon;

  /// The goal the server keeps as [key] (its [name]), if it is one.
  static SpeakingGoal? fromKey(String? key) {
    for (final goal in values) {
      if (goal.name == key) return goal;
    }
    return null;
  }

  /// Its name on the chip.
  String label(AppLocalizations l10n) => switch (this) {
    presentations => l10n.goalPresentations,
    interviews => l10n.goalInterviews,
    meetings => l10n.goalMeetings,
    teaching => l10n.goalTeaching,
    recording => l10n.goalRecording,
    calm => l10n.goalCalm,
    other => l10n.goalOther,
  };

  /// What the first call will do about it, in one sentence.
  String plan(AppLocalizations l10n) => switch (this) {
    presentations => l10n.goalPresentationsPlan,
    interviews => l10n.goalInterviewsPlan,
    meetings => l10n.goalMeetingsPlan,
    teaching => l10n.goalTeachingPlan,
    recording => l10n.goalRecordingPlan,
    calm => l10n.goalCalmPlan,
    other => l10n.goalOtherPlan,
  };
}
