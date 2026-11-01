import WebSocket from 'ws';
import { TimedWord } from './speech-metrics';

/**
 * The two Deepgram sockets of a call, behind small interfaces so the
 * session can be tested over fakes: Flux STT listens, Flux TTS speaks.
 * The key never leaves the server.
 */

/** One Flux STT turn event (`TurnInfo`), with what the session reads. */
export interface TurnEvent {
  event:
    'StartOfTurn' | 'Update' | 'EagerEndOfTurn' | 'TurnResumed' | 'EndOfTurn';
  turnIndex: number;
  transcript: string;
  words: TimedWord[];
  /** Where the turn's audio starts and ends, in seconds of the stream. */
  windowStart: number;
  windowEnd: number;
  /** On EndOfTurn: `model` (meaning), `timeout` (silence) or `manual`. */
  trigger?: string;
}

/** Flux's end-of-turn knobs, changeable mid-stream by `Configure`. */
export interface TurnThresholds {
  eot_threshold: number;
  eot_timeout_ms: number;
}

export interface ListenerEvents {
  onTurn(event: TurnEvent): void;
  /** The socket closed; with an error when it wasn't asked to. */
  onClose(error?: string): void;
}

/** Flux STT, one socket per call. */
export interface Listener {
  /** PCM16, 16 kHz, mono. */
  send(pcm: Buffer): void;
  configure(thresholds: TurnThresholds): void;
  /** Ends the turn now (`trigger: manual`): the talk cap. */
  endTurn(): void;
  close(): void;
}

export interface SpeakerEvents {
  /** A sentence's audio is about to come (Flux TTS `SpeechStarted`). */
  onSentence(): void;
  /** PCM16, 24 kHz, mono. */
  onAudio(pcm: Buffer): void;
  /** A sentence's audio is all out, with the characters it billed. */
  onSentenceDone(chars: number): void;
  onClose(error?: string): void;
}

/** Flux TTS, one socket per call; one TTS turn per sentence. */
export interface Speaker {
  speak(sentence: string): void;
  /** Stops the sentence playing and drops the ones waiting. */
  interrupt(): void;
  close(): void;
}

/** Opens both sockets; one per call. */
export interface VoiceVendor {
  readonly configured: boolean;
  /** [language] hints Flux STT ('pt', 'en'). */
  listen(
    thresholds: TurnThresholds,
    events: ListenerEvents,
    language?: string,
  ): Listener;
  /** [voice] is the Flux TTS model, the coach's. */
  speaker(events: SpeakerEvents, voice?: string): Speaker;
}

/** The voice when none is named: Flux TTS, Brazilian Portuguese (`calls/coaches.ts`). */
export const VOICE = 'flux-bianca-pt';
/** The phone plays what the server sends at this rate. */
export const SPEECH_RATE = 24_000;

/** Deepgram over its WebSockets. Off without `DEEPGRAM_API_KEY`. */
export class Deepgram implements VoiceVendor {
  constructor(private readonly _key: string) {}

  get configured(): boolean {
    return this._key !== '';
  }

  private get _headers() {
    return { Authorization: `Token ${this._key}` };
  }

  listen(
    thresholds: TurnThresholds,
    events: ListenerEvents,
    language = 'pt',
  ): Listener {
    const url =
      'wss://api.deepgram.com/v2/listen?model=flux-general-multi' +
      `&language_hint=${language}&encoding=linear16&sample_rate=16000` +
      `&eot_threshold=${thresholds.eot_threshold}` +
      `&eot_timeout_ms=${thresholds.eot_timeout_ms}`;
    const socket = new WebSocket(url, { headers: this._headers });
    // Audio sent before the socket opens waits here, so no word is lost.
    const waiting: (Buffer | string)[] = [];
    const send = (data: Buffer | string) => {
      if (socket.readyState === WebSocket.OPEN) socket.send(data);
      else if (socket.readyState === WebSocket.CONNECTING) waiting.push(data);
    };
    let closing = false;
    let failure: string | undefined;

    socket.on('open', () => {
      for (const data of waiting.splice(0)) socket.send(data);
    });
    socket.on('message', (data, binary) => {
      if (binary) return;
      const message = parse(data);
      if (message?.type === 'TurnInfo') {
        events.onTurn(turnEventOf(message));
      } else if (message?.type === 'Error') {
        failure = `Flux STT: ${String(message.code)} ${String(message.description)}`;
      }
    });
    socket.on('error', (error) => (failure ??= `Flux STT: ${error.message}`));
    socket.on('close', () =>
      events.onClose(closing ? undefined : (failure ?? 'Flux STT closed')),
    );

    return {
      send: (pcm) => send(pcm),
      configure: (it) =>
        send(JSON.stringify({ type: 'Configure', thresholds: it })),
      endTurn: () => send(JSON.stringify({ type: 'ForceEndTurn' })),
      close: () => {
        closing = true;
        if (socket.readyState === WebSocket.OPEN) {
          socket.send(JSON.stringify({ type: 'CloseStream' }));
        }
        // Flux drains what it has and closes; don't wait for it long.
        setTimeout(() => socket.terminate(), 2_000).unref();
      },
    };
  }

  speaker(events: SpeakerEvents, voice = VOICE): Speaker {
    const url =
      `wss://api.deepgram.com/v2/speak?model=${voice}` +
      `&encoding=linear16&sample_rate=${SPEECH_RATE}`;
    const socket = new WebSocket(url, { headers: this._headers });
    const waiting: string[] = [];
    const send = (message: object) => {
      const data = JSON.stringify(message);
      if (socket.readyState === WebSocket.OPEN) socket.send(data);
      else if (socket.readyState === WebSocket.CONNECTING) waiting.push(data);
    };
    let closing = false;
    let failure: string | undefined;
    // Flux TTS closes a socket that hears nothing for 60 s.
    const alive = setInterval(() => {
      if (socket.readyState === WebSocket.OPEN) socket.ping();
    }, 20_000);

    socket.on('open', () => {
      for (const data of waiting.splice(0)) socket.send(data);
    });
    socket.on('message', (data, binary) => {
      if (binary) {
        events.onAudio(bytesOf(data));
        return;
      }
      const message = parse(data);
      switch (message?.type) {
        case 'SpeechStarted':
          events.onSentence();
          break;
        case 'SpeechMetadata':
          events.onSentenceDone(Number(message.billable_character_count) || 0);
          break;
        case 'SpeechInterrupted': {
          const meta = message.metadata as Record<string, unknown> | undefined;
          events.onSentenceDone(Number(meta?.billable_character_count) || 0);
          break;
        }
        case 'Error':
          failure = `Flux TTS: ${String(message.code)} ${String(message.description)}`;
          break;
      }
    });
    socket.on('error', (error) => (failure ??= `Flux TTS: ${error.message}`));
    socket.on('close', () => {
      clearInterval(alive);
      events.onClose(closing ? undefined : (failure ?? 'Flux TTS closed'));
    });

    return {
      // Flux joins Speak texts with no space between them, and reads
      // "minuto.Agora" as "minuto ponto Agora": every sentence ends in one.
      speak: (sentence) => {
        send({ type: 'Speak', text: `${sentence} ` });
        send({ type: 'Flush' });
      },
      interrupt: () => send({ type: 'Interrupt' }),
      close: () => {
        closing = true;
        clearInterval(alive);
        socket.terminate();
      },
    };
  }
}

/** A frame's bytes, whichever of its three shapes `ws` hands over. */
export function bytesOf(data: WebSocket.RawData): Buffer {
  if (Buffer.isBuffer(data)) return data;
  if (Array.isArray(data)) return Buffer.concat(data);
  return Buffer.from(data);
}

function parse(data: WebSocket.RawData): Record<string, unknown> | undefined {
  try {
    return JSON.parse(bytesOf(data).toString('utf8')) as Record<
      string,
      unknown
    >;
  } catch {
    return undefined;
  }
}

/** Flux's `TurnInfo`, typed and with untimed words dropped. */
export function turnEventOf(message: Record<string, unknown>): TurnEvent {
  const words = Array.isArray(message.words) ? message.words : [];
  return {
    event: message.event as TurnEvent['event'],
    turnIndex: Number(message.turn_index) || 0,
    transcript:
      typeof message.transcript === 'string' ? message.transcript : '',
    words: words.flatMap((it: Record<string, unknown>) =>
      typeof it?.word === 'string' &&
      typeof it.start === 'number' &&
      typeof it.end === 'number'
        ? [{ word: it.word, start: it.start, end: it.end }]
        : [],
    ),
    windowStart: Number(message.audio_window_start) || 0,
    windowEnd: Number(message.audio_window_end) || 0,
    trigger: typeof message.trigger === 'string' ? message.trigger : undefined,
  };
}
