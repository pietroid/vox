# The voice call

A call with the agent, on the phone: the person talks, the agent answers
when they finish, and its feedback rests on numbers measured in code.
Delivered in [`product/delivery/2026-10-31-voice-call/`](../delivery/2026-10-31-voice-call/README.md),
from the RFC [`2026-10-30-voice-pipeline`](../research/2026-10-30-voice-pipeline/README.md).

## What the person sees

The home's one accent action starts a call (`/ligacao`; *Fazer minha
primeira ligação* before the first, *Começar ligação* after, *Continuar
este assunto* on a call's page, see [call-history.md](./call-history.md));
the text chat is the chat icon in the top bar. The call screen shows the agent's
presence (Ouvindo · Pensando · Falando · Microfone desligado), its captions
(the sentence it is saying, the one before faded) and three controls:
mute, captions, hang up. No button ends a turn.

## The contract

`wss /api/assistant/voice`, one socket per call, signed in on the upgrade
(bearer token on the phones, the session cookie on the web; a browser's
`Origin` must be ours).

| Direction | Message | Meaning |
|---|---|---|
| phone → server | binary | the mic, PCM16 16 kHz mono, ~80 ms chunks |
| phone → server | `{type:'mute', muted}` | the mic is off; the server feeds Flux silence so the call stays up |
| server → phone | `{type:'state', state}` | `listening` · `thinking` · `speaking`, the pipeline's events |
| server → phone | `{type:'caption', text}` | the sentence whose audio comes next |
| server → phone | binary | the agent's voice, PCM16 24 kHz mono |
| server → phone | `{type:'interrupt'}` | the person cut in: drop what's queued |
| server closes | 4401 · 4503 · 1011 · 4000 | not signed in · no voice on this server · dropped · 30-minute cap |

`?follows=<callId>` on the socket continues that call's subject: the coach
is told the earlier calls on it ([call-history.md](./call-history.md)).

The phone shows Falando while its player still has audio, and a caption
when its audio starts playing (`PlaybackClock`), not when it arrives.

## Turn-taking

Flux STT ends a turn. Every turn starts at Flux's defaults
(`eot_threshold` 0.7, 5 s), so a short answer ends on its meaning. Once a
turn passes **10 s**, the server sends `Configure` with `eot_threshold` 1.0
and `eot_timeout_ms` 3000: only **3 s of silence** ends a talk. Measured in
Phase 0: at 0.8 and 0.9 Flux still ended a paced talk at a 0.9 s pause
between sentences. A turn Flux ends early merges with the next if the
agent hasn't spoken yet. Speaking over the agent stops it. A talk is cut
at 10 minutes.

## Measuring and coaching

A turn of 15 s or more is a **take**: `speech-metrics.ts` measures pace
(Flux's word timings), pauses and pitch (the relayed PCM, measured as it
passes) and hesitation (voiced time with no word). The first take is the
person's reference. The model gets the transcript, the numbers and the
reference, and is told to use only those. After a talk of 20 s or more the
agent first says a fixed *"Boa! Deixa eu ver seus números…"*.

## What is kept

The audio is measured and dropped; the conversation lives as long as the
socket. When it closes, a call in which the person was answered goes to
the history: the model writes a title, a summary and what to take away
from the conversation, and only those, the summed numbers, the time and
the cost are stored; the transcript is not
([call-history.md](./call-history.md)). The server logs each turn's cost
and time to first audio; PostHog gets one `voice_call` per call with
counts, cost and whether it was a follow-up, no words.

## Files

- Server: `server/src/assistant/voice/` (`voice.gateway.ts`,
  `voice-session.ts`, `deepgram.ts`, `speech-metrics.ts`, `coach.ts`);
  `OpenRouterClient.stream`; `deploy/nginx.conf` upgrades the path.
  `server/scripts/deepgram-probe.mjs` and `voice-e2e.mjs` run against the
  real services.
- App: `app/packages/call/` (`CallCubit`, `CallService`, `VoiceLine`,
  `PlaybackClock`, `RecordMicrophone`, `PcmVoicePlayer`, the page).
- Env: `DEEPGRAM_API_KEY` (and the OpenRouter key and model). Without
  them the socket closes 4503 and the screen says the call isn't available.
