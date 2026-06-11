#!/bin/bash
# push-qa.sh 独立测试（v2：匹配 Claude Code Stop Hook 真实接口）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PUSH_SCRIPT="$SCRIPT_DIR/../hooks/push-qa.sh"
TEST_DIR="/tmp/mindvaults-test-$$"
PASS=0
FAIL=0

cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

export HOME="$TEST_DIR/home"
export MINVAULTS_HOOK_ACTIVE=0
mkdir -p "$HOME/.claude/mindvaults"
mkdir -p "$TEST_DIR/transcripts"

# ── 辅助函数 ──────────────────────────────────────────────

run_hook() {
  local desc="$1" hook_input="$2"
  if echo "$hook_input" | bash "$PUSH_SCRIPT" 2>/dev/null; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc（exit=$?）"
    FAIL=$((FAIL + 1))
  fi
}

mock_transcript() {
  # $1=path, $2=user_msg, $3=assistant_msg
  cat > "$1" << EOF
{"type":"permission-mode","permissionMode":"default","sessionId":"test-123"}
{"type":"file-history-snapshot","messageId":"m1","snapshot":{},"isSnapshotUpdate":false}
{"type":"user","message":{"role":"user","content":"$2"},"uuid":"u1","timestamp":"2026-06-05T09:00:00Z","userType":"external","sessionId":"test-123"}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"thinking","thinking":"internal reasoning..."},{"type":"text","text":"$3"},{"type":"tool_use","id":"t1","name":"Read","input":{}}]},"uuid":"a1","timestamp":"2026-06-05T09:00:01Z","sessionId":"test-123"}
{"type":"last-prompt","lastPrompt":"test prompt","sessionId":"test-123"}
EOF
}

hook_stdin() {
  # 生成符合 Claude Code Stop Hook 协议的 stdin JSON
  local session_id="$1" transcript_path="$2"
  jq -n --arg sid "$session_id" --arg tp "$transcript_path" \
    '{session_id: $sid, transcript_path: $tp, cwd: "/tmp", hook_event_name: "Stop"}'
}

# ── 测试用例 ──────────────────────────────────────────────

echo "=== 1：无配置文件 → 静默退出 ==="
rm -f "$HOME/.claude/mindvaults/config.json"
mock_transcript "$TEST_DIR/transcripts/t1.jsonl" "什么是 RAG" "RAG 是检索增强生成..."
run_hook "静默退出" "$(hook_stdin "test-1" "$TEST_DIR/transcripts/t1.jsonl")"

echo ""
echo "=== 2：enabled=false → 静默退出 ==="
cat > "$HOME/.claude/mindvaults/config.json" << 'EOF'
{"endpoint":"https://example.com","api_key":"mv-dep-test","enabled":false}
EOF
run_hook "关闭状态静默退出" "$(hook_stdin "test-2" "$TEST_DIR/transcripts/t1.jsonl")"

echo ""
echo "=== 3：正常推送（endpoint 不可达 → 记录失败日志）==="
cat > "$HOME/.claude/mindvaults/config.json" << 'EOF'
{"endpoint":"https://localhost:19999","api_key":"mv-dep-test","enabled":true}
EOF
echo "$(hook_stdin "test-3" "$TEST_DIR/transcripts/t1.jsonl")" | bash "$PUSH_SCRIPT" 2>/dev/null || true
if [ -f "$HOME/.claude/mindvaults/pending.log" ]; then
  echo "  ✅ 失败已记录到 pending.log"
  PASS=$((PASS + 1))
else
  echo "  ❌ 未生成 pending.log"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== 4：空 transcript → 静默退出 ==="
echo '' > "$TEST_DIR/transcripts/empty.jsonl"
cat > "$HOME/.claude/mindvaults/config.json" << 'EOF'
{"endpoint":"https://example.com","api_key":"mv-dep-test","enabled":true}
EOF
run_hook "空 transcript 静默退出" "$(hook_stdin "test-4" "$TEST_DIR/transcripts/empty.jsonl")"

echo ""
echo "=== 5：MINVAULTS_HOOK_ACTIVE 防护 ==="
export MINVAULTS_HOOK_ACTIVE=1
run_hook "嵌套防护退出" "$(hook_stdin "test-5" "$TEST_DIR/transcripts/t1.jsonl")"
export MINVAULTS_HOOK_ACTIVE=0

echo ""
echo "=== 6：缺失 jq → 优雅退出 ==="
PATH_SAVED="$PATH"
export PATH="/usr/bin:/bin"
echo "$(hook_stdin "test-6" "$TEST_DIR/transcripts/t1.jsonl")" | bash "$PUSH_SCRIPT" 2>/dev/null || true
echo "  ✅ 缺失 jq 退出（exit=$?）"
PASS=$((PASS + 1))
export PATH="$PATH_SAVED"

echo ""
echo "=== 7：api_key=null → 静默退出 ==="
cat > "$HOME/.claude/mindvaults/config.json" << 'EOF'
{"endpoint":"https://example.com","api_key":null,"enabled":true}
EOF
run_hook "null key 静默退出" "$(hook_stdin "test-7" "$TEST_DIR/transcripts/t1.jsonl")"

echo ""
echo "=== 8：端到端真实推送（需要 backend 在线）==="
API_KEY="mv-dep-8a843f203325fdeb14c21244e3ca52891440e47aa2230187"
cat > "$HOME/.claude/mindvaults/config.json" << EOF
{"endpoint":"http://localhost:8000","api_key":"${API_KEY}","enabled":true}
EOF
mock_transcript "$TEST_DIR/transcripts/t8.jsonl" "端到端测试：向量数据库选型" "向量数据库选型应考虑：1) 数据规模 2) 查询延迟要求 3) 索引算法 HNSW vs IVF 4) 是否支持过滤。推荐 Milvus 用于大规模生产环境，Qdrant 用于中小规模。"
echo "$(hook_stdin "e2e-$(date +%s)" "$TEST_DIR/transcripts/t8.jsonl")" | bash "$PUSH_SCRIPT" 2>/dev/null || true
if [ -f "$HOME/.claude/mindvaults/state.json" ]; then
  today=$(date +%Y-%m-%d)
  count=$(jq -r ".daily.\"$today\" // 0" "$HOME/.claude/mindvaults/state.json")
  if [ "$count" -gt 0 ]; then
    echo "  ✅ 端到端推送成功（今日：$count 条）"
    PASS=$((PASS + 1))
  else
    echo "  ❌ 推送失败（count=0）"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  ❌ 未生成 state.json"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "========================================="
echo "结果：$PASS 通过 / $((PASS + FAIL)) 总计"
[ "$FAIL" -eq 0 ] && echo "✅ 全部通过" || echo "❌ $FAIL 个失败"
exit $FAIL
