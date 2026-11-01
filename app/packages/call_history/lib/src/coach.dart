import 'package:l10n/l10n.dart';

/// The language a coach speaks, and the call with them is in.
enum CoachLanguage {
  /// Brazilian Portuguese.
  pt,

  /// English.
  en;

  /// Its name, as a group heading ("Português").
  String label(AppLocalizations l10n) => switch (this) {
    pt => l10n.languagePortuguese,
    en => l10n.languageEnglish,
  };

  /// Its short tag on an avatar ("PT").
  String tag(AppLocalizations l10n) => switch (this) {
    pt => l10n.languageTagPt,
    en => l10n.languageTagEn,
  };
}

/// {@template coach}
/// Who coaches a subject: a voice and a language, picked when the subject
/// starts and kept for every call on it.
///
/// The coach is named after the Flux TTS voice they speak with, so the
/// name the person picks is the voice they hear.
/// {@endtemplate}
enum Coach {
  /// Portuguese, a woman's voice. Every call before coaches existed.
  bianca(CoachLanguage.pt, 'flux-bianca-pt'),

  /// Portuguese, a man's voice.
  bruno(CoachLanguage.pt, 'flux-bruno-pt'),

  /// English, a woman's voice.
  haley(CoachLanguage.en, 'flux-haley-en'),

  /// English, a man's voice.
  marcus(CoachLanguage.en, 'flux-marcus-en');

  const Coach(this.language, this.voice);

  /// The language the calls are in.
  final CoachLanguage language;

  /// The Flux TTS voice, as the server names it.
  final String voice;

  /// The coach the server keeps as [key] (its [name]); [bianca] otherwise,
  /// the voice every earlier call had.
  static Coach fromKey(String? key) {
    for (final coach in values) {
      if (coach.name == key) return coach;
    }
    return bianca;
  }

  /// The name on their avatar.
  String label(AppLocalizations l10n) => switch (this) {
    bianca => l10n.coachBianca,
    bruno => l10n.coachBruno,
    haley => l10n.coachHaley,
    marcus => l10n.coachMarcus,
  };
}
