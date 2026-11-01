import { callMetrics, memoryPrompt, parseNotes } from './call-summary';
import { CallRow } from './call.store';

describe('parseNotes', () => {
  it('reads the JSON even inside a fence', () => {
    const text =
      '```json\n{"title":"Entrevista","summary":"Você treinou.","learnings":["Contar uma história só", 3, ""]}\n```';

    expect(parseNotes(text)).toEqual({
      title: 'Entrevista',
      summary: 'Você treinou.',
      learnings: ['Contar uma história só'],
    });
  });

  it('keeps at most three learnings and clips a long title', () => {
    const notes = parseNotes(
      JSON.stringify({
        title: 'a'.repeat(200),
        summary: 'Resumo.',
        learnings: ['1', '2', '3', '4'],
      }),
    );

    expect(notes?.learnings).toEqual(['1', '2', '3']);
    expect(notes?.title).toHaveLength(80);
    expect(notes?.title.endsWith('…')).toBe(true);
  });

  it.each(['', 'sem json', '{"title":"x"}', '{"title":"","summary":"y"}'])(
    'refuses %j',
    (text) => {
      expect(parseNotes(text)).toBeUndefined();
    },
  );
});

describe('callMetrics', () => {
  it('is null without a take', () => {
    expect(callMetrics([])).toBeNull();
  });
});

describe('memoryPrompt', () => {
  const row = (i: number): CallRow => ({
    id: `c${i}`,
    userId: 'ana',
    startedAt: new Date(Date.UTC(2026, 9, i + 1, 2)),
    durationMs: 1000,
    costUsd: 0.01,
    coach: 'bianca',
    title: `Ensaio ${i}`,
    summary: 'Resumo.',
    learnings: [],
    metrics: null,
    subjectId: 'c1',
    subjectIndex: i,
    followsCallId: null,
    seenAt: null,
  });

  it('tells only the last three calls, in São Paulo days', () => {
    const memory = memoryPrompt('calm', [row(1), row(2), row(3), row(4)]);

    expect(memory).not.toContain('Ensaio 1');
    // 5 Oct 02:00 UTC is still the 4th in São Paulo.
    expect(memory).toContain('4ª ligação (04/10/2026), "Ensaio 4"');
    // A follow-up is about the subject, not the goal.
    expect(memory).not.toContain('falar com calma');
  });

  it('says nothing without a goal or a subject', () => {
    expect(memoryPrompt(undefined, [])).toBe('');
    expect(memoryPrompt('unknown', [])).toBe('');
  });
});
