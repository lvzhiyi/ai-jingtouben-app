# 镜头本 · AI 短剧镜头本

帮 AI 短剧新手把一个故事整理成可以直接拿去生成的镜头。大厂负责生成视频，镜头本负责生成之前和之后的整理工作。

第一版：故事 → 分镜卡片（流式生成，含景别、画面、台词、为什么这样拍）、角色卡、即梦 / 可灵双平台提示词、镜头进度板、导出分享。

## 仓库结构

```
app/      Flutter 客户端（iOS / Android / Web）· BLoC · drift
server/   NestJS 转发服务 · SSE · 按设备限流 · 提示词模板下发
docs/     架构说明
```

## 本地运行

### 1. 转发服务

```bash
cd server
cp .env.example .env      # 不填 LLM_API_KEY 时使用模拟数据
npm install
npm run start:dev         # http://localhost:3000/health
```

### 2. 客户端（首次）

```bash
cd app
flutter create . --project-name jingtouben --org com.lvzhiyi --platforms android,ios,web
rm test/widget_test.dart  # flutter create 生成的示例测试引用了不存在的 MyApp
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Android 调试包访问本机 http 服务需要允许明文流量：在 `android/app/src/debug/AndroidManifest.xml` 的 `<manifest>` 里加上

```xml
<application android:usesCleartextTraffic="true" />
```

Web 版的 drift 需要把 `sqlite3.wasm` 和 `drift_worker.js` 放进 `app/web/`，下载与 `pubspec.lock` 中 sqlite3、drift 版本对应的文件：
[sqlite3.dart releases](https://github.com/simolus3/sqlite3.dart/releases)、[drift releases](https://github.com/simolus3/drift/releases)。

### 3. 运行

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/   # iOS 模拟器 / Web
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/    # Android 模拟器
```

真机调试把地址换成电脑的局域网 IP。VS Code 里可以直接用 `.vscode/launch.json` 的两个配置。

## 验证

```bash
cd app && dart format lib test && flutter analyze && flutter test
cd server && npm run typecheck && npm test
```

## 要记录的数字

| 指标 | 怎么测 | 结果 |
| --- | --- | --- |
| 首字延迟 | 分镜页状态行直接显示（发出请求到第一个字） | 待测 |
| 流式帧耗时 / 掉帧数 | DevTools，优化前后各一次 | 待测 |
| 结构化输出一次解析成功率 | 20 个故事样本，`ParsedShot.repaired == false` 的比例 | 待测 |
| 测试覆盖率 | CI 的 Coverage 步骤 | 待测 |

## 展示方式

不上架：国内 AI 生成类 App 需要企业主体办理大模型备案登记。通过演示视频、开源仓库、APK / TestFlight 和面试现场演示展示。
