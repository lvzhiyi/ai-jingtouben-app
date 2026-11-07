import { Module } from '@nestjs/common';
import { LlmService } from './llm.service';

/** 上游模型调用，分镜和道具绘图共用。 */
@Module({
  providers: [LlmService],
  exports: [LlmService],
})
export class LlmModule {}
