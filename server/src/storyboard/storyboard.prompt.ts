/** 景别枚举，必须与客户端 ShotSize.label 保持一致。 */
export const SHOT_SIZES = ['大远景', '远景', '全景', '中景', '近景', '特写', '大特写'] as const;

export interface StoryboardInput {
  story: string;
  characters: Array<{ name: string; appearance?: string; outfit?: string }>;
}

export interface ChatMessage {
  role: 'system' | 'user';
  content: string;
}

const SYSTEM_PROMPT = [
  '你是 AI 短剧分镜师，帮新手把故事拆成可以直接拿去生成视频的镜头。',
  '只输出 JSON Lines：每行一个镜头对象，行与行之间只有换行；不要输出 Markdown、代码块、编号或任何解释。',
  '每个对象包含以下字段：',
  `- shotSize：景别，只能是 ${SHOT_SIZES.join('、')} 之一`,
  '- scene：画面描述，写清人物动作、环境和光线，一句话，60 字以内',
  '- dialogue：台词，没有台词输出空字符串',
  '- reason：为什么这样拍，面向新手解释镜头语言，30 字以内',
  '- characters：出场角色名数组，名称必须与角色列表一致',
  '镜头数量 6 到 12 个，按剧情顺序输出。',
  // 示例只说明格式；场景和人名刻意与常见故事无关，避免模型把示例里的角色套进用户的故事
  '格式示例（只示范字段写法，人物和情节必须来自用户的故事）：{"shotSize":"全景","scene":"清晨的车站站台，主角拖着行李箱走向检票口","dialogue":"","reason":"先交代时间、地点和人物处境","characters":["主角"]}',
].join('\n');

export function buildStoryboardMessages(input: StoryboardInput): ChatMessage[] {
  const characters =
    input.characters.length > 0
      ? input.characters
          .map((c) => {
            const appearance = c.appearance ? `：${c.appearance}` : '';
            const outfit = c.outfit ? `，穿${c.outfit}` : '';
            return `- ${c.name}${appearance}${outfit}`;
          })
          .join('\n')
      : '（未提供：沿用故事里的称呼，如「我」「她」「初恋」；故事没有称呼时再起名，同一角色前后名称保持一致）';
  return [
    { role: 'system', content: SYSTEM_PROMPT },
    { role: 'user', content: `角色：\n${characters}\n\n故事：\n${input.story}` },
  ];
}
