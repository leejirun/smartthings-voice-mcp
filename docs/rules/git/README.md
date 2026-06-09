# Git 워크플로 스크립트 (Git Bash)

## 매번 터미널 시작
→ docs/rules/startTerminal.md 참고

## 단계별 흐름

| PRD | 브랜치 | 작업 끝나면 | PR merge 후 |
|-----|--------|-------------|-------------|
| 3-1 | feature/project-setup | steps/after-3-1.sh | start-next-feature.sh smartthings-client |
| 3-2 | feature/smartthings-client | steps/after-3-2.sh | start-next-feature.sh oven-command-test |
| 3-3 | feature/oven-command-test | steps/after-3-3.sh | (Day 2로) |

## 공통 명령
- 작업 마무리(커밋+push): `bash docs/rules/git/finish-feature.sh "커밋 메시지"`
- main 최신화: `bash docs/rules/git/sync-main.sh`
- 다음 브랜치 시작: `bash docs/rules/git/start-next-feature.sh <브랜치명>`


[3-1 작업 중 — feature/project-setup]
  ↓
bash docs/rules/git/steps/after-3-1.sh
  ↓ GitHub PR merge
  ↓
bash docs/rules/git/start-next-feature.sh feature/smartthings-client
[3-2 작업 중 — feature/smartthings-client]
  ↓
bash docs/rules/git/steps/after-3-2.sh
  ↓ PR merge
  ↓
bash docs/rules/git/start-next-feature.sh feature/oven-command-test
[3-3 작업 중 — feature/oven-command-test]
  ↓
bash docs/rules/git/steps/after-3-3.sh
  ↓ PR merge → Day 2