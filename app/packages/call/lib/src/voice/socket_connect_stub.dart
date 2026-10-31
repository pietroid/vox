import 'package:call/src/voice/voice_line.dart';

/// The web can't call yet: the RFC puts the phones first, and the mic and
/// player plugins the call uses are the phones'.
const socketsSupported = false;

/// Never reached: [socketsSupported] is false here.
Future<VoiceLine> connectVoice(Uri uri, {String? token}) =>
    throw UnsupportedError('No call on this platform');
