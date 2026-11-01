import { AuthUser } from '../../auth/auth.tokens';
import { ChatMessage } from '../openrouter.client';
import {
  ListenerEvents,
  SpeakerEvents,
  TurnEvent,
  TurnThresholds,
  VoiceVendor,
} from './deepgram';
import {
  ACKNOWLEDGEMENT,
  APOLOGY,
  LONG_TURN,
  Phone,
  ReplyModel,
  SHORT_TURN,
  VoiceSession,
} from './voice-session';

const ana: AuthUser = {
  id: 'user-1',
  email: 'ana@exemplo.com',
  name: 'Ana Souza',
};

/** Flux, both ways, as the session sees it: every call recorded. */
class FakeVendor implements VoiceVendor {
  readonly configured = true;
  listenerEvents!: ListenerEvents;
  heard: Buffer[] = [];
  configured_: TurnThresholds[] = [];
  endedTurns = 0;
  listenerClosed = false;
  speakers: { events: SpeakerEvents; said: string[]; closed: boolean }[] = [];

  listen(thresholds: TurnThresholds, events: ListenerEvents) {
    this.configured_.push(thresholds);
    this.listenerEvents = events;
    return {
      send: (pcm: Buffer) => this.heard.push(pcm),
      configure: (it: TurnThresholds) => this.configured_.push(it),
      endTurn: () => this.endedTurns++,
      close: () => (this.listenerClosed = true),
    };
  }

  speaker(events: SpeakerEvents) {
    const speaker = { events, said: [] as string[], closed: false };
    this.speakers.push(speaker);
    return {
      speak: (sentence: string) => speaker.said.push(sentence),
      interrupt: () => undefined,
      close: () => (speaker.closed = true),
    };
  }

  get speaker_() {
    return this.speakers[this.speakers.length - 1];
  }

  /** Flux TTS speaks the next sentence it was given, all of it. */
  speakOne(chars = 10) {
    this.speaker_.events.onSentence();
    this.speaker_.events.onAudio(Buffer.from([1, 2]));
    this.speaker_.events.onSentenceDone(chars);
  }

  turn(event: TurnEvent['event'], fields: Partial<TurnEvent> = {}) {
    this.listenerEvents.onTurn({
      event,
      turnIndex: 0,
      transcript: '',
      words: [],
      windowStart: 0,
      windowEnd: 0,
      ...fields,
    });
  }
}

/** The model: answers each call with the pieces queued for it. */
class FakeModel implements ReplyModel {
  calls: ChatMessage[][] = [];
  replies: (string[] | Error)[] = [];

  async *stream(messages: ChatMessage[], signal: AbortSignal) {
    this.calls.push(messages);
    const reply = this.replies.shift() ?? ['Certo.'];
    await Promise.resolve();
    if (reply instanceof Error) throw reply;
    for (const piece of reply) {
      if (signal.aborted) return;
      yield piece;
      await Promise.resolve();
    }
  }
}

class FakePhone implements Phone {
  messages: Record<string, unknown>[] = [];
  audio = 0;
  closed?: number;
  sendJson(message: Record<string, unknown>) {
    this.messages.push(message);
  }
  sendAudio() {
    this.audio++;
  }
  close(code: number) {
    this.closed = code;
  }
  get states() {
    return this.messages
      .filter((it) => it.type === 'state')
      .map((it) => it.state);
  }
  get captions() {
    return this.messages
      .filter((it) => it.type === 'caption')
      .map((it) => it.text);
  }
}

/** Lets the model's stream run to its end. */
const settle = () => new Promise((resolve) => setImmediate(resolve));

function words(from: number, to: number): TurnEvent['words'] {
  return [
    { word: 'começo', start: from, end: from + 0.5 },
    { word: 'fim.', start: to - 0.5, end: to },
  ];
}

function call() {
  const vendor = new FakeVendor();
  const model = new FakeModel();
  const phone = new FakePhone();
  const lines: string[] = [];
  const session = new VoiceSession(ana, phone, vendor, model, (it) =>
    lines.push(it),
  );
  // The greeting, spoken out.
  vendor.speakOne();
  return { vendor, model, phone, session, lines };
}

describe('VoiceSession', () => {
  it('greets by first name, then listens', () => {
    const { vendor, phone } = call();

    expect(vendor.configured_).toEqual([SHORT_TURN]);
    expect(vendor.speaker_.said).toEqual([
      'Oi, Ana! O que você quer treinar hoje?',
    ]);
    expect(phone.captions).toEqual(['Oi, Ana! O que você quer treinar hoje?']);
    expect(phone.states).toEqual(['listening', 'speaking', 'listening']);
  });

  it('on a follow-up, greets the subject and tells the coach the memory', async () => {
    const vendor = new FakeVendor();
    const model = new FakeModel();
    const session = new VoiceSession(
      ana,
      new FakePhone(),
      vendor,
      model,
      () => undefined,
      undefined,
      { memory: 'Da última vez: começar pelo resultado.', followUp: true },
    );
    vendor.speakOne();
    expect(vendor.speaker_.said).toEqual([
      'Oi, Ana! Vamos continuar de onde paramos?',
    ]);

    vendor.turn('StartOfTurn');
    vendor.turn('EndOfTurn', {
      transcript: 'Bom dia a todos…',
      words: words(0, 30),
    });
    await settle();
    vendor.speakOne();
    vendor.speakOne();

    expect(model.calls[0][0].content).toContain(
      'Da última vez: começar pelo resultado.',
    );
    // What the history is handed when the call ends.
    expect(session.takes).toHaveLength(1);
    expect(session.conversation.map((it) => it.role)).toEqual([
      'assistant',
      'user',
      'assistant',
    ]);
  });

  it('answers a turn sentence by sentence, each caption before its audio', async () => {
    const { vendor, model, phone } = call();
    model.replies.push(['Boa ideia. Comece ', 'quando quiser.']);

    vendor.turn('StartOfTurn');
    vendor.turn('EndOfTurn', {
      transcript: 'Quero treinar um pitch.',
      words: words(0, 2),
    });
    expect(phone.states.at(-1)).toBe('thinking');
    await settle();

    expect(vendor.speaker_.said.slice(1)).toEqual([
      'Boa ideia.',
      'Comece quando quiser.',
    ]);
    vendor.speakOne();
    expect(phone.states.at(-1)).toBe('speaking');
    expect(phone.captions.at(-1)).toBe('Boa ideia.');
    vendor.speakOne();
    expect(phone.states.at(-1)).toBe('listening');

    // The model read the greeting and the person's words, with no numbers:
    // a short answer isn't a take.
    const sent = model.calls[0];
    expect(sent[0].role).toBe('system');
    expect(sent.slice(1)).toEqual([
      { role: 'assistant', content: 'Oi, Ana! O que você quer treinar hoje?' },
      { role: 'user', content: 'Quero treinar um pitch.' },
    ]);
  });

  it('measures a long talk, acknowledges it, and keeps the first as the reference', async () => {
    const { vendor, model } = call();

    vendor.turn('StartOfTurn');
    vendor.turn('EndOfTurn', {
      transcript: 'Bom dia a todos…',
      words: words(0, 30),
    });
    await settle();

    expect(vendor.speaker_.said[1]).toBe(ACKNOWLEDGEMENT);
    const message = model.calls[0].at(-1)!.content;
    expect(message).toContain('[Medidas desta fala]');
    expect(message).not.toContain('[Primeira fala');

    vendor.speakOne();
    vendor.speakOne();
    vendor.turn('StartOfTurn');
    vendor.turn('EndOfTurn', { transcript: 'De novo…', words: words(40, 60) });
    await settle();

    expect(model.calls[1].at(-1)!.content).toContain(
      '[Primeira fala, a referência]',
    );
  });

  it('lets only a long silence end a turn once it runs past ten seconds', () => {
    const { vendor } = call();

    vendor.turn('StartOfTurn', { words: words(5, 5.5) });
    vendor.turn('Update', { windowEnd: 12 });
    vendor.turn('Update', { windowEnd: 16 });
    expect(vendor.configured_).toEqual([SHORT_TURN, LONG_TURN]);

    vendor.turn('EndOfTurn', { transcript: 'Fim.', words: words(5, 40) });
    expect(vendor.configured_).toEqual([SHORT_TURN, LONG_TURN, SHORT_TURN]);
  });

  it('ends a talk at the ten-minute cap', () => {
    const { vendor } = call();

    vendor.turn('StartOfTurn');
    vendor.turn('Update', { windowEnd: 601 });

    expect(vendor.endedTurns).toBe(1);
  });

  it('stops when the person cuts in, keeping what was heard of the reply', async () => {
    const { vendor, model, phone } = call();
    model.replies.push(['Primeira frase. Segunda frase. Terceira.']);

    vendor.turn('StartOfTurn');
    vendor.turn('EndOfTurn', {
      transcript: 'Me dá um exemplo.',
      words: words(0, 2),
    });
    await settle();
    const first = vendor.speaker_;
    vendor.speakOne();
    vendor.turn('StartOfTurn');

    expect(phone.messages.at(-2)).toEqual({ type: 'interrupt' });
    expect(phone.states.at(-1)).toBe('listening');
    expect(first.closed).toBe(true);
    // Audio still coming from the old voice is dropped.
    first.events.onAudio(Buffer.from([1]));
    expect(phone.audio).toBe(2);

    vendor.turn('EndOfTurn', { transcript: 'Outro.', words: words(5, 6) });
    await settle();
    expect(model.calls[1].slice(-3)).toEqual([
      { role: 'user', content: 'Me dá um exemplo.' },
      { role: 'assistant', content: 'Primeira frase.' },
      { role: 'user', content: 'Outro.' },
    ]);
  });

  it('merges a turn Flux ended too early with the next, when the agent had not spoken', async () => {
    const { vendor, model, phone } = call();

    vendor.turn('StartOfTurn');
    vendor.turn('EndOfTurn', {
      transcript: 'Primeira parte.',
      words: words(0, 3),
    });
    vendor.turn('StartOfTurn');
    expect(phone.messages.at(-1)).not.toEqual({ type: 'interrupt' });
    vendor.turn('EndOfTurn', {
      transcript: 'Segunda parte.',
      words: words(4, 6),
    });
    await settle();

    expect(model.calls.at(-1)!.at(-1)!.content).toBe(
      'Primeira parte. Segunda parte.',
    );
  });

  it('says it could not answer when the model fails', async () => {
    const { vendor, model, lines } = call();
    model.replies.push(new Error('down'));

    vendor.turn('StartOfTurn');
    vendor.turn('EndOfTurn', { transcript: 'Oi?', words: words(0, 1) });
    await settle();

    expect(vendor.speaker_.said.at(-1)).toBe(APOLOGY);
    expect(lines).toContain('model failed: down');
  });

  describe('muted', () => {
    beforeEach(() => jest.useFakeTimers());
    afterEach(() => jest.useRealTimers());

    it('sends Flux silence instead of the mic, so it stays up', () => {
      const { vendor, session } = call();

      session.command({ type: 'mute', muted: true });
      session.hear(Buffer.from([9, 9]));
      jest.advanceTimersByTime(400);

      expect(vendor.heard).toHaveLength(5);
      expect(vendor.heard.every((it) => it.every((b) => b === 0))).toBe(true);

      session.command({ type: 'mute', muted: false });
      jest.advanceTimersByTime(400);
      session.hear(Buffer.from([9, 9]));
      expect(vendor.heard).toHaveLength(6);
      session.hangUp();
    });
  });

  it('closes both sockets and reports the cost on hang-up', () => {
    const { vendor, session, lines } = call();

    session.hear(Buffer.alloc(32_000)); // 1 s
    session.hangUp();

    expect(vendor.listenerClosed).toBe(true);
    expect(vendor.speaker_.closed).toBe(true);
    expect(session.report.spokenChars).toBe(10);
    expect(session.report.usd).toBeGreaterThan(0);
    expect(lines.at(-1)).toMatch(
      /^call ended: 0 turns, 1 s heard, 10 chars spoken/,
    );
  });

  it('drops the call when Deepgram does', () => {
    const { vendor, phone } = call();

    vendor.listenerEvents.onClose('Flux STT: boom');

    expect(phone.closed).toBe(1011);
  });
});
