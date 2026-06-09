#!/usr/bin/env bash
set -e
source "$(dirname "$0")/_common.sh"

echo "=== main 최신화 ==="
git checkout main
git pull origin main

echo ""
echo "main 최신 커밋:"
git log --oneline -3
echo ""
echo "완료. 다음: start-next-feature.sh <브랜치명>"