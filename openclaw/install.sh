#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Installing mindvaults OpenClaw Skill"

if ! command -v openclaw &> /dev/null; then
    echo "ERROR: openclaw CLI not found. Please install OpenClaw first."
    exit 1
fi

openclaw skills install "${SCRIPT_DIR}"

echo ""
echo "==> Done! Next steps:"
echo "  1. Edit ~/.openclaw/openclaw.json to configure MCP server"
echo "     (see config/openclaw.json.template for reference)"
echo "  2. Restart gateway: pkill -f 'openclaw gateway' && openclaw gateway --port 18789 &"
