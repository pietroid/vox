# A call with the agent, streamed through Deepgram

2026-10-31 · delivery (draft: design done, build next) · track: **mockup** ·
from the RFC [*Stream the call through Deepgram, measure in code, coach with the model*](../../research/2026-10-30-voice-pipeline/README.md)

## 1. The prompt

Issue [#3](https://github.com/pietroid/vox/issues/3), *Implement: Stream the
call through Deepgram, measure in code, coach with the model*:

> Build what the RFC [product/research/2026-10-30-voice-pipeline/README.md](https://github.com/pietroid/vox/blob/main/product/research/2026-10-30-voice-pipeline/README.md) recommends, approved in #1 and merged in #2.
>
> - Read it as the research (see "From an RFC" in the /create skill): what it recommends, in its priority order, and its Rollout are the spec.
> - A `> **Decision**` note in it is binding; every other decision takes the option marked *(recommended)*.
> - The plan (or the board, if it changes what the person sees) says which rollout phases this PR ships, Phase 0 first.

The RFC's binding decisions: phone first (iOS, Android); Deepgram **Flux
STT** and **Flux TTS** as two separate calls with our model in between; no
button ends a turn, Flux does (a long pause means "I'm done"); the call
screen from the design system is the main feature.

## 2. The design

**Track: mockup.** The RFC's first piece is the call screen, so the person
approves what they will see before anything is wired.

![The board: home with the call as its one action, then the call in Ouvindo, Pensando, Falando, and muted with captions hidden](img/mockup-board.png)

Drawn by the real app (`app/lib/voice_call_preview.dart`, five scenes) with
the widgets the build ships; pins in [`board.json`](board.json). Each screen
alone: [1](img/mockup-1.png) · [2](img/mockup-2.png) ·
[3](img/mockup-3.png) · [4](img/mockup-4.png) · [5](img/mockup-5.png).

### What this PR ships: the rollout phases

The RFC orders the work in *The change*; this delivery cuts it into phases:

| Phase | What | Ships here |
|---|---|---|
| **0 · Measure** | a 20-line script against the key: Flux TTS first-audio latency and how its pt voice sounds; Flux STT's end of turn on a long Portuguese talk; cost per turn in the server log | **yes, first** |
| **1 · The call** | the call screen; mic streamed as PCM with echo cancel; `wss /api/assistant/voice` relaying to Flux STT, `Configure` as a turn grows, cut-in; Flux TTS sentence by sentence; metrics in TypeScript; the model's reply streamed; WebSocket through nginx and the tunnel | **yes** |
| 2 · The material | the session plan built once from the person's slides or notes (cached prefix) | no: the app has no way to give it material yet; a follow-up issue |

### References

Drawn from known patterns, not browsed (no Mobbin session here):

- **The phone's own call screen** (iOS Phone, WhatsApp calls): round
  controls at the thumb, toggles turn light when on, hang-up the one red.
- **ChatGPT voice mode**: an abstract presence instead of a face, its
  motion driven by the voice's loudness; no button to end a turn.
- **Live captions** (Android Live Caption, FaceTime): the current line at
  full ink, the previous one fading.

### Decisions

| Pin | Decision | Why |
|---|---|---|
| A | The home's one accent action is **Começar ligação**, `AppIcons.call` (Phosphor `phone`), opening `/ligacao` full screen | the call is the product; the RFC centres on it |
| B | The text chat becomes **Prefiro escrever**, a tertiary button | the RFC keeps it as the quiet fallback |
| C | Home copy states the rule: talk for real, Vox answers when you finish | no button ends a turn, so the person must know |
| D | The listening halo follows the mic's loudness (RMS on the phone, ~20×/s), in ink | "a halo follows your voice"; no round trip; never a timer |
| E | Captions are only the agent's; its last sentence stays faded while you talk | the design system's rule: speech going by, not a transcript |
| F | Title *Assistente* and the elapsed time, tabular figures | as the design system draws it |
| G | Pensando = from Flux's end of turn to the first audio; the dot breathes | the screen's states are the pipeline's events |
| H | After a long talk the phone says a fixed **"Boa! Deixa eu ver seus números…"** (`callAcknowledge`) | time to first audio; never generated |
| I | Falando: filled dot, teal rings follow the played audio's loudness | the design system |
| J | Feedback cites numbers measured in code (pace, pauses) against the person's own first takes | measure with code, judge with the model |
| K | Speaking over the agent stops it (Flux start of turn cancels the reply) | as on a call |
| L | Mute stops the PCM; the ring goes grey and still, *Microfone desligado*; Flux kept alive | the RFC; a still ring says nobody is heard |
| M | Captions off hides them but keeps their room | the dot never moves while you look at it |
| N | Hang up: the one red control; closes both Deepgram sockets, logs the session cost | the RFC |

**New in the design system** (`app_ui`): `AppPresence` (listening,
thinking, speaking, muted; `level` 0–1), `AppCallControl` (+ `.hangUp`), the
icons `call`, `microphone`, `microphoneOff`, `captions`, `captionsOff`,
`hangUp` (Phosphor fill `phoneDisconnect`), and the token
`AppSpacing.callCaptions` (120, the room kept for captions). Nothing generic
"AI": the presence is the dot from the mark.

## Build brief

*Phase 3 starts here; Phase 4 replaces this section with sections 3–5.*

### Files the design session wrote (kept on this branch for the build)

- `app/lib/voice_call_preview.dart`: the preview entry point, 5 scenes.
  Delete it at the end of Phase 4.
- `app/packages/call/`: new package; `CallState` (`CallPhase`: connecting,
  listening, thinking, speaking, unavailable, dropped), `CallCubit` (seeded;
  toggles; `captioned`), `CallPage`/`CallView`.
- `app/packages/app_ui/lib/src/widgets/app_presence.dart`,
  `app_call_control.dart`; `app_icons.dart`, `app_spacing.dart`,
  `app_ui.dart` (exports).
- `app/lib/home/home_page.dart` (the two buttons), `app/lib/app/view/app.dart`
  (route `/ligacao`, screen name *Ligação*), `app/pubspec.yaml` (+ `call`).
- `app/packages/l10n/lib/arb/app_pt.arb` + `gen/`: `homeCall*`, `homeWrite`,
  `call*` (incl. `callAcknowledge`, `callUnavailable`, `callDropped`).

### Server (`server/src/assistant/`)

1. **Phase 0 first:** `scripts`-style probe (`server/scripts/deepgram-probe.ts`
   or similar) that opens Flux TTS `/v2/speak` in `pt` and Flux STT
   `flux-general-multi`, prints time to first audio and end-of-turn events
   on a recorded pt-BR talk (`product/research/.../code/make_samples.sh`
   makes one). Record what it printed in section 3.
2. `voice.gateway.ts`: WebSocket at `/api/assistant/voice`, authenticated
   like `SessionGuard` (session cookie or bearer, on the upgrade); 503-style
   close without `DEEPGRAM_API_KEY`. Relays PCM 16 kHz mono to Flux STT;
   sends `{state}` (listening / thinking / speaking) and `{caption}` with
   each audio sentence; after ~20 s of speech sends `Configure`
   (`eot_threshold` 0.9, `eot_timeout_ms` 3000), back to defaults next
   turn; `StartOfTurn` while replying cancels the LLM stream and TTS.
   Keep-alives while muted. Talk cap ~10 min.
3. `deepgram-tts.ts`: sentences in, audio chunks out (Flux TTS, pt voice).
4. `speech-metrics.ts`: port of `code/speech_metrics.py` on Flux word
   timings (wpm, pause share, longest pause; voiced time with no word as
   filler time); specs against `data/takes.jsonl`.
5. `assistant.service.ts`: streamed OpenRouter reply split by sentence; a
   coaching system prompt that receives transcript + metrics; the person's
   own baseline from the session's first take.
6. Cost per turn (STT seconds, TTS chars, LLM tokens) in the server log;
   the session's row in `analytics/events.ts` (no text, no audio). Audio
   never stored.
7. `deploy/nginx.conf`: WebSocket upgrade on `/api/assistant/voice`;
   Cloudflare tunnel passes WebSockets by default (check). Nest needs
   `@nestjs/websockets` + `ws` adapter.
8. `DEEPGRAM_API_KEY` in `server/.env.example` and `SETUP.md`.

### App (`app/packages/call/`)

- A `VoiceConnection` behind an interface (fake in tests and preview):
  open the socket with the token from `TokenStore`, send mic PCM, receive
  state/caption/audio. Mic: a streaming recorder with echo cancellation
  (e.g. `record` stream mode, PCM16 16 kHz); player for streamed PCM
  (e.g. `flutter_sound` / `just_audio` custom source). RMS of both → `level`.
- `CallCubit` driven by the connection; the elapsed timer; play
  `callAcknowledge` with the phone's TTS (`flutter_tts`) on end of a long
  turn; iOS mic permission string, Android `RECORD_AUDIO`.
- Cubit and widget tests; `AppPresence` respects reduced motion.

### Decided unattended

- **Track: mockup**, since the call screen is the RFC's main feature.
- The home's primary action becomes the call; the text chat stays as
  *Prefiro escrever* (the RFC: "the text chat stays as the quiet fallback").
- Toggles moved from their default (muted, captions off) turn ink with a
  dark glyph, like a phone's call buttons; the design system didn't say.
- Muted shows the ring grey and still, with *Microfone desligado* in place
  of *Ouvindo*.
- The halo follows loudness only (no time-based pulse as in the HTML); with
  reduced motion only Pensando's breath stops.
- The caption area keeps a fixed height (`AppSpacing.callCaptions`) so the
  dot never moves between states.
- Phase 2 (session plan from material) is left for a follow-up: the app
  has no way to give it material yet. Phases 0 and 1 ship here.
- Unavailable (no key) and dropped are drawn as a centred line with only the
  hang-up button; not on the board.

### Open questions

- None blocking. If the Phase 0 probe shows Flux TTS's pt voice or latency
  disappointing, the RFC's fallback is the phone's voice (`flutter_tts`):
  the build would ask on the issue before switching.

### Cost of the design session

Measured by the queue and written in the PR.
