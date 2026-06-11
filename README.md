# mindvaults Skills

mindvaults 的 AI 平台插件集合，让知识库能力无缝接入各种 AI 工具。

## 可用 Skills

| Skill | 平台 | 功能 |
|-------|------|------|
| [glean](./glean/) | Claude Code | 对话结束自动推送 QA 到沉淀库 |
| [openclaw](./openclaw/) | OpenClaw | MCP 工具集 + 微信 ClawBot 接入 |

## 快速安装

### glean（Claude Code 知识沉淀）

```bash
cd glean && bash install.sh
```

### openclaw（MCP + 微信）

```bash
cd openclaw && bash install.sh
```

## 目录结构

```
mindvaults-skills/
├── README.md
├── glean/               # Claude Code Skill
│   ├── SKILL.md
│   ├── hooks/
│   └── commands/
└── openclaw/            # OpenClaw Skill
    ├── SKILL.md
    └── config/
```

## 关联项目

- [mindvaults](https://github.com/sqking-coke/mindvaults) — 主仓库（RAG 知识库后端+前端）
