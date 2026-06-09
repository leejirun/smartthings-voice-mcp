#!/usr/bin/env bash
set -e
source "$(dirname "$0")/_common.sh"

COMMIT_MSG="$1"
if [ -z "$COMMIT_MSG" ]; then
  echo "사용법: bash docs/rules/git/finish-feature.sh \"feat: 메시지\""
  exit 1
fi

require_not_main
check_env_not_staged

BRANCH="$(current_branch)"

echo "=== 상태 확인 ==="
git status

read -p "위 내용으로 commit + push 할까요? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
  echo "취소됨"
  exit 0
fi

git add .
git commit -m "$COMMIT_MSG"
git push -u origin "$BRANCH"

echo ""
echo "=== push 완료 ==="
echo "브랜치: $BRANCH"
echo "다음: GitHub에서 PR 생성 → main 으로 merge"
echo "  gh pr create --title \"$COMMIT_MSG\" --body \"...\""