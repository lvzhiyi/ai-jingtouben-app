import { Body, Controller, Logger, Post, Res } from '@nestjs/common';
import type { Response } from 'express';
import { pipeSse } from '../common/sse-response';
import { LlmService } from '../llm/llm.service';
import { DrawPropsRequestDto } from './props.dto';

/**
 * 道具绘图接口：模型用受限的绘图 JSON 画简单道具，流式返回，协议见 `pipeSse`。
 * 只做转发：不解析、不校验、不缓存，校验和缓存都在客户端。日志不打印道具名。
 */
@Controller('props')
export class PropsController {
  private readonly logger = new Logger(PropsController.name);

  constructor(private readonly llm: LlmService) {}

  @Post('draw')
  draw(@Body() body: DrawPropsRequestDto, @Res() res: Response): Promise<void> {
    return pipeSse(res, this.logger, '道具绘图', (signal) => this.llm.streamPropDrawings(body.names, signal));
  }
}
