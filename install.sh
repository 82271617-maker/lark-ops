#!/usr/bin/env bash
# lark-ops 安装：把技能拷进 DSH 技能目录，并检查 lark-cli 是否就绪
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SKILL_SRC="$REPO_DIR/.agents/skills/lark-ops"
SKILL_DEST="${SKILL_DEST:-$HOME/.dsh/skills}"

echo "==> 仓库目录: $REPO_DIR"
[ -d "$SKILL_SRC" ] || { echo "!! 找不到技能目录: $SKILL_SRC" >&2; exit 1; }

echo "==> 安装技能到 $SKILL_DEST"
mkdir -p "$SKILL_DEST"
rm -rf "$SKILL_DEST/lark-ops"
cp -R "$SKILL_SRC" "$SKILL_DEST/lark-ops"

echo "==> 检查 lark-cli"
if command -v lark-cli >/dev/null 2>&1; then
  lark-cli --version | sed 's/^/    /'
  echo "    提示：确认已登录 → lark-cli auth status（要看到 user: ready）"
else
  echo "    !! 未安装 lark-cli，执行：npm i -g @larksuite/cli"
fi

echo
echo "✅ 安装完成：$SKILL_DEST/lark-ops/SKILL.md"
echo "   开新会话后，说「读一下这个飞书文档」即可触发"
