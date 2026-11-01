import {
  BadRequestException,
  Body,
  Controller,
  Get,
  HttpCode,
  NotFoundException,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { AuthUser } from '../auth/auth.tokens';
import { CurrentUser } from '../auth/current-user.decorator';
import { SessionGuard } from '../auth/session.guard';
import { CallsService, CallView } from './calls.service';
import { isGoal } from './goals';

const NOT_FOUND = 'Essa ligação não foi encontrada.';

/** The person's calls: the history on the home, and one call opened. */
@Controller('calls')
@UseGuards(SessionGuard)
export class CallsController {
  constructor(private readonly _calls: CallsService) {}

  /** Newest first, with the goal picked before the first call. */
  @Get()
  list(
    @CurrentUser() user: AuthUser,
  ): Promise<{ goal: string | null; calls: CallView[] }> {
    return this._calls.history(user.id);
  }

  @Get(':id')
  async one(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<CallView> {
    const call = await this._calls.one(user.id, id);
    if (call === undefined) throw new NotFoundException(NOT_FOUND);
    return call;
  }

  /** The person opened it: it stops being "Nova". */
  @Post(':id/seen')
  @HttpCode(204)
  async seen(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<void> {
    if (!(await this._calls.markSeen(user.id, id, new Date()))) {
      throw new NotFoundException(NOT_FOUND);
    }
  }
}

/** What brought the person here, picked on the first-run home. */
@Controller('users/me/goal')
@UseGuards(SessionGuard)
export class GoalController {
  constructor(private readonly _calls: CallsService) {}

  @Put()
  @HttpCode(204)
  async set(
    @CurrentUser() user: AuthUser,
    @Body() dto: { goal?: unknown },
  ): Promise<void> {
    const goal = dto?.goal;
    if (!isGoal(goal)) throw new BadRequestException('Objetivo inválido.');
    await this._calls.setGoal(user.id, goal);
  }
}
