/**
 * Pace, pauses, hesitation and pitch of one turn, measured in code: the
 * numbers the coach is given, never asked to guess.
 *
 * A port of the RFC's `speech_metrics.py`. Pace and pauses come from Flux's
 * word timings; hesitation ("é…", which Flux doesn't transcribe in
 * Portuguese) is voiced time where no word is; pitch is measured on the PCM
 * the server relays, as it arrives, so nothing waits at the end of a turn.
 */

/** One word as Flux STT times it, in seconds from the stream's start. */
export interface TimedWord {
  word: string;
  start: number;
  end: number;
}

/** What one turn measured. Times in seconds. */
export interface SpeechMetrics {
  /** From the first word's start to the last word's end. */
  durationS: number;
  words: number;
  wpm: number;
  /** Silent gaps between words of at least [MIN_PAUSE]. */
  pauses: number;
  pausesPerMin: number;
  /** Pauses of at least [LONG_PAUSE]. */
  longPauses: number;
  longestPauseS: number;
  /** Share of the turn spent in pauses, 0–1. */
  pauseShare: number;
  /** Voiced time with no word on it: "é…", "hã…". */
  hesitationS: number;
  /** How many such stretches there were. */
  hesitations: number;
  /** The voice's median pitch, when there was audio to measure. */
  pitchMedianHz?: number;
  /** p90 − p10 around the median, in semitones: low means monotone. */
  pitchSpreadSemitones?: number;
}

const RATE = 16_000;
const FRAME = 480; // 30 ms
const HOP = 160; // 10 ms
const HOP_S = HOP / RATE;
/** Shorter gaps are articulation, not pauses. */
export const MIN_PAUSE = 0.25;
export const LONG_PAUSE = 2.0;
/** A voiced stretch with no word this long is an "é…". */
const MIN_HESITATION = 0.3;
/** How far from a word's timed edge its sound may still run. */
const EDGE = 0.2;
/** Frames quieter than this never get a pitch: it saves the Pi the work. */
const PITCH_FLOOR_DB = -50;

/**
 * Loudness and pitch of the relayed audio, 16 kHz mono PCM16, one value per
 * 10 ms hop; hop `i` is at `i / 100` s, the same clock as Flux's words as
 * long as both get the same bytes.
 */
export class VoiceTrack {
  readonly db: number[] = [];
  readonly f0: number[] = [];
  private _tail = new Float32Array(0);
  private _odd?: Buffer;
  private readonly _window = hanning(FRAME);

  /** Adds a chunk of PCM16 (little-endian), measuring every whole hop. */
  push(chunk: Buffer): void {
    // A chunk may split a sample; its odd byte waits for the next one.
    const pcm = this._odd ? Buffer.concat([this._odd, chunk]) : chunk;
    this._odd = pcm.length % 2 === 1 ? pcm.subarray(pcm.length - 1) : undefined;
    const samples = new Float32Array(this._tail.length + (pcm.length >> 1));
    samples.set(this._tail);
    for (let i = 0; i < pcm.length >> 1; i++) {
      samples[this._tail.length + i] = pcm.readInt16LE(i * 2) / 32768;
    }
    let at = 0;
    for (; at + FRAME <= samples.length; at += HOP) {
      const frame = samples.subarray(at, at + FRAME);
      let energy = 0;
      for (const x of frame) energy += x * x;
      const db = 20 * Math.log10(Math.sqrt(energy / FRAME) + 1e-9);
      this.db.push(db);
      // Pitch on every other hop: 20 ms is plenty for a median and spread.
      this.f0.push(
        db > PITCH_FLOOR_DB && this.db.length % 2 === 0
          ? pitchOf(frame, this._window)
          : NaN,
      );
    }
    this._tail = samples.slice(at);
  }

  /** Seconds measured so far. */
  get seconds(): number {
    return this.db.length * HOP_S;
  }

  /** Which hops of [from, to) are speech, by the script's relative rule. */
  voiced(from: number, to: number): { start: number; mask: boolean[] } {
    const a = Math.max(0, Math.floor(from / HOP_S));
    const b = Math.min(this.db.length, Math.ceil(to / HOP_S));
    const db = this.db.slice(a, b);
    if (db.length === 0) return { start: a, mask: [] };
    const floor = percentile(db, 10);
    const top = Math.max(...db);
    const cut = Math.max(floor + 15, top - 45);
    return { start: a, mask: db.map((it) => it > cut) };
  }
}

/** The metrics of one turn: its words, and the audio when the server had it. */
export function measure(words: TimedWord[], track?: VoiceTrack): SpeechMetrics {
  const timed = words.filter(
    (it) => Number.isFinite(it.start) && Number.isFinite(it.end),
  );
  if (timed.length === 0) {
    return {
      durationS: 0,
      words: words.length,
      wpm: 0,
      pauses: 0,
      pausesPerMin: 0,
      longPauses: 0,
      longestPauseS: 0,
      pauseShare: 0,
      hesitationS: 0,
      hesitations: 0,
    };
  }
  const from = timed[0].start;
  const to = timed[timed.length - 1].end;
  const span = Math.max(to - from, 0.001);
  const voice = track?.voiced(from, to);
  const pauses: number[] = [];
  let hesitation = 0;
  let hesitations = 0;

  if (voice === undefined || voice.mask.length === 0) {
    // Words alone: a pause is a gap between them.
    for (let i = 1; i < timed.length; i++) {
      const gap = timed[i].start - timed[i - 1].end;
      if (gap >= MIN_PAUSE) pauses.push(gap);
    }
  } else {
    // With the audio, as the script: a pause is a silent run.
    for (const run of runs(voice.mask, false)) {
      if (run.length * HOP_S >= MIN_PAUSE) pauses.push(run.length * HOP_S);
    }
    // A hesitation is a voiced run inside a gap between words, clear of
    // their edges (Flux times words to ~80 ms).
    for (let i = 1; i < timed.length; i++) {
      const a = Math.round((timed[i - 1].end + EDGE) / HOP_S) - voice.start;
      const b = Math.round((timed[i].start - EDGE) / HOP_S) - voice.start;
      if (b - a < MIN_HESITATION / HOP_S) continue;
      for (const run of runs(voice.mask.slice(Math.max(0, a), b), true)) {
        if (run.length * HOP_S >= MIN_HESITATION) {
          hesitation += run.length * HOP_S;
          hesitations++;
        }
      }
    }
  }

  const minutes = span / 60;
  const paused = pauses.reduce((sum, it) => sum + it, 0);
  return {
    durationS: round(span, 1),
    words: words.length,
    wpm: Math.round(words.length / minutes),
    pauses: pauses.length,
    pausesPerMin: round(pauses.length / minutes, 1),
    longPauses: pauses.filter((it) => it >= LONG_PAUSE).length,
    longestPauseS: round(Math.max(0, ...pauses), 2),
    pauseShare: round(Math.min(1, paused / span), 2),
    hesitationS: round(hesitation, 1),
    hesitations,
    ...(track ? pitchStats(track, from, to) : {}),
  };
}

/** The runs of [value] in [mask], as {start, length} in hops. */
function runs(
  mask: boolean[],
  value: boolean,
): { start: number; length: number }[] {
  const out: { start: number; length: number }[] = [];
  let start = -1;
  for (let i = 0; i <= mask.length; i++) {
    const on = i < mask.length && mask[i] === value;
    if (on && start < 0) start = i;
    if (!on && start >= 0) {
      out.push({ start, length: i - start });
      start = -1;
    }
  }
  return out;
}

function pitchStats(
  track: VoiceTrack,
  from: number,
  to: number,
): Pick<SpeechMetrics, 'pitchMedianHz' | 'pitchSpreadSemitones'> {
  const { start, mask } = track.voiced(from, to);
  const voiced = mask
    .map((on, i) => (on ? track.f0[start + i] : NaN))
    .filter((it) => Number.isFinite(it));
  // Under half a second of pitched voice says nothing about intonation.
  if (voiced.length < 25) return {};
  const median = percentile(voiced, 50);
  const semis = voiced.map((it) => 12 * Math.log2(it / median));
  return {
    pitchMedianHz: Math.round(median),
    pitchSpreadSemitones: round(
      percentile(semis, 90) - percentile(semis, 10),
      1,
    ),
  };
}

/** Autocorrelation F0, 75–400 Hz; NaN when the frame isn't clearly periodic. */
function pitchOf(frame: Float32Array, window: Float32Array): number {
  let mean = 0;
  for (const x of frame) mean += x;
  mean /= frame.length;
  const y = new Float32Array(frame.length);
  for (let i = 0; i < frame.length; i++) y[i] = (frame[i] - mean) * window[i];
  const lo = Math.floor(RATE / 400);
  const hi = Math.floor(RATE / 75);
  const ac = (lag: number): number => {
    let sum = 0;
    for (let i = 0; i + lag < y.length; i++) sum += y[i] * y[i + lag];
    return sum;
  };
  const zero = ac(0);
  if (zero <= 0) return NaN;
  let best = lo;
  let bestValue = -Infinity;
  for (let lag = lo; lag < hi; lag++) {
    const value = ac(lag);
    if (value > bestValue) {
      bestValue = value;
      best = lag;
    }
  }
  return bestValue / zero > 0.45 ? RATE / best : NaN;
}

function hanning(n: number): Float32Array {
  const out = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    out[i] = 0.5 - 0.5 * Math.cos((2 * Math.PI * i) / (n - 1));
  }
  return out;
}

/** numpy's default (linear) percentile. */
export function percentile(values: number[], p: number): number {
  const sorted = [...values].sort((a, b) => a - b);
  const at = ((sorted.length - 1) * p) / 100;
  const lo = Math.floor(at);
  const hi = Math.ceil(at);
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (at - lo);
}

function round(value: number, digits: number): number {
  const k = 10 ** digits;
  return Math.round(value * k) / k;
}
