import { setTimeout as sleep } from 'node:timers/promises';

const MOCK_SHOTS = [
  {
    shotSize: '全景',
    scene: '雨夜的老街，霓虹灯在积水里晃动，林夏撑着伞站在公交站台',
    dialogue: '',
    reason: '先用全景交代时间、地点和人物处境',
    characters: ['林夏'],
  },
  {
    shotSize: '中景',
    scene: '林夏低头看手机，屏幕的光照亮她的脸',
    dialogue: '',
    reason: '中景把注意力收到人物的动作上',
    characters: ['林夏'],
  },
  {
    shotSize: '特写',
    scene: '手机屏幕上弹出一条消息：我到了，你在哪？',
    dialogue: '',
    reason: '特写让观众和角色同时看到关键信息',
    characters: [],
  },
  {
    shotSize: '近景',
    scene: '林夏抬头，雨水顺着伞沿滴落，表情从惊讶变成犹豫',
    dialogue: '……是你吗？',
    reason: '近景放大情绪变化，是短剧最常用的情绪镜头',
    characters: ['林夏'],
  },
  {
    shotSize: '远景',
    scene: '街对面，一个撑黑伞的男人停下脚步，看不清脸',
    dialogue: '',
    reason: '远景保持距离感，制造悬念',
    characters: ['陈默'],
  },
  {
    shotSize: '中景',
    scene: '两人隔着马路对视，一辆车驶过挡住视线',
    dialogue: '',
    reason: '用前景遮挡做转场，给下一集留钩子',
    characters: ['林夏', '陈默'],
  },
];

/**
 * 没有配置模型 Key 时的模拟输出：先等一段首字延迟，再按随机长度切块输出，模拟真实模型的流式增量。
 * 切块会把一行 JSON 拆到多个增量里，正好覆盖客户端的拼行逻辑。
 */
export async function* mockStoryboard(signal: AbortSignal): AsyncGenerator<string> {
  const lines = MOCK_SHOTS.map((shot) => JSON.stringify(shot));
  // 故意给第 3 行加一个行尾逗号，演示客户端的修复兜底
  lines[2] = `${lines[2]},`;
  const text = `${lines.join('\n')}\n`;

  await sleep(600, undefined, { signal });
  for (let i = 0; i < text.length; ) {
    const size = 2 + Math.floor(Math.random() * 6);
    yield text.slice(i, i + size);
    i += size;
    await sleep(25, undefined, { signal });
  }
}
