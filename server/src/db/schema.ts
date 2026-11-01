import {
  boolean,
  doublePrecision,
  index,
  integer,
  jsonb,
  pgTable,
  text,
  timestamp,
} from 'drizzle-orm/pg-core';

/**
 * Everything the app keeps, in one Postgres database.
 *
 * The four tables here are Better Auth's and follow its schema exactly: who
 * someone is, their sessions, the Google account behind them, and the
 * short-lived verification rows the OAuth dance needs. The app's own tables
 * go below them. After editing, `npm run db:generate` and commit `drizzle/`.
 */

const createdAt = () =>
  timestamp('created_at', { withTimezone: true }).notNull().defaultNow();
const updatedAt = () =>
  timestamp('updated_at', { withTimezone: true })
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date());

// ---------------------------------------------------------------------------
// Better Auth
// ---------------------------------------------------------------------------

export const user = pgTable('user', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  email: text('email').notNull().unique(),
  emailVerified: boolean('email_verified').notNull().default(false),
  image: text('image'),
  createdAt: createdAt(),
  updatedAt: updatedAt(),
});

export const session = pgTable(
  'session',
  {
    id: text('id').primaryKey(),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    token: text('token').notNull().unique(),
    ipAddress: text('ip_address'),
    userAgent: text('user_agent'),
    userId: text('user_id')
      .notNull()
      .references(() => user.id, { onDelete: 'cascade' }),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (table) => [index('session_user_id_idx').on(table.userId)],
);

export const account = pgTable(
  'account',
  {
    id: text('id').primaryKey(),
    accountId: text('account_id').notNull(),
    providerId: text('provider_id').notNull(),
    userId: text('user_id')
      .notNull()
      .references(() => user.id, { onDelete: 'cascade' }),
    accessToken: text('access_token'),
    refreshToken: text('refresh_token'),
    idToken: text('id_token'),
    accessTokenExpiresAt: timestamp('access_token_expires_at', {
      withTimezone: true,
    }),
    refreshTokenExpiresAt: timestamp('refresh_token_expires_at', {
      withTimezone: true,
    }),
    scope: text('scope'),
    password: text('password'),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (table) => [index('account_user_id_idx').on(table.userId)],
);

export const verification = pgTable(
  'verification',
  {
    id: text('id').primaryKey(),
    identifier: text('identifier').notNull(),
    value: text('value').notNull(),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (table) => [index('verification_identifier_idx').on(table.identifier)],
);

// ---------------------------------------------------------------------------
// The app
// ---------------------------------------------------------------------------

/** What brought a person to Vox, asked before their first call. */
export const userGoal = pgTable('user_goal', {
  userId: text('user_id')
    .primaryKey()
    .references(() => user.id, { onDelete: 'cascade' }),
  /** A `SpeakingGoal` key: `presentations`, `interviews`… */
  goal: text('goal').notNull(),
  updatedAt: updatedAt(),
});

/** A call's numbers, as `calls/call-metrics.ts` sums its takes. */
export interface StoredCallMetrics {
  wordsPerMinute: number;
  longPauses: number;
  hesitations: number;
}

/**
 * One finished call: when, how long, what it cost, and what the model
 * wrote about it. Never the audio, never the transcript.
 *
 * Calls on one subject share `subject_id` (the first call's id); a
 * follow-up names the call it continues in `follows_call_id`.
 */
export const call = pgTable(
  'call',
  {
    id: text('id').primaryKey(),
    userId: text('user_id')
      .notNull()
      .references(() => user.id, { onDelete: 'cascade' }),
    startedAt: timestamp('started_at', { withTimezone: true }).notNull(),
    durationMs: integer('duration_ms').notNull(),
    costUsd: doublePrecision('cost_usd').notNull(),
    title: text('title').notNull(),
    summary: text('summary').notNull(),
    learnings: jsonb('learnings').$type<string[]>().notNull(),
    metrics: jsonb('metrics').$type<StoredCallMetrics>(),
    subjectId: text('subject_id').notNull(),
    subjectIndex: integer('subject_index').notNull(),
    followsCallId: text('follows_call_id'),
    seenAt: timestamp('seen_at', { withTimezone: true }),
    createdAt: createdAt(),
  },
  (table) => [
    index('call_user_started_idx').on(table.userId, table.startedAt),
    index('call_subject_idx').on(table.userId, table.subjectId),
  ],
);

export const schema = {
  user,
  session,
  account,
  verification,
  userGoal,
  call,
};
