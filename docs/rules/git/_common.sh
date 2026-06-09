#!/usr/bin/env bash
# 공통 설정 — Git Bash 전용

# 프로젝트 루트로 이동 (스크립트 위치 기준)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT" || exit 1

# venv 활성화
if [ -f ".venv/Scripts/activate" ]; then
  source .venv/Scripts/activate
else
  echo "[경고] .venv 없음. python -m venv .venv 후 pip install -r requirements.txt"
fi

# 현재 브랜치 출력
current_branch() {
  git branch --show-current
}

# main인지 확인
require_not_main() {
  if [ "$(current_branch)" = "main" ]; then
    echo "[에러] main 브랜치에서는 이 작업을 하지 마세요. feature 브랜치로 checkout 하세요."
    exit 1
  fi
}

# .env가 커밋 대상인지 검사
check_env_not_staged() {
  if git status --porcelain | grep -qE '^[AMDR].*\.env$|^\?\? .*\.env$'; then
    echo "[에러] .env 가 git 에 올라가려 합니다. git check-ignore -v .env 확인"
    exit 1
  fi
}

# smoke_test 실행 (3-1 검증)
run_smoke_test() {
  echo "=== smoke_test 실행 ==="
  python scripts/smoke_test.py || exit 1
}