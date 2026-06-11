#!/bin/bash
set -e

SKILL_DIR="${HOME}/.claude/skills/mindvaults-glean"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Installing mindvaults-glean to ${SKILL_DIR}"

mkdir -p "${SKILL_DIR}"

cp "${SCRIPT_DIR}/SKILL.md" "${SKILL_DIR}/"
cp -r "${SCRIPT_DIR}/hooks" "${SKILL_DIR}/"
cp -r "${SCRIPT_DIR}/commands" "${SKILL_DIR}/"
cp -r "${SCRIPT_DIR}/references" "${SKILL_DIR}/"
cp -r "${SCRIPT_DIR}/.claude-plugin" "${SKILL_DIR}/"

echo "==> Done! Restart Claude Code and run /mindvaults on to get started."
