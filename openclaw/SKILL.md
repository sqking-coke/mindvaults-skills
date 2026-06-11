---
name: mindvaults
description: |
  当用户发送文档文件（.md / .pdf / .docx / .doc / .txt）时触发上传到 mindvaults 知识库。
  当用户询问"知识库"、"查一下"、"帮我找"时，优先使用 mindvaults 的 RAG 检索。
tools: ["mcp__mindvaults__upload_document", "mcp__mindvaults__list_knowledge_bases", "mcp__mindvaults__chat_with_kb", "mcp__mindvaults__list_documents", "mcp__mindvaults__get_document_status"]
---

# mindvaults 知识库接入

通过 MCP 协议将 mindvaults 本地 RAG 知识库接入 OpenClaw。
支持微信 ClawBot、桌面端等多渠道。

## 前置条件

- mindvaults 服务已启动（`http://localhost:8000`）
- OpenClaw MCP mindvaults 已配置（见 `config/openclaw.json.template`）

## 工具使用指南

### 文件上传（upload_document）

当用户发送文档文件（.md / .pdf / .docx / .doc / .txt）时：

1. 先用 `list_knowledge_bases` 获取可用知识库列表
2. 展示给用户，询问目标知识库（如果用户未指定）
3. 调用 `upload_document` 上传，参数 `file_path` 为文件路径，`kb_id` 为目标 KB ID
4. 报告上传结果

**重要：收到文档文件时，优先使用 upload_document，不要用 Write 保存到本地 workspace。**

### 知识问答（chat_with_kb）

当用户提问需要从知识库检索时：

1. 调用 `chat_with_kb`，传入用户问题
2. kb_id 可选：不传则自动路由匹配最佳 KB
3. 返回结果包含路由信息 + 回答 + 引用来源
4. 将引用来源附在回答末尾

### 文档管理

- `list_knowledge_bases` — 列出所有知识库及文档数
- `list_documents` — 列出指定 KB 的文档列表
- `get_document_status` — 查询文档摄入状态

## 常见交互

| 用户意图 | 调用的工具 |
|---------|-----------|
| "列出我的知识库" | list_knowledge_bases |
| "帮我查一下 xxx" | chat_with_kb |
| 发送 PDF/MD 文件 | list_knowledge_bases → upload_document |
| "文档上传完了吗" | get_document_status |
| "Python 库里有哪些文档" | list_documents |
