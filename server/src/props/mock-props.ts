import { setTimeout as sleep } from 'node:timers/promises';

type Point = [number, number];

/** 模拟绘图：猫和行李箱来自真实模型的输出（2026-11-07 可行性实验），其余道具画成一个带提手的盒子。 */
const KNOWN: Record<string, object> = {
  猫: {
    anchor: 'ground',
    size: 0.28,
    shapes: [
      { t: 'polyline', pts: [[0.68, 0.87], [0.85, 0.81], [0.94, 0.66], [0.94, 0.47], [0.87, 0.4]] as Point[] },
      { t: 'ellipse', x: 0.49, y: 0.72, w: 0.52, h: 0.54, fill: 'light' },
      {
        t: 'polygon',
        pts: [
          [0.23, 0.29], [0.19, 0.02], [0.39, 0.14], [0.6, 0.14], [0.79, 0.02],
          [0.75, 0.3], [0.7, 0.45], [0.5, 0.53], [0.29, 0.45],
        ] as Point[],
        fill: 'light',
      },
      { t: 'line', pts: [[0.35, 0.29], [0.4, 0.29]] },
      { t: 'line', pts: [[0.6, 0.29], [0.65, 0.29]] },
      { t: 'polygon', pts: [[0.46, 0.36], [0.54, 0.36], [0.5, 0.4]], fill: 'dark' },
      { t: 'line', pts: [[0.34, 0.38], [0.07, 0.34]] },
      { t: 'line', pts: [[0.66, 0.38], [0.93, 0.34]] },
      {
        t: 'polyline',
        pts: [
          [0.4, 0.64], [0.39, 0.95], [0.32, 1.0], [0.49, 1.0], [0.5, 0.74],
          [0.51, 1.0], [0.68, 1.0], [0.61, 0.95], [0.6, 0.64],
        ] as Point[],
      },
    ],
  },
  行李箱: {
    anchor: 'ground',
    size: 0.48,
    shapes: [
      {
        t: 'polygon',
        pts: [[0.35, 0.27], [0.35, 0.03], [0.65, 0.03], [0.65, 0.27], [0.6, 0.27], [0.6, 0.09], [0.4, 0.09], [0.4, 0.27]],
        fill: 'none',
      },
      { t: 'circle', x: 0.26, y: 0.95, r: 0.05, fill: 'dark' },
      { t: 'circle', x: 0.74, y: 0.95, r: 0.05, fill: 'dark' },
      {
        t: 'polygon',
        pts: [[0.17, 0.27], [0.83, 0.27], [0.9, 0.34], [0.9, 0.89], [0.83, 0.94], [0.17, 0.94], [0.1, 0.89], [0.1, 0.34]],
        fill: 'light',
      },
      { t: 'line', pts: [[0.29, 0.4], [0.29, 0.81]] },
      { t: 'line', pts: [[0.45, 0.4], [0.45, 0.81]] },
      { t: 'line', pts: [[0.61, 0.4], [0.61, 0.81]] },
    ],
  },
};

const BOX = {
  anchor: 'hand',
  size: 0.2,
  grip: [0.5, 0.08],
  shapes: [
    { t: 'arc', x: 0.5, y: 0.25, r: 0.15, start: 180, end: 360 },
    { t: 'polygon', pts: [[0.15, 0.25], [0.85, 0.25], [0.85, 0.95], [0.15, 0.95]], fill: 'accent' },
    { t: 'line', pts: [[0.15, 0.5], [0.85, 0.5]] },
  ],
};

/** 没有配置模型 Key 时的模拟输出：等一会儿再按小块输出，覆盖客户端的拼接逻辑。 */
export async function* mockPropDrawings(names: string[], signal: AbortSignal): AsyncGenerator<string> {
  const items = names.map((name) => ({ name, ...(KNOWN[name] ?? BOX) }));
  const text = JSON.stringify({ items });
  await sleep(800, undefined, { signal });
  for (let i = 0; i < text.length; i += 40) {
    yield text.slice(i, i + 40);
    await sleep(10, undefined, { signal });
  }
}
