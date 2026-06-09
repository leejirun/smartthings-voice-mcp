# 개발 상세 기획서
# Phase 3 진입 전 최종 검증 완료
Voice-Controlled SmartThings MCP Server - 음성 명령 기반 스마트 오븐 자동 제어 시스템

--------------------------------------------------------
대상 디바이스
Samsung Bespoke 큐커 오븐 35L 직화오븐 (MC35A8599LE)
Device ID
2650303a-47a0-a3b3-c82d-79963c52f073
DeviceType
Samsung OCF Oven
API 제어 가능 여부
✅ 확인 완료 (2025-06-09 직접 테스트)
개발 언어
Python 3.11+
개발 도구
Cursor / Windsurf (바이브코딩)
현재 진행 단계
Phase 1~2 완료 → Phase 3 (MCP 서버) 시작
--------------------------------------------------------


1. Phase 1~2 완료 결과 (검증 내용)
1.1 SmartThings API 연동 확인
-PAT(Personal Access Token) 발급 및 인증 성공
-Device 목록 조회 API 정상 응답 확인
-오븐 Device ID 확인: 2650303a-47a0-a3b3-c82d-79963c52f073

1.2 오븐 Capability 확인 결과
아래 Capability가 실제 디바이스에서 확인됨 — API 제어 완전 가능
Capability | 용도 |  제어 가능
ovenMode  | 기본 모드 조회/설정 | ✅
ovenSetpoint | 온도 설정 (40~200°C) | ✅
ovenOperatingState | 조리 시간 / 동작 상태 | ✅
samsungce.ovenMode | 삼성 확장 모드 (11종) | ✅
samsungce.cookRecipe | 모드+온도+시간 일괄 전송 | ✅ 핵심
samsungce.definedRecipe | 사전 정의 레시피 실행 | ✅
temperatureMeasurement | 현재 내부 온도 조회 | ✅
remoteControlStatus | 원격 제어 활성화 여부 | ✅
samsungce.doorState | 도어 열림/닫힘 상태 | ✅ 조회

1.3 지원 오븐 모드 목록 (실제 확인)
samsungce.ovenMode capability에서 직접 조회한 실제 지원 모드 11종:
모드명 (API값) | 한국어 | 설명
AirFryer | 에어프라이어 | 열풍 순환으로 기름 없이 튀김
Convection | 컨벡션 | 팬+히터 열풍 오븐
HotBlast | 직화열풍 (핫블라스트) | 직화 + 열풍 동시
Bake | 베이크 | 상하 히터 기본 오븐
Grill |  그릴 | 상단 그릴 열원
MicroWave | 전자레인지 | 마이크로웨이브
Autocook | 자동요리 |  식재료 선택 자동 조리
AutocookCustom | 맞춤 자동요리 | 자동요리 사용자 설정
Fermentation | 발효 | 저온 발효 (빵 반죽 등)
Drying | 건조 | 식품 건조
Deodorization | 탈취 | 조리실 탈취
NoOperation | 대기 | 동작 없음 (기본값)

2. Phase 3 — MCP 서버 상세 설계
2.1 프로젝트 디렉토리 구조
smartthings-voice-mcp/
├── .env                    # 로컬만, Git 제외
├── .env.example            # 커밋
├── .gitignore
├── requirements.txt
├── main.py                 # Day 1: 빈 스텁 또는 pass만
├── server/
│   ├── __init__.py
│   ├── tools.py            # 빈 스텁
│   └── prompts.py          # 빈 스텁
├── smartthings/
│   ├── __init__.py
│   ├── client.py           # 빈 스텁
│   └── models.py           # 빈 스텁
├── history/
│   ├── __init__.py
│   └── store.py            # 빈 스텁
└── tests/
    ├── __init__.py
    └── test_client.py      # 빈 스텁


2.2 MCP Tool 상세 명세
Tool명 | 설명 | 입력 파라미터 | 사용 Capability
get_oven_status | 오븐 현재 상태 전체 조회 |없음 |ovenOperatingStatetemperatureMeasurementremoteControlStatus
set_oven_recipe | 모드+온도+시간 일괄 설정(핵심 Tool) | mode: strtemp: intminutes: int | samsungce.cookRecipe
set_oven_mode | 모드만 단독 설정 | mode: str | samsungce.ovenMode
set_temperature | 온도만 단독 설정 | temp: int (40~200) | ovenSetpoint
set_cook_time | 조리 시간만 단독 설정 | minutes: int (1~120) | ovenOperatingState
stop_oven | 오븐 동작 중단 | 없음 | ovenOperatingState
get_supported_modes | 지원 모드 목록 반환 | 없음 | samsungce.ovenMode
get_cook_history | 과거 조리 기록 조회 | limit: int (기본 5) | 로컬 SQLite
save_cook_history | 조리 설정 히스토리 저장 | mode, temp, minutes, memo | 로컬 SQLite



2.3 핵심 파일별 구현 가이드
a.smartthings/client.py — API 클라이언트
SmartThings REST API 호출을 담당하는 비동기 클라이언트. 모든 API 호출은 이 파일에서만 처리한다.


메서드 | HTTP | 엔드포인트 | 설명
get_status() | GET | /devices/{id}/status | 전체 상태 조회
get_capability_status(cap) | GET | /devices/{id}/components/main/capabilities/{cap}/status | 특정 capability 조회
execute_command(cap, cmd, args) | POST | /devices/{id}/commands | 명령 실행
get_devices() | GET | /devices | 디바이스 목록


b.server/tools.py — MCP Tool 정의
MCP SDK의 @tool 데코레이터로 Tool을 정의한다. LLM이 자연어에서 파악한 파라미터를 받아 SmartThings client를 호출하는 중간 레이어

# 구현 예시 구조@mcp.tool()async def set_oven_recipe(mode: str, temp: int, minutes: int) -> str:    """    오븐 모드, 온도, 조리시간을 한 번에 설정합니다.    mode: AirFryer | Convection | HotBlast | Bake | Grill | MicroWave    temp: 40~200 (섭씨)    minutes: 1~120    """    # 1. 파라미터 유효성 검증    # 2. remoteControlStatus 확인 (원격제어 활성화 여부)    # 3. samsungce.cookRecipe 명령 전송    # 4. 히스토리 저장    # 5. 결과 반환

C.history/store.py — 조리 히스토리
SQLite로 조리 기록을 로컬 저장. '어제 스테이크 설정으로 해줘' 같은 자연어 참조를 가능하게 하는 레이어

컬럼명 | 타입 | 설명
id | INTEGER PK |  자동증가
created_at | DATETIME | 조리 시작 시각
mode | TEXT | 오븐 모드 (예: AirFryer)
temperature |  INTEGER | 온도 (°C)
cook_minutes | INTEGER | 조리 시간 (분)
memo | TEXT | 재료/메모 (예: 닭가슴살)
voice_input | TEXT | 원본 음성 텍스트



3. 개발 환경 설정
3.1 .env 파일 구성
# .env (Git 제외 필수)SMARTTHINGS_PAT=여기에토큰SMARTTHINGS_DEVICE_ID=2650303a-47a0-a3b3-c82d-79963c52f073SMARTTHINGS_BASE_URL=https://api.smartthings.com/v1# 오븐 제한값OVEN_TEMP_MIN=40OVEN_TEMP_MAX=200OVEN_TIME_MAX=120


3.2 requirements.txt
mcp>=1.0.0          # MCP 서버 SDKhttpx>=0.27.0       # 비동기 HTTP 클라이언트pydantic>=2.0.0     # 요청/응답 모델 검증python-dotenv>=1.0  # .env 파일 로드aiosqlite>=0.20.0   # 비동기 SQLitepytest-asyncio      # 비동기 테스트

3.3 MCP 서버 실행 방법
# 설치pip install -r requirements.txt# 실행 (stdio 방식 — Cursor/Claude Desktop 연동)python main.py# Claude Desktop 설정 (claude_desktop_config.json){  "mcpServers": {    "oven-controller": {      "command": "python",      "args": ["C:/path/to/smartthings-oven-mcp/main.py"],      "env": { "SMARTTHINGS_PAT": "토큰" }    }  }}

4. SmartThings API 명령 레퍼런스
개발 중 참고할 실제 API 호출 형식. 모두 PowerShell에서 직접 테스트 완료된 내용 기준

4.1 오븐 모드 설정
POST /v1/devices/{deviceId}/commands{  "commands": [{    "component": "main",    "capability": "samsungce.ovenMode",    "command": "setOvenMode",    "arguments": ["AirFryer"]  }]}

4.2 온도 설정
POST /v1/devices/{deviceId}/commands{  "commands": [{    "component": "main",    "capability": "ovenSetpoint",    "command": "setOvenSetpoint",    "arguments": [180]  }]}

4.3 조리 시작 (cookRecipe — 핵심)
POST /v1/devices/{deviceId}/commands{  "commands": [{    "component": "main",    "capability": "samsungce.cookRecipe",    "command": "setCookRecipe",    "arguments": [{      "ovenMode": "AirFryer",      "ovenSetpoint": 200,      "cookTime": 1500    }]  }]}// cookTime 단위: 초 (25분 = 1500초)

4.4 원격 제어 상태 확인
GET /v1/devices/{deviceId}/components/main/capabilities/remoteControlStatus/status// 응답에서 remoteControlEnabled: true 여부 확인 필수// false이면 SmartThings 앱에서 원격제어 허용 설정 필요

5. 구현 시 주의사항

5.1 원격 제어 활성화 필수
-모든 명령 전송 전 remoteControlStatus 확인 로직 필요
-비활성화 상태면 SmartThings 앱 → 오븐 → 원격 제어 허용 안내 메시지 반환

5.2 cookTime 단위 주의
-samsungce.cookRecipe의 cookTime 파라미터 단위는 초(second)
-사용자가 '25분'이라고 말하면 → 1500으로 변환 필요  -> minutes * 60 = cookTime(초)

5.3 PAT 만료 처리
-PAT는 24시간 만료 → 만료 시 401 에러 발생
-httpx 클라이언트에서 401 응답 감지 시 명확한 에러 메시지 반환 -> 'SmartThings 토큰이 만료됐습니다. .env의 PAT를 재발급해주세요.'

5.4 OCF 디바이스 특성
-이 오븐은 OCF(Open Connectivity Foundation) 디바이스
-일부 명령은 앱 플러그인 레벨에서 처리되어 API 응답과 실제 동작에 딜레이 있을 수 있음
-명령 전송 후 2~3초 대기 후 상태 재조회로 반영 여부 확인 권장

6. Phase 3 개발 순서
순서 | 작업 | 완료 기준
3-1 | 프로젝트 초기 세팅(.env, requirements.txt, 디렉토리 구조) |  .env 로드 및 httpx로 디바이스 조회 성공
3-2 | SmartThings 클라이언트 구현(client.py) | get_status(), execute_command() 동작 확인
3-3 | 오븐 모드 설정 명령 테스트(실제 오븐에 전송) | AirFryer 모드 설정 명령 전송 후 앱에서 확인
3-4 | MCP 서버 기본 구조 구현(main.py, tools.py) |  Claude Desktop에서 MCP 서버 연결 확인
3-5 | 핵심 Tool 구현(set_oven_recipe) | Claude에게 '에어프라이 200도 25분' 말하면 오븐 설정됨
3-6 | 나머지 Tool 구현(상태조회, 중단, 모드목록) | 모든 Tool Claude에서 정상 동작
3-7 | 히스토리 기능 구현(store.py, SQLite) | '저번이랑 똑같이' 명령 처리 가능
3-8 | 에러 처리 강화(401, 원격제어 비활성 등) | 각 에러 케이스 자연어 피드백 반환


7. 포트폴리오 어필 포인트 정리
이직 면접/포트폴리오 제출 시 강조할 기술적 포인트:

a.MCP 프로토콜 이해 및 직접 구현
- 단순 API 래퍼가 아닌 LLM이 사용하는 Tool 설계 관점
b.실제 IoT 디바이스 API 연동 경험
-Capability 조회 → 명령 설계 → 에러 처리 전 과정 직접 수행
c.비동기 백엔드 설계 (asyncio + httpx)
-동기 코드 대비 성능 최적화 관점 설명 가능
d.실 문제를 기술로 해결한 구체적 사례
-'버튼 하나만 누르면 되는' UX 목표를 API 설계로 달성
e.Pydantic 기반 입력 검증
-온도 범위, 모드 enum 검증으로 안정성 확보
