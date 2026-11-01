CREATE TABLE "call" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"started_at" timestamp with time zone NOT NULL,
	"duration_ms" integer NOT NULL,
	"cost_usd" double precision NOT NULL,
	"title" text NOT NULL,
	"summary" text NOT NULL,
	"learnings" jsonb NOT NULL,
	"metrics" jsonb,
	"subject_id" text NOT NULL,
	"subject_index" integer NOT NULL,
	"follows_call_id" text,
	"seen_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "user_goal" (
	"user_id" text PRIMARY KEY NOT NULL,
	"goal" text NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "call" ADD CONSTRAINT "call_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_goal" ADD CONSTRAINT "user_goal_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "call_user_started_idx" ON "call" USING btree ("user_id","started_at");--> statement-breakpoint
CREATE INDEX "call_subject_idx" ON "call" USING btree ("user_id","subject_id");