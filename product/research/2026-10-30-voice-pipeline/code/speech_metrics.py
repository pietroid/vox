"""Pace, pauses and pitch from a WAV, with nothing but numpy.

What the server (or the phone) could compute for free after each take,
before any model sees it. Pace needs a word count (from the transcript; here
from the text the take was made from); pauses and pitch come from the audio.

    python speech_metrics.py take.wav WORDS [--plot out.png --title T]

Prints one JSON line: duration, speech time, words per minute, pauses
(count, longest, share of time), pitch median and spread in semitones, and
how long the analysis took.
"""
import json
import sys
import time
import wave

import numpy as np

FRAME = 0.030  # s
HOP = 0.010  # s
MIN_PAUSE = 0.25  # s: shorter gaps are articulation, not pauses
LONG_PAUSE = 2.0  # s


def read(path):
    with wave.open(path) as w:
        rate = w.getframerate()
        x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16)
    return x.astype(np.float32) / 32768, rate


def frames(x, rate):
    n, h = int(FRAME * rate), int(HOP * rate)
    count = 1 + max(0, (len(x) - n) // h)
    idx = np.arange(n)[None, :] + h * np.arange(count)[:, None]
    return x[idx]


def speech_mask(f):
    db = 20 * np.log10(np.sqrt((f**2).mean(axis=1)) + 1e-9)
    floor = np.percentile(db, 10)
    return db > max(floor + 15, db.max() - 45), db


def pauses(mask):
    """Silent runs of at least MIN_PAUSE between the first and last speech."""
    on = np.flatnonzero(mask)
    if len(on) == 0:
        return []
    inner = mask[on[0] : on[-1] + 1]
    runs, start = [], None
    for i, s in enumerate(inner):
        if not s and start is None:
            start = i
        elif s and start is not None:
            runs.append(((start + on[0]) * HOP, (i - start) * HOP))
            start = None
    return [(t, d) for t, d in runs if d >= MIN_PAUSE]


def pitch(f, rate, mask):
    """Autocorrelation F0 per voiced frame, 75-400 Hz; NaN where unvoiced."""
    lo, hi = int(rate / 400), int(rate / 75)
    out = np.full(len(f), np.nan)
    win = np.hanning(f.shape[1])
    for i in np.flatnonzero(mask):
        y = (f[i] - f[i].mean()) * win
        ac = np.correlate(y, y, "full")[len(y) - 1 :]
        if ac[0] <= 0:
            continue
        lag = lo + np.argmax(ac[lo:hi])
        if ac[lag] / ac[0] > 0.45:  # clearly periodic: voiced
            out[i] = rate / lag
    return out


def analyse(path, words):
    t0 = time.perf_counter()
    x, rate = read(path)
    f = frames(x, rate)
    mask, db = speech_mask(f)
    ps = pauses(mask)
    f0 = pitch(f, rate, mask)
    voiced = f0[~np.isnan(f0)]
    semis = 12 * np.log2(voiced / np.median(voiced))
    duration = len(x) / rate
    on = np.flatnonzero(mask)
    span = (on[-1] - on[0] + 1) * HOP
    result = {
        "take": path.rsplit("/", 1)[-1],
        "duration_s": round(duration, 1),
        "words": words,
        "wpm": round(words / (span / 60)),
        "pauses": len(ps),
        "pauses_per_min": round(len(ps) / (span / 60), 1),
        "long_pauses": sum(d >= LONG_PAUSE for _, d in ps),
        "longest_pause_s": round(max((d for _, d in ps), default=0), 2),
        "pause_share": round(sum(d for _, d in ps) / span, 2),
        "pitch_median_hz": round(float(np.median(voiced))),
        # Spread of the voice around its own median: low = monotone.
        "pitch_spread_semitones": round(float(np.percentile(semis, 90) - np.percentile(semis, 10)), 1),
        "analysis_ms": round((time.perf_counter() - t0) * 1000),
    }
    return result, (x, rate, db, mask, f0, ps)


def plot(path_png, title, raw):
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    x, rate, db, mask, f0, ps = raw
    bg, fg, muted, accent, second = "#0d1117", "#e6edf3", "#8b949e", "#f0883e", "#58a6ff"
    t = np.arange(len(db)) * HOP
    fig, (a, b) = plt.subplots(2, 1, figsize=(7.8, 4.2), sharex=True, facecolor=bg)
    for ax in (a, b):
        ax.set_facecolor(bg)
        ax.tick_params(colors=muted, labelsize=9)
        for s in ax.spines.values():
            s.set_visible(False)
    a.fill_between(t, -60, np.maximum(db, -60), color=second, alpha=0.6, lw=0)
    for start, d in ps:
        a.axvspan(start, start + d, color=accent, alpha=0.35, lw=0)
    a.set_ylabel("loudness dB", color=muted, fontsize=9)
    a.set_title(title, color=fg, fontsize=11, loc="left")
    b.plot(t, f0, ".", color=fg, ms=1.5)
    b.set_ylabel("pitch Hz", color=muted, fontsize=9)
    b.set_xlabel("seconds  ·  orange = pauses ≥ 0.25 s", color=muted, fontsize=9)
    fig.tight_layout()
    fig.savefig(path_png, dpi=150, facecolor=bg)


if __name__ == "__main__":
    args = sys.argv[1:]
    result, raw = analyse(args[0], int(args[1]))
    print(json.dumps(result, ensure_ascii=False))
    if "--plot" in args:
        title = args[args.index("--title") + 1] if "--title" in args else ""
        plot(args[args.index("--plot") + 1], title, raw)
