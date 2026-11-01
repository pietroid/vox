// dart format off
// coverage:ignore-file
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('pt')
  ];

  /// The app's name, as it is written everywhere.
  ///
  /// In pt, this message translates to:
  /// **'Vox'**
  String get appName;

  /// No description provided for @authSignIn.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get authSignIn;

  /// No description provided for @authSignInWithGoogle.
  ///
  /// In pt, this message translates to:
  /// **'Entrar com Google'**
  String get authSignInWithGoogle;

  /// No description provided for @authSignInFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível entrar'**
  String get authSignInFailed;

  /// The greeting at the top of the home screen.
  ///
  /// In pt, this message translates to:
  /// **'Olá, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingAnonymous.
  ///
  /// In pt, this message translates to:
  /// **'Olá'**
  String get homeGreetingAnonymous;

  /// No description provided for @homeSignOut.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get homeSignOut;

  /// No description provided for @assistantOpen.
  ///
  /// In pt, this message translates to:
  /// **'Falar com o assistente'**
  String get assistantOpen;

  /// No description provided for @assistantTitle.
  ///
  /// In pt, this message translates to:
  /// **'Assistente'**
  String get assistantTitle;

  /// No description provided for @assistantHint.
  ///
  /// In pt, this message translates to:
  /// **'Pergunte qualquer coisa'**
  String get assistantHint;

  /// No description provided for @assistantSend.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get assistantSend;

  /// No description provided for @assistantEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Como posso ajudar?'**
  String get assistantEmpty;

  /// No description provided for @assistantFailed.
  ///
  /// In pt, this message translates to:
  /// **'O assistente não respondeu. Tente de novo.'**
  String get assistantFailed;

  /// No description provided for @homeCallStart.
  ///
  /// In pt, this message translates to:
  /// **'Começar ligação'**
  String get homeCallStart;

  /// No description provided for @callTitle.
  ///
  /// In pt, this message translates to:
  /// **'Assistente'**
  String get callTitle;

  /// No description provided for @callConnecting.
  ///
  /// In pt, this message translates to:
  /// **'Conectando…'**
  String get callConnecting;

  /// No description provided for @callListening.
  ///
  /// In pt, this message translates to:
  /// **'Ouvindo'**
  String get callListening;

  /// No description provided for @callThinking.
  ///
  /// In pt, this message translates to:
  /// **'Pensando'**
  String get callThinking;

  /// No description provided for @callSpeaking.
  ///
  /// In pt, this message translates to:
  /// **'Falando'**
  String get callSpeaking;

  /// No description provided for @callMuted.
  ///
  /// In pt, this message translates to:
  /// **'Microfone desligado'**
  String get callMuted;

  /// No description provided for @callMute.
  ///
  /// In pt, this message translates to:
  /// **'Desligar o microfone'**
  String get callMute;

  /// No description provided for @callUnmute.
  ///
  /// In pt, this message translates to:
  /// **'Ligar o microfone'**
  String get callUnmute;

  /// No description provided for @callCaptionsHide.
  ///
  /// In pt, this message translates to:
  /// **'Esconder legendas'**
  String get callCaptionsHide;

  /// No description provided for @callCaptionsShow.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar legendas'**
  String get callCaptionsShow;

  /// No description provided for @callHangUp.
  ///
  /// In pt, this message translates to:
  /// **'Encerrar ligação'**
  String get callHangUp;

  /// No description provided for @callUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'A ligação não está disponível agora. Tente mais tarde ou converse por escrito.'**
  String get callUnavailable;

  /// No description provided for @callDropped.
  ///
  /// In pt, this message translates to:
  /// **'A ligação caiu. Tente de novo.'**
  String get callDropped;

  /// No description provided for @callMicrophoneDenied.
  ///
  /// In pt, this message translates to:
  /// **'O Vox precisa do microfone para a ligação. Permita o acesso nos Ajustes do telefone.'**
  String get callMicrophoneDenied;

  /// The top bar's icon that opens the written chat.
  ///
  /// In pt, this message translates to:
  /// **'Conversar por escrito'**
  String get homeOpenAssistant;

  /// The first-run home's headline, before the first call.
  ///
  /// In pt, this message translates to:
  /// **'Vamos ouvir sua voz'**
  String get homeOnboardingTitle;

  /// No description provided for @homeOnboardingBody.
  ///
  /// In pt, this message translates to:
  /// **'Na primeira ligação, você fala por uns três minutos e o Vox devolve seu ritmo, suas pausas e o que treinar.'**
  String get homeOnboardingBody;

  /// No description provided for @homeGoalQuestion.
  ///
  /// In pt, this message translates to:
  /// **'O que te traz aqui?'**
  String get homeGoalQuestion;

  /// No description provided for @homeGoalHint.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um. A primeira ligação começa por aí.'**
  String get homeGoalHint;

  /// No description provided for @homeFirstCallStart.
  ///
  /// In pt, this message translates to:
  /// **'Fazer minha primeira ligação'**
  String get homeFirstCallStart;

  /// No description provided for @homeFirstCallNote.
  ///
  /// In pt, this message translates to:
  /// **'Uns três minutos · só você e o Vox'**
  String get homeFirstCallNote;

  /// No description provided for @goalPresentations.
  ///
  /// In pt, this message translates to:
  /// **'Apresentações'**
  String get goalPresentations;

  /// No description provided for @goalInterviews.
  ///
  /// In pt, this message translates to:
  /// **'Entrevistas'**
  String get goalInterviews;

  /// No description provided for @goalMeetings.
  ///
  /// In pt, this message translates to:
  /// **'Reuniões'**
  String get goalMeetings;

  /// No description provided for @goalTeaching.
  ///
  /// In pt, this message translates to:
  /// **'Aulas'**
  String get goalTeaching;

  /// No description provided for @goalRecording.
  ///
  /// In pt, this message translates to:
  /// **'Podcast e vídeo'**
  String get goalRecording;

  /// No description provided for @goalCalm.
  ///
  /// In pt, this message translates to:
  /// **'Falar com calma'**
  String get goalCalm;

  /// No description provided for @goalOther.
  ///
  /// In pt, this message translates to:
  /// **'Outra coisa'**
  String get goalOther;

  /// What the first call does for this goal.
  ///
  /// In pt, this message translates to:
  /// **'O Vox vai pedir que você apresente um tema do seu trabalho em um minuto, como numa reunião de verdade.'**
  String get goalPresentationsPlan;

  /// No description provided for @goalInterviewsPlan.
  ///
  /// In pt, this message translates to:
  /// **'O Vox faz de entrevistador: uma pergunta clássica, sua resposta, e o que ela passou.'**
  String get goalInterviewsPlan;

  /// No description provided for @goalMeetingsPlan.
  ///
  /// In pt, this message translates to:
  /// **'O Vox simula uma reunião e pede sua opinião sobre um tema. Você treina falar sem rodeios.'**
  String get goalMeetingsPlan;

  /// No description provided for @goalTeachingPlan.
  ///
  /// In pt, this message translates to:
  /// **'Você explica um assunto que conhece como se fosse para a turma, e o Vox mede seu ritmo.'**
  String get goalTeachingPlan;

  /// No description provided for @goalRecordingPlan.
  ///
  /// In pt, this message translates to:
  /// **'Você grava uma abertura de episódio, e o Vox ouve como ela soaria para quem escuta.'**
  String get goalRecordingPlan;

  /// No description provided for @goalCalmPlan.
  ///
  /// In pt, this message translates to:
  /// **'Uma conversa leve, sem pressa. O Vox mostra onde sua fala acelera.'**
  String get goalCalmPlan;

  /// No description provided for @goalOtherPlan.
  ///
  /// In pt, this message translates to:
  /// **'O Vox começa perguntando o que você quer treinar, e segue a partir daí.'**
  String get goalOtherPlan;

  /// The home's call-out right after the first call.
  ///
  /// In pt, this message translates to:
  /// **'Primeira ligação feita'**
  String get homeFirstDoneTitle;

  /// No description provided for @homeFirstDoneBody.
  ///
  /// In pt, this message translates to:
  /// **'Seu resumo está logo abaixo. Ligue de novo quando quiser: o Vox lembra do que vocês conversaram.'**
  String get homeFirstDoneBody;

  /// The home's call-out once there is a history.
  ///
  /// In pt, this message translates to:
  /// **'Pronto para a próxima?'**
  String get homeNextTitle;

  /// The last call's first learning, under the call-out.
  ///
  /// In pt, this message translates to:
  /// **'Da última vez: {learning}'**
  String homeNextLastLearning(String learning);

  /// The call-out's line when the last call left no learning.
  ///
  /// In pt, this message translates to:
  /// **'Ligue quando quiser: o Vox lembra do que vocês conversaram.'**
  String get homeNextBody;

  /// No description provided for @historyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Suas ligações'**
  String get historyTitle;

  /// While the server writes the notes of the call that just ended.
  ///
  /// In pt, this message translates to:
  /// **'Escrevendo o resumo da sua ligação…'**
  String get historySummarizing;

  /// No description provided for @historyLoadFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não deu para carregar suas ligações.'**
  String get historyLoadFailed;

  /// No description provided for @historyRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get historyRetry;

  /// No description provided for @callLoadFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não deu para abrir esta ligação.'**
  String get callLoadFailed;

  /// Under the history's title: how many calls and how long they took together.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 ligação} other{{count} ligações}} · {duration}'**
  String historyTotals(int count, String duration);

  /// The badge on a call the person has not opened yet.
  ///
  /// In pt, this message translates to:
  /// **'Nova'**
  String get callNew;

  /// No description provided for @callToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje, {time}'**
  String callToday(String time);

  /// No description provided for @callYesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem, {time}'**
  String callYesterday(String time);

  /// No description provided for @callOnDay.
  ///
  /// In pt, this message translates to:
  /// **'{day}, {time}'**
  String callOnDay(String day, String time);

  /// No description provided for @callMinutes.
  ///
  /// In pt, this message translates to:
  /// **'{minutes} min'**
  String callMinutes(int minutes);

  /// No description provided for @callMinutesSeconds.
  ///
  /// In pt, this message translates to:
  /// **'{minutes} min {seconds} s'**
  String callMinutesSeconds(int minutes, int seconds);

  /// What a call cost, in dollars, the amount already written with a comma.
  ///
  /// In pt, this message translates to:
  /// **'US\$ {amount}'**
  String callCost(String amount);

  /// On a call that follows up an earlier one: which call on the subject it is.
  ///
  /// In pt, this message translates to:
  /// **'{index}ª do assunto'**
  String callSubjectIndex(int index);

  /// No description provided for @callDetailSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get callDetailSummary;

  /// No description provided for @callDetailLearnings.
  ///
  /// In pt, this message translates to:
  /// **'O que levar daqui'**
  String get callDetailLearnings;

  /// No description provided for @callDetailNumbers.
  ///
  /// In pt, this message translates to:
  /// **'Seus números'**
  String get callDetailNumbers;

  /// No description provided for @metricPace.
  ///
  /// In pt, this message translates to:
  /// **'palavras/min'**
  String get metricPace;

  /// No description provided for @metricPauses.
  ///
  /// In pt, this message translates to:
  /// **'pausas longas'**
  String get metricPauses;

  /// No description provided for @metricHesitations.
  ///
  /// In pt, this message translates to:
  /// **'hesitações'**
  String get metricHesitations;

  /// How a number moved since the first call on the subject, signed.
  ///
  /// In pt, this message translates to:
  /// **'{delta} desde a 1ª'**
  String metricSinceFirst(String delta);

  /// The detail's one button: a new call that picks up this one.
  ///
  /// In pt, this message translates to:
  /// **'Continuar este assunto'**
  String get callFollowUpStart;

  /// No description provided for @callFollowUpNote.
  ///
  /// In pt, this message translates to:
  /// **'O Vox lembra desta conversa e começa de onde vocês pararam.'**
  String get callFollowUpNote;

  /// The home's one button: picks a coach and starts a call on a new subject.
  ///
  /// In pt, this message translates to:
  /// **'Novo assunto'**
  String get homeNewSubject;

  /// The heading over the list of subjects on the home.
  ///
  /// In pt, this message translates to:
  /// **'Seus assuntos'**
  String get subjectsTitle;

  /// The heading over a subject's calls on its page.
  ///
  /// In pt, this message translates to:
  /// **'Ligações'**
  String get subjectCallsTitle;

  /// The subject page's one button: calls the same coach again on it.
  ///
  /// In pt, this message translates to:
  /// **'Continuar com {coach}'**
  String subjectContinue(String coach);

  /// Which call on its subject this is, in a small round badge.
  ///
  /// In pt, this message translates to:
  /// **'{index}ª'**
  String callSubjectIndexShort(int index);

  /// The coach sheet's heading.
  ///
  /// In pt, this message translates to:
  /// **'Novo assunto'**
  String get coachPickerTitle;

  /// Under the coach sheet's heading: the coach is kept for every call on the subject.
  ///
  /// In pt, this message translates to:
  /// **'Quem te acompanha nele? Fica o mesmo até o fim do assunto.'**
  String get coachPickerBody;

  /// The coach sheet's button: starts the subject's first call.
  ///
  /// In pt, this message translates to:
  /// **'Começar com {coach}'**
  String coachPickerStart(String coach);

  /// Tooltip of the speaker button that plays a coach's voice.
  ///
  /// In pt, this message translates to:
  /// **'Ouvir {coach}'**
  String coachPickerListen(String coach);

  /// A coach's name: the Flux TTS voice's own name, never translated.
  ///
  /// In pt, this message translates to:
  /// **'Bianca'**
  String get coachBianca;

  /// No description provided for @coachBruno.
  ///
  /// In pt, this message translates to:
  /// **'Bruno'**
  String get coachBruno;

  /// No description provided for @coachHaley.
  ///
  /// In pt, this message translates to:
  /// **'Haley'**
  String get coachHaley;

  /// No description provided for @coachMarcus.
  ///
  /// In pt, this message translates to:
  /// **'Marcus'**
  String get coachMarcus;

  /// A coach group: the calls are in Brazilian Portuguese.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// A coach group: the calls are in English.
  ///
  /// In pt, this message translates to:
  /// **'Inglês'**
  String get languageEnglish;

  /// The tiny language tag on a coach's avatar.
  ///
  /// In pt, this message translates to:
  /// **'PT'**
  String get languageTagPt;

  /// No description provided for @languageTagEn.
  ///
  /// In pt, this message translates to:
  /// **'EN'**
  String get languageTagEn;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
