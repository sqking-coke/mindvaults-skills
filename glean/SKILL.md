---
name: mindvaults-glean
description: |
  Use when the user asks about 知识沉淀, 保存对话, 同步知识库, mindvaults,
  conversation archiving, saving Q&A, syncing to knowledge base, or configuring
  automatic dialog capture to a private knowledge vault.
user-invocable: true
---

# mindvaults 知识沉淀同步

每次对话结束自动推送 QA 对到你的 mindvaults 沉淀库，走提炼 + 审核管道，最终分配到目标知识库。

## 自动收集

对话回合结束时，Stop Hook 自动运行：
1. 检查收集开关（`~/.claude/mindvaults/config.json` 中的 `enabled` 字段）
2. 提取本轮 QA 对
3. POST 到你的 mindvaults 实例 `/api/v1/kb/external/push`
4. 成功静默，失败记录到 `~/.claude/mindvaults/pending.log`

## 用户命令

| 命令 | 功能 |
|------|------|
| `/mindvaults on` | 开启自动收集 |
| `/mindvaults off` | 暂停收集 |
| `/mindvaults push` | 手动推送当前会话全部 QA |
| `/mindvaults status` | 查看今日推送统计 |

## 首次配置

1. 在 mindvaults 设置页（`/settings`）获取 API Key 和端点地址
2. 创建配置文件 `~/.claude/mindvaults/config.json`：
```json
{
  "endpoint": "https://your-instance.com",
  "api_key": "mv-dep-xxxxxxxxxxxx",
  "enabled": true
}
```
3. 运行 `/mindvaults on` 确认开启

> 详细配置选项和故障排查见 `references/config-guide.md`

## 数据流

```
对话结束 → Stop Hook → push-qa.sh → POST /api/v1/kb/external/push
                                              ↓
                                    mindvaults 沉淀库（去重 + 入库）
                                              ↓
                                    定时 LLM 提炼 → insight → 审核 → 目标 KB
```

## 隐私

- API Key 仅存本地 `~/.claude/mindvaults/config.json`
- 对话内容 HTTPS 加密传输
- 可随时 `/mindvaults off` 暂停
- 本地保留 7 天失败重试日志，过期自动清理
