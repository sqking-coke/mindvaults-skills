# mindvaults-glean

Claude Code 对话自动推送插件，将每次对话的 QA 对同步到你的 mindvaults 知识沉淀库。

## 安装

### 方式一：从 GitHub 安装（推荐）

```bash
# 在 Claude Code 中运行
/plugin install github.com/sqking-coke/mindvaults-glean
```

### 方式二：手动安装

```bash
mkdir -p ~/.claude/skills/mindvaults-glean
cp -r SKILL.md hooks/ commands/ references/ .claude-plugin/ ~/.claude/skills/mindvaults-glean/
```

## 首次配置

1. 登录 mindvaults → 设置 → 外部推送，获取 API Key
2. 创建配置文件：

```bash
mkdir -p ~/.claude/mindvaults
cat > ~/.claude/mindvaults/config.json << 'EOF'
{
  "endpoint": "https://your-instance.com",
  "api_key": "mv-dep-xxxxxxxxxxxx",
  "enabled": true
}
EOF
```

3. 在 Claude Code 中运行 `/mindvaults on`

## 命令

| 命令 | 功能 |
|------|------|
| `/mindvaults on` | 开启自动收集 |
| `/mindvaults off` | 暂停自动收集 |
| `/mindvaults push` | 手动推送当前会话 |
| `/mindvaults status` | 查看今日统计 |

## 工作原理

```
对话结束 → Stop Hook 触发 → push-qa.sh
    ↓
提取 QA 对 → POST /api/v1/kb/external/push
    ↓
mindvaults 沉淀库 → LLM 提炼 → 审核 → 目标知识库
```

## 隐私

- API Key 仅存在本地 `~/.claude/mindvaults/config.json`
- 对话内容通过 HTTPS 加密传输
- 随时 `/mindvaults off` 暂停收集

## 依赖

- `jq`（JSON 处理）
- `curl`（HTTP 请求）

## 许可

MIT
