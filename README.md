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
flutter run                                                    # 模拟器 / Web：自动连本机服务
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000/  # 真机：换成电脑的局域网 IP
```

不传 `API_BASE_URL` 时按平台选地址：Android 模拟器用 `10.0.2.2:3000`（模拟器里的 localhost 指向它自己），iOS 模拟器和 Web 用 `localhost:3000`。真机连不到这两个地址，必须传电脑的局域网 IP。VS Code 里可以直接用 `.vscode/launch.json` 的两个配置。

## 分镜分享

分镜页右上角「分享分镜」导出当前完整镜头、角色卡和即梦／可灵提示词，提示词随本次角色资料实时拼接。Android、iOS 使用 Pigeon 调起系统文本分享面板，Web 复制全文（需要 HTTPS 或 localhost，并允许剪贴板访问）。无镜头、生成中或模板未加载时按钮禁用；停止或部分失败后的有效镜头可分享，文本会标注未完整生成。打开或取消系统面板不等于已发送。

## 镜头进度板

分镜页右上角「镜头进度板」按镜头记录去即梦／可灵生成的每一次：选平台、复制这次的提示词、写一句效果备注，记录时存下当时的提示词快照；挑出最满意的一次标为选定。镜头状态由记录推导——没有记录是「待生成」，有记录未选定是「生成中」，选定一条是「已选定」——顶部显示已选定数量和进度条，可按状态筛选。点开一条记录可以回看快照、改备注或删除。

已经记过生成时，分镜页点「重新生成」会先确认：新分镜替换全部镜头，生成记录随旧镜头一起清空。

## 导出 JSON（给 ai-tools）

分镜页右上角「导出 JSON」把项目标题、故事、角色卡和镜头（景别、画面、台词、为什么这样拍、出场角色）导出成结构化 JSON，不含即梦／可灵提示词，给本机的 [ai-tools](../ai-tools) 本地流水线用：那边的 `studio import` 会把它改写成英文出图提示词，再跑出图、配音、图生视频。格式说明见 ai-tools README 的「从镜头本导入」，代码在 `app/lib/data/share/storyboard_json.dart`（`format: jingtouben.storyboard`，`version: 1`，改格式时升版本号）。

走和分享相同的通道：Android、iOS 调起系统面板（隔空投送、存到文件），Web 复制全文，复制后在 Mac 上运行 `pbpaste | uv run studio import -`。启用条件和分享一样，但不依赖提示词模板；未完整生成时带 `"incomplete": true`。

Pigeon 版本锁定在 `app/pubspec.lock`。修改 `app/pigeons/share_api.dart` 后，在 `app/` 运行 `tool/generate_pigeon.sh`，生成 Dart、Kotlin、Swift 三端接口；生成文件不要手改。首次加入或修改原生分享实现后，完整停止并重新 `flutter run`，热重载不能加载新的原生代码。

11/1 验证：Android API 37 模拟器实测打开系统分享面板，APK 与 Web 构建通过，Chrome 分享分支测试通过。iOS 已接入 UIActivityViewController（含 iPad 锚点），当前机器没有完整 Xcode，尚未编译或实机验证。

## 验证

```bash
cd app && dart format lib test && flutter analyze && flutter test
cd server && npm run typecheck && npm test
```

覆盖率（CI 同一套口径和门槛）：

```bash
cd app && MIN_COVERAGE=85 tool/coverage.sh   # 纳入所有 lib 文件，排除生成代码和表定义
cd server && npm run test:cov                # 门槛在 package.json 的 jest.coverageThreshold
```

### 性能基线

在真实页面上回放一次固定的流式生成（20 个镜头、每 25 ms 一个增量，不连网络和模型），再来回滑动列表，记录帧耗时。需要接一台真机或模拟器，用 profile 模式：

```bash
cd app && flutter drive --profile --no-dds --driver=test_driver/perf_driver.dart --target=integration_test/storyboard_perf_test.dart
```

结果写到 `app/build/storyboard_perf.json`（`storyboard_streaming` 是生成过程，`shot_list_scroll` 是滑动，`memory_rss_mb` 是生成前 / 生成中峰值 / 生成后 / 滑动后的进程内存 RSS）。`--no-dds` 不能省，否则测试连不上 VM Service。

## 要记录的数字

| 指标 | 怎么测 | 结果 |
| --- | --- | --- |
| 首字延迟 | 分镜页状态行直接显示（发出请求到第一个字） | 11/1，本机 server 连真实模型：App（Android 模拟器）3.7–6.1 s；同一段故事绕过 App 直接请求 server 为 5.1–5.5 s，客户端链路几乎不增加耗时，主要取决于模型和故事本身（换一段措辞规整的故事直连只要 2.0–2.9 s） |
| 流式帧耗时 / 掉帧数 | 「性能基线」测试 + DevTools，优化前后各一次 | 基线（11/1，Android 模拟器 API 37，profile，跑 2 次）：生成过程 UI 线程构建平均 1.5–1.7 ms、P90 2.6–2.8 ms、P99 23–25 ms，构建超 16 ms 的帧 5–6 / 338–366；滑动构建平均 2.1 ms、P99 24–38 ms。模拟器光栅化平均 65–144 ms，靠软件模拟 GPU，不作数。内存（RSS，模拟器）：生成前 252 MB、生成中峰值 263 MB、生成后 246 MB，生成 20 个镜头不涨内存。**真机（11/1，Android 小米 15 Ultra，profile，约 120 Hz）**：生成过程构建平均 0.26 ms、P90 0.82 ms、P99 2.0 ms、最差 7.8 ms，光栅化平均 0.28 ms、P99 0.56 ms，超预算帧 0 / 1936；滑动构建平均 0.29 ms、P99 3.0 ms，光栅化 P99 0.63 ms，超预算帧 0 / 916（工具按 16 ms 统计；按 120 Hz 的 8.3 ms 预算看，最差帧也在预算内）；内存 RSS 生成前 295 MB、峰值 300 MB、生成后 272 MB |
| 结构化输出一次解析成功率 | 20 个故事样本，`ParsedShot.repaired == false` 的比例 | 待测 |
| 测试覆盖率 | CI 的 Test + coverage 步骤（门槛：app 85%，server 行 90% / 分支 75%） | 11/6：app 行覆盖率 94.7%（1460/1542，加入镜头进度板后；11/1 补测试前按同一口径是 50.1%）；server 行 98.8%、分支 84.1%（11/1） |

## 展示方式

不上架：国内 AI 生成类 App 需要企业主体办理大模型备案登记。通过演示视频、开源仓库、APK / TestFlight 和面试现场演示展示。
