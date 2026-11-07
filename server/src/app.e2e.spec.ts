import { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import { AppModule } from './app.module';
import { configureApp } from './app.setup';
import { LlmService, UpstreamError } from './llm/llm.service';
import templates from './templates/prompt-templates.json';

/**
 * 端到端：起一个真实 HTTP 服务（和 main.ts 同一套配置），用 fetch 请求。
 * 模型调用替换成假的 LlmService，测试不联网、不花钱。
 */
describe('转发服务', () => {
  let app: NestExpressApplication;
  let baseUrl: string;
  let llm: jest.Mocked<Pick<LlmService, 'streamStoryboard' | 'streamPropDrawings'>>;

  const story = '雨夜，林夏在老街等一个不会来的人。';
  let deviceSeq = 0;
  /** 每个用例用不同的设备 ID，互不占用限流额度。 */
  const nextDevice = () => `00000000-0000-4000-8000-${String(++deviceSeq).padStart(12, '0')}`;

  const postStream = (body: unknown, deviceId = nextDevice()) =>
    fetch(`${baseUrl}/storyboard/stream`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-device-id': deviceId },
      body: JSON.stringify(body),
    });

  beforeAll(async () => {
    llm = { streamStoryboard: jest.fn(), streamPropDrawings: jest.fn() };
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(LlmService)
      .useValue(llm)
      .compile();
    app = moduleRef.createNestApplication<NestExpressApplication>({ logger: false });
    configureApp(app);
    await app.listen(0, '127.0.0.1');
    baseUrl = await app.getUrl();
  });

  afterAll(() => app.close());

  it('把模型增量原样转成 SSE delta 事件，结束时发 done', async () => {
    llm.streamStoryboard.mockImplementation(async function* () {
      yield '{"scene":"雨夜';
      yield '老街"}\n';
    });

    const response = await postStream({ story, characters: [{ name: '林夏', outfit: '米色风衣' }] });

    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toContain('text/event-stream');
    expect(response.headers.get('x-accel-buffering')).toBe('no');
    expect(await response.text()).toBe(
      'event: delta\ndata: {"text":"{\\"scene\\":\\"雨夜"}\n\n' +
        'event: delta\ndata: {"text":"老街\\"}\\n"}\n\n' +
        'event: done\ndata: {}\n\n',
    );
    expect(llm.streamStoryboard).toHaveBeenCalledWith(
      { story, characters: [{ name: '林夏', outfit: '米色风衣' }] },
      expect.any(AbortSignal),
    );
  });

  it('上游出错时发 error 事件，只带错误码不带原文', async () => {
    llm.streamStoryboard.mockImplementation(async function* () {
      yield '{"scene":';
      throw new UpstreamError(502);
    });
    const body = await (await postStream({ story })).text();
    expect(body).toContain('event: error\ndata: {"code":"upstream_error"}');

    llm.streamStoryboard.mockImplementation(async function* () {
      throw new Error('意外错误');
    });
    expect(await (await postStream({ story })).text()).toContain('{"code":"internal_error"}');
  });

  it('客户端断开时中止上游请求', async () => {
    let signal: AbortSignal | undefined;
    llm.streamStoryboard.mockImplementation(async function* (_input, abortSignal) {
      signal = abortSignal;
      yield '第一段';
      await new Promise((resolve) => abortSignal.addEventListener('abort', resolve));
    });

    const controller = new AbortController();
    const response = await fetch(`${baseUrl}/storyboard/stream`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-device-id': nextDevice() },
      body: JSON.stringify({ story }),
      signal: controller.signal,
    });
    const reader = response.body!.getReader();
    await reader.read();
    controller.abort();

    // 服务端通过 res 的 close 事件感知断开，稍等片刻
    for (let i = 0; i < 50 && !signal?.aborted; i++) await new Promise((r) => setTimeout(r, 10));
    expect(signal?.aborted).toBe(true);
  });

  it('参数校验：故事太短、角色太多、多余字段都会被拒绝或剔除', async () => {
    expect((await postStream({ story: '太短' })).status).toBe(400);
    const tooMany = Array.from({ length: 11 }, (_, i) => ({ name: `角色${i}` }));
    expect((await postStream({ story, characters: tooMany })).status).toBe(400);
    expect((await postStream({ story, characters: [{ name: '' }] })).status).toBe(400);

    llm.streamStoryboard.mockImplementation(async function* () {});
    await (await postStream({ story, extra: 'x' })).text();
    expect(llm.streamStoryboard).toHaveBeenLastCalledWith({ story, characters: [] }, expect.any(AbortSignal));
  });

  const postDraw = (body: unknown, deviceId = nextDevice()) =>
    fetch(`${baseUrl}/props/draw`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-device-id': deviceId },
      body: JSON.stringify(body),
    });

  it('道具绘图：把模型输出转成 SSE，出错时只发错误码', async () => {
    llm.streamPropDrawings.mockImplementation(async function* () {
      yield '{"items":';
      yield '[]}';
    });
    const response = await postDraw({ names: ['猫', '吉他'] });
    expect(response.status).toBe(200);
    expect(await response.text()).toBe(
      'event: delta\ndata: {"text":"{\\"items\\":"}\n\n' +
        'event: delta\ndata: {"text":"[]}"}\n\n' +
        'event: done\ndata: {}\n\n',
    );
    expect(llm.streamPropDrawings).toHaveBeenCalledWith(['猫', '吉他'], expect.any(AbortSignal));

    llm.streamPropDrawings.mockImplementation(async function* () {
      throw new UpstreamError(500);
    });
    expect(await (await postDraw({ names: ['猫'] })).text()).toContain('{"code":"upstream_error"}');
  });

  it('道具绘图参数校验：0 个、超过 5 个、空名字、超过 10 个字都拒绝', async () => {
    llm.streamPropDrawings.mockClear();
    expect((await postDraw({ names: [] })).status).toBe(400);
    expect((await postDraw({ names: ['一', '二', '三', '四', '五', '六'] })).status).toBe(400);
    expect((await postDraw({ names: [''] })).status).toBe(400);
    expect((await postDraw({ names: ['一二三四五六七八九十一'] })).status).toBe(400);
    expect((await postDraw({ names: '猫' })).status).toBe(400);
    expect(llm.streamPropDrawings).not.toHaveBeenCalled();
  });

  it('同一设备超过每分钟额度返回 429，换设备不受影响', async () => {
    llm.streamStoryboard.mockImplementation(async function* () {});
    const device = nextDevice();
    // setup-env 把额度设成每分钟 3 次
    for (let i = 0; i < 3; i++) {
      const response = await postStream({ story }, device);
      expect(response.status).toBe(200);
      await response.text();
    }
    expect((await postStream({ story }, device)).status).toBe(429);
    expect((await postStream({ story })).status).toBe(200);
  });

  it('设备 ID 缺失或格式不对时按 IP 限流', async () => {
    llm.streamStoryboard.mockImplementation(async function* () {});
    const statuses: number[] = [];
    for (let i = 0; i < 4; i++) {
      const response = await postStream({ story }, `not-a-uuid-${i}`);
      statuses.push(response.status);
      await response.text();
    }
    // 4 个不同的伪造 ID 共用同一个 IP 额度
    expect(statuses).toEqual([200, 200, 200, 429]);
  });

  it('下发提示词模板，带缓存头，不受限流影响', async () => {
    for (let i = 0; i < 5; i++) {
      const response = await fetch(`${baseUrl}/templates`);
      expect(response.status).toBe(200);
      expect(response.headers.get('cache-control')).toBe('public, max-age=300');
      expect(await response.json()).toEqual(templates);
    }
  });

  it('健康检查报告运行模式', async () => {
    const response = await fetch(`${baseUrl}/health`);
    // setup-env 清空了 Key，所以是模拟模式
    expect(await response.json()).toEqual({ ok: true, mode: 'mock' });
  });
});
