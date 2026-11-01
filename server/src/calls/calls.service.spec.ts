import { BadRequestException, NotFoundException } from '@nestjs/common';
import { AuthUser } from '../auth/auth.tokens';
import { ModelOutcome } from '../assistant/openrouter.client';
import { SpeechMetrics } from '../assistant/voice/speech-metrics';
import { FALLBACK_NOTES } from './call-summary';
import { CallRow, InMemoryCallStore } from './call.store';
import { CallsController, GoalController } from './calls.controller';
import { CallsService, FinishedCall } from './calls.service';
import { coachOf } from './coaches';

const ana: AuthUser = { id: 'ana', email: 'ana@exemplo.com', name: 'Ana' };
const bia: AuthUser = { id: 'bia', email: 'bia@exemplo.com', name: 'Bia' };

const notes = JSON.stringify({
  title: 'Apresentação do trimestre',
  summary: 'Você apresentou os números do trimestre.',
  learnings: ['Começar pelo resultado', 'Pausar antes do número'],
});

function take(over: Partial<SpeechMetrics> = {}): SpeechMetrics {
  return {
    durationS: 30,
    words: 80,
    wpm: 160,
    pauses: 6,
    pausesPerMin: 12,
    longPauses: 2,
    longestPauseS: 2.4,
    pauseShare: 0.2,
    hesitationS: 1.2,
    hesitations: 3,
    ...over,
  };
}

function finished(over: Partial<FinishedCall> = {}): FinishedCall {
  return {
    startedAt: new Date('2026-11-01T22:42:00Z'),
    durationMs: 372_000,
    usd: 0.0612,
    turns: 3,
    conversation: [
      { role: 'assistant', content: 'Oi, Ana!' },
      { role: 'user', content: 'Quero treinar minha apresentação.' },
    ],
    takes: [take()],
    ...over,
  };
}

function setUp(reply: () => Promise<ModelOutcome>) {
  const store = new InMemoryCallStore();
  const asked: string[] = [];
  const model = {
    configured: true,
    generate: (messages: { content: string }[]) => {
      asked.push(messages.map((it) => it.content).join('\n'));
      return reply();
    },
  };
  const service = new CallsService(store, model);
  let n = 0;
  service.newId = () => `c${++n}`;
  return {
    store,
    asked,
    service,
    calls: new CallsController(service),
    goals: new GoalController(service),
  };
}

const answering = () =>
  Promise.resolve<ModelOutcome>({
    kind: 'final',
    content: notes,
    usage: {
      promptTokens: 900,
      completionTokens: 120,
      cachedTokens: 0,
      cost: 0.0008,
    },
  });

describe('CallsService', () => {
  it('keeps a call with the notes the model wrote and the summed numbers', async () => {
    const { service, asked } = setUp(answering);

    const row = await service.record(
      ana.id,
      { memory: '', coach: coachOf() },
      finished(),
    );

    expect(row).toMatchObject<Partial<CallRow>>({
      id: 'c1',
      userId: 'ana',
      durationMs: 372_000,
      costUsd: 0.062,
      title: 'Apresentação do trimestre',
      learnings: ['Começar pelo resultado', 'Pausar antes do número'],
      metrics: { wordsPerMinute: 160, longPauses: 2, hesitations: 3 },
      subjectId: 'c1',
      subjectIndex: 1,
      followsCallId: null,
      seenAt: null,
    });
    // The model read the conversation and the numbers.
    expect(asked[0]).toContain('Pessoa: Quero treinar minha apresentação.');
    expect(asked[0]).toContain('ritmo 160 palavras por minuto');
  });

  it('keeps nothing of a call in which nobody was answered', async () => {
    const { service, store } = setUp(answering);

    await service.record(
      ana.id,
      { memory: '', coach: coachOf() },
      finished({ turns: 0 }),
    );

    expect(store.rows).toHaveLength(0);
  });

  it('still keeps the call when the model fails', async () => {
    const { service } = setUp(() => Promise.reject(new Error('down')));

    const row = await service.record(
      ana.id,
      { memory: '', coach: coachOf() },
      finished(),
    );

    expect(row?.title).toBe(FALLBACK_NOTES.title);
    expect(row?.learnings).toEqual([]);
    expect(row?.costUsd).toBe(0.0612);
  });

  it('a follow-up joins the subject, remembers it and shows the change', async () => {
    const { service, calls } = setUp(answering);
    const first = await service.record(
      ana.id,
      { memory: '', coach: coachOf() },
      finished(),
    );

    const brief = await service.brief(ana.id, first!.id);
    expect(brief.follows?.id).toBe('c1');
    expect(brief.memory).toContain('1ª ligação (01/11/2026)');
    expect(brief.memory).toContain('Começar pelo resultado');

    const second = await service.record(
      ana.id,
      brief,
      finished({
        startedAt: new Date('2026-11-02T22:00:00Z'),
        takes: [take({ words: 70, longPauses: 4, hesitations: 1 })],
      }),
    );
    expect(second).toMatchObject({
      subjectId: 'c1',
      subjectIndex: 2,
      followsCallId: 'c1',
    });

    const history = await calls.list(ana);
    expect(history.calls.map((it) => it.id)).toEqual(['c2', 'c1']);
    expect(history.calls[0].metrics).toEqual({
      wordsPerMinute: 140,
      longPauses: 4,
      hesitations: 1,
      wordsPerMinuteDelta: -20,
      longPausesDelta: 2,
      hesitationsDelta: -2,
    });
    // The subject's first call has nothing to compare with.
    expect(history.calls[1].metrics?.wordsPerMinuteDelta).toBeUndefined();
    await expect(calls.one(ana, 'c2')).resolves.toEqual(history.calls[0]);
  });

  it("starts fresh from someone else's call", async () => {
    const { service } = setUp(answering);
    const theirs = await service.record(
      bia.id,
      { memory: '', coach: coachOf() },
      finished(),
    );

    const brief = await service.brief(ana.id, theirs!.id);

    expect(brief).toEqual({
      memory: '',
      follows: undefined,
      coach: coachOf(),
    });
  });

  it('keeps the coach a subject started with on every follow-up', async () => {
    const { service } = setUp(answering);
    const first = await service.record(
      ana.id,
      await service.brief(ana.id, undefined, 'marcus'),
      finished(),
    );
    expect(first!.coach).toBe('marcus');

    // The app asks for no coach on a follow-up; another one is ignored too.
    const brief = await service.brief(ana.id, first!.id, 'bruno');
    expect(brief.coach).toMatchObject({ key: 'marcus', language: 'en' });
    await service.record(ana.id, brief, finished());

    const { calls } = await service.history(ana.id);
    expect(calls.map((it) => [it.coach, it.subjectId])).toEqual([
      ['marcus', first!.id],
      ['marcus', first!.id],
    ]);
  });

  it('starts an unknown coach as Bianca', async () => {
    const { service } = setUp(answering);
    expect((await service.brief(ana.id, undefined, 'hal')).coach.key).toBe(
      'bianca',
    );
  });

  it('tells the first call about the goal', async () => {
    const { service, goals } = setUp(answering);

    await goals.set(ana, { goal: 'interviews' });

    expect((await service.brief(ana.id)).memory).toContain(
      'entrevistas de emprego',
    );
  });
});

describe('CallsController', () => {
  it("reads and marks only the person's own calls", async () => {
    const { service, calls } = setUp(answering);
    await service.record(bia.id, { memory: '', coach: coachOf() }, finished());

    await expect(calls.list(ana)).resolves.toEqual({ goal: null, calls: [] });
    await expect(calls.one(ana, 'c1')).rejects.toThrow(NotFoundException);
    await expect(calls.seen(ana, 'c1')).rejects.toThrow(NotFoundException);

    await calls.seen(bia, 'c1');
    expect((await calls.one(bia, 'c1')).seen).toBe(true);
  });

  it('answers the goal with the history', async () => {
    const { calls, goals } = setUp(answering);

    await goals.set(ana, { goal: 'calm' });

    await expect(calls.list(ana)).resolves.toEqual({
      goal: 'calm',
      calls: [],
    });
  });

  it.each([[undefined], [{}], [{ goal: 'singing' }], [{ goal: 3 }]])(
    'refuses the goal %j',
    async (dto) => {
      const { goals } = setUp(answering);

      await expect(goals.set(ana, dto as never)).rejects.toThrow(
        BadRequestException,
      );
    },
  );
});
