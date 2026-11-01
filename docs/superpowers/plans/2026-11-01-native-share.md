# 分镜原生分享 Implementation Plan

**Goal:** 分享当前分镜文本至 Android／iOS 系统面板，Web 复制。
**Architecture:** 纯 Dart 格式化器 + 分享服务 + Pigeon HostApi；独立 Bloc 按钮订阅状态，page 注入服务。
**Tech Stack:** Flutter、BLoC、Pigeon 29.1.0、Kotlin、Swift。
**Spec:** ../specs/2026-11-01-native-share-design.md

## Global Constraints

不手改生成代码；不落库提示词；不记录内容；不提交、推送或发布。本次在用户当前工作区完成。

## Review Focus

- 空列表、模板未就绪、生成中不得分享。
- 角色改动须反映在本次导出的提示词。
- 坏行不导出；停止／失败的部分结果须说明不完整。
- 分享失败后可以重试；异步返回时组件可能已卸载。
- iPad 弹出锚点和新 Flutter implicit engine 注册必须有效。

## Task 1：文本与平台边界
- [x] 在 app/test/data/storyboard_share_test.dart 写输出内容、空镜头、Pigeon 参数、Web 剪贴板、原生异常测试，运行观察失败。
- [x] 在 app/pigeons/share_api.dart 定义异步 shareText(title, text)，生成 Dart/Kotlin/Swift。
- [x] app/lib/data/share/ 下实现 storyboard_text.dart 和 storyboard_share.dart，测试通过。

## Task 2：页面与原生实现
- [x] 为分享按钮补组件测试：禁用状态、防连点、错误重试、复制成功。
- [x] app/lib/pages/storyboard/widgets/share_button.dart 实现按钮，page 注入服务，view 加入口。
- [x] Android MainActivity 注册 HostApi；iOS ShareHandler + implicit engine 注册，加入 Xcode Sources。
- [x] 运行组件测试；构建 Android 和 iOS simulator 验证原生编译。

## Task 3：回归与文档
- [x] dart format lib test，flutter analyze，flutter test，MIN_COVERAGE=85 tool/coverage.sh。
- [x] server typecheck、test、coverage；运行客户端检查（原生变更须重启）。
- [x] 更新 README、架构面试速记和 AGENTS.md 的进度，报告实际验证及限制。

## 验证记录

- Flutter analyze 无问题；67 测试通过；覆盖率 93.1%（1098/1180）。
- Chrome：4 个分享测试通过，原生通道测试按平台跳过。
- Android debug APK、Web 构建通过；Android 模拟器实际打开系统 Sharesheet，完整重启并热重载成功。
- server typecheck、18 测试和覆盖率通过；行 98.8%，分支 84.09%。
- iOS 编译尝试失败：本机没有完整 Xcode（仅 Command Line Tools）；已根据当前 Flutter 头文件及独立审查修正 registrar.viewController 属性使用，仍待 Xcode 环境验证。
- 独立审查：发现一处 Swift 属性误当方法调用，已修正；无其他明确问题。未提交／推送。
