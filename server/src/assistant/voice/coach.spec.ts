import { SentenceSplitter, turnMessage } from './coach';
import { measure } from './speech-metrics';

describe('SentenceSplitter', () => {
  it('hands each sentence over as soon as it ends', () => {
    const splitter = new SentenceSplitter();

    expect(splitter.push('Boa! Você fa')).toEqual(['Boa!']);
    expect(splitter.push('lou rápido. Vamos de ')).toEqual([
      'Você falou rápido.',
    ]);
    expect(splitter.push('novo?')).toEqual([]);
    expect(splitter.flush()).toEqual(['Vamos de novo?']);
  });

  it('keeps a number with a decimal point whole', () => {
    const splitter = new SentenceSplitter();

    expect(splitter.push('Foram 1.5 segundos. ')).toEqual([
      'Foram 1.5 segundos.',
    ]);
  });

  it('drops markdown the voice would read aloud', () => {
    const splitter = new SentenceSplitter();

    expect(splitter.push('**Ritmo**: bom.\n- Pausas: poucas.\n')).toEqual([
      'Ritmo: bom.',
      'Pausas: poucas.',
    ]);
  });
});

describe('turnMessage', () => {
  it('is the transcript alone for a short answer', () => {
    expect(turnMessage('Quero treinar um pitch.')).toBe(
      'Quero treinar um pitch.',
    );
  });

  it('gives a take its numbers and the first take as the reference', () => {
    const words = [
      { word: 'a', start: 0, end: 10 },
      { word: 'b', start: 11, end: 20 },
    ];
    const first = measure(words);
    const now = measure(words.slice(0, 1));

    const message = turnMessage('a b', now, first);

    expect(message).toContain('[Medidas desta fala]');
    expect(message).toContain('palavras por minuto');
    expect(message).toContain('[Primeira fala, a referência]');
  });
});
