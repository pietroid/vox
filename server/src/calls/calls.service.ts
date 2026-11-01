import { randomUUID } from 'node:crypto';
import { Inject, Injectable, Logger } from '@nestjs/common';
import {
  ChatMessage,
  ModelOutcome,
  OpenRouterClient,
  ToolDefinition,
} from '../assistant/openrouter.client';
import type { SpeechMetrics } from '../assistant/voice/speech-metrics';
import type { StoredCallMetrics } from '../db/schema';
import {
  callMetrics,
  FALLBACK_NOTES,
  memoryPrompt,
  notesRequest,
  parseNotes,
} from './call-summary';
import type { CallRow, CallStore } from './call.store';
import { Coach, coachOf } from './coaches';
import { Goal } from './goals';

/** The Nest token the store is injected under. */
export const CALL_STORE = Symbol('CALL_STORE');

/** The model, as the notes need it. */
export type NotesModel = Pick<OpenRouterClient, 'configured'> & {
  generate(
    messages: ChatMessage[],
    tools: ToolDefinition[],
  ): Promise<ModelOutcome>;
};

/** A call's numbers, and how each moved since the subject's first call. */
export interface CallMetricsView extends StoredCallMetrics {
  wordsPerMinuteDelta?: number;
  longPausesDelta?: number;
  hesitationsDelta?: number;
}

/** One call, as the app reads it. */
export interface CallView {
  id: string;
  startedAt: string;
  durationMs: number;
  costUsd: number;
  title: string;
  summary: string;
  learnings: string[];
  metrics: CallMetricsView | null;
  subjectIndex: number;
  /** The id of the subject's first call. */
  subjectId: string;
  /** Who coached it: a `CoachKey`. */
  coach: string;
  seen: boolean;
}

/** What a call starts with: what the coach is told, and what it follows. */
export interface CallBrief {
  /** Appended to the coach's prompt; empty when there's nothing to say. */
  memory: string;
  /** The call this one follows up, the person's own. */
  follows?: CallRow;
  /** Who speaks: the subject's coach on a follow-up, else the one asked for. */
  coach: Coach;
}

/** What the voice session knows when a call ends. */
export interface FinishedCall {
  startedAt: Date;
  durationMs: number;
  usd: number;
  turns: number;
  conversation: ChatMessage[];
  takes: SpeechMetrics[];
}

/**
 * The history of calls: what is kept when a call ends, what the app reads
 * back, and what a follow-up is told of the calls before it.
 */
@Injectable()
export class CallsService {
  private readonly _logger = new Logger('Calls');
  /** Ids for new calls; a spec fixes them. */
  newId: () => string = () => randomUUID();

  constructor(
    @Inject(CALL_STORE) private readonly _store: CallStore,
    @Inject(OpenRouterClient) private readonly _model: NotesModel,
  ) {}

  /** The person's goal and calls, newest first. */
  async history(
    userId: string,
  ): Promise<{ goal: string | null; calls: CallView[] }> {
    const [rows, goal] = await Promise.all([
      this._store.list(userId),
      this._store.goal(userId),
    ]);
    const firsts = new Map(
      rows
        .filter((it) => it.subjectIndex === 1)
        .map((it) => [it.subjectId, it]),
    );
    return {
      goal: goal ?? null,
      calls: rows.map((it) => viewOf(it, firsts.get(it.subjectId))),
    };
  }

  /** One of the person's calls, or undefined when it isn't theirs. */
  async one(userId: string, id: string): Promise<CallView | undefined> {
    const row = await this._store.get(userId, id);
    if (row === undefined) return undefined;
    const [first] = await this._store.subject(userId, row.subjectId);
    return viewOf(row, first);
  }

  markSeen(userId: string, id: string, at: Date): Promise<boolean> {
    return this._store.markSeen(userId, id, at);
  }

  setGoal(userId: string, goal: Goal): Promise<void> {
    return this._store.setGoal(userId, goal);
  }

  /**
   * What a call opens with. [followsId] that isn't one of the person's
   * calls is ignored: the call starts fresh rather than not at all, with
   * [coachKey] (Bianca when unknown). A follow-up keeps its subject's
   * coach whatever [coachKey] says.
   */
  async brief(
    userId: string,
    followsId?: string,
    coachKey?: string,
  ): Promise<CallBrief> {
    const goal = await this._store.goal(userId);
    const follows = followsId
      ? await this._store.get(userId, followsId)
      : undefined;
    const earlier = follows
      ? await this._store.subject(userId, follows.subjectId)
      : [];
    return {
      memory: memoryPrompt(goal, earlier),
      follows,
      coach: coachOf(follows ? follows.coach : coachKey),
    };
  }

  /**
   * Keeps a finished call: the model writes its notes from the
   * conversation, code sums its numbers. A call in which the person was
   * never answered isn't kept. The conversation itself is dropped here.
   */
  async record(
    userId: string,
    brief: CallBrief,
    call: FinishedCall,
  ): Promise<CallRow | undefined> {
    if (call.turns === 0) return undefined;
    const metrics = callMetrics(call.takes);
    let notes = FALLBACK_NOTES;
    let notesUsd = 0;
    try {
      const outcome = await this._model.generate(
        notesRequest(call.conversation, metrics),
        [],
      );
      notesUsd = outcome.usage?.cost ?? 0;
      const parsed =
        outcome.kind === 'final' ? parseNotes(outcome.content) : undefined;
      if (parsed) notes = parsed;
      else this._logger.warn(`[${userId}] notes unreadable, kept without`);
    } catch (error) {
      this._logger.warn(
        `[${userId}] notes failed: ${error instanceof Error ? error.message : String(error)}`,
      );
    }

    const follows = brief.follows;
    let subjectIndex = 1;
    if (follows) {
      const subject = await this._store.subject(userId, follows.subjectId);
      subjectIndex =
        Math.max(
          follows.subjectIndex,
          ...subject.map((it) => it.subjectIndex),
        ) + 1;
    }
    const id = this.newId();
    const row: CallRow = {
      id,
      userId,
      startedAt: call.startedAt,
      durationMs: Math.round(call.durationMs),
      costUsd: round(call.usd + notesUsd, 4),
      title: notes.title,
      summary: notes.summary,
      learnings: notes.learnings,
      metrics,
      subjectId: follows?.subjectId ?? id,
      subjectIndex,
      followsCallId: follows?.id ?? null,
      coach: brief.coach.key,
      seenAt: null,
    };
    await this._store.insert(row);
    return row;
  }
}

function viewOf(row: CallRow, first?: CallRow): CallView {
  const m = row.metrics;
  const base = first && first.id !== row.id ? first.metrics : null;
  return {
    id: row.id,
    startedAt: row.startedAt.toISOString(),
    durationMs: row.durationMs,
    costUsd: row.costUsd,
    title: row.title,
    summary: row.summary,
    learnings: row.learnings,
    metrics: m
      ? {
          ...m,
          ...(base
            ? {
                wordsPerMinuteDelta: m.wordsPerMinute - base.wordsPerMinute,
                longPausesDelta: m.longPauses - base.longPauses,
                hesitationsDelta: m.hesitations - base.hesitations,
              }
            : {}),
        }
      : null,
    subjectIndex: row.subjectIndex,
    subjectId: row.subjectId,
    coach: coachOf(row.coach).key,
    seen: row.seenAt !== null,
  };
}

function round(value: number, digits: number): number {
  const k = 10 ** digits;
  return Math.round(value * k) / k;
}
