import { Module } from '@nestjs/common';
import { LlmModule } from '../llm/llm.module';
import { PropsController } from './props.controller';

@Module({
  imports: [LlmModule],
  controllers: [PropsController],
})
export class PropsModule {}
