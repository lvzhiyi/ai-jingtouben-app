import type { ChatMessage } from '../storyboard/storyboard.prompt';

/** 道具摆放位置，必须与客户端 `PropAnchor` 一致。 */
export const PROP_ANCHORS = ['hand', 'ground', 'table', 'wall'] as const;

/** 填充档位，客户端映射到预演配色，必须与客户端 `PropFill` 一致。 */
export const PROP_FILLS = ['none', 'light', 'mid', 'dark', 'accent'] as const;

const SYSTEM_PROMPT = [
  '你是分镜草图的道具画师。用下面受限的 JSON 绘图格式画简单、易认的简笔道具（正侧面或正面轮廓，像铅笔分镜里的图标）。',
  '坐标：每个道具画在 0–1 的方框里，x 向右、y 向下；道具撑满方框，放在地上的东西底边贴 y=1。',
  '图形（按从后到前的顺序）：',
  '- {"t":"line","pts":[[x,y],[x,y]]}',
  '- {"t":"polyline","pts":[[x,y],...]}：不闭合，2–16 个点',
  '- {"t":"polygon","pts":[[x,y],...],"fill":F}：闭合，3–12 个点',
  '- {"t":"circle","x":..,"y":..,"r":..,"fill":F}',
  '- {"t":"ellipse","x":..,"y":..,"w":..,"h":..,"fill":F}：x、y 为中心',
  '- {"t":"arc","x":..,"y":..,"r":..,"start":度,"end":度}：0 度指向右，顺时针',
  `F 只能是 ${PROP_FILLS.map((f) => `"${f}"`).join(' | ')}。`,
  '每个道具最多 30 个图形，坐标在 0 到 1 之间，保留两位小数。',
  '每个道具还要给：',
  `- "anchor"：放在哪，${PROP_ANCHORS.map((a) => `"${a}"`).join(' | ')}（拿在手里、放在地上、放在桌上、挂在墙上）`,
  '- "size"：道具高度相对人身高（人 = 1）的比例，0.03 到 1.5',
  '- "grip"：只有 anchor 为 "hand" 时给，手握住的位置 [x,y]（方框坐标），如吉他的琴颈、伞柄、包的提手',
  '道具名按用户给的原样写回 "name"。',
  '只输出 JSON，不要 Markdown 或解释：{"items":[{"name":"…","anchor":"…","size":…,"grip":[x,y],"shapes":[…]}]}',
].join('\n');

export function buildDrawMessages(names: string[]): ChatMessage[] {
  return [
    { role: 'system', content: SYSTEM_PROMPT },
    { role: 'user', content: `请画这些道具：${names.join('、')}` },
  ];
}
