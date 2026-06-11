# mindvaults 配置参考

## 配置文件

`~/.claude/mindvaults/config.json`：

```json
{
  "endpoint": "https://your-mindvaults-instance.com",
  "api_key": "mv-dep-xxxxxxxxxxxx",
  "enabled": false
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `endpoint` | string | 是 | mindvaults 部署地址，不含尾部斜杠 |
| `api_key` | string | 是 | 在设置页获取的推送专用 Key |
| `enabled` | boolean | 是 | 自动收集开关，默认 `false`（手动模式）。`/mindvaults on` 开启自动收集，`/mindvaults off` 关闭

## 获取 API Key

1. 登录你的 mindvaults 实例
2. 进入「设置」→「外部推送」
3. 复制端点地址和 API Key
4. 填入 `~/.claude/mindvaults/config.json`

## 状态文件

`~/.claude/mindvaults/state.json`（自动维护，无需手动编辑）：

```json
{
  "daily": { "2026-06-05": 15 },
  "last_push_at": "2026-06-05T17:30:00+08:00"
}
```

- `daily`：按日期统计推送条数
- `last_push_at`：最近一次推送时间

## 失败重试

推送失败时，QA 内容记录到 `~/.claude/mindvaults/pending.log`，格式：

```
2026-06-05T17:30:00+08:00 | HTTP 500 | 什么是 GIL
```

目前不支持自动重试，后续版本加入。

## 故障排查

### push-qa.sh 静默退出

脚本在以下情况静默退出（这是正常行为）：
- 配置文件不存在或 `enabled != true`
- 本轮无 QA 内容（空对话）
- Stop Hook 嵌套调用保护

如需调试，在终端手动运行：

```bash
export CLAUDE_TRANSCRIPT_PATH="/path/to/transcript.json"
export CLAUDE_SESSION_ID="test-session"
bash ~/.claude/skills/mindvaults-glean/hooks/push-qa.sh
```

### API Key 无效

1. 确认 Key 未被轮换（在设置页检查）
2. 确认 `endpoint` 地址正确
3. 测试连通性：`curl -I https://your-instance.com/api/v1/kb/external/push`

### jq 未安装

```bash
brew install jq          # macOS
apt-get install jq       # Linux
```
