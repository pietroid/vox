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
- **Turn detection is a mode, not a constant.** A call ends a turn at a
  pause; a rehearsal's pauses are part of the talk, so a talk is ended by
  the speaker and the detector only runs in conversation. Read:
  [Deepgram Flux](https://developers.deepgram.com/docs/models-languages-overview).
  Met in: [voice pipeline](2026-10-30-voice-pipeline/README.md).

## Agents

- **Precompute what you can predict.** Questions and rubric about known
  material are built once per session; a stable prefix (material + plan) is
  what prompt caching rewards. Met in:
  [voice pipeline](2026-10-30-voice-pipeline/README.md).
