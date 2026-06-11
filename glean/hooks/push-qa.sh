#!/bin/bash
# mindvaults-glean — 对话结束自动推送 QA 到 mindvaults 沉淀库
# 触发方式：Claude Code Stop Hook（stdin 接收 JSON）
# 文档：https://code.claude.com/docs/zh-CN/hooks#stop
#
# transcript JSONL 格式（Claude Code 实际格式）：
#   user 消息：      {"type":"user", "message":{"role":"user","content":"..."}}
#   assistant 消息： {"type":"assistant", "message":{"role":"assistant","content":[
#                      {"type":"thinking","thinking":"..."},
#                      {"type":"text","text":"..."},
#                      {"type":"tool_use",...}
#                    ]}}
set -euo pipefail

CONFIG="$HOME/.claude/mindvaults/config.json"
STATE="$HOME/.claude/mindvaults/state.json"
PENDING_LOG="$HOME/.claude/mindvaults/pending.log"

# ── 依赖检查 ──────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  echo "[mindvaults] 错误：缺少 jq，请先安装 brew install jq" >&2
  exit 0
fi

if ! command -v curl &>/dev/null; then
  echo "[mindvaults] 错误：缺少 curl" >&2
  exit 0
fi

# ── 防止 Stop Hook 嵌套触发 ───────────────────────────────
if [ "${MINVAULTS_HOOK_ACTIVE:-0}" = "1" ]; then
  exit 0
fi

# ── 解析 stdin（Claude Code Stop Hook 协议）───────────────
# stdin 格式：{"session_id":"...","transcript_path":"/path/to/transcript.jsonl",...}
hook_input=$(cat)
session_id=$(echo "$hook_input" | jq -r '.session_id // "unknown"')
transcript_path=$(echo "$hook_input" | jq -r '.transcript_path // ""')

# ── 读取配置 ──────────────────────────────────────────────
if [ ! -f "$CONFIG" ]; then
  exit 0
fi

enabled=$(jq -r '.enabled // false' "$CONFIG" 2>/dev/null)
if [ "$enabled" != "true" ]; then
  exit 0
fi

endpoint=$(jq -r '.endpoint // ""' "$CONFIG")
api_key=$(jq -r '.api_key // ""' "$CONFIG")

if [ -z "$endpoint" ] || [ -z "$api_key" ] || [ "$api_key" = "null" ]; then
  exit 0
fi

# ── 提取本轮 QA（从 JSONL transcript）─────────────────────
question=""
answer=""

if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  # user 消息：.message.content 是字符串（过滤掉数组类型的 tool result）
  question=$(jq -r 'select(.type == "user") | .message.content | select(type == "string") // empty' "$transcript_path" 2>/dev/null | tail -1)

  # assistant 消息：.message.content 是数组，取 text block 的 .text
  answer=$(jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text // empty' "$transcript_path" 2>/dev/null | tail -1)
fi

if [ -z "$question" ] || [ -z "$answer" ]; then
  exit 0
fi

# ── 构建请求 ──────────────────────────────────────────────
platform="claude_code"

payload=$(jq -n \
  --arg platform "$platform" \
  --arg session_id "$session_id" \
  --arg q "$question" \
  --arg a "$answer" \
  '{
    platform: $platform,
    session_id: $session_id,
    qa_pairs: [{question: $q, answer: $a}]
  }')

# ── 推送（设置防护标记防嵌套）─────────────────────────────
export MINVAULTS_HOOK_ACTIVE=1

push_url="${endpoint}/api/v1/kb/external/push"
response=$(curl -s -w "\n%{http_code}" \
  -X POST "$push_url" \
  -H "Authorization: Bearer ${api_key}" \
  -H "Content-Type: application/json" \
  --connect-timeout 10 \
  --max-time 30 \
  -d "$payload" 2>/dev/null) || true

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

# ── 校验响应 ──────────────────────────────────────────────
if [ "$http_code" != "200" ]; then
  mkdir -p "$(dirname "$PENDING_LOG")"
  echo "$(date -Iseconds) | HTTP $http_code | $(echo "$question" | cut -c1-80)" >> "$PENDING_LOG"
  exit 0
fi

code=$(echo "$body" | jq -r '.code // -1' 2>/dev/null)
if [ "$code" != "0" ]; then
  mkdir -p "$(dirname "$PENDING_LOG")"
  echo "$(date -Iseconds) | API code=$code | $(echo "$question" | cut -c1-80)" >> "$PENDING_LOG"
  exit 0
fi

# ── 更新统计 ──────────────────────────────────────────────
mkdir -p "$(dirname "$STATE")"

if [ ! -f "$STATE" ]; then
  echo '{"daily":{},"last_push_at":""}' > "$STATE"
fi

today=$(date +%Y-%m-%d)
count=$(jq -r ".daily.\"$today\" // 0" "$STATE" 2>/dev/null || echo 0)
count=$((count + 1))

jq --arg today "$today" --arg count "$count" --arg time "$(date -Iseconds)" \
  '.daily[$today] = ($count | tonumber) | .last_push_at = $time' \
  "$STATE" > "${STATE}.tmp" && mv "${STATE}.tmp" "$STATE"

exit 0
