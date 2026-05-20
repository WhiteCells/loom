# LOOM

LOOM 是一个用于管理本地 AI Coding Agent 配置。

## 设计目标

- 为每一套 Agent 配置提供独立的命名空间，避免不同模型、代理和密钥配置相互覆盖。
- 支持一键切换当前生效配置，并将修改后的配置保存回对应配置目录。
- 统一管理常见配置文件，例如 `skills`、`.env`、`auth.json`、`config.toml`。
- 使用文件系统作为主要数据源，Profile 目录保存完整配置，少量状态和缓存使用 JSON/NDJSON 文件维护。
- 提供 OpenAI Codex 与 Anthropic Claude Code 的可用性检查入口。

## 范围

当前文档聚焦配置管理与健康检查设计，不包含完整 UI、登录体系、云同步或团队协作能力。

### 已覆盖

- Codex 配置目录设计
- 配置文件结构
- 本地文件存储与元数据设计
- API 可用性检查
- 代理端口健康检查
- token 使用统计记录
- Claude Code 模型接口检查

## 核心概念

### 配置集 Profile

一个 Profile 表示一套完整的 Agent 运行配置。每个 Profile 都有唯一名称，并对应一个独立目录。

示例：

```text
profiles/
  openai-default/
    profile.json
    skills/
    .env
    auth.json
    config.toml
  openai-proxy/
    profile.json
    skills/
    .env
    auth.json
    config.toml
  claude-default/
    profile.json
    .env
    auth.json
    config.json
```

Profile 需要支持以下操作：

- 创建：基于默认模板生成配置目录。
- 复制：从已有 Profile 克隆一份新配置。
- 编辑：修改环境变量、认证信息、模型和代理配置。
- 保存：将 UI 或服务端修改写回对应配置文件。
- 启用：把目标 Profile 同步到对应 Agent 的默认配置路径。
- 删除：删除 Profile 目录和关联缓存文件。

### 当前配置 Active Profile

系统应使用 `active.json` 记录当前启用的 Profile。这样既能避免引入数据库，也能让状态对用户保持可见、可复制、可恢复。

```json
{
  "codex": {
    "profile": "openai-default",
    "target_path": "/home/<username>/.codex",
    "activated_at": "2026-05-15T03:09:38.921Z"
  }
}
```

## 目录设计

### Codex 默认路径

- Windows：`C:/`
- Linux：`/home/<username>/.codex`

> Windows 路径后续需要根据实际 Codex 安装与配置路径进一步校准。

### LOOM 本地目录

建议使用单独的应用数据目录保存 Profile、当前启用状态、检查结果和使用统计。

```text
loom/
  active.json
  profiles/
    <profile-name>/
      profile.json
      skills/
      .env
      auth.json
      config.toml
  health/
    <profile-name>.json
  usage/
    <profile-name>.ndjson
  backups/
    <timestamp>-<profile-name>/
  logs/
```

## Codex 配置文件

每个 Codex Profile 至少包含以下文件或目录：

```text
skills/
profile.json
.env
auth.json
config.toml
```

### `profile.json`

用于保存 Profile 的描述性元数据。真实运行配置仍以 `.env`、`auth.json`、`config.toml` 等文件为准。

```json
{
  "name": "openai-default",
  "agent_type": "codex",
  "description": "默认 OpenAI Codex 配置",
  "created_at": "2026-05-15T03:09:38.921Z",
  "updated_at": "2026-05-15T03:09:38.921Z"
}
```

### `.env`

用于保存代理、运行时环境变量等配置。

```env
HTTP_PROXY=http://127.0.0.1:2080
HTTPS_PROXY=http://127.0.0.1:2080
```

### `auth.json`

用于保存认证模式和 API Key。

```json
{
  "auth_mode": "apikey",
  "OPENAI_API_KEY": "sk-xxx"
}
```

安全要求：

- UI 默认隐藏密钥明文。
- 日志与健康检查结果不得输出完整 API Key。
- 备份导出时应提醒用户其中可能包含敏感信息。

### `config.toml`

`config.toml` 应包含默认模型、推理强度、数据存储策略和模型供应商配置。

```toml
model_provider = "OpenAI"
model = "gpt-5.5"
model_reasoning_effort = "xhigh"
disable_response_storage = true

[model_providers.OpenAI]
name = "OpenAI"
base_url = "https://api.jucode.cn/v1"
wire_api = "responses"
requires_openai_auth = true
```

建议在应用层提供结构化表单编辑，保存时再序列化为 TOML，避免使用纯字符串拼接修改配置。

## 文件存储设计

当前阶段不引入 SQLite。LOOM 以文件系统作为唯一数据源：Profile 是否存在由 `profiles/<profile-name>/` 决定，当前启用状态由 `active.json` 决定，健康检查和 token 统计作为可重建的缓存或追加日志保存。

这种方式的优点是实现简单、状态透明、方便手动复制和备份，也更符合配置管理工具的使用方式。只有当后续出现大量统计、复杂筛选、审计追踪或多进程高频写入时，再评估引入 SQLite。

### Profile 元数据

路径：`profiles/<profile-name>/profile.json`

```json
{
  "name": "openai-default",
  "agent_type": "codex",
  "description": "默认 OpenAI Codex 配置",
  "created_at": "2026-05-15T03:09:38.921Z",
  "updated_at": "2026-05-15T03:09:38.921Z"
}
```

### 当前启用状态

路径：`active.json`

```json
{
  "codex": {
    "profile": "openai-default",
    "target_path": "/home/<username>/.codex",
    "activated_at": "2026-05-15T03:09:38.921Z"
  },
  "claude": {
    "profile": "claude-default",
    "target_path": "/home/<username>/.claude",
    "activated_at": "2026-05-15T03:09:38.921Z"
  }
}
```

### 健康检查缓存

路径：`health/<profile-name>.json`

```json
{
  "profile": "openai-default",
  "checked_at": "2026-05-15T03:09:38.921Z",
  "checks": [
    {
      "type": "model_list",
      "endpoint": "https://api.openai.com/v1/models",
      "status": "ok",
      "latency_ms": 328,
      "message": "available"
    }
  ]
}
```

健康检查结果是缓存数据，删除后可以重新生成。

### Token 使用日志

路径：`usage/<profile-name>.ndjson`

每一行保存一个 token 使用事件，便于追加写入和后续批量统计。

```json
{"created_at":"2026-05-15T03:09:38.921Z","model":"gpt-5.5","input_tokens":13310,"cached_input_tokens":6528,"output_tokens":27,"reasoning_output_tokens":0,"total_tokens":13337,"context_window":258400}
```

## 关键流程

### 创建 Profile

1. 用户输入 Profile 名称和 Agent 类型。
2. 系统创建 Profile 目录。
3. 系统写入默认 `profile.json`、`.env`、`auth.json`、`config.toml`。
4. 系统通过扫描 `profiles/` 目录刷新 Profile 列表。
5. UI 展示新 Profile，并允许立即编辑。

### 修改 Profile

1. 读取 Profile 目录中的配置文件。
2. 将 `.env`、`auth.json`、`config.toml` 解析为结构化数据。
3. 用户在 UI 中修改配置。
4. 保存前进行字段校验。
5. 序列化并写回原配置文件。
6. 更新 `profile.json` 中的 `updated_at`。

### 启用 Profile

1. 读取目标 Profile。
2. 备份当前 Agent 默认配置目录。
3. 将 Profile 文件同步到 Agent 默认路径。
4. 写入 `active.json`。
5. 自动执行一次健康检查。

### 健康检查

健康检查分为三类：

- 服务状态检查：检查官方状态页。
- 模型列表检查：检查 API Key 与模型供应商是否可用。
- 代理端口检查：检查本地代理是否可连接。

## OpenAI Codex

### 可用性检查

```sh
export OPENAI_API_KEY=xxx

curl https://status.openai.com/api/v2/status.json

curl https://api.jucode.cn/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"

curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

检查结果建议保存到 `health/<profile-name>.json`，并在 UI 中展示最近一次检查时间、状态、耗时和错误信息。

### 代理端口检查

当 `.env` 中配置了 `HTTP_PROXY` 或 `HTTPS_PROXY` 时，需要额外检查代理端口。

建议检查项：

- 代理地址格式是否有效。
- 主机与端口是否可连接。
- 经代理访问模型接口是否成功。

示例代理配置：

```env
HTTP_PROXY=http://127.0.0.1:2080
HTTPS_PROXY=http://127.0.0.1:2080
```

## Anthropic Claude Code

### 可用性检查

```sh
export ANTHROPIC_API_KEY=xxx

curl https://status.claude.com/api/v2/status.json

curl 'https://token-plan-cn.xiaomimimo.com/v1/models' \
  -H 'Authorization: Bearer $ANTHROPIC_API_KEY'

curl https://api.anthropic.com/v1/models \
  -H 'Authorization: Bearer $ANTHROPIC_API_KEY'
```

后续可以为 Claude Code 补充独立的 Profile 文件结构，例如 `settings.json`、`config.json` 或其实际配置路径。

## Token 使用统计

Codex 运行过程中可能产生 `token_count` 事件。LOOM 可以监听、导入或粘贴该事件，并解析为结构化统计数据。

原始事件示例：

```json
{
  "timestamp": "2026-05-15T03:09:38.921Z",
  "type": "event_msg",
  "payload": {
    "type": "token_count",
    "info": {
      "total_token_usage": {
        "input_tokens": 13310,
        "cached_input_tokens": 6528,
        "output_tokens": 27,
        "reasoning_output_tokens": 0,
        "total_tokens": 13337
      },
      "last_token_usage": {
        "input_tokens": 13310,
        "cached_input_tokens": 6528,
        "output_tokens": 27,
        "reasoning_output_tokens": 0,
        "total_tokens": 13337
      },
      "model_context_window": 258400
    },
    "rate_limits": {
      "limit_id": "codex",
      "limit_name": null,
      "primary": null,
      "secondary": null,
      "credits": null,
      "plan_type": null,
      "rate_limit_reached_type": null
    }
  }
}
```

解析后建议展示：

- 本次输入 token
- 缓存命中 token
- 输出 token
- 推理 token
- 总 token
- 模型上下文窗口
- 记录时间

## 错误处理

常见错误及处理方式：

| 场景 | 处理方式 |
| --- | --- |
| 配置文件不存在 | 使用默认模板生成，并提示用户确认 |
| TOML 或 JSON 解析失败 | 保留原文件，展示具体错误位置 |
| API Key 无效 | 标记健康检查失败，不记录完整密钥 |
| 代理不可连接 | 标记代理检查失败，并提示检查端口 |
| 启用 Profile 失败 | 回滚到启用前备份 |
| 状态文件写入失败 | 阻止继续启用，并提示重试 |

## 安全设计

- 密钥仅保存在本地配置文件中。
- 日志、缓存文件和 UI 错误信息中只展示密钥前后少量字符。
- 健康检查请求头不得写入日志。
- 导出 Profile 前需要提示其中可能包含密钥。
- 删除 Profile 前需要二次确认。

## 后续迭代

- 补齐 Windows Codex 实际配置路径。
- 补齐 Claude Code 配置目录与文件结构。
- 增加 Profile 导入、导出和加密备份。
- 增加模型供应商模板管理。
- 增加健康检查历史趋势图。
- 增加 token 使用量按 Profile、模型、日期聚合统计。
- 当统计、审计或并发写入需求变复杂时，再评估是否引入 SQLite。


Support

CLI

- list

npm 安装

alias

```sh
clang-format -i src/*.cc src/*.h
```
