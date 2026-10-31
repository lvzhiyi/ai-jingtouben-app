import { Module } from '@nestjs/common';
import { LlmService } from './llm.service';
import { StoryboardController } from './storyboard.controller';

@Module({
  controllers: [StoryboardController],
  providers: [LlmService],
})
export class StoryboardModule {}
