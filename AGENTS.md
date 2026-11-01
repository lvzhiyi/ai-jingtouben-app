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

- app：`dart format lib test && flutter analyze && flutter test`
- server：`npm run typecheck && npm test`
- 只报告实际跑过的验证；性能数字以 DevTools 实测为准。

## 协作方式

- 用中文沟通；优先给能直接用的代码和步骤，改完自己跑「验证」里的命令。
- 涉及技术选型时，顺带一两句「面试中怎么讲」，好的讲法补进 [架构说明](docs/architecture.md) 的「面试讲法速记」。
- 测到「要记录的数字」后，填进 README 的表格。

## 冲刺进度（10/29–11/11，每推进一步更新这里）

- [x] 10/29 定位 + 一页技术方案（docs/architecture.md）
- [x] 10/30 骨架、CI、转发服务：本机 app / server 验证命令通过，GitHub CI 在 625f1a4 上首次全绿
- [~] 10/31 流式生成分镜：SSE 解码、拼行、逐行解析和分镜页已写，首字延迟待实测
- [x] 11/1 UI 视觉改版：参考 iPhone App 的奶油白与浅粉渐变、大圆角卡片和黑色悬浮操作，统一项目首页与分镜工作台；app 静态分析及 24 个测试通过，Android 热重载成功
- [~] 11/1 增量渲染 + 性能基线：正在写的镜头按半行 JSON 补齐后实时显示（`PartialShot` / `DraftingShot`）；`integration_test/storyboard_perf_test.dart` 回放固定流式输入，模拟器 UI 线程基线已填进 README，真机和 DevTools 实测待做
- [~] 11/2 数据模型 + 本地存储：drift 表和仓库已写（schemaVersion 1）
- [~] 11/3 结构化分镜 + 角色卡 + 双平台提示词：提示词模板和拼接已写，角色卡页面未做
- [ ] 11/4 周复盘 + 用户访谈
- [ ] 11/5 补测试，覆盖率进 CI
- [ ] 11/6 镜头进度板 + Pigeon 导出（Pigeon 尚未引入）
- [ ] 11/7 性能优化 + 前后对比表
- [ ] 11/8 README、演示视频、APK、Web 版
- [ ] 11/9–11/11 简历、模拟面试、投递

下一步：接真机跑一次「性能基线」并用 DevTools 看流式过程的帧图，补上真机数字；同时连本机 server 实测首字延迟。11/7 优化的候选：`items` 追加时整表复制和 Equatable 深比较、每个增量都做一次半行修复解析、新到镜头时整个列表重建、增量按帧合并。
