"""The two takes one above the other: loudness, pauses in orange, the numbers.

    python plot_takes.py rushed.wav paced.wav WORDS out.png
"""
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

from speech_metrics import HOP, analyse

bg, fg, muted, accent, second = "#0d1117", "#e6edf3", "#8b949e", "#f0883e", "#58a6ff"
paths, words, out = sys.argv[1:3], int(sys.argv[3]), sys.argv[4]
runs = [analyse(p, words) for p in paths]
end = max(len(raw[2]) for _, raw in runs) * HOP
fig, axes = plt.subplots(2, 1, figsize=(7.8, 4.6), sharex=True, facecolor=bg)
for ax, name, (r, raw) in zip(axes, ["Rushed", "Paced"], runs):
    _, _, db, _, _, ps = raw
    t = np.arange(len(db)) * HOP
    ax.set_facecolor(bg)
    ax.fill_between(t, -60, np.maximum(db, -60), color=second, alpha=0.55, lw=0)
    for start, d in ps:
        ax.axvspan(start, start + d, color=accent, alpha=0.45, lw=0)
    ax.set_xlim(0, end)
    ax.set_yticks([])
    ax.tick_params(colors=muted, labelsize=9)
    for s in ax.spines.values():
        s.set_visible(False)
    ax.set_title(
        f"{name}: {r['wpm']} wpm · pauses {int(r['pause_share']*100)}% of the time · "
        f"longest {r['longest_pause_s']} s",
        color=fg, fontsize=11, loc="left",
    )
axes[1].set_xlabel("seconds  ·  same 104 words  ·  orange = pause ≥ 0.25 s", color=muted, fontsize=9)
fig.tight_layout()
fig.savefig(out, dpi=150, facecolor=bg)
