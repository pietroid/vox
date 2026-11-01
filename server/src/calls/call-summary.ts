import type { ChatMessage } from '../assistant/openrouter.client';
import type { SpeechMetrics } from '../assistant/voice/speech-metrics';
import type { StoredCallMetrics } from '../db/schema';
import type { CallRow } from './call.store';
import { GOALS, isGoal } from './goals';

/**
 * What the history keeps of a call, and what a later call is told of the
 * earlier ones. The model writes the words (a title, a summary, what to
 * take away) once, after hang-up; the numbers are code's, summed from the
 * call's takes.
 */

/** What the model writes about a finished call. */
export interface CallNotes {
  title: string;
  summary: string;
  learnings: string[];
}

/** How many earlier calls on a subject a follow-up is told about. */
export const MEMORY_CALLS = 3;
const MAX_TITLE = 80;
const MAX_SUMMARY = 600;
const MAX_LEARNING = 160;
const MAX_LEARNINGS = 3;

/** When the model can't write the notes, the call is still kept. */
export const FALLBACK_NOTES: CallNotes = {
  title: 'Ligação com o Vox',
  summary: 'Não foi possível escrever o resumo desta ligação.',
  learnings: [],
};

/** The call's numbers: every take's, summed. Null when nothing was long enough. */
export function callMetrics(takes: SpeechMetrics[]): StoredCallMetrics | null {
  const seconds = takes.reduce((sum, it) => sum + it.durationS, 0);
  if (takes.length === 0 || seconds <= 0) return null;
  const words = takes.reduce((sum, it) => sum + it.words, 0);
  return {
    wordsPerMinute: Math.round((words / seconds) * 60),
    longPauses: takes.reduce((sum, it) => sum + it.longPauses, 0),
    hesitations: takes.reduce((sum, it) => sum + (it.hesitations ?? 0), 0),
  };
}

/** The request for the notes: the conversation and its numbers. */
export function notesRequest(
  conversation: ChatMessage[],
  metrics: StoredCallMetrics | null,
): ChatMessage[] {
  const lines = conversation
    .filter((it) => it.role === 'user' || it.role === 'assistant')
    .map((it) => `${it.role === 'user' ? 'Pessoa' : 'Vox'}: ${it.content}`);
  if (metrics) lines.push('', `[Números da ligação] ${describe(metrics)}`);
  return [
    {
      role: 'system',
      content: [
        'Você resume uma ligação de treino de fala entre uma pessoa e o Vox, o treinador dela.',
        'Responda só com um objeto JSON, sem markdown: {"title": string, "summary": string, "learnings": string[]}.',
        'title: o assunto da ligação em até oito palavras, sem ponto final.',
        'summary: dois ou três períodos, falando com a pessoa ("você"), sobre o que ela treinou e como foi.',
        'learnings: de uma a três coisas concretas para levar para a próxima vez, a mais importante primeiro, cada uma em até doze palavras.',
        'Escreva em português do Brasil. Use só o que está na ligação e nos números; nunca invente uma medida.',
      ].join('\n'),
    },
    { role: 'user', content: lines.join('\n') },
  ];
}

/** The model's answer as notes, or undefined when it isn't usable. */
export function parseNotes(text: string): CallNotes | undefined {
  const start = text.indexOf('{');
  const end = text.lastIndexOf('}');
  if (start < 0 || end <= start) return undefined;
  let json: unknown;
  try {
    json = JSON.parse(text.slice(start, end + 1));
  } catch {
    return undefined;
  }
  const it = json as Record<string, unknown>;
  if (typeof it.title !== 'string' || typeof it.summary !== 'string') {
    return undefined;
  }
  const title = clip(it.title, MAX_TITLE);
  const summary = clip(it.summary, MAX_SUMMARY);
  if (title === '' || summary === '') return undefined;
  const learnings = (Array.isArray(it.learnings) ? it.learnings : [])
    .filter((l): l is string => typeof l === 'string')
    .map((l) => clip(l, MAX_LEARNING))
    .filter((l) => l !== '')
    .slice(0, MAX_LEARNINGS);
  return { title, summary, learnings };
}

/**
 * What the coach is told before a call: the person's goal, and on a
 * follow-up, the last few calls on the subject.
 */
export function memoryPrompt(goal: string | undefined, earlier: CallRow[]) {
  const lines: string[] = [];
  if (earlier.length > 0) {
    lines.push(
      'Esta ligação continua um assunto que vocês já treinaram. O que ficou das ligações anteriores, da mais antiga para a mais recente:',
    );
    for (const row of earlier.slice(-MEMORY_CALLS)) {
      lines.push(
        `- ${row.subjectIndex}ª ligação (${dayOf(row.startedAt)}), "${row.title}": ${row.summary}` +
          (row.learnings.length
            ? ` O que levar: ${row.learnings.join('; ')}.`
            : '') +
          (row.metrics ? ` Números: ${describe(row.metrics)}.` : ''),
      );
    }
    lines.push(
      'Retome de onde pararam: lembre em uma frase o que ficou da última vez e proponha treinar isso agora. Compare os números novos com os de antes quando os tiver.',
    );
  } else if (isGoal(goal)) {
    const it = GOALS[goal];
    lines.push(
      `A pessoa disse que veio ao Vox por causa de: ${it.label}.`,
      `Se esta for a primeira ligação dela, comece por aí: ${it.opening}`,
    );
  }
  return lines.join('\n');
}

function describe(m: StoredCallMetrics): string {
  return `ritmo ${m.wordsPerMinute} palavras por minuto, ${m.longPauses} pausas longas, ${m.hesitations} hesitações`;
}

/** The day, as a person in Brazil reads it; never the server's zone. */
function dayOf(at: Date): string {
  return at.toLocaleDateString('pt-BR', { timeZone: 'America/Sao_Paulo' });
}

function clip(text: string, max: number): string {
  const it = text.replace(/\s+/g, ' ').trim();
  return it.length <= max ? it : `${it.slice(0, max - 1).trimEnd()}…`;
}
