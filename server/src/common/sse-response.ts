import { Logger } from '@nestjs/common';
import type { Response } from 'express';
import { UpstreamError } from '../llm/llm.service';

/**
 * 把模型的文本增量按统一的 SSE 协议写给客户端：
 * - `event: delta`，`data: {"text": "..."}`：模型文本增量，原样转发，服务端不解析
 * - `event: done`，`data: {}`：正常结束
 * - `event: error`，`data: {"code": "upstream_error" | "internal_error"}`：生成失败，不带原文
 * - `: ping`：每 15 秒一次心跳，防止代理断开空闲连接
 *
 * 客户端断开（取消、离开页面）时中止上游请求，不再为没人看的输出付费。
 */
export async function pipeSse(
  res: Response,
  logger: Logger,
  label: string,
  produce: (signal: AbortSignal) => AsyncGenerator<string>,
): Promise<void> {
  res.status(200);
  res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
  res.setHeader('Cache-Control', 'no-cache, no-transform');
  res.setHeader('Connection', 'keep-alive');
  // 关闭 Nginx 缓冲，否则增量会被攒成一大块，首字延迟失去意义
  res.setHeader('X-Accel-Buffering', 'no');
  res.flushHeaders();

  const abort = new AbortController();
  res.on('close', () => {
    if (!res.writableFinished) abort.abort();
  });
  const send = (event: string, data: unknown): void => {
    res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
  };
  const heartbeat = setInterval(() => res.write(': ping\n\n'), 15_000);

  try {
    for await (const text of produce(abort.signal)) {
      send('delta', { text });
    }
    send('done', {});
  } catch (error) {
    if (!abort.signal.aborted) {
      const code = error instanceof UpstreamError ? 'upstream_error' : 'internal_error';
      logger.warn(`${label}失败：${code}`);
      send('error', { code });
    }
  } finally {
    clearInterval(heartbeat);
    res.end();
  }
}
