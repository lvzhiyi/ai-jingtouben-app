/**
 * 增量解析 SSE 文本，只关心 data 字段。
 *
 * 网络包的边界和事件边界无关：一行可能被拆成两个包，`\r\n` 也可能被拆开，所以要缓冲未完成的行。
 */
export class SseDataParser {
  private pending = '';
  private data: string[] = [];

  /** 追加一段文本，返回这段文本里已经完整的事件的 data（多行 data 用换行拼接）。 */
  push(chunk: string): string[] {
    let text = this.pending + chunk;
    // 末尾的 \r 可能是被拆开的 \r\n，留到下一段再判断，否则会多出一个空行导致事件提前结束
    let carry = '';
    if (text.endsWith('\r')) {
      carry = '\r';
      text = text.slice(0, -1);
    }
    const lines = text.split(/\r\n|\n|\r/);
    this.pending = (lines.pop() ?? '') + carry;

    const events: string[] = [];
    for (const line of lines) {
      if (line === '') {
        if (this.data.length > 0) {
          events.push(this.data.join('\n'));
          this.data = [];
        }
        continue;
      }
      if (line.startsWith('data:')) {
        const value = line.slice(5);
        this.data.push(value.startsWith(' ') ? value.slice(1) : value);
      }
      // event、id 和以冒号开头的注释在上游响应里用不到，直接忽略
    }
    return events;
  }
}

/** 逐个产出 SSE 响应体里的 data。调用方提前退出循环时会取消读取，从而关闭上游连接。 */
export async function* readSseData(body: ReadableStream<Uint8Array>): AsyncGenerator<string> {
  const reader = body.getReader();
  // stream: true 让 TextDecoder 保留被拆开的多字节字符（中文 UTF-8 占 3 字节）
  const decoder = new TextDecoder();
  const parser = new SseDataParser();
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      yield* parser.push(decoder.decode(value, { stream: true }));
    }
    yield* parser.push(decoder.decode());
  } finally {
    await reader.cancel().catch(() => undefined);
  }
}
