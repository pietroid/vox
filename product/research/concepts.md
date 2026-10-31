# Concepts: what the RFCs taught

Every idea an RFC taught (*Ideas to keep*, the `[!TIP]`s recapped in *Go
deeper*): the sentence to remember, the source to read, and where it was
met. A new RFC reads this first, gives an idea already here one line and a
link, and goes one level deeper on it (see `/research`, Phase 3). Newest
topics add to the bottom of their group.

RFCs: [voice pipeline](2026-10-30-voice-pipeline/README.md).

## Voice and speech

- **Measure with code, judge with the model.** Pace, pauses and filler time
  are arithmetic on word timestamps and loudness; give the model the
  numbers and let it coach. Read: [CrisperWhisper](https://arxiv.org/abs/2408.16589).
  Met in: [voice pipeline](2026-10-30-voice-pipeline/README.md).
- **Time to first audio, not time to answer.** Stream the reply into TTS
  sentence by sentence and cover a known wait with a fixed phrase. Read:
  [ElevenLabs latency guide](https://elevenlabs.io/blog/voice-agent-latency-optimization).
  Met in: [voice pipeline](2026-10-30-voice-pipeline/README.md).
- **The end of a turn is in the words, the pause only confirms it.**
  Pauses inside a turn run longer than the gaps between speakers, so a
  silence timer fires on pauses as often as on real ends (56% vs 48% at
  0.5 s). Judge the end on meaning, ask for more certainty as a turn grows
  long, and keep a long silence as the backstop; no button, as on a call.
  (Replaces "turn detection is a mode", ruled out on review.) Read:
  [Heldner & Edlund 2010](https://doi.org/10.1016/j.wocn.2010.08.002),
  [Flux configure](https://developers.deepgram.com/docs/flux/configure).
  Met in: [voice pipeline](2026-10-30-voice-pipeline/README.md).
- **The screen's states are the pipeline's events.** A voice UI's states
  (listening, thinking, speaking) and captions come from turn events and
  the sentences sent to TTS; levels are measured where the audio is.
  Nothing is inferred twice. Met in:
  [voice pipeline](2026-10-30-voice-pipeline/README.md).

## Agents

- **Precompute what you can predict.** Questions and rubric about known
  material are built once per session; a stable prefix (material + plan) is
  what prompt caching rewards. Met in:
  [voice pipeline](2026-10-30-voice-pipeline/README.md).
