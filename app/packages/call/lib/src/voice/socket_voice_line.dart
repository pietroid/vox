import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:call/src/voice/voice_line.dart';
import 'package:web_socket_channel/io.dart';

/// {@template socket_voice_line}
/// The [VoiceLine] over a WebSocket, signed in with the bearer token the
/// phone keeps.
/// {@endtemplate}
class SocketVoiceLine implements VoiceLine {
  SocketVoiceLine._(this._channel) {
    _channel.stream.listen(
      _onMessage,
      onError: (Object _) {},
      onDone: () {
        _events.add(VoiceClosed(_channel.closeCode));
        unawaited(_events.close());
      },
    );
  }

  /// Opens the call at [uri], signed in with [token].
  static Future<VoiceLine> connect(Uri uri, {String? token}) async {
    final channel = IOWebSocketChannel.connect(
      uri,
      headers: {
        if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
      },
      pingInterval: const Duration(seconds: 20),
    );
    await channel.ready;
    return SocketVoiceLine._(channel);
  }

  final IOWebSocketChannel _channel;
  final _events = StreamController<VoiceEvent>();

  @override
  Stream<VoiceEvent> get events => _events.stream;

  void _onMessage(dynamic message) {
    if (message is List<int>) {
      _events.add(VoiceAudio(Uint8List.fromList(message)));
      return;
    }
    if (message is! String) return;
    final Object? json;
    try {
      json = jsonDecode(message);
    } on FormatException {
      return;
    }
    if (json is! Map<String, dynamic>) return;
    final event = switch (json) {
      {'type': 'state', 'state': 'listening'} => const VoicePhase(
        ServerPhase.listening,
      ),
      {'type': 'state', 'state': 'thinking'} => const VoicePhase(
        ServerPhase.thinking,
      ),
      {'type': 'state', 'state': 'speaking'} => const VoicePhase(
        ServerPhase.speaking,
      ),
      {'type': 'caption', 'text': final String text} => VoiceCaption(text),
      {'type': 'interrupt'} => const VoiceInterrupt(),
      _ => null,
    };
    if (event != null) _events.add(event);
  }

  @override
  void sendAudio(Uint8List pcm) => _channel.sink.add(pcm);

  @override
  void mute({required bool muted}) =>
      _channel.sink.add(jsonEncode({'type': 'mute', 'muted': muted}));

  @override
  Future<void> close() => _channel.sink.close(1000);
}
