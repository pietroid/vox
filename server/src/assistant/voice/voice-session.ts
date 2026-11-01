import { AuthUser } from '../../auth/auth.tokens';
import { ChatMessage, ModelUsage } from '../openrouter.client';
import {
  coachPrompt,
  SentenceSplitter,
  TAKE_SECONDS,
  turnMessage,
} from './coach';
import {
  Listener,
  Speaker,
  TurnEvent,
  TurnThresholds,
  VoiceVendor,
} from './deepgram';
import {
  measure,
  SpeechMetrics,
  TimedWord,
  VoiceTrack,
} from './speech-metrics';

/**
 * One call, from the phone's socket opening to its closing.
 *
 * The phone streams the mic as PCM; the session relays it to Flux STT and
 * measures it as it passes. Flux ends the person's turn; the session asks
 * the model, cuts its streamed reply into sentences, and has Flux TTS speak
 * each one, telling the phone the caption just before its audio. The
 * screen's states are these events, sent as they happen:
 *
 * - `{type:'state', state:'listening'|'thinking'|'speaking'}`
 * - `{type:'caption', text}` before a sentence's audio
 * - binary frames: the agent's voice, PCM16 24 kHz mono
 * - `{type:'interrupt'}`: the person cut in; drop what's queued
 *
 * The phone sends binary PCM16 16 kHz mono, and `{type:'mute', muted}`.
 * The audio is dropped as it's measured, and the conversation lives as
 * long as the socket: when it closes, the gateway hands [conversation] and
 * [takes] to the history, which keeps only the notes the model writes from
 * them and the numbers.
 */

/** What a call starts with, from the history. */
export interface SessionBrief {
  /** Added to the coach's prompt: the goal, or the earlier calls. */
  memory?: string;
  /** The call continues a subject: the greeting says so. */
  followUp?: boolean;
}

/** The phone's end of the call. */
export interface Phone {
  sendJson(message: Record<string, unknown>): void;
  sendAudio(pcm: Buffer): void;
  close(code: number, reason: string): void;
}

/** The model, streamed. */
export interface ReplyModel {
  stream(
    messages: ChatMessage[],
    signal: AbortSignal,
    onUsage?: (usage: ModelUsage) => void,
  ): AsyncIterable<string>;
}

/** What a session logs and reports. */
export interface SessionReport {
  turns: number;
  /** Seconds of audio streamed to Flux STT (the mic is open all call). */
  heardS: number;
  /** Characters Flux TTS billed. */
  spokenChars: number;
  modelUsd: number;
  usd: number;
}

/** Flux's own defaults: a short answer ends on its meaning, fast. */
export const SHORT_TURN: TurnThresholds = {
  eot_threshold: 0.7,
  eot_timeout_ms: 5000,
};
/**
 * Once a turn runs past [LONG_TURN_SECONDS], only a 3 s silence ends it.
 * Phase 0 measured why: at 0.8 and 0.9 Flux still ended a paced talk at a
 * 0.9 s pause between sentences; at 1.0 it kept the talk whole.
 */
export const LONG_TURN: TurnThresholds = {
  eot_threshold: 1.0,
  eot_timeout_ms: 3000,
};
export const LONG_TURN_SECONDS = 10;
/** After a talk this long, a fixed phrase covers the wait for the model. */
export const ACKNOWLEDGE_SECONDS = 20;
export const ACKNOWLEDGEMENT = 'Boa! Deixa eu ver seus números…';
export const APOLOGY = 'Desculpe, não consegui responder agora. Pode repetir?';
/** One turn may run this long; then it ends, as the chat's length cap did. */
export const TALK_CAP_SECONDS = 600;
/** A call may last this long. */
export const CALL_CAP_SECONDS = 30 * 60;
/** How many messages of the call the model reads back. */
const HISTORY = 40;

/** Deepgram's prices, read 2026-10-31: Flux STT multi, Flux TTS. */
const STT_USD_PER_MIN = 0.0078;
const TTS_USD_PER_CHAR = 0.045 / 1000;

/** While muted, the phone sends nothing; Flux hears silence instead. */
const SILENCE = Buffer.alloc(2560); // 80 ms at 16 kHz
const SILENCE_MS = 80;

type CallState = 'listening' | 'thinking' | 'speaking';

interface Reply {
  abort: AbortController;
  /** Sentences sent to the voice and not yet spoken out. */
  pending: number;
  captions: string[];
  spoken: string[];
  written: boolean;
  /** When the person's turn ended, for time to first audio. */
  endedAt: number;
  firstAudioMs?: number;
  modelUsage?: ModelUsage;
}

export class VoiceSession {
  private readonly _track = new VoiceTrack();
  private readonly _history: ChatMessage[] = [];
  private readonly _listener: Listener;
  private _speaker: Speaker;
  private _state: CallState = 'listening';
  private _muted = false;
  private _silence?: NodeJS.Timeout;
  private readonly _cap: NodeJS.Timeout;
  private _closed = false;

  /** The person's words since the agent last spoke: turns Flux ended too early merge here. */
  private _words: TimedWord[] = [];
  private _transcript: string[] = [];
  private _turnStart?: number;
  private _long = false;
  private _baseline?: SpeechMetrics;
  private readonly _takes: SpeechMetrics[] = [];
  private _reply?: Reply;

  private readonly _report: SessionReport = {
    turns: 0,
    heardS: 0,
    spokenChars: 0,
    modelUsd: 0,
    usd: 0,
  };

  constructor(
    private readonly _user: AuthUser,
    private readonly _phone: Phone,
    private readonly _vendor: VoiceVendor,
    private readonly _model: ReplyModel,
    private readonly _log: (line: string) => void,
    private readonly _now: () => number = () => performance.now(),
    private readonly _brief: SessionBrief = {},
  ) {
    this._listener = _vendor.listen(SHORT_TURN, {
      onTurn: (event) => this._onTurn(event),
      onClose: (error) => error && this._fail(error),
    });
    this._speaker = this._openSpeaker();
    this._cap = setTimeout(
      () => this.hangUp(4000, 'A ligação chegou ao limite de 30 minutos.'),
      CALL_CAP_SECONDS * 1000,
    );
    this._cap.unref?.();
    this._send({ type: 'state', state: 'listening' });
    this._greet();
  }

  get report(): SessionReport {
    return { ...this._report, usd: round(this._usd(), 4) };
  }

  /** What was said and answered, in order. */
  get conversation(): ChatMessage[] {
    return [...this._history];
  }

  /** Each take's numbers, in order. */
  get takes(): SpeechMetrics[] {
    return [...this._takes];
  }

  /** PCM from the phone's mic. */
  hear(pcm: Buffer): void {
    if (this._closed || this._muted) return;
    this._relay(pcm);
  }

  /** A JSON message from the phone. */
  command(message: unknown): void {
    const it = message as { type?: unknown; muted?: unknown } | null;
    if (it?.type === 'mute' && typeof it.muted === 'boolean')
      this._mute(it.muted);
  }

  /** The phone hung up, or the call is ended here. */
  hangUp(code?: number, reason?: string): void {
    if (this._closed) return;
    this._closed = true;
    clearInterval(this._silence);
    clearTimeout(this._cap);
    this._reply?.abort.abort();
    this._listener.close();
    this._speaker.close();
    if (code !== undefined) this._phone.close(code, reason ?? '');
    const r = this.report;
    this._log(
      `call ended: ${r.turns} turns, ${r.heardS.toFixed(0)} s heard, ` +
        `${r.spokenChars} chars spoken, $${r.usd.toFixed(4)}`,
    );
  }

  private _relay(pcm: Buffer): void {
    this._listener.send(pcm);
    this._track.push(pcm);
    this._report.heardS = this._track.seconds;
  }

  private _mute(muted: boolean): void {
    if (muted === this._muted) return;
    this._muted = muted;
    clearInterval(this._silence);
    // Flux STT has no keep-alive message: silence keeps it, and its clock,
    // going, so word timings and the measured audio stay aligned.
    if (muted) {
      this._silence = setInterval(() => this._relay(SILENCE), SILENCE_MS);
      this._silence.unref?.();
    }
  }

  private _onTurn(turn: TurnEvent): void {
    if (this._closed) return;
    switch (turn.event) {
      case 'StartOfTurn':
        this._turnStart = turn.words[0]?.start ?? turn.windowStart;
        this._cutIn();
        break;
      case 'Update': {
        const length = turn.windowEnd - (this._turnStart ?? turn.windowStart);
        if (!this._long && length >= LONG_TURN_SECONDS) {
          this._long = true;
          this._listener.configure(LONG_TURN);
        }
        if (length >= TALK_CAP_SECONDS) this._listener.endTurn();
        break;
      }
      case 'EndOfTurn':
        if (this._long) {
          this._long = false;
          this._listener.configure(SHORT_TURN);
        }
        this._turnStart = undefined;
        if (turn.transcript.trim() === '') return;
        this._words.push(...turn.words);
        this._transcript.push(turn.transcript.trim());
        void this._answer(turn.trigger);
        break;
    }
  }

  /** The person spoke over the agent: it stops, as on a call. */
  private _cutIn(): void {
    const reply = this._reply;
    if (reply === undefined) return;
    this._reply = undefined;
    reply.abort.abort();
    if (reply.spoken.length > 0 || reply.firstAudioMs !== undefined) {
      // What was heard of the reply stays in the conversation.
      this._remember(reply);
      this._send({ type: 'interrupt' });
    }
    // Flux TTS's own Interrupt can race a sentence that just ended; a new
    // socket for the next reply can't.
    this._speaker.close();
    this._speaker = this._openSpeaker();
    this._setState('listening');
  }

  private async _answer(trigger?: string): Promise<void> {
    this._reply?.abort.abort();
    const reply: Reply = {
      abort: new AbortController(),
      pending: 0,
      captions: [],
      spoken: [],
      written: false,
      endedAt: this._now(),
    };
    this._reply = reply;
    this._setState('thinking');

    const span = this._words.length
      ? this._words[this._words.length - 1].end - this._words[0].start
      : 0;
    const metrics =
      span >= TAKE_SECONDS ? measure(this._words, this._track) : undefined;
    if (metrics) {
      this._baseline ??= metrics;
      this._takes.push(metrics);
      this._log(
        `take measured (${trigger ?? 'model'}): ${JSON.stringify(metrics)}`,
      );
    }
    if (span >= ACKNOWLEDGE_SECONDS) this._say(reply, ACKNOWLEDGEMENT);

    const messages: ChatMessage[] = [
      { role: 'system', content: coachPrompt(this._user, this._brief.memory) },
      ...this._history.slice(-HISTORY),
      {
        role: 'user',
        content: turnMessage(
          this._transcript.join(' '),
          metrics,
          this._baseline,
        ),
      },
    ];
    const splitter = new SentenceSplitter();
    try {
      for await (const text of this._model.stream(
        messages,
        reply.abort.signal,
        (usage) => {
          reply.modelUsage = usage;
        },
      )) {
        if (reply.abort.signal.aborted) return;
        for (const sentence of splitter.push(text)) this._say(reply, sentence);
      }
      if (reply.abort.signal.aborted) return;
      for (const sentence of splitter.flush()) this._say(reply, sentence);
    } catch (error) {
      if (reply.abort.signal.aborted) return;
      this._log(
        `model failed: ${error instanceof Error ? error.message : String(error)}`,
      );
      if (reply.captions.length === 0 && reply.spoken.length === 0) {
        this._say(reply, APOLOGY);
      }
    }
    reply.written = true;
    this._report.modelUsd += reply.modelUsage?.cost ?? 0;
    this._finishIfDone(reply);
  }

  private _greet(): void {
    const name = this._user.name.split(' ')[0] || this._user.name;
    const reply: Reply = {
      abort: new AbortController(),
      pending: 0,
      captions: [],
      spoken: [],
      written: true,
      endedAt: this._now(),
    };
    this._reply = reply;
    this._say(
      reply,
      this._brief.followUp
        ? `Oi, ${name}! Vamos continuar de onde paramos?`
        : `Oi, ${name}! O que você quer treinar hoje?`,
    );
  }

  private _say(reply: Reply, sentence: string): void {
    reply.pending++;
    reply.captions.push(sentence);
    this._speaker.speak(sentence);
  }

  private _openSpeaker(): Speaker {
    // Events of a speaker replaced on cut-in are dropped.
    const speaker: Speaker = this._vendor.speaker({
      onSentence: () => {
        if (this._speaker !== speaker) return;
        const reply = this._reply;
        const caption = reply?.captions.shift();
        if (reply === undefined || caption === undefined) return;
        reply.spoken.push(caption);
        if (reply.firstAudioMs === undefined) {
          reply.firstAudioMs = Math.round(this._now() - reply.endedAt);
          this._commitTurn();
        }
        this._send({ type: 'caption', text: caption });
        this._setState('speaking');
      },
      onAudio: (pcm) => {
        if (this._speaker !== speaker || this._reply === undefined) return;
        this._phone.sendAudio(pcm);
      },
      onSentenceDone: (chars) => {
        this._report.spokenChars += chars;
        if (this._speaker !== speaker || this._reply === undefined) return;
        this._reply.pending--;
        this._finishIfDone(this._reply);
      },
      onClose: (error) => {
        if (this._speaker === speaker && error) this._fail(error);
      },
    });
    return speaker;
  }

  /** The person's words become a turn of the conversation once the agent answers them. */
  private _commitTurn(): void {
    if (this._transcript.length === 0) return;
    this._history.push({ role: 'user', content: this._transcript.join(' ') });
    this._words = [];
    this._transcript = [];
    this._report.turns++;
  }

  private _finishIfDone(reply: Reply): void {
    if (this._reply !== reply || !reply.written || reply.pending > 0) return;
    this._reply = undefined;
    this._remember(reply);
    if (reply.firstAudioMs !== undefined) {
      const u = reply.modelUsage;
      this._log(
        `turn ${this._report.turns}: first audio ${reply.firstAudioMs} ms, ` +
          `${reply.spoken.join(' ').length} chars spoken` +
          (u
            ? `, ${u.promptTokens}+${u.completionTokens} tokens, $${u.cost.toFixed(4)} model`
            : '') +
          `; call so far $${this._usd().toFixed(4)}`,
      );
    }
    this._setState('listening');
  }

  private _remember(reply: Reply): void {
    if (reply.spoken.length === 0) return;
    this._history.push({ role: 'assistant', content: reply.spoken.join(' ') });
  }

  private _setState(state: CallState): void {
    if (state === this._state) return;
    this._state = state;
    this._send({ type: 'state', state });
  }

  private _send(message: Record<string, unknown>): void {
    if (!this._closed) this._phone.sendJson(message);
  }

  private _fail(error: string): void {
    if (this._closed) return;
    this._log(`call dropped: ${error}`);
    this.hangUp(1011, 'A ligação caiu.');
  }

  private _usd(): number {
    return (
      (this._report.heardS / 60) * STT_USD_PER_MIN +
      this._report.spokenChars * TTS_USD_PER_CHAR +
      this._report.modelUsd
    );
  }
}

function round(value: number, digits: number): number {
  const k = 10 ** digits;
  return Math.round(value * k) / k;
}
