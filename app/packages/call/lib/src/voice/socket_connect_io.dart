import 'package:call/src/voice/socket_voice_line.dart';
import 'package:call/src/voice/voice_line.dart';

/// The phones can call.
const socketsSupported = true;

/// Opens the call's socket at [uri], signed in with [token].
Future<VoiceLine> connectVoice(Uri uri, {String? token}) =>
    SocketVoiceLine.connect(uri, token: token);
