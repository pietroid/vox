import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AssistantController } from './assistant.controller';
import { AssistantService } from './assistant.service';
import { OpenRouterClient } from './openrouter.client';
import { VoiceGateway } from './voice/voice.gateway';

/** The assistant, through OpenRouter: the chat, and the call. */
@Module({
  imports: [ConfigModule],
  controllers: [AssistantController],
  providers: [AssistantService, OpenRouterClient, VoiceGateway],
})
export class AssistantModule {}
