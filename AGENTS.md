# 镜头本 · 开发约定

给 AI 编程助手和自己看的约定。产品背景见 [README](README.md)，分层与目录规则见 [架构说明](docs/architecture.md)。

## 仓库

- `app/`：Flutter 客户端（iOS / Android / Web），BLoC + drift
- `server/`：NestJS 转发服务，只做转发、限流、模板下发，不做业务

## 编码前

- 先读 [架构说明](docs/architecture.md)。
- 第三方 API 以 `pubspec.lock` / `package-lock.json` 锁定的版本为准，不凭记忆写；不确定时查官方文档或依赖源码。
- 第一版范围外的东西（账号、付费、云同步、图片视频生成）不要顺手加。

## 约束

- 客户端不打包任何密钥；调用模型只能经过 server。
- 不手改生成代码（`*.g.dart`）。改表后运行 build_runner，并同步 `schemaVersion` 和迁移步骤。
- 提示词使用时实时拼接，不落库。改模板时同时改 `server/src/templates/prompt-templates.json` 和 `app/assets/prompt_templates.json`，CI 会比对。
- 页面按 page / view / controller / state 组织；网络和数据库只在 `data/` 层，view 不直接调用。
- 日志里不打印故事内容、请求体和响应体。
- 不自动提交、推送或发布。

## 验证

- app：`dart format lib test && flutter analyze && flutter test`；覆盖率 `MIN_COVERAGE=85 tool/coverage.sh`
- server：`npm run typecheck && npm test`；覆盖率 `npm run test:cov`
- 只报告实际跑过的验证；性能数字以 DevTools 实测为准。

## 协作方式

- 用中文沟通；优先给能直接用的代码和步骤，改完自己跑「验证」里的命令。
- 涉及技术选型时，顺带一两句「面试中怎么讲」，好的讲法补进 [架构说明](docs/architecture.md) 的「面试讲法速记」。
- 测到「要记录的数字」后，填进 README 的表格。

## 冲刺进度（10/29–11/11，每推进一步更新这里）

- [x] 10/29 定位 + 一页技术方案（docs/architecture.md）
- [x] 10/30 骨架、CI、转发服务：本机 app / server 验证命令通过，GitHub CI 在 625f1a4 上首次全绿
- [x] 10/31 流式生成分镜：SSE 解码、拼行、逐行解析和分镜页；首字延迟已实测，见 README
- [x] 11/1 UI 视觉改版：参考 iPhone App 的奶油白与浅粉渐变、大圆角卡片和黑色悬浮操作，统一项目首页与分镜工作台；app 静态分析及 24 个测试通过，Android 热重载成功
- [~] 11/1 增量渲染 + 性能基线：正在写的镜头按半行 JSON 补齐后实时显示（`PartialShot` / `DraftingShot`）；`integration_test/storyboard_perf_test.dart` 回放固定流式输入，模拟器 UI 线程基线已填进 README，真机和 DevTools 实测待做
- [x] 11/2 数据模型 + 本地存储：drift 表和仓库，schemaVersion 2（镜头出场角色改存名字），`drift_schemas/` 快照 + `test/data/migration_test.dart` 迁移测试
- [x] 11/3 结构化分镜 + 角色卡 + 双平台提示词：角色卡页面（增删改、同项目不重名、最多 10 个，生成时带给模型，改名同步镜头）；镜头出场角色落库；镜头卡按「镜头 + 角色卡 + 模板」实时拼即梦 / 可灵提示词，一键复制
- [ ] 11/4 周复盘 + 用户访谈
- [x] 11/5 补测试，覆盖率进 CI（提前到 11/1）：app 92.7%（`tool/coverage.sh`，门槛 85%），server 行 98.8%（端到端起真实 HTTP 服务，门槛 90%）；补测试时修了两个 bug：故事不生成就不保存、模板加载覆盖输入中的故事
- [~] 11/6 镜头进度板 + Pigeon 导出：进度板已完成（分镜页入口，按镜头记录每次即梦／可灵生成并存提示词快照、选定一次、改备注、删除，状态由记录推导，按状态筛选和进度条；有记录时重新生成先确认），app 86 测试、覆盖率 94.7%；11/6 在 Android 模拟器（Pixel 9 Pro XL，mock 转发服务）走通记录／选定／筛选／改备注／删除和重新生成确认清空，无运行时异常。Pigeon 29.1.0 原生文本分享已实现，Android 模拟器实测系统面板、Web 构建及 Chrome 分支测试通过；iOS 已接入但缺完整 Xcode 未编译
- [x] 11/5 对接 ai-tools：分镜页「导出 JSON」（`storyboard_json.dart`），ai-tools 用 `studio import` 导入跑本地生成；两边联调通过，app 72 测试、覆盖率 93.4%
- [ ] 11/7 性能优化 + 前后对比表
- [ ] 11/8 README、演示视频、APK、Web 版
- [ ] 11/9–11/11 简历、模拟面试、投递

下一步：在有完整 Xcode 的环境编译并验证 iOS／iPad 原生分享；11/4 周复盘 + 用户访谈；接真机跑一次「性能基线」并用 DevTools 看流式过程的帧图，补上真机数字。11/7 优化的候选：`items` 追加时整表复制和 Equatable 深比较、每个增量都做一次半行修复解析、新到镜头时整个列表重建、增量按帧合并。

## 工作流配置（ai-dev-workflow）

- 产品文档根：无单独目录（项目首页：`README.md`）
- 需求说明：`README.md`（产品背景与第一版范围）
- 任务卡目录 / 总览：无 / `AGENTS.md`「冲刺进度」
- 设计索引：无
- 工程规范：架构 `docs/architecture.md`；代码 / UI / 接口见 `docs/development/` 下的 coding、ui、api-integration；验证见 `README.md`「验证」；约束见本文件「约束」
- 规格工具：无
- 交接目录：`docs/development/handoffs/<task-id>.md`
- 验证命令：
  - 文档：workflow-core 文档规范检查（`check_docs.py`，由技能调用）
  - 轻量：app `cd app && dart format lib test && flutter analyze && flutter test <相关测试文件>`；server `cd server && npm run typecheck && npm test -- <相关测试>`
  - 标准：app `cd app && dart format lib test && flutter analyze && flutter test`；server `cd server && npm run typecheck && npm test`
  - 完整：标准档 + `cd app && MIN_COVERAGE=85 tool/coverage.sh && flutter build web --release`；`cd server && npm run test:cov && npm run build`；`diff app/assets/prompt_templates.json server/src/templates/prompt-templates.json`
- 默认验证平台：Android（模拟器或真机）；iOS 只在明确要求且有完整 Xcode 时验证；Web 按需
- 设计工具：无
- 接口工具：无
- 代码产物要求：不手改生成代码（`*.g.dart`、Pigeon 产物）；改表后运行 build_runner，同步 `schemaVersion` 和迁移步骤；Pigeon 用 `app/tool/generate_pigeon.sh` 重新生成
- 项目额外约定：只在 develop 上提交，不开 feat 分支和 PR；改提示词模板要同时改客户端和服务端两份；不自动提交、推送或发布
