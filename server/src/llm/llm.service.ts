import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { readSseData } from '../common/sse';
import { buildDrawMessages } from '../props/draw.prompt';
import { mockPropDrawings } from '../props/mock-props';
import { mockStoryboard } from '../storyboard/mock-storyboard';
import { buildStoryboardMessages, ChatMessage, StoryboardInput } from '../storyboard/storyboard.prompt';

export class UpstreamError extends Error {
  constructor(readonly status: number) {
    super(`upstream responded ${status}`);
  }
}

/**
 * 调用 OpenAI 兼容的 Chat Completions 流式接口（DeepSeek、通义千问、豆包等都兼容），产出文本增量。
 *
 * 不绑定某一家 SDK：换模型只改环境变量。没有配置 Key 时走模拟数据。
 * 分镜和道具绘图共用 `streamChat`，各自只负责拼消息和提供模拟数据。
 */
@Injectable()
export class LlmService {
  private readonly logger = new Logger(LlmService.name);

  constructor(private readonly config: ConfigService) {}

  streamStoryboard(input: StoryboardInput, signal: AbortSignal): AsyncGenerator<string> {
    if (!this.hasKey) return mockStoryboard(signal);
    return this.streamChat(buildStoryboardMessages(input), { temperature: 0.7 }, signal);
  }

  /** 道具绘图：输出 `{"items":[…]}` 文本。温度低一些，格式更稳。 */
  streamPropDrawings(names: string[], signal: AbortSignal): AsyncGenerator<string> {
    if (!this.hasKey) return mockPropDrawings(names, signal);
    return this.streamChat(buildDrawMessages(names), { temperature: 0.4 }, signal);
  }

  private get hasKey(): boolean {
    return Boolean(this.config.get<string>('LLM_API_KEY'));
  }

  private async *streamChat(
    messages: ChatMessage[],
    options: { temperature: number },
    signal: AbortSignal,
  ): AsyncGenerator<string> {
    const apiKey = this.config.get<string>('LLM_API_KEY');
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
      // 必须流式：有的中转网关对非流式请求 60 秒就超时，道具绘图一批要一两分钟
      body: JSON.stringify({ model, stream: true, temperature: options.temperature, messages }),
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
