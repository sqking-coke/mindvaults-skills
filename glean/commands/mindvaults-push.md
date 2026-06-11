---
name: mindvaults push
description: 手动推送当前会话全部 QA
user-invocable: true
---

# /mindvaults push — 手动推送当前会话

立即提取并推送当前会话的全部 QA 对到 mindvaults 沉淀库，无论自动收集是否开启。

## 执行步骤

1. 读取配置文件获取端点和 API Key
2. 提取当前会话全部 QA 对
3. 逐条 POST 到 `/api/v1/kb/external/push`（自动去重）
4. 输出推送结果

## 输出示例

```
📤 推送完成：收到 5 条，跳过 2 条（重复）
✅ 成功推送 5 条 QA 到 mindvaults
```
