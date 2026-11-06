# 代码规范

分层和目录职责见[架构说明](../architecture.md)，项目约束见 [AGENTS.md](../../AGENTS.md)「约束」。

- 格式与静态分析：
  - app：`app/analysis_options.yaml`，基于 `flutter_lints`，行宽 100，开启 `prefer_single_quotes`、`always_declare_return_types`、`avoid_print`；`*.g.dart`、`build/`、平台目录不参与分析。命令 `dart format lib test && flutter analyze`。
  - server：TypeScript 用 `npm run typecheck`（`tsc --noEmit`）做检查，没有配置 ESLint / Prettier。
- 命名：待确认（目前按 Dart / TypeScript 社区惯例写）。
- 注释：待确认（现有代码里公开类和方法都写了中文文档注释，说明业务原因）。
- 日志：不打印故事内容、请求体和响应体；错误信息不回显地址和凭据。
- 依赖：改依赖时同时检查 `app/pubspec.lock`、`server/package-lock.json`；第三方 API 以锁定版本为准，不带入凭据、生产地址或真实敏感数据。

## 生成代码

- drift：`cd app && dart run build_runner build --delete-conflicting-outputs`，生成 `*.g.dart`。改表时同步 `schemaVersion`、迁移步骤和 `app/drift_schemas/` 快照。
- Pigeon：接口定义在 `app/pigeons/`，用 `app/tool/generate_pigeon.sh` 重新生成 Dart / Kotlin / Swift 文件。
- 生成文件不手改，改生成源后重新生成并检查 diff。
