import { ConfigService } from '@nestjs/config';
import { LlmService, UpstreamError } from './llm.service';

const input = { story: '雨夜，林夏在老街等一个不会来的人。', characters: [] };

/** 构造一个按块返回的上游 SSE 响应体。 */
function sseBody(chunks: string[]): ReadableStream<Uint8Array> {
  const encoder = new TextEncoder();
  return new ReadableStream({
    start(controller) {
      for (const chunk of chunks) controller.enqueue(encoder.encode(chunk));
      controller.close();
    },
  });
}

function service(env: Record<string, string | undefined>): LlmService {
  return new LlmService(new ConfigService(env));
}

async function collect(stream: AsyncGenerator<string>): Promise<string[]> {
  const result: string[] = [];
  for await (const text of stream) result.push(text);
  return result;
}

describe('LlmService', () => {
  const fetchMock = jest.fn<Promise<Response>, Parameters<typeof fetch>>();

  beforeEach(() => {
    fetchMock.mockReset();
    global.fetch = fetchMock as unknown as typeof fetch;
  });

  it('按 OpenAI 兼容格式请求上游，只交出非空的文本增量，遇到 [DONE] 结束', async () => {
    fetchMock.mockResolvedValue(
      new Response(
        sseBody([
          'data: {"choices":[{"delta":{"role":"assistant"}}]}\n\n',
          'data: {"choices":[{"delta":{"content":"雨夜"}}]}\n\ndata: {"choices":[{"delta":{"cont',
          'ent":"老街"}}]}\n\n',
          'data: not json\n\n',
          'data: [DONE]\n\n',
          'data: {"choices":[{"delta":{"content":"不应出现"}}]}\n\n',
        ]),
      ),
    );

    const llm = service({ LLM_API_KEY: 'sk-test', LLM_BASE_URL: 'https://llm.example.com/v1/', LLM_MODEL: 'm1' });
    expect(await collect(llm.streamStoryboard(input, new AbortController().signal))).toEqual(['雨夜', '老街']);

    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe('https://llm.example.com/v1/chat/completions');
    expect((init?.headers as Record<string, string>).Authorization).toBe('Bearer sk-test');
    const body = JSON.parse(String(init?.body));
    expect(body).toMatchObject({ model: 'm1', stream: true });
    expect(body.messages[1].content).toContain(input.story);
  });

  it('未配置地址和模型时使用默认值', async () => {
    fetchMock.mockResolvedValue(new Response(sseBody(['data: [DONE]\n\n'])));
    await collect(service({ LLM_API_KEY: 'sk-test' }).streamStoryboard(input, new AbortController().signal));

    expect(fetchMock.mock.calls[0][0]).toBe('https://api.deepseek.com/v1/chat/completions');
    expect(JSON.parse(String(fetchMock.mock.calls[0][1]?.body)).model).toBe('deepseek-chat');
  });

  it('上游返回非 2xx 时抛 UpstreamError', async () => {
    fetchMock.mockResolvedValue(new Response('quota exceeded', { status: 429 }));
    const stream = service({ LLM_API_KEY: 'sk-test' }).streamStoryboard(input, new AbortController().signal);

    await expect(collect(stream)).rejects.toEqual(new UpstreamError(429));
  });

  it('没有 Key 时走模拟数据，不请求上游；中止后停止输出', async () => {
    const controller = new AbortController();
    const stream = service({}).streamStoryboard(input, controller.signal);

    const first = await stream.next();
    expect(first.value).toEqual(expect.any(String));
    expect(fetchMock).not.toHaveBeenCalled();

    controller.abort();
    await expect(stream.next()).rejects.toThrow();
  });

  it('道具绘图请求上游时带上道具名，温度更低', async () => {
    fetchMock.mockResolvedValue(
      new Response(sseBody(['data: {"choices":[{"delta":{"content":"{\\"items\\":[]}"}}]}\n\n', 'data: [DONE]\n\n'])),
    );
    const llm = service({ LLM_API_KEY: 'sk-test' });
    expect(await collect(llm.streamPropDrawings(['猫', '吉他'], new AbortController().signal))).toEqual([
      '{"items":[]}',
    ]);

    const body = JSON.parse(String(fetchMock.mock.calls[0][1]?.body));
    expect(body).toMatchObject({ stream: true, temperature: 0.4 });
    expect(body.messages[1].content).toContain('猫、吉他');
  });

  it('道具绘图没有 Key 时走模拟数据，每个道具名都有一项', async () => {
    const text = (await collect(service({}).streamPropDrawings(['行李箱', '花束'], new AbortController().signal))).join(
      '',
    );
    const items = (JSON.parse(text) as { items: Array<{ name: string; shapes: unknown[] }> }).items;
    expect(items.map((item) => item.name)).toEqual(['行李箱', '花束']);
    expect(items.every((item) => item.shapes.length > 0)).toBe(true);
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
