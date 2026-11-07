import { buildDrawMessages, PROP_ANCHORS, PROP_FILLS } from './draw.prompt';

describe('buildDrawMessages', () => {
  it('系统提示列出全部图形、摆放位置和填充档位，要求只输出 JSON', () => {
    const [system] = buildDrawMessages(['猫']);
    expect(system.role).toBe('system');
    for (const shape of ['line', 'polyline', 'polygon', 'circle', 'ellipse', 'arc']) {
      expect(system.content).toContain(`"t":"${shape}"`);
    }
    for (const anchor of PROP_ANCHORS) expect(system.content).toContain(`"${anchor}"`);
    for (const fill of PROP_FILLS) expect(system.content).toContain(`"${fill}"`);
    expect(system.content).toContain('grip');
    expect(system.content).toContain('只输出 JSON');
  });

  it('用户消息只包含道具名', () => {
    const [, user] = buildDrawMessages(['猫', '咖啡杯']);
    expect(user).toEqual({ role: 'user', content: '请画这些道具：猫、咖啡杯' });
  });
});
