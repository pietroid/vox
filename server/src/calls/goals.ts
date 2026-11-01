/**
 * What brought a person to Vox, picked on the first-run home. The keys are
 * the app's `SpeakingGoal` names; each carries what the first call does
 * about it, the same promise the app shows under the chips.
 */
export const GOALS = {
  presentations: {
    label: 'apresentações',
    opening:
      'Peça que a pessoa apresente um tema do trabalho dela em um minuto, como numa reunião de verdade.',
  },
  interviews: {
    label: 'entrevistas de emprego',
    opening:
      'Faça de entrevistador: uma pergunta clássica de entrevista, ouça a resposta e diga o que ela passou.',
  },
  meetings: {
    label: 'falar em reuniões',
    opening:
      'Simule uma reunião e peça a opinião da pessoa sobre um tema, para ela treinar falar sem rodeios.',
  },
  teaching: {
    label: 'dar aulas',
    opening:
      'Peça que a pessoa explique um assunto que conhece como se fosse para a turma, e comente o ritmo.',
  },
  recording: {
    label: 'podcast e vídeo',
    opening:
      'Peça que a pessoa grave a abertura de um episódio, e diga como ela soaria para quem escuta.',
  },
  calm: {
    label: 'falar com calma',
    opening:
      'Converse sem pressa sobre algo leve, e mostre onde a fala da pessoa acelera.',
  },
  other: {
    label: 'outra coisa',
    opening: 'Pergunte o que a pessoa quer treinar e siga a partir daí.',
  },
} as const;

export type Goal = keyof typeof GOALS;

export function isGoal(value: unknown): value is Goal {
  return typeof value === 'string' && Object.hasOwn(GOALS, value);
}
