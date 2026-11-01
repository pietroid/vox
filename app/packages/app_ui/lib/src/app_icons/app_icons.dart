import 'package:app_ui/src/app_icons/app_icon_data.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// {@template app_icons}
/// A collection of app icons used throughout the application.
///
/// Icons default to Phosphor; SVG assets are kept only for brand logos
/// that are not available in the Phosphor set.
/// {@endtemplate}
class AppIcons {
  /// Google Icon (SVG asset).
  static const google = AppIconData.asset('google');

  /// The assistant. A placeholder until the app has a mark of its own for
  /// it (`/design-system`): never a sparkle, a wand or a robot.
  static const assistant = AppIconData.phosphor(
    PhosphorIconsRegular.chatCircleDots,
  );

  /// Sends a message.
  static const send = AppIconData.phosphor(PhosphorIconsRegular.paperPlaneTilt);

  /// Leaves the account.
  static const signOut = AppIconData.phosphor(PhosphorIconsRegular.signOut);

  /// Closes a page or a sheet.
  static const close = AppIconData.phosphor(PhosphorIconsRegular.x);

  /// Starts a call with the agent.
  static const call = AppIconData.phosphor(PhosphorIconsRegular.phone);

  /// The microphone, open: the call's mute button.
  static const microphone = AppIconData.phosphor(
    PhosphorIconsRegular.microphone,
  );

  /// The microphone, muted.
  static const microphoneOff = AppIconData.phosphor(
    PhosphorIconsRegular.microphoneSlash,
  );

  /// The call's live captions, shown.
  static const captions = AppIconData.phosphor(PhosphorIconsRegular.subtitles);

  /// The call's live captions, hidden.
  static const captionsOff = AppIconData.phosphor(
    PhosphorIconsRegular.subtitlesSlash,
  );

  /// Ends a call: the receiver put down, filled.
  static const hangUp = AppIconData.phosphor(
    PhosphorIconsFill.phoneDisconnect,
  );

  /// Back to the page before.
  static const back = AppIconData.phosphor(PhosphorIconsRegular.arrowLeft);

  /// Opens a row: the caret at the end of a tappable card.
  static const chevron = AppIconData.phosphor(PhosphorIconsRegular.caretRight);

  /// How long a call took.
  static const duration = AppIconData.phosphor(PhosphorIconsRegular.clock);

  /// What a call cost, in dollars.
  static const cost = AppIconData.phosphor(PhosphorIconsRegular.coins);

  /// A call that follows up an earlier one on the same subject.
  static const followUp = AppIconData.phosphor(
    PhosphorIconsRegular.arrowBendDownRight,
  );

  /// Something the person learned in a call.
  static const learning = AppIconData.phosphor(PhosphorIconsRegular.lightbulb);

  /// The pace of speech, in words a minute.
  static const pace = AppIconData.phosphor(PhosphorIconsRegular.gauge);

  /// The long pauses in a talk.
  static const pauses = AppIconData.phosphor(PhosphorIconsRegular.pause);

  /// The hesitations in a talk: voice with no word in it.
  static const hesitations = AppIconData.phosphor(
    PhosphorIconsRegular.waveform,
  );

  /// Goal: presenting at work.
  static const goalPresentations = AppIconData.phosphor(
    PhosphorIconsRegular.presentationChart,
  );

  /// Goal: job interviews.
  static const goalInterviews = AppIconData.phosphor(
    PhosphorIconsRegular.briefcase,
  );

  /// Goal: speaking up in meetings.
  static const goalMeetings = AppIconData.phosphor(
    PhosphorIconsRegular.usersThree,
  );

  /// Goal: teaching a class.
  static const goalTeaching = AppIconData.phosphor(
    PhosphorIconsRegular.chalkboardTeacher,
  );

  /// Goal: recording a podcast or a video.
  static const goalRecording = AppIconData.phosphor(
    PhosphorIconsRegular.microphoneStage,
  );

  /// Goal: speaking more calmly.
  static const goalCalm = AppIconData.phosphor(PhosphorIconsRegular.wind);

  /// Goal: anything else.
  static const goalOther = AppIconData.phosphor(PhosphorIconsRegular.dotsThree);
}
