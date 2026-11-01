import { AuthUser } from '../../auth/auth.tokens';
import { Coach, coachOf } from '../../calls/coaches';
import { SpeechMetrics } from './speech-metrics';

/**
 * What the agent is told on a call, and how its streamed reply is cut into
 * sentences for the voice. Measuring is code's job (`speech-metrics.ts`);
 * the model only reads the numbers and says what they mean.
 */

/** A turn this long or longer is a take: it gets measured for the coach. */
export const TAKE_SECONDS = 15;

/**
 * The system prompt of a call. [memory] is what the history adds: the
 * person's goal, or the earlier calls on the subject a follow-up continues.
 * [coach] names who speaks and the language the whole call is in; the
 * instructions stay in Portuguese, the replies follow the coach.
 */
export function coachPrompt(
  user: AuthUser,
  memory = '',
  coach: Coach = coachOf(),
): string {
  const name = user.name.split(' ')[0] || user.name;
  const english = coach.language === 'en';
  const lines = [
    `Você é ${coach.name}, ${coach.role} de fala e apresentação do Vox, numa ligação de voz.`,
    `Você está falando com ${name}. Tudo o que você escreve é falado em voz alta.`,
    english
      ? 'Esta ligação é inteiramente em inglês: responda sempre em inglês, mesmo que a pessoa fale português, e ajude-a a treinar a fala em inglês. Fale como numa ligação: frases curtas, sem listas, sem markdown, sem emojis.'
      : 'Fale como numa ligação: frases curtas, em português do Brasil, sem listas, sem markdown, sem emojis.',
    'Responda em no máximo três ou quatro frases e termine com uma pergunta ou um próximo passo.',
    english
      ? 'Escreva números por extenso quando forem poucos, e arredonde: "about a hundred and twenty words per minute".'
      : 'Escreva números por extenso quando forem poucos, e arredonde: "cerca de cento e vinte palavras por minuto".',
    'Quando a fala da pessoa for longa, você recebe os números dela medidos em código: ritmo, pausas, hesitações e entonação, e os da primeira fala dela na ligação, que é a referência.',
    'Use esses números. Nunca invente uma medida que não recebeu, e compare com a referência da própria pessoa, não com uma norma.',
    'A transcrição é automática e pode trocar palavras: nunca aponte uma palavra estranha como erro de dicção, e só cite trechos que fazem sentido.',
    'Comece pelo ponto mais importante: um elogio concreto e uma coisa a mudar, com o trecho em que ela aparece.',
    'Para falas curtas, apenas converse: entenda o que a pessoa quer treinar e conduza o treino.',
  ];
  if (memory.trim() !== '') lines.push('', memory.trim());
  return lines.join('\n');
}

/** The coach's first sentence, in their language. */
export function greeting(
  name: string,
  coach: Coach = coachOf(),
  followUp = false,
): string {
  if (coach.language === 'en') {
    return followUp
      ? `Hi, ${name}! Shall we pick up where we left off?`
      : `Hi, ${name}! What would you like to practice today?`;
  }
  return followUp
    ? `Oi, ${name}! Vamos continuar de onde paramos?`
    : `Oi, ${name}! O que você quer treinar hoje?`;
}

/** The person's turn as the model reads it: the words, then the numbers. */
export function turnMessage(
  transcript: string,
  metrics?: SpeechMetrics,
  baseline?: SpeechMetrics,
): string {
  if (metrics === undefined) return transcript;
  const lines = [transcript, '', `[Medidas desta fala] ${describe(metrics)}`];
  if (baseline !== undefined && baseline !== metrics) {
    lines.push(`[Primeira fala, a referência] ${describe(baseline)}`);
  }
  return lines.join('\n');
}

function describe(m: SpeechMetrics): string {
  const parts = [
    `duração ${m.durationS} s`,
    `${m.words} palavras`,
    `ritmo ${m.wpm} palavras por minuto`,
    `${m.pauses} pausas (${m.pausesPerMin} por minuto, a maior de ${m.longestPauseS} s, ${Math.round(m.pauseShare * 100)}% do tempo em pausa)`,
    `${m.longPauses} pausas de 2 s ou mais`,
    `hesitações sem palavra ("é…", "hã…"): ${m.hesitationS} s`,
  ];
  if (m.pitchMedianHz !== undefined) {
    parts.push(
      `tom mediano ${m.pitchMedianHz} Hz, variação de ${m.pitchSpreadSemitones} semitons`,
    );
  }
  return parts.join('; ');
}

/**
 * Cuts a streamed reply into sentences as they complete, so the first one
 * is spoken while the rest is written. A sentence ends at `.`, `!`, `?` or
 * `…` followed by a space, or at a line break; markdown the model slipped
 * in is dropped, since Flux TTS would read it aloud.
 */
export class SentenceSplitter {
  private _buffer = '';

  /** Adds a piece of the reply; answers the sentences it completed. */
  push(text: string): string[] {
    this._buffer += text;
    const out: string[] = [];
    const end = /([.!?…]+)["')\]]*\s+|\n+/g;
    let from = 0;
    let match: RegExpExecArray | null;
    while ((match = end.exec(this._buffer)) !== null) {
      const sentence = clean(
        this._buffer.slice(from, match.index + match[0].length),
      );
      from = match.index + match[0].length;
      if (sentence !== '') out.push(sentence);
    }
    this._buffer = this._buffer.slice(from);
    return out;
  }

  /** What's left when the reply ends. */
  flush(): string[] {
    const rest = clean(this._buffer);
    this._buffer = '';
    return rest === '' ? [] : [rest];
  }
}

function clean(text: string): string {
  return text
    .replace(/[*_#`>]+/g, '')
    .replace(/^\s*[-•]\s+/, '')
    .replace(/\s+/g, ' ')
    .trim();
}
