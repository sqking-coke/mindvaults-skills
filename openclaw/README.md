# mindvaults OpenClaw Skill

将 mindvaults 本地 RAG 知识库接入 OpenClaw，支持微信 ClawBot 等多渠道。

## 前置条件

- mindvaults ≥ v0.9.0 已安装并运行
- OpenClaw ≥ 2026.6.x
- Node.js ≥ 22

## 安装

### 方式一：一键安装（推荐）

```bash
git clone https://github.com/sqking-coke/mindvaults-skills.git
cd mindvaults-skills/openclaw && bash install.sh
```

### 方式二：手动安装

**1. Clone 仓库**

```bash
git clone https://github.com/sqking-coke/mindvaults-skills.git
```

**2. 安装 Skill**

```bash
openclaw skills install ./mindvaults-skills/openclaw
```

**3. 配置 MCP Server**

编辑 `~/.openclaw/openclaw.json`，添加 MCP 配置（参考 `config/openclaw.json.template`）：

```json
{
  "mcp": {
    "servers": {
      "mindvaults": {
        "enabled": true,
        "command": "/path/to/mindvaults/backend/venv/bin/python",
        "args": ["-m", "app.mcp.server"],
        "cwd": "/path/to/mindvaults/backend"
      }
    }
  }
}
```

**4. 重启 Gateway**

```bash
pkill -f "openclaw gateway" || true
openclaw gateway --port 18789 &
```

**5. （可选）安装微信 ClawBot**

```bash
npx -y @tencent-weixin/openclaw-weixin-cli@latest install
```

## 可用工具

| 工具 | 功能 |
|------|------|
| `list_knowledge_bases` | 列出所有知识库 |
| `chat_with_kb` | RAG 问答（含来源引用） |
| `upload_document` | 上传文档到知识库 |
| `list_documents` | 列出文档 |
| `get_document_status` | 查询摄入状态 |

## 相关文档

- [MCP 协议规范](https://modelcontextprotocol.io)
- [mindvaults 主仓库](https://github.com/sqking-coke/mindvaults)
