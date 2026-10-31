import { SseDataParser } from './sse';

describe('SseDataParser', () => {
  it('一个事件被拆进多个包时拼接后再交出', () => {
    const parser = new SseDataParser();
    expect(parser.push('data: {"a"')).toEqual([]);
    expect(parser.push(':1}\n')).toEqual([]);
    expect(parser.push('\n')).toEqual(['{"a":1}']);
  });

  it('\\r\\n 被拆开时不会让事件提前结束', () => {
    const parser = new SseDataParser();
    expect(parser.push('data: first\r')).toEqual([]);
    expect(parser.push('\ndata: second\r\n\r\n')).toEqual(['first\nsecond']);
  });

  it('忽略注释和其他字段，[DONE] 原样交出', () => {
    const parser = new SseDataParser();
    expect(parser.push(': ping\n\nevent: x\nid: 1\ndata: [DONE]\n\n')).toEqual(['[DONE]']);
  });
});
