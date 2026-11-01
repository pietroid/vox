import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { OpenRouterClient } from '../assistant/openrouter.client';
import { Database, DB } from '../db/db';
import { DrizzleCallStore } from './call.store';
import { CallsController, GoalController } from './calls.controller';
import { CALL_STORE, CallsService } from './calls.service';

/** The history of calls and the goal; the call's gateway keeps calls here. */
@Module({
  imports: [ConfigModule],
  controllers: [CallsController, GoalController],
  providers: [
    CallsService,
    OpenRouterClient,
    {
      provide: CALL_STORE,
      inject: [DB],
      useFactory: (db: Database) => new DrizzleCallStore(db),
    },
  ],
  exports: [CallsService],
})
export class CallsModule {}
