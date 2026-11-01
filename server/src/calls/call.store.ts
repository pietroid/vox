import { and, asc, desc, eq } from 'drizzle-orm';
import type { Database } from '../db/db';
import { call, StoredCallMetrics, userGoal } from '../db/schema';

/** One stored call, as the store hands it out. */
export interface CallRow {
  id: string;
  userId: string;
  startedAt: Date;
  durationMs: number;
  costUsd: number;
  title: string;
  summary: string;
  learnings: string[];
  metrics: StoredCallMetrics | null;
  subjectId: string;
  subjectIndex: number;
  followsCallId: string | null;
  /** A `CoachKey`; the subject's first call picked it. */
  coach: string;
  seenAt: Date | null;
}

/**
 * Where calls and goals are kept. Every method takes the user's id and
 * reads or writes only their rows.
 */
export interface CallStore {
  /** The person's calls, newest first. */
  list(userId: string): Promise<CallRow[]>;
  get(userId: string, id: string): Promise<CallRow | undefined>;
  /** The calls on one subject, oldest first. */
  subject(userId: string, subjectId: string): Promise<CallRow[]>;
  insert(row: CallRow): Promise<void>;
  /** Marks a call opened; false when it isn't the person's. */
  markSeen(userId: string, id: string, at: Date): Promise<boolean>;
  goal(userId: string): Promise<string | undefined>;
  setGoal(userId: string, goal: string): Promise<void>;
}

/** The store in Postgres. */
export class DrizzleCallStore implements CallStore {
  constructor(private readonly _db: Database) {}

  list(userId: string): Promise<CallRow[]> {
    return this._db
      .select()
      .from(call)
      .where(eq(call.userId, userId))
      .orderBy(desc(call.startedAt));
  }

  async get(userId: string, id: string): Promise<CallRow | undefined> {
    const [row] = await this._db
      .select()
      .from(call)
      .where(and(eq(call.userId, userId), eq(call.id, id)));
    return row;
  }

  subject(userId: string, subjectId: string): Promise<CallRow[]> {
    return this._db
      .select()
      .from(call)
      .where(and(eq(call.userId, userId), eq(call.subjectId, subjectId)))
      .orderBy(asc(call.subjectIndex));
  }

  async insert(row: CallRow): Promise<void> {
    await this._db.insert(call).values(row);
  }

  async markSeen(userId: string, id: string, at: Date): Promise<boolean> {
    const updated = await this._db
      .update(call)
      .set({ seenAt: at })
      .where(and(eq(call.userId, userId), eq(call.id, id)))
      .returning({ id: call.id });
    return updated.length > 0;
  }

  async goal(userId: string): Promise<string | undefined> {
    const [row] = await this._db
      .select({ goal: userGoal.goal })
      .from(userGoal)
      .where(eq(userGoal.userId, userId));
    return row?.goal;
  }

  async setGoal(userId: string, goal: string): Promise<void> {
    await this._db
      .insert(userGoal)
      .values({ userId, goal })
      .onConflictDoUpdate({ target: userGoal.userId, set: { goal } });
  }
}

/** The store in memory, for specs. */
export class InMemoryCallStore implements CallStore {
  readonly rows: CallRow[] = [];
  readonly goals = new Map<string, string>();

  list(userId: string): Promise<CallRow[]> {
    return Promise.resolve(
      this.rows
        .filter((it) => it.userId === userId)
        .sort((a, b) => b.startedAt.getTime() - a.startedAt.getTime()),
    );
  }

  get(userId: string, id: string): Promise<CallRow | undefined> {
    return Promise.resolve(
      this.rows.find((it) => it.userId === userId && it.id === id),
    );
  }

  subject(userId: string, subjectId: string): Promise<CallRow[]> {
    return Promise.resolve(
      this.rows
        .filter((it) => it.userId === userId && it.subjectId === subjectId)
        .sort((a, b) => a.subjectIndex - b.subjectIndex),
    );
  }

  insert(row: CallRow): Promise<void> {
    this.rows.push({ ...row });
    return Promise.resolve();
  }

  async markSeen(userId: string, id: string, at: Date): Promise<boolean> {
    const row = await this.get(userId, id);
    if (row) row.seenAt = at;
    return row !== undefined;
  }

  goal(userId: string): Promise<string | undefined> {
    return Promise.resolve(this.goals.get(userId));
  }

  setGoal(userId: string, goal: string): Promise<void> {
    this.goals.set(userId, goal);
    return Promise.resolve();
  }
}
