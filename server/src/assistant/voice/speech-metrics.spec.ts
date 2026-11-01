import paced from './fixtures/flux-paced.json';
import rushed from './fixtures/flux-rushed.json';
import { measure, VoiceTrack } from './speech-metrics';

const RATE = 16_000;

/** PCM16 of a tone (or silence, at 0 Hz) for [seconds]. */
function tone(seconds: number, hz: number): Buffer {
  const n = Math.round(seconds * RATE);
  const out = Buffer.alloc(n * 2);
  for (let i = 0; i < n; i++) {
    const x = hz === 0 ? 0 : 0.3 * Math.sin((2 * Math.PI * hz * i) / RATE);
    out.writeInt16LE(Math.round(x * 32767), i * 2);
  }
  return out;
}

/** A track fed in odd-sized chunks, as a socket would. */
function trackOf(pcm: Buffer, chunk = 2_222): VoiceTrack {
  const track = new VoiceTrack();
  for (let at = 0; at < pcm.length; at += chunk) {
    track.push(pcm.subarray(at, at + chunk));
  }
  return track;
}

describe('measure', () => {
  // Real Flux STT word timings of the RFC's two takes (Phase 0, against
  // the key); the script measured 180 and 118 wpm on the same audio.
  it('tells the rushed take from the paced one by pace', () => {
    const fast = measure(rushed);
    const slow = measure(paced);

    expect(fast.wpm).toBe(184);
    expect(slow.wpm).toBe(121);
    expect(slow.longestPauseS).toBeGreaterThan(fast.longestPauseS);
    expect(slow.pauseShare).toBeGreaterThan(fast.pauseShare);
  });

  it('counts pauses on the audio, and long ones apart', () => {
    // word · 0.5 s pause · word · 2.5 s pause · word
    const pcm = Buffer.concat([
      tone(1, 180),
      tone(0.5, 0),
      tone(1, 180),
      tone(2.5, 0),
      tone(1, 180),
    ]);
    const words = [
      { word: 'um', start: 0, end: 1 },
      { word: 'dois', start: 1.5, end: 2.5 },
      { word: 'três', start: 5, end: 6 },
    ];

    const metrics = measure(words, trackOf(pcm));

    expect(metrics.pauses).toBe(2);
    expect(metrics.longPauses).toBe(1);
    expect(metrics.longestPauseS).toBeCloseTo(2.5, 1);
    expect(metrics.pauseShare).toBeCloseTo(0.5, 1);
    expect(metrics.hesitationS).toBe(0);
  });

  it('finds an "é…": voice where no word is', () => {
    // word · 0.3 s silence · 1 s of voice Flux gave no word · 0.3 s · word
    const pcm = Buffer.concat([
      tone(1, 180),
      tone(0.3, 0),
      tone(1, 150),
      tone(0.3, 0),
      tone(1, 180),
    ]);
    const words = [
      { word: 'então', start: 0, end: 1 },
      { word: 'assim', start: 2.6, end: 3.6 },
    ];

    const metrics = measure(words, trackOf(pcm));
    expect(metrics.hesitationS).toBeCloseTo(1, 1);
    expect(metrics.hesitations).toBe(1);
  });

  it('measures pitch, the same whatever the chunk size', () => {
    // Silence around the voice gives the loudness rule its floor.
    const pcm = Buffer.concat([
      tone(0.5, 0),
      tone(1, 200),
      tone(1, 250),
      tone(0.5, 0),
    ]);
    const words = [
      { word: 'a', start: 0.3, end: 1.5 },
      { word: 'b', start: 1.5, end: 2.7 },
    ];

    const one = measure(words, trackOf(pcm, 2_560));
    const other = measure(words, trackOf(pcm, 999));

    expect(one.pitchMedianHz).toBeGreaterThanOrEqual(195);
    expect(one.pitchMedianHz).toBeLessThanOrEqual(255);
    // 200 → 250 Hz is ~3.9 semitones.
    expect(one.pitchSpreadSemitones).toBeCloseTo(3.9, 0);
    expect(other).toEqual(one);
  });

  it('answers zeros for a turn with no timed word', () => {
    expect(measure([]).wpm).toBe(0);
  });
});
