// dart format off
// coverage:ignore-file

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Vox';

  @override
  String get authSignIn => 'Entrar';

  @override
  String get authSignInWithGoogle => 'Entrar com Google';

  @override
  String get authSignInFailed => 'Não foi possível entrar';

  @override
  String homeGreeting(String name) {
    return 'Olá, $name';
  }

  @override
  String get homeGreetingAnonymous => 'Olá';

  @override
  String get homeSignOut => 'Sair';

  @override
  String get assistantOpen => 'Falar com o assistente';

  @override
  String get assistantTitle => 'Assistente';

  @override
  String get assistantHint => 'Pergunte qualquer coisa';

  @override
  String get assistantSend => 'Enviar';

  @override
  String get assistantEmpty => 'Como posso ajudar?';

  @override
  String get assistantFailed => 'O assistente não respondeu. Tente de novo.';

  @override
  String get homeCallStart => 'Começar ligação';

  @override
  String get callTitle => 'Assistente';

  @override
  String get callConnecting => 'Conectando…';

  @override
  String get callListening => 'Ouvindo';

  @override
  String get callThinking => 'Pensando';

  @override
  String get callSpeaking => 'Falando';

  @override
  String get callMuted => 'Microfone desligado';

  @override
  String get callMute => 'Desligar o microfone';

  @override
  String get callUnmute => 'Ligar o microfone';

  @override
  String get callCaptionsHide => 'Esconder legendas';

  @override
  String get callCaptionsShow => 'Mostrar legendas';

  @override
  String get callHangUp => 'Encerrar ligação';

  @override
  String get callUnavailable => 'A ligação não está disponível agora. Tente mais tarde ou converse por escrito.';

  @override
  String get callDropped => 'A ligação caiu. Tente de novo.';

  @override
  String get callMicrophoneDenied => 'O Vox precisa do microfone para a ligação. Permita o acesso nos Ajustes do telefone.';

  @override
  String get homeOpenAssistant => 'Conversar por escrito';

  @override
  String get homeOnboardingTitle => 'Vamos ouvir sua voz';

  @override
  String get homeOnboardingBody => 'Na primeira ligação, você fala por uns três minutos e o Vox devolve seu ritmo, suas pausas e o que treinar.';

  @override
  String get homeGoalQuestion => 'O que te traz aqui?';

  @override
  String get homeGoalHint => 'Escolha um. A primeira ligação começa por aí.';

  @override
  String get homeFirstCallStart => 'Fazer minha primeira ligação';

  @override
  String get homeFirstCallNote => 'Uns três minutos · só você e o Vox';

  @override
  String get goalPresentations => 'Apresentações';

  @override
  String get goalInterviews => 'Entrevistas';

  @override
  String get goalMeetings => 'Reuniões';

  @override
  String get goalTeaching => 'Aulas';

  @override
  String get goalRecording => 'Podcast e vídeo';

  @override
  String get goalCalm => 'Falar com calma';

  @override
  String get goalOther => 'Outra coisa';

  @override
  String get goalPresentationsPlan => 'O Vox vai pedir que você apresente um tema do seu trabalho em um minuto, como numa reunião de verdade.';

  @override
  String get goalInterviewsPlan => 'O Vox faz de entrevistador: uma pergunta clássica, sua resposta, e o que ela passou.';

  @override
  String get goalMeetingsPlan => 'O Vox simula uma reunião e pede sua opinião sobre um tema. Você treina falar sem rodeios.';

  @override
  String get goalTeachingPlan => 'Você explica um assunto que conhece como se fosse para a turma, e o Vox mede seu ritmo.';

  @override
  String get goalRecordingPlan => 'Você grava uma abertura de episódio, e o Vox ouve como ela soaria para quem escuta.';

  @override
  String get goalCalmPlan => 'Uma conversa leve, sem pressa. O Vox mostra onde sua fala acelera.';

  @override
  String get goalOtherPlan => 'O Vox começa perguntando o que você quer treinar, e segue a partir daí.';

  @override
  String get homeFirstDoneTitle => 'Primeira ligação feita';

  @override
  String get homeFirstDoneBody => 'Seu resumo está logo abaixo. Ligue de novo quando quiser: o Vox lembra do que vocês conversaram.';

  @override
  String get homeNextTitle => 'Pronto para a próxima?';

  @override
  String homeNextLastLearning(String learning) {
    return 'Da última vez: $learning';
  }

  @override
  String get homeNextBody => 'Ligue quando quiser: o Vox lembra do que vocês conversaram.';

  @override
  String get historyTitle => 'Suas ligações';

  @override
  String get historySummarizing => 'Escrevendo o resumo da sua ligação…';

  @override
  String get historyLoadFailed => 'Não deu para carregar suas ligações.';

  @override
  String get historyRetry => 'Tentar de novo';

  @override
  String get callLoadFailed => 'Não deu para abrir esta ligação.';

  @override
  String historyTotals(int count, String duration) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ligações',
      one: '1 ligação',
    );
    return '$_temp0 · $duration';
  }

  @override
  String get callNew => 'Nova';

  @override
  String callToday(String time) {
    return 'Hoje, $time';
  }

  @override
  String callYesterday(String time) {
    return 'Ontem, $time';
  }

  @override
  String callOnDay(String day, String time) {
    return '$day, $time';
  }

  @override
  String callMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String callMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String callCost(String amount) {
    return 'US\$ $amount';
  }

  @override
  String callSubjectIndex(int index) {
    return '$indexª do assunto';
  }

  @override
  String get callDetailSummary => 'Resumo';

  @override
  String get callDetailLearnings => 'O que levar daqui';

  @override
  String get callDetailNumbers => 'Seus números';

  @override
  String get metricPace => 'palavras/min';

  @override
  String get metricPauses => 'pausas longas';

  @override
  String get metricHesitations => 'hesitações';

  @override
  String metricSinceFirst(String delta) {
    return '$delta desde a 1ª';
  }

  @override
  String get callFollowUpStart => 'Continuar este assunto';

  @override
  String get callFollowUpNote => 'O Vox lembra desta conversa e começa de onde vocês pararam.';
}
