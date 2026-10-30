"""What one practice session costs, per pipeline, and the transcript size.

A session (the assumptions, change them here):
  - the person speaks 6 min (a 4-min talk plus answers), in 6 turns;
  - the agent speaks 6 replies of ~200 chars and one 1,200-char feedback;
  - each LLM turn reads the material (6k tokens) + plan + conversation and
    writes ~80 tokens; the feedback writes ~400.
Prices, USD, read 2026-10-30 (see the RFC's Go deeper for the pages):
  Groq whisper-large-v3-turbo $0.04/h (10 s minimum per request)
  Deepgram Nova-3 multilingual pre-recorded $0.0052/min, Aura-2 $0.030/1k chars
  OpenAI gpt-4o-mini-transcribe ~$0.003/min, gpt-4o-mini-tts ~$0.015/min
  Gemini 3.5 Flash-Lite: $0.30/M audio in, 32 tokens/s; Flash-Lite TTS
    $6/M audio out (to 2026-12-31), assumed 32 tokens/s too
  LLM text: $0.10/M in, $0.40/M out (a Flash-Lite-class model), cached
    input at 0.25x. Realtime speech-to-speech: ~$0.06/min in, ~$0.24/min
    out (OpenAI's 2025 published estimate, unverified).

    python session_cost.py  ->  ../data/session_cost.csv, ../img/cost.png
"""
import csv

SPEAK_MIN = 6.0
TURNS = 6
AGENT_CHARS = TURNS * 200 + 1200
AGENT_MIN = AGENT_CHARS / 900  # ~900 chars of pt-BR per spoken minute
CHARS_PER_WORD = 598 / 104  # measured on code/pitch.txt


def llm(cached: bool) -> float:
    material, plan, convo_per_turn = 6000, 800, 600
    cost = 0.0
    for turn in range(TURNS + 1):
        prefix = material + plan
        convo = convo_per_turn * turn
        out = 400 if turn == TURNS else 80
        in_price = 0.10e-6
        prefix_price = in_price * (0.25 if cached and turn > 0 else 1)
        cost += prefix * prefix_price + convo * in_price + out * 0.40e-6
    return cost




pipelines = [
    # name, stt, tts, llm, note
    ("Phone STT + phone TTS", 0.0, 0.0, llm(True), "breaks on long talks"),
    ("Groq Whisper + phone TTS", max(SPEAK_MIN, TURNS * 10 / 60) * 0.04 / 60, 0.0, llm(True), "recommended"),
    ("Groq Whisper + Gemini TTS", SPEAK_MIN * 0.04 / 60, AGENT_MIN * 60 * 32 * 6e-6, llm(True), "nicer voice"),
    ("Gemini hears audio + TTS", SPEAK_MIN * 60 * 32 * 0.30e-6, AGENT_MIN * 60 * 32 * 6e-6, llm(True), "no word timings"),
    ("OpenAI mini STT + TTS", SPEAK_MIN * 0.003, AGENT_MIN * 0.015, llm(True), ""),
    ("Deepgram Nova-3 + Aura-2", SPEAK_MIN * 0.0052, AGENT_CHARS / 1000 * 0.030, llm(True), ""),
    ("Realtime speech-to-speech", SPEAK_MIN * 0.06, AGENT_MIN * 0.24, 0.0, "estimate"),
]

rows = []
for name, stt, tts, model, note in pipelines:
    total = stt + tts + model
    rows.append({
        "pipeline": name, "stt": round(stt, 5), "tts": round(tts, 5),
        "llm": round(model, 5), "session_usd": round(total, 4),
        "month_100_users_20_sessions_usd": round(total * 2000, 2), "note": note,
    })

with open("../data/session_cost.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys())
    w.writeheader()
    w.writerows(rows)

# How long a talk fits in one 4,000-char message (assistant.controller.ts:25).
with open("../data/transcript_fit.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["wpm", "chars_per_min", "minutes_in_4000_chars"])
    for wpm in (87, 111, 138, 150, 180):
        cpm = wpm * (CHARS_PER_WORD + 1)
        w.writerow([wpm, round(cpm), round(4000 / cpm, 1)])

print(f"LLM per session cached {llm(True):.4f} uncached {llm(False):.4f}")
for r in rows:
    print(r)

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

bg, fg, muted, accent, second = "#0d1117", "#e6edf3", "#8b949e", "#f0883e", "#58a6ff"
names = [r["pipeline"] for r in rows][::-1]
vals = [r["session_usd"] * 100 for r in rows][::-1]  # cents
fig, ax = plt.subplots(figsize=(7.8, 4.4), facecolor=bg)
ax.set_facecolor(bg)
colors = [accent if n == "Groq Whisper + phone TTS" else second for n in names]
ax.barh(names, vals, color=colors, height=0.6)
for y, v in enumerate(vals):
    ax.text(v * 1.15, y, f"{v:.2f}¢", va="center", color=fg, fontsize=10)
ax.set_xscale("log")
ax.set_xlim(0.05, 600)
ax.tick_params(colors=muted, labelsize=10)
ax.tick_params(axis="x", labelsize=8)
for s in ax.spines.values():
    s.set_visible(False)
ax.set_title("One 10-min practice session, US cents (log scale)", color=fg, fontsize=11, loc="left")
ax.set_xlabel("STT + TTS + LLM · material of 6k tokens, cached", color=muted, fontsize=9)
fig.tight_layout()
fig.savefig("../img/cost.png", dpi=150, facecolor=bg)
