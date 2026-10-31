"""Share of gaps (the turn ended) vs pauses (the same speaker goes on) that
a silence threshold would call 'end of turn'. Numbers from Heldner & Edlund
2010, J. Phonetics 38(4), section 'Results' (data/silence_threshold.csv).

    python plot_silence.py ../data/silence_threshold.csv ../img/silence.png
"""
import csv
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

bg, fg, muted, accent, second = "#0d1117", "#e6edf3", "#8b949e", "#f0883e", "#58a6ff"
rows = [r for r in csv.DictReader(open(sys.argv[1])) if r["corpus"] == "HCRC Map Task"]
fig, ax = plt.subplots(figsize=(5.2, 4.2), facecolor=bg)
ax.set_facecolor(bg)
w = 0.36
for i, r in enumerate(rows):
    g, p = float(r["gaps_captured_pct"]), float(r["pauses_captured_pct"])
    ax.bar(i - w / 2, g, w, color=second)
    ax.bar(i + w / 2, p, w, color=accent)
    ax.text(i - w / 2, g + 1.5, f"{g:.0f}%", ha="center", color=fg, fontsize=15)
    ax.text(i + w / 2, p + 1.5, f"{p:.0f}%", ha="center", color=fg, fontsize=15)
ax.set_xticks(range(len(rows)), [f"silence > {int(r['threshold_ms'])/1000:g} s" for r in rows],
              color=fg, fontsize=13)
ax.set_yticks([])
ax.set_ylim(0, 70)
for s in ax.spines.values():
    s.set_visible(False)
ax.tick_params(length=0)
ax.set_title("A silence timer fires on pauses\nas often as on real ends",
             color=fg, fontsize=14, loc="left")
ax.text(0, -0.2, "blue: the turn really ended (gap)\norange: the speaker went on (pause)\n"
        "HCRC Map Task corpus · Heldner & Edlund 2010",
        transform=ax.transAxes, color=muted, fontsize=10.5, va="top")
fig.tight_layout()
fig.savefig(sys.argv[2], dpi=150, facecolor=bg)
