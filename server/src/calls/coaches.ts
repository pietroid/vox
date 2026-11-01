/**
 * Who coaches a subject: a name, the Flux TTS voice they speak with, and
 * the language the calls with them are in. Picked when a subject starts
 * (`?coach=` on the call's socket) and kept on every call of it, so a
 * follow-up hears the same voice. The keys are the app's `Coach` names.
 */

export type CoachLanguage = 'pt' | 'en';

export interface Coach {
  key: CoachKey;
  name: string;
  /** The Flux TTS model. */
  voice: string;
  /** The language the coach speaks and Flux STT is hinted with. */
  language: CoachLanguage;
  /** How the coach's prompt names their role, in Portuguese. */
  role: 'treinadora' | 'treinador';
}

export const COACHES = {
  bianca: {
    name: 'Bianca',
    voice: 'flux-bianca-pt',
    language: 'pt',
    role: 'treinadora',
  },
  bruno: {
    name: 'Bruno',
    voice: 'flux-bruno-pt',
    language: 'pt',
    role: 'treinador',
  },
  haley: {
    name: 'Haley',
    voice: 'flux-haley-en',
    language: 'en',
    role: 'treinadora',
  },
  marcus: {
    name: 'Marcus',
    voice: 'flux-marcus-en',
    language: 'en',
    role: 'treinador',
  },
} as const satisfies Record<string, Omit<Coach, 'key'>>;

export type CoachKey = keyof typeof COACHES;

/** Every call before coaches existed had her voice. */
export const DEFAULT_COACH: CoachKey = 'bianca';

/** The coach kept as [key]; the default for anything unknown or absent. */
export function coachOf(key?: string | null): Coach {
  const k: CoachKey =
    key != null && Object.hasOwn(COACHES, key)
      ? (key as CoachKey)
      : DEFAULT_COACH;
  return { key: k, ...COACHES[k] };
}
