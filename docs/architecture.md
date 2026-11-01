# 架构说明

一页技术方案：https://claude.ai/artifact/BQADpUgwLR26o34Jbfohns

## 整体

```
Flutter 客户端 ──POST /storyboard/stream (SSE)──▶ NestJS 转发服务 ──stream──▶ OpenAI 兼容模型
     │          ◀── delta / done / error ──              │（持有 Key、按设备限流）
     │          ──GET /templates──▶ 下发提示词模板（带版本号）
     ▼
 drift（SQLite）：project / character_card / shot / generation / key_value
```

客户端只负责整理和展示，分镜、角色卡、进度都存在本地；密钥和提示词模板放在服务端；生成视频留给用户去即梦、可灵完成。

## 客户端目录（app/lib）

| 目录 | 职责 |
| --- | --- |
| `bootstrap/` | 启动流程与 `AppDependencies`：读取配置、打开数据库、组装仓库，统一释放 |
| `config/` | `--dart-define` 构建参数，不从本地存储读取 |
| `net/` | 错误分类、按平台选择支持流式读取的 HTTP 客户端 |
| `data/db/` | drift 表定义和数据库；`*.g.dart` 为生成代码 |
| `data/models/` | 景别、状态、平台枚举，镜头草稿、角色资料等纯数据 |
| `data/storyboard/` | 流式分镜：SSE 解码 → 拼行 → 逐行解析校验 |
| `data/prompt/` | 提示词模板解析、实时拼接、模板仓库（服务端 → 缓存 → 内置） |
| `data/repositories/` | 按表封装读写，页面只依赖仓库 |
| `pages/<page>/` | `page`（组装依赖）/ `view`（布局交互）/ `controller`（BLoC/Cubit）/ `state`；拆出的组件放 `widgets/`，每个组件一个文件 |
| `resources/` | 主题与共享尺寸 |
| `router/` | go_router 路由表 |

规则：

- view 不直接访问网络和数据库；跨页面的业务能力放 `data/`，由 page 注入。
- 简单页面可以只有 page + view，不为凑结构建空的 controller/state。
- 输入框、动画等控制器由创建它的组件释放。

## 流式分镜的数据流

1. `StoryboardApi.generate` 发 POST，响应体依次经过 `utf8.decoder`（多字节字符跨包）、`SseDecoder`（事件跨包）、`LineAccumulator`（一行 JSON 跨多个 delta）。
2. 每拼出一行交给 `ShotLineParser`：直接解析 → 修复常见错误后再解析 → 字段校验与兜底。坏行标成「需重新生成」，不影响其他镜头。
3. `StoryboardController` 用 `emit.forEach` 消费更新；生成相关事件走 `restartable()`，「停止」和「重新生成」会自动取消上一次订阅，连接随之断开，服务端感知断开后中止上游请求。
4. 只有收到 `done` 的完整结果才在事务里整体写库；取消或失败保留上一次的完整结果。
5. 增量渲染：每个 delta 之后，`LineAccumulator.pending` 里还没写完的半行借用 `ShotLineParser.repair` 补齐引号和括号，读出已经写出来的字段（`PartialShot`），内容变了才发 `ShotDrafting`。状态里单独放 `drafting`，只有列表末尾的 `DraftingShot` 订阅它，高频重建不碰已完成的镜头。

## 改表流程

1. 改 `tables.dart`，`schemaVersion` 加 1，在 `migration.onUpgrade` 里写 `if (from < N)` 的升级步骤；
2. `dart run build_runner build --delete-conflicting-outputs`；
3. `dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/drift_schema_vN.json` 存下新版本快照；
4. `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/`，在 `test/data/migration_test.dart` 补一个从上一版升级的用例（插旧数据 → 迁移 → 校验结构和数据）。

## 相对 course_student_app 的调整

保留了熟悉的部分：`bootstrap/` + `AppDependencies` 统一管理生命周期、page/view/controller/state 页面结构、go_router、错误分类不带敏感信息、构建期配置。

| 调整 | 原因 |
| --- | --- |
| 单仓库拆成 `app/` + `server/` | 转发服务是作品集的一部分，放在一起方便面试官一次看全，CI 也能一起跑 |
| Hive + HydratedBloc + SharedPreferences → 只用 drift | 镜头、角色、生成记录之间有关联查询；三套存储会带来三套生命周期和清理逻辑，键值需求用一张 `key_values` 表就够了 |
| dio + retrofit → package:http | 只有两个接口，其中流式接口需要直接拿字节流；retrofit 对 SSE 帮助不大，http 的 `send` 和 Web 端的 FetchClient 刚好覆盖 |
| 去掉 freezed / json_serializable | 模型输出的 JSON 需要「宽进严出」的手写校验（修复、默认值、提示），代码生成的严格 fromJson 反而不合适；drift 已经生成表的数据类 |
| 去掉登录、会话守卫、启动屏插件 | 第一版没有账号；少一个原生插件，少一份平台配置 |
| 页面控制器按需用 Bloc | 流式生成有多种事件和取消语义，用 Bloc + `restartable` 表达；简单列表页仍用 Cubit |
| Jenkins → GitHub Actions；去掉 `check.py` 的文档检查 | 开源仓库免费、面试官能直接看到流水线；个人项目文档少，不需要文档链接校验 |
| 新增安装级设备 ID | 转发服务要按设备限流。随机 UUID，不读硬件标识，卸载即重置 |

## 面试讲法速记

- **为什么 POST + 自己解析 SSE**：故事可能上千字，放不进 GET 查询串；浏览器 EventSource 只支持 GET，所以客户端自己解析。只需要服务端单向推送，SSE 基于普通 HTTP，比 WebSocket 简单，代理和抓包都好调。
- **JSON 被拆在两个包里怎么办**：分三层处理——字节层交给 `utf8.decoder`，事件层 `SseDecoder` 缓冲到空行，行层 `LineAccumulator` 缓冲到换行。每层有单测，测试里故意每 7 字节切一刀。
- **模型输出坏 JSON 用户看到什么**：先自动修复（行尾逗号、编号前缀、截断补齐），修不好的那一行显示「需重新生成」，其他镜头照常展示；修复过的计入失败，用来统计一次解析成功率。
- **取消怎么做**：`restartable()` 让新事件取消旧处理器 → 取消订阅 → http 连接关闭 → 服务端 `res.on('close')` 中止上游 fetch，不为没人看的输出付费。
- **数据库升级怎么保证不丢数据**：每个版本用 drift_dev 存一份结构快照，迁移测试从旧版本建库、插数据、执行迁移，再和新版本快照逐表比对结构并检查数据还在。
- **覆盖率怎么算才不虚高**：`flutter test --coverage` 只统计被测试 import 到的文件，没测的页面根本不出现，第一次看到 83% 其实只有 50%。脚本先生成一个 import 全部 lib 文件的空测试再统计，并排除生成代码；CI 和本地跑同一个脚本，低于门槛就失败。
- **组件测试里用 drift 卡住怎么办**：数据库要在 setUp（真实异步）里打开，在 testWidgets 的假时钟里首次打开会死锁；等待数据时交替 `runAsync` 让出真实时间和 `pump` 推进帧。
- **补测试抓到了什么**：一是故事只有点生成才保存，写完直接返回就丢了——改成输入停顿 0.5 秒自动保存、离开页面补存；二是 `emit(state.copyWith(templates: await load()))` 会在等待前就取走旧 state，模板加载期间的输入被覆盖——先 await 再读 state。
- **为什么 drift 不用 hive**：有关联查询和外键级联；提示词不落库，按「镜头 + 角色卡 + 模板」实时拼，改一处全更新。
- **角色卡怎么和镜头对上**：镜头里存出场角色名而不是角色卡 ID——模型输出的就是名字，没建角色卡的人物也要留下；拼提示词时按名字匹配，角色卡改名时在同一事务里同步改镜头。同一项目内不允许重名；生成时现读角色卡交给模型，提示要求出场角色名与角色列表一致。不建角色也能生成，模型沿用故事原有称呼。
- **增量渲染怎么做**：半行 JSON 不等换行，直接用修复逻辑补齐括号后解析，字段写到哪显示到哪；补不齐（截在键名上）就沿用上一帧。正在写的镜头单独一个状态字段、单独一个 BlocBuilder，已完成的列表只在整行到达时重建一次。
- **性能基线怎么测**：integration_test 回放固定节奏的 SSE（固定随机种子切块），`watchPerformance` 收集引擎的 FrameTiming，profile 模式跑，输出构建/光栅化的平均、P90、P99 和超预算帧数；输入固定，优化前后可直接对比。模拟器的光栅化数字不作数，只看 UI 线程。
- **Key 为什么不能放客户端**：安装包能被解包，Key 一泄露就会被刷；转发服务持有 Key，并按安装 ID 限流，缺 ID 时退回按 IP。
