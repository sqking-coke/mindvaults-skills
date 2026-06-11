---
name: mindvaults on
description: 开启 mindvaults 自动收集
user-invocable: true
---

# /mindvaults on — 开启自动收集

将 `~/.claude/mindvaults/config.json` 中的 `enabled` 设为 `true`。

## 执行步骤

1. 检查配置文件是否存在
2. 如果不存在，提示用户先完成首次配置
3. 设置 `enabled = true`
4. 确认开启成功，显示当前统计

## 输出示例

```
✅ mindvaults 自动收集已开启
📊 今日已推送：15 条
🔗 端点：https://your-instance.com
```
