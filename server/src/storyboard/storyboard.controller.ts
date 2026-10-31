import { Body, Controller, Logger, Post, Res } from '@nestjs/common';
import type { Response } from 'express';
import { LlmService, UpstreamError } from './llm.service';
import { StoryboardRequestDto } from './storyboard.dto';

/**
 * 流式分镜接口。
 *
 * 协议（SSE）：
 * - `event: delta`，`data: {"text": "..."}`：模型文本增量，原样转发，不在服务端解析镜头
 * - `event: done`，`data: {}`：正常结束
 * - `event: error`，`data: {"code": "upstream_error" | "internal_error"}`：生成失败
 * - `: ping`：每 15 秒一次心跳，防止代理断开空闲连接
 */
@Controller('storyboard')
export class StoryboardController {
  private readonly logger = new Logger(StoryboardController.name);

  constructor(private readonly llm: LlmService) {}

  /** 用 POST 而不是 GET：故事可能上千字，放不进查询串；EventSource 只支持 GET，所以客户端自己解析 SSE。 */
  @Post('stream')
  async stream(@Body() body: StoryboardRequestDto, @Res() res: Response): Promise<void> {
    res.status(200);
    res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
    res.setHeader('Cache-Control', 'no-cache, no-transform');
    res.setHeader('Connection', 'keep-alive');
    // 关闭 Nginx 缓冲，否则增量会被攒成一大块，首字延迟失去意义
    res.setHeader('X-Accel-Buffering', 'no');
    res.flushHeaders();

    const abort = new AbortController();
    // 客户端断开（取消或改故事）时中止上游请求，不再为没人看的输出付费
    res.on('close', () => {
      if (!res.writableFinished) abort.abort();
    });
    const send = (event: string, data: unknown): void => {
      res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
    };
    const heartbeat = setInterval(() => res.write(': ping\n\n'), 15_000);

    try {
      const input = { story: body.story, characters: body.characters ?? [] };
      for await (const text of this.llm.streamStoryboard(input, abort.signal)) {
        send('delta', { text });
      }
      send('done', {});
    } catch (error) {
      if (!abort.signal.aborted) {
        const code = error instanceof UpstreamError ? 'upstream_error' : 'internal_error';
        this.logger.warn(`分镜生成失败：${code}`);
        send('error', { code });
      }
    } finally {
      clearInterval(heartbeat);
      res.end();
    }
  }
}
