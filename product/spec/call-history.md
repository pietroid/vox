# The first call and the history of calls

What the home is: an invitation until the first call ends, then the
history of calls, each one opening into its summary, what to take from it,
its numbers, and a button that continues the subject with the agent
remembering it. Delivered in
[`product/delivery/2026-11-01-call-history/`](../delivery/2026-11-01-call-history/README.md).

## What the person sees

- **Before the first call** (no call kept): the agent's presence, *Vamos
  ouvir sua voz*, *O que te traz aqui?* with seven goal chips (optional, one
  at a time; a pick shows what the first call will do about it), and one
  button, *Fazer minha primeira ligação*. Writing is the chat icon in the
  top bar.
- **Right after a call**: *Escrevendo o resumo da sua ligação…* while the
  server writes it (the home reads the history again every 2 s, up to 8
  times, until the new call appears).
- **The history**: a call-out with *Começar ligação* (after the first call,
  *Primeira ligação feita*; later, *Da última vez: <first learning>*), then
  *Suas ligações*, newest first. A card: the day (*Hoje*, *Ontem* or the
  date), *Nova* until opened, the title, two lines of summary, the first
  learning, the minutes, the cost in US$, and *Nª do assunto* on a
  follow-up.
- **A call, opened** (`/ligacoes/:id`): the day, the title, the duration to
  the second, the cost, *Resumo*, *O que levar daqui*, *Seus números*
  (pace, long pauses, hesitations, each with its change since the
  subject's first call; only fewer hesitations turns green) and, pinned,
  *Continuar este assunto*.

## The contract

| Route | Answers |
|---|---|
| `GET /api/calls` | `{ goal, calls: [CallView] }`, newest first |
| `GET /api/calls/:id` | `CallView`, or 404 *Essa ligação não foi encontrada.* |
| `POST /api/calls/:id/seen` | 204; the call stops being *Nova* (404 when not yours) |
| `PUT /api/users/me/goal { goal }` | 204; 400 *Objetivo inválido.* for a key not in `GOALS` |
| `wss /api/assistant/voice?follows=<id>` | the call continues that call's subject |

`CallView`: `id`, `startedAt` (ISO, UTC), `durationMs`, `costUsd`, `title`,
`summary`, `learnings` (0–3), `metrics` (`wordsPerMinute`, `longPauses`,
`hesitations`, and the `…Delta`s against the subject's first call, absent on
it) or `null`, `subjectIndex`, `seen`.

Every route takes `SessionGuard` and reads only the person's rows. Goals are
the app's `SpeakingGoal` names: `presentations`, `interviews`, `meetings`,
`teaching`, `recording`, `calm`, `other`.

## What is kept, and when

When the call's socket closes, `CallsService.record` keeps it, **unless
the person was never answered** (no turn). The model is asked once, from
the conversation and the numbers, for `{ title, summary, learnings }` in
Portuguese (`call-summary.ts`); if it fails or answers something
unreadable, the call is kept with a fixed title and no learnings. **The
audio and the transcript are never stored**: only those notes, the
numbers (summed from the call's takes, `speech-metrics.ts`), the time and
the cost (Deepgram + the call's model turns + the notes).

## Memory

A call opens with a brief (`CallsService.brief`) added to the coach's
prompt (`coachPrompt(user, memory)`):

- **A follow-up** (`?follows=<id>`, the person's own call): the last 3
  calls on the subject, each with its day, title, summary, learnings and
  numbers, and the instruction to pick up where they stopped. The greeting
  becomes *Oi, Ana! Vamos continuar de onde paramos?* The new call gets the
  subject's id and the next index. An id that isn't the person's call is
  ignored: the call starts fresh.
- **Otherwise**, the goal, if picked, and the opening that goal promises
  (the same sentence the app shows under the chips, `goals.ts`).

## Files

- Server: `server/src/calls/` (`calls.controller.ts`, `calls.service.ts`,
  `call.store.ts` with the Drizzle and in-memory stores, `call-summary.ts`,
  `goals.ts`); tables `call` and `user_goal` (`drizzle/0001_calls.sql`);
  `voice.gateway.ts` asks for the brief and records on close.
- App: `app/packages/call_history/` (`CallHistoryRepository`,
  `CallHistoryCubit`, `CallRecord`, `SpeakingGoal`, `CallFormat`, the views
  `GoalPicker`, `CallCard`, `CallDetailPage`); `lib/home/home_page.dart`
  (`startCall`, `openCall`) and `lib/home/call_detail_route.dart`;
  `CallPage(follows:)` pops whether the call got through.
