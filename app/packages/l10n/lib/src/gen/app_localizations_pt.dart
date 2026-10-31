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
  String get homeEmptyTitle => 'Tudo pronto';

  @override
  String get homeEmptyBody => 'Esta tela está em branco. É aqui que o app começa.';

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
  String get homeCallTitle => 'Pronto para ensaiar?';

  @override
  String get homeCallBody => 'Ligue e fale como falaria de verdade. O Vox responde quando você terminar.';

  @override
  String get homeCallStart => 'Começar ligação';

  @override
  String get homeWrite => 'Prefiro escrever';

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
}
