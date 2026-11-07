import { buildStoryboardMessages, CAMERA_MOVES, SHOT_SIZES } from './storyboard.prompt';

describe('buildStoryboardMessages', () => {
  it('系统提示列出全部景别并要求 JSON Lines', () => {
    const [system] = buildStoryboardMessages({ story: '雨夜重逢', characters: [] });
    expect(system.role).toBe('system');
    for (const size of SHOT_SIZES) expect(system.content).toContain(size);
    expect(system.content).toContain('JSON Lines');
  });

  it('系统提示列出全部运镜和时长字段', () => {
    const [system] = buildStoryboardMessages({ story: '雨夜重逢', characters: [] });
    for (const move of CAMERA_MOVES) expect(system.content).toContain(move);
    expect(system.content).toContain('cameraMove');
    expect(system.content).toContain('durationSec');
    expect(system.content).toContain('props');
    expect(system.content).toContain('owner');
  });

  it('有角色卡时逐个列出外貌和服装，缺的字段不出现', () => {
    const [, user] = buildStoryboardMessages({
      story: '雨夜重逢',
      characters: [{ name: '林夏', appearance: '齐肩短发', outfit: '米色风衣' }, { name: '陈默' }],
    });
    expect(user.content).toBe('角色：\n- 林夏：齐肩短发，穿米色风衣\n- 陈默\n\n故事：\n雨夜重逢');
  });

  it('没有角色卡时要求沿用故事里的称呼', () => {
    const [, user] = buildStoryboardMessages({ story: '雨夜重逢', characters: [] });
    expect(user.content).toContain('沿用故事里的称呼');
  });
});
