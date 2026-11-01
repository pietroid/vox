# The first call, then the history of calls

2026-11-01 · delivery (draft: design) · track: **mockup**

## 1. The prompt

Issue [#5](https://github.com/pietroid/vox/issues/5), *Create an onboarding
and a history of calls*:

> Create an attractive onboarding experience. From until the user signs up until the moment the user does the first call, there should be a nice empty screen engaging the user to do his first call and asking what brings the user there.
>
> After the first call ends, it appears on the first page in the history of calls, with content summary and the learnings. It should show the date, how much the user spent (in $) and in time too. When clicking on it, it should open with more details about the summary of it, and have a button to call again and follow up on that subject (so the memory accumulates)
>
> Make a good design with good iconography, great calls to action, etc. Make it shine.

## 2. The design

**Track: mockup.** It's all about what the person sees: the empty home, a
history on the home, and a page for each call.

![The board: the first-run home, a goal picked, the home after the first call, the history, a call opened, and its numbers](img/mockup-board.png)

Drawn by the real app (`app/lib/call_history_preview.dart`, six scenes)
with the widgets the build will ship; pins in [`board.json`](board.json).
Each screen alone: [1](img/mockup-1.png) · [2](img/mockup-2.png) ·
[3](img/mockup-3.png) · [4](img/mockup-4.png) · [5](img/mockup-5.png) ·
[6](img/mockup-6.png).

### The flow

1. **Before the first call** the home is an invitation: the agent's
   presence (the dot from the mark), *Vamos ouvir sua voz*, the question
   *O que te traz aqui?* with seven goal chips, and one button,
   *Fazer minha primeira ligação*.
2. **Picking a goal** shows one line on what the first call will do about
   it. The goal is optional: the button works without it.
3. **After the first call** the home becomes the history: a call-out
   (*Primeira ligação feita*) with *Começar ligação*, then *Suas ligações*
   with the call's card, marked *Nova*.
4. **The history**: every call, newest first. Each card shows the date, the
   subject, two lines of summary, the first learning, the minutes, the cost
   in US$, and *2ª do assunto* when it follows up an earlier call. The
   call-out quotes the last call's first learning (*Da última vez: …*).
5. **A call, opened** (`/ligacoes/:id`): the date, the subject as a
   heading, the facts as pills (time to the second, cost, subject index),
   *Resumo*, *O que levar daqui* (numbered), *Seus números*, and one button
   pinned at the foot, *Continuar este assunto*.
6. **Its numbers**: pace, long pauses and hesitations, the numbers
   `speech-metrics.ts` already measures, each with its change since the
   subject's first call.

### References

Drawn from known patterns, not browsed (Mobbin needs a login, and no
browser was connected to this unattended run):

- **Duolingo / Headspace onboarding**: one question with tappable answers
  before the first lesson, and a line saying what the first session will
  be like, so the first tap has a promise behind it.
- **Granola / Otter meeting history**: a list of sessions, each card
  carrying the AI's title, a gist and the facts, the detail opening into
  summary and action items.
- **Strava activity detail**: a few big numbers in tiles with the change
  against a baseline, under the story of the activity.

### Decisions

| Pin | Decision | Why |
|---|---|---|
| 1A | The hero is `AppPresence` (the brand's dot, speaking), not an illustration | The person meets what they'll talk to; no generic AI art |
| 1B, 2A | Seven goal chips (new `AppChoiceChip`), one at a time, optional | One tap, no typing; skipping must not block the first call |
| 1C, 3A, 5C | One accent button per screen, full width, with `AppIcons.call` | Every call starts from the same glyph and colour |
| 1D | *Prefiro escrever* moves to a chat icon (`AppIcons.assistant`) in the top bar | Keeps one accent action in the body; the chat stays a tap away |
| 1E | *Uns três minutos · só você e o Vox* under the first button | Says how long and that nobody else listens, the two worries before a first call |
| 2B | One sentence per goal on what the first call does | The goal changes the call, and the person sees how |
| 3B | *Nova* badge until the call is opened | Points at the first card right after the call ends |
| 3D | The card leads with the first learning, behind `AppIcons.learning` (Phosphor lightbulb) | The learning is why the history is worth opening |
| 3E | Cost as *US$ 0,07* (`coins`), time as *6 min* (`clock`) | The issue asks for both; the Brazilian comma, dollars because that's what the calls cost |
| 4A | The call-out quotes *Da última vez: …* | Carries the last lesson into the next call |
| 4B | *2ª do assunto* with `arrowBendDownRight` | Shows which calls continue a subject, so memory is visible |
| 5A | Duration to the second on the detail, minutes on the card | Precise where there's room, scannable in the list |
| 5C | *Continuar este assunto*, pinned, with *O Vox lembra desta conversa…* above | The follow-up is the page's one action, and the line says what it does |
| 6B | Only fewer hesitations turns green | Pace and pauses have no good direction on their own |

New icons (all Phosphor regular, named in `AppIcons`): `back`, `chevron`,
`duration`, `cost`, `followUp`, `learning`, `pace`, `pauses`,
`hesitations`, and `goalPresentations`, `goalInterviews`, `goalMeetings`,
`goalTeaching`, `goalRecording`, `goalCalm`, `goalOther`. No new brand SVG.

### Decided unattended

- **Track: mockup**, six scenes (the sixth is the detail scrolled to its
  numbers, which sit below the fold on a 390×844 phone).
- **The goal is optional.** The first-call button is enabled before a pick:
  a question that blocks the first call costs more than it tells.
- **Writing moves to the top bar** (chat icon) on both homes, instead of a
  second button under the call.
- **Cost is shown in US dollars** as the issue says, not converted to reais.
- **"Follow up" means a new call that starts with the earlier calls on the
  subject as memory** (their summaries, learnings and numbers in the
  model's context), not one growing call.
- **The history is the home**, not a separate tab: the app has one screen
  today, and the issue says "on the first page".

## Build brief

Phase 3 starts here; Phase 4 replaces this section with sections 3–5.

### Files written in the design session (uncommitted until the queue commits them)

- `app/lib/call_history_preview.dart`: the preview, six scenes over a seeded
  `CallHistoryCubit` (delete it in Phase 4 after the build prints).
- `app/lib/home/home_page.dart`: `HomePage` (provides an empty
  `CallHistoryCubit` for now) and `HomeView` (first run vs history).
- `app/packages/call_history/` (new, in `app/pubspec.yaml`): `CallRecord`,
  `CallMetrics`, `SpeakingGoal`, `CallHistoryCubit`/`State` (no repository
  yet), `CallFormat` (`callWhen`, `callDuration`, `callCost`, `now` passed
  in), views `GoalPicker`, `CallCard`, `CallDetailPage`.
- `app/packages/app_ui/`: widgets `AppCard`, `AppChoiceChip`, `AppMeta`;
  tokens `AppSpacing.iconSmall`, `AppSpacing.badge`; the icons above.
- `app/packages/l10n/lib/arb/app_pt.arb` (+ `gen/`): the new strings.
  `homeWrite`, `homeCallTitle`, `homeCallBody`, `homeEmptyTitle` and
  `homeEmptyBody` are now unused: remove them in the build.

### What the build must do

**Server** (`server/src/calls/`, a Nest module, `SessionGuard` and
`@CurrentUser()` on every route, every query scoped to the user):

- Tables in `db/schema.ts`: `user_goal` (or a `goal` column on the user),
  and `calls` (id, user id, started at, duration ms, cost USD, title,
  summary, learnings JSON, metrics JSON, `follows_call_id` nullable,
  `subject_id`, seen at). `npm run db:generate`.
- At the end of a call the voice session (`voice-session.ts`) stores the
  call: it already knows duration and cost per turn and the metrics of each
  take; it asks the model once, after hang-up, for `{ title, summary,
  learnings[] }` in Portuguese from the transcript and the numbers, and
  writes the row. The audio and the transcript are still not stored; only
  what the model wrote and the numbers. **This changes the voice-call
  spec's "Nothing is kept"**: update `product/spec/voice-call.md`.
- Routes: `GET /api/calls` (newest first), `GET /api/calls/:id`,
  `POST /api/calls/:id/seen`, `PUT /api/users/me/goal { goal }` (refuse an
  unknown goal, in Portuguese). Rows in `analytics/events.ts` for the
  writes (no words, only the goal's key).
- The socket takes `?goal=` on the first call and `?follows=<callId>` on a
  follow-up: the coach's system prompt then gets the goal, or the subject's
  earlier calls (summaries, learnings, numbers; the last few, capped), and
  the new row gets the same `subject_id` and `subject_index + 1`. Metric
  deltas are against the subject's first call.

**App:**

- A `CallHistoryRepository` (in `call_history`, over `api_client`), behind
  the cubit: `load()`, `markSeen(id)`, `saveGoal(goal)`; a fake for tests.
- `HomePage` gets the cubit from the repository; it reloads when a call
  ends (the call route pops).
- Route `/ligacoes/:id` → `CallDetailPage`, marking it seen; *Continuar
  este assunto* pushes `/ligacao?follows=<id>`, and the first call passes
  the goal. `CallPage`/`CallService` pass both to the socket.
- Specs: the cubit (`bloc_test`), `CallFormat` (today, yesterday, a date;
  minutes, minutes and seconds; cost rounding), `GoalPicker`, `CallCard`,
  `CallDetailPage`, `HomeView` first run vs history.

### Open questions

- Should a person be able to **delete** a call from the history? Not in
  the issue; left out of the design.
- The cost shown is **what the call cost Vox** (Deepgram + model), as the
  issue asks. If Vox later charges the person a price of its own, this
  number should become that.

### Cost and time of the design session

Measured by the queue, which writes the figures in the PR (the run was told
to skip `.tool/cost`).
