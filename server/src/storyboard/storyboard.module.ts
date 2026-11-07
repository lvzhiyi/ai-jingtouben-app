import { Module } from '@nestjs/common';
import { LlmModule } from '../llm/llm.module';
import { StoryboardController } from './storyboard.controller';

@Module({
  imports: [LlmModule],
  controllers: [StoryboardController],
})
export class StoryboardModule {}
