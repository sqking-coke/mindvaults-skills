---
name: mindvaults status
description: 查看 mindvaults 今日推送统计
user-invocable: true
---

# /mindvaults status — 查看统计

读取 `~/.claude/mindvaults/state.json`，显示今日收集状态。

## 执行步骤

1. 读取状态文件
2. 获取配置文件中的开关状态
3. 输出统计信息

## 输出示例

```
📊 mindvaults 收集状态
状态：✅ 已开启
端点：https://your-instance.com
今日推送：15 条
最近推送：2026-06-05 17:30
失败重试：2 条待处理
```
