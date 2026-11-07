# 镜头本 · 开发约定

给 AI 编程助手和自己看的约定。产品背景见 [README](README.md)，分层与目录规则见 [架构说明](docs/architecture.md)。

## 仓库

- `app/`：Flutter 客户端（iOS / Android / Web），BLoC + drift
- `server/`：NestJS 转发服务，只做转发、限流、模板下发，不做业务

## 编码前

- 先读 [架构说明](docs/architecture.md)。
- 第三方 API 以 `pubspec.lock` / `package-lock.json` 锁定的版本为准，不凭记忆写；不确定时查官方文档或依赖源码。
- 第一版范围外的东西（账号、付费、云同步、图片视频生成）不要顺手加。用文本模型生成预演用的矢量道具在范围内（2026-11-07 确认），不算图片生成。

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

## 当前优先级

冲刺排期（10/29–11/11）已取消，不再按日期推进；已完成的工作见 git 历史和 README。

1. **镜头预演**（完整档，进行中）：需求 [docs/product/需求/镜头预演.md](docs/product/需求/镜头预演.md)，模块卡 [docs/product/任务/镜头预演.md](docs/product/任务/镜头预演.md)。顺序 PV-R01 → PV-R02 / PV-R03 → PV-R04 → PV-R05；Q1 / Q2 / Q5 / Q6 已确认（9:16、7 种运镜、单镜头只编辑景别和运镜、未知运镜提示不落库），Q3 / Q4 不阻塞。PV-R01（运镜 + 时长，schemaVersion 3）、PV-R03（预演播放，11/7 改为手绘分镜风格并加取景参照、景别小图、场景模板，再改为分层摄影机：视差、真推、景深；人物改为木偶人，按关键词摆姿态、拿伞或手机）已实现、完整档验证通过，待验收；下一步 PV-R04（时长微调 + 单镜头改景别 / 运镜），PV-R02 等 Q4。
2. 待办（不排期）：
   - 道具生成需求草稿 [docs/product/需求/道具生成.md](docs/product/需求/道具生成.md)：文本模型生成矢量道具，已纳入第一版，需求 v0.2，模块卡 [docs/product/任务/道具生成.md](docs/product/任务/道具生成.md)；PG-R01–R04 已实现（schemaVersion 4、`POST /props/draw`），完整档验证通过，真实模型试跑过（道具和握持点合法；近景以上桌上道具已改为举在胸前；漏列动物未改），待验收
   - iOS／iPad 原生分享在完整 Xcode 环境编译验证（Pigeon 已接入）
   - 真机性能基线 + DevTools 帧图；分镜流式性能优化候选：`items` 追加时整表复制和 Equatable 深比较、每个增量都做一次半行修复解析、新到镜头时整个列表重建、增量按帧合并
   - 用户访谈；README、演示视频、APK、Web 版

## 工作流配置（ai-dev-workflow）

- 产品文档根：无单独目录（项目首页：`README.md`）
- 需求说明：`README.md`（产品背景与第一版范围）；功能需求见 `docs/product/需求/`
- 任务卡目录 / 总览：`docs/product/任务/` / `AGENTS.md`「当前优先级」
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
