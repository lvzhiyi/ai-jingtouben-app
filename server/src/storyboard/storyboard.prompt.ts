/** 景别枚举，必须与客户端 ShotSize.label 保持一致。 */
export const SHOT_SIZES = ['大远景', '远景', '全景', '中景', '近景', '特写', '大特写'] as const;

/** 运镜枚举，必须与客户端 CameraMove.label 保持一致。 */
export const CAMERA_MOVES = ['固定', '推', '拉', '摇', '移', '跟', '升降'] as const;

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
  `- cameraMove：运镜，只能是 ${CAMERA_MOVES.join('、')} 之一，镜头不动时写「固定」`,
  '- durationSec：镜头时长（秒），1 到 10 之间的数字；有台词时要够把台词念完',
  '- props：画面里需要出现的道具数组，最多 3 个，没有道具输出空数组；每项 {"name": 道具名, "owner": 拿着或在身边的角色名，放在场景里写 null}；道具名用 2 到 6 个字的常见叫法，如「伞」「行李箱」「咖啡杯」，不要形容词',
  '镜头数量 6 到 12 个，按剧情顺序输出。',
  // 示例只说明格式；场景和人名刻意与常见故事无关，避免模型把示例里的角色套进用户的故事
  '格式示例（只示范字段写法，人物和情节必须来自用户的故事）：{"shotSize":"全景","scene":"清晨的车站站台，主角拖着行李箱走向检票口","dialogue":"","reason":"先交代时间、地点和人物处境","characters":["主角"],"cameraMove":"跟","durationSec":3,"props":[{"name":"行李箱","owner":"主角"}]}',
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
