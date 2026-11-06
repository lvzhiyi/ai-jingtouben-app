# 接口联调约定

## 契约来源

- 接口工具：无；契约以 `server/` 代码为准，改接口时同时改服务端 DTO / 控制器、客户端 `app/lib/data/` 和两端测试。
- 契约记录位置：接口变化写在对应提交说明和[架构说明](../architecture.md)里。

| 接口 | 说明 | 定义位置 |
| --- | --- | --- |
| `POST /storyboard/stream` | 流式生成分镜，返回 SSE：`delta`（`{"text"}` 文本增量）、`done`、`error`（`{"code": "upstream_error" \| "internal_error"}`），每 15 秒一次 `: ping` 心跳 | `server/src/storyboard/storyboard.controller.ts`；请求体校验在 `storyboard.dto.ts`（故事 10–3000 字，角色名 1–20 字） |
| `GET /templates` | 下发提示词模板，缓存 5 分钟，不限流 | `server/src/templates/templates.controller.ts` |
| `GET /health` | 健康检查 | `server/src/health.controller.ts` |

## 项目接入边界

- 环境与地址注入方式：客户端用 `--dart-define=API_BASE_URL=...`（`app/lib/config/app_config.dart`），没传时本机开发 Android 模拟器用 `10.0.2.2:3000`、其他平台用 `localhost:3000`；release 包必须用 https。服务端变量见 `server/.env.example`。构建参数不放凭据。
- 响应包裹与成功码：不做统一包裹；流式接口始终返回 200，错误通过 SSE `error` 事件传递。
- 鉴权与过期处理：第一版没有账号；服务端按 `x-device-id`（客户端生成的安装 ID）限流，缺失时按 IP。
- Mock：服务端没配 `LLM_API_KEY` 时返回本地 mock 分镜，只用于本机开发；客户端 Mock 只放在测试里。
- 模型密钥只在服务端，客户端不打包任何密钥。

## 测试账号与数据

- 不需要测试账号；模型密钥通过安全渠道提供，只写在服务端 `.env`，不进文档和仓库。
