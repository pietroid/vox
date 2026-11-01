import 'package:call/src/voice/devices.dart';
import 'package:call/src/voice/socket_connect_stub.dart'
    if (dart.library.io) 'package:call/src/voice/socket_connect_io.dart';
import 'package:call/src/voice/voice_line.dart';

/// {@template call_service}
/// What a call needs from outside: the socket to the server, the mic and
/// the speaker. The app gives the real ones; tests and previews fakes.
/// {@endtemplate}
abstract interface class CallService {
  /// Whether this platform can call at all (the phones, for now).
  bool get supported;

  /// Opens the call; [follows] is the id of the call it continues, and
  /// [coach] who starts a new subject (a follow-up keeps its own).
  Future<VoiceLine> dial({String? follows, String? coach});

  /// The mic, for one call.
  Microphone microphone();

  /// The speaker, for one call.
  VoicePlayer player();
}

/// {@template server_call_service}
/// Calls `wss <api>/assistant/voice`, signed in with the person's token.
/// {@endtemplate}
class ServerCallService implements CallService {
  /// {@macro server_call_service}
  ServerCallService({required this.apiBaseUrl, required this.token});

  /// Where the API lives, as the rest of the app reaches it.
  final String apiBaseUrl;

  /// The bearer token the phones keep; null on the web, which has its
  /// cookie.
  final Future<String?> Function() token;

  @override
  bool get supported => socketsSupported;

  /// The socket's address: the API's, with ws for http, `?follows=` when
  /// the call continues an earlier one, and `?coach=` when it starts a
  /// subject with someone.
  Uri uri({String? follows, String? coach}) {
    final api = Uri.base.resolve('$apiBaseUrl/assistant/voice');
    final query = {'follows': ?follows, 'coach': ?coach};
    return api.replace(
      scheme: api.scheme == 'https' ? 'wss' : 'ws',
      queryParameters: query.isEmpty ? null : query,
    );
  }

  @override
  Future<VoiceLine> dial({String? follows, String? coach}) async =>
      connectVoice(
        uri(follows: follows, coach: coach),
        token: await token(),
      );

  @override
  Microphone microphone() => RecordMicrophone();

  @override
  VoicePlayer player() => PcmVoicePlayer();
}
