#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> コンテナ起動中..."
docker compose up -d

echo "==> Claude Code CLI を起動します（初回はログインを求められます）"
exec docker compose exec app claude
