import type { IncomingMessage, Server } from 'node:http';
import type { Duplex } from 'node:stream';
import {
  Inject,
  Injectable,
  Logger,
  OnApplicationShutdown,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { WebSocket, WebSocketServer } from 'ws';
import { ANALYTICS } from '../../analytics/analytics';
import type { Analytics } from '../../analytics/analytics';
import type { Auth } from '../../auth/auth';
import { AUTH, AuthUser } from '../../auth/auth.tokens';
import { headersOf } from '../../auth/session.guard';
import { CallBrief, CallsService } from '../../calls/calls.service';
import { coachOf } from '../../calls/coaches';
import { OpenRouterClient } from '../openrouter.client';
import { bytesOf, Deepgram } from './deepgram';
import { VoiceSession } from './voice-session';

/** Where the phone opens its call. */
export const VOICE_PATH = '/api/assistant/voice';
/** Close codes the app reads: no voice on this server, and not signed in. */
export const UNAVAILABLE = 4503;
export const UNAUTHORIZED = 4401;

/**
 * The call's WebSocket, `wss /api/assistant/voice`, beside Nest's HTTP
 * routes on the same server. Signed in like every route (the bearer token
 * or the session cookie, on the upgrade request); without
 * `DEEPGRAM_API_KEY` or a model it closes with [UNAVAILABLE], as the chat
 * answers 503.
 *
 * `?follows=<callId>` continues a subject: the coach is told the earlier
 * calls on it, and the subject's coach speaks. `?coach=<key>` picks who
 * starts a new subject (`calls/coaches.ts`). When the socket closes, the call goes to the history
 * (`CallsService.record`), which keeps the model's notes and the numbers.
 */
@Injectable()
export class VoiceGateway implements OnApplicationShutdown {
  private readonly _logger = new Logger('Voice');
  private readonly _wss = new WebSocketServer({
    noServer: true,
    maxPayload: 1 << 20,
  });
  private readonly _vendor: Deepgram;

  constructor(
    @Inject(AUTH) private readonly _auth: Auth,
    @Inject(ANALYTICS) private readonly _analytics: Analytics,
    private readonly _model: OpenRouterClient,
    private readonly _config: ConfigService,
    private readonly _calls: CallsService,
  ) {
    this._vendor = new Deepgram(_config.get<string>('DEEPGRAM_API_KEY') ?? '');
  }

  /** Listens for the call's upgrade on the server Nest listens with. */
  attach(server: Server): void {
    server.on(
      'upgrade',
      (request: IncomingMessage, socket: Duplex, head: Buffer) => {
        const path = (request.url ?? '').split('?')[0];
        if (path !== VOICE_PATH) return;
        void this._upgrade(request, socket, head);
      },
    );
  }

  onApplicationShutdown(): void {
    for (const client of this._wss.clients)
      client.close(1001, 'O servidor reiniciou.');
  }

  private async _upgrade(
    request: IncomingMessage,
    socket: Duplex,
    head: Buffer,
  ) {
    // A browser sends its Origin, and with it the cookie: only ours may.
    // The phones send no Origin and authenticate with a bearer token.
    const origin = request.headers.origin;
    if (origin !== undefined && !this._origins.includes(origin)) {
      socket.end('HTTP/1.1 403 Forbidden\r\n\r\n');
      return;
    }

    let user: AuthUser | undefined;
    try {
      const session = await this._auth.api.getSession({
        headers: headersOf(request),
      });
      if (session !== null) {
        user = {
          id: session.user.id,
          email: session.user.email,
          name: session.user.name,
        };
      }
    } catch (error) {
      this._logger.warn(`session check failed: ${String(error)}`);
    }

    const available = this._vendor.configured && this._model.configured;
    const params = new URL(request.url ?? '', 'http://x').searchParams;
    let brief: CallBrief = {
      memory: '',
      coach: coachOf(params.get('coach')),
    };
    if (user !== undefined && available) {
      try {
        brief = await this._calls.brief(
          user.id,
          params.get('follows') ?? undefined,
          brief.coach.key,
        );
      } catch (error) {
        // The history is a bonus: without it the call still starts.
        this._logger.warn(`brief failed: ${String(error)}`);
      }
    }

    this._wss.handleUpgrade(request, socket, head, (ws) => {
      if (user === undefined) {
        ws.close(UNAUTHORIZED, 'Entre de novo para ligar.');
        return;
      }
      if (!available) {
        ws.close(
          UNAVAILABLE,
          'A ligação ainda não está disponível neste servidor.',
        );
        return;
      }
      this._call(ws, user, brief);
    });
  }

  private _call(ws: WebSocket, user: AuthUser, brief: CallBrief): void {
    const started = Date.now();
    const log = (line: string) => this._logger.log(`[${user.id}] ${line}`);
    log('call started');
    const session = new VoiceSession(
      user,
      {
        sendJson: (message) =>
          ws.readyState === WebSocket.OPEN && ws.send(JSON.stringify(message)),
        sendAudio: (pcm) => ws.readyState === WebSocket.OPEN && ws.send(pcm),
        close: (code, reason) => ws.close(code, reason),
      },
      this._vendor,
      this._model,
      log,
      undefined,
      {
        memory: brief.memory,
        followUp: brief.follows !== undefined,
        coach: brief.coach,
      },
    );

    ws.on('message', (data, binary) => {
      if (binary) {
        session.hear(bytesOf(data));
        return;
      }
      try {
        session.command(JSON.parse(bytesOf(data).toString('utf8')));
      } catch {
        // Not JSON: nothing the app sends, ignored.
      }
    });
    ws.on('close', () => {
      session.hangUp();
      const r = session.report;
      // Counts and cost only: never a word or a second of audio.
      this._analytics.capture(user.id, 'voice_call', {
        seconds: Math.round((Date.now() - started) / 1000),
        turns: r.turns,
        heard_s: Math.round(r.heardS),
        spoken_chars: r.spokenChars,
        usd: r.usd,
        follow_up: brief.follows !== undefined,
        coach: brief.coach.key,
      });
      this._calls
        .record(user.id, brief, {
          startedAt: new Date(started),
          durationMs: Date.now() - started,
          usd: r.usd,
          turns: r.turns,
          conversation: session.conversation,
          takes: session.takes,
        })
        .then((row) => row && log(`call kept: ${row.id}`))
        .catch((error: unknown) => log(`call not kept: ${String(error)}`));
    });
    ws.on('error', (error) => log(`socket error: ${error.message}`));
  }

  private get _origins(): string[] {
    return [
      this._config.get<string>('BETTER_AUTH_URL'),
      ...(this._config.get<string>('TRUSTED_ORIGINS') ?? '').split(','),
    ]
      .map((it) => (it ?? '').trim().replace(/\/$/, ''))
      .filter((it) => it !== '');
  }
}
