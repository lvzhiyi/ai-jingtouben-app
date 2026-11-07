import { Body, Controller, Logger, Post, Res } from '@nestjs/common';
import type { Response } from 'express';
import { pipeSse } from '../common/sse-response';
import { LlmService } from '../llm/llm.service';
import { StoryboardRequestDto } from './storyboard.dto';

/** 流式分镜接口。协议见 `pipeSse`。 */
@Controller('storyboard')
export class StoryboardController {
  private readonly logger = new Logger(StoryboardController.name);

  constructor(private readonly llm: LlmService) {}

  /** 用 POST 而不是 GET：故事可能上千字，放不进查询串；EventSource 只支持 GET，所以客户端自己解析 SSE。 */
  @Post('stream')
  stream(@Body() body: StoryboardRequestDto, @Res() res: Response): Promise<void> {
    const input = { story: body.story, characters: body.characters ?? [] };
    return pipeSse(res, this.logger, '分镜生成', (signal) => this.llm.streamStoryboard(input, signal));
  }
}
