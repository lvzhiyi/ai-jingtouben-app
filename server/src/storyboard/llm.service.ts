import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { readSseData } from '../common/sse';
import { mockStoryboard } from './mock-storyboard';
import { buildStoryboardMessages, StoryboardInput } from './storyboard.prompt';

export class UpstreamError extends Error {
  constructor(readonly status: number) {
    super(`upstream responded ${status}`);
  }
}

/**
 * 调用 OpenAI 兼容的 Chat Completions 流式接口（DeepSeek、通义千问、豆包等都兼容），产出文本增量。
 *
 * 不绑定某一家 SDK：换模型只改环境变量。没有配置 Key 时走模拟数据。
 */
@Injectable()
export class LlmService {
  private readonly logger = new Logger(LlmService.name);

  constructor(private readonly config: ConfigService) {}

  async *streamStoryboard(input: StoryboardInput, signal: AbortSignal): AsyncGenerator<string> {
    const apiKey = this.config.get<string>('LLM_API_KEY');
    if (!apiKey) {
      yield* mockStoryboard(signal);
      return;
    }

    const baseUrl = (this.config.get<string>('LLM_BASE_URL') ?? 'https://api.deepseek.com/v1').replace(
      /\/+$/,
      '',
    );
    const model = this.config.get<string>('LLM_MODEL') ?? 'deepseek-chat';
    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      signal,
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        Accept: 'text/event-stream',
      },
      body: JSON.stringify({
        model,
        stream: true,
        temperature: 0.7,
        messages: buildStoryboardMessages(input),
      }),
    });
    if (!response.ok || !response.body) {
      // 不记录响应体：可能回显用户的故事内容
      this.logger.warn(`上游模型返回 ${response.status}`);
      throw new UpstreamError(response.status);
    }

    for await (const data of readSseData(response.body)) {
      if (data === '[DONE]') return;
      const text = extractDelta(data);
      if (text) yield text;
    }
  }
}

function extractDelta(data: string): string {
  try {
    const json = JSON.parse(data) as { choices?: Array<{ delta?: { content?: unknown } }> };
    const content = json.choices?.[0]?.delta?.content;
    return typeof content === 'string' ? content : '';
  } catch {
    return '';
  }
}
