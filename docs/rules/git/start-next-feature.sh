#!/usr/bin/env bash
set -e
source "$(dirname "$0")/_common.sh"

NEXT_BRANCH="$1"
if [ -z "$NEXT_BRANCH" ]; then
  echo "사용법: bash docs/rules/git/start-next-feature.sh feature/smartthings-client"
  exit 1
fi

# main 최신화
git checkout main
git pull origin main

# 브랜치가 이미 있으면 checkout + main merge, 없으면 새로 생성
if git show-ref --verify --quiet "refs/heads/$NEXT_BRANCH"; then
  echo "=== 기존 브랜치 $NEXT_BRANCH — main 반영 ==="
  git checkout "$NEXT_BRANCH"
  git merge main -m "chore: merge main into $NEXT_BRANCH"
else
  echo "=== 새 브랜치 $NEXT_BRANCH 생성 ==="
  git checkout -b "$NEXT_BRANCH"
fi

echo ""
echo "현재 브랜치: $(current_branch)"
git log --oneline -3
echo ""
echo "venv 확인: $(which python)"


# 3-1 PR merge 후 → 3-2 시작
# bash docs/rules/git/start-next-feature.sh feature/smartthings-client
# 3-2 PR merge 후 → 3-3 시작
# bash docs/rules/git/start-next-feature.sh feature/oven-command-test