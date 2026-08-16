# B1-1 New Baseline · G2 Build Audit

- Cycle: `restart-20260816`
- Gate: `G2_BUILD`
- Rule: 기존 구현을 자동 승계하지 않고 공식 필수 체크리스트와 다시 대조한다.

## 재사용 판정

| 항목 | 판정 | 근거/조치 |
|---|---|---|
| `scripts/monitor.sh` 기본 구조 | REUSE + REWRITE | 프로세스/포트 실패, 리소스 수집, WARNING, 로그 포맷 구조는 재사용. 제공 Agent binary 이름 인식과 로그 append 실패 처리를 보완 |
| `config/agent.env.example` | REUSE + REWRITE | 공식 5개 환경변수 유지, 실제 감시 대상 프로세스 패턴을 명시 |
| `config/crontab.example` | REUSE | `agent-admin`이 매분 `$AGENT_HOME/bin/monitor.sh` 실행하는 구조가 필수 요구와 일치 |
| `config/agent-monitor.logrotate` | REUSE + REWRITE | 10MB 정책 유지. 전체 최대 10개가 되도록 current + rotated 9로 조정하고 새 로그를 `0660`으로 생성 |
| SSH / UFW / users / groups / ACL 문서 | REUSE | G5 실제 Ubuntu에서 새 기준으로 다시 적용·검증할 실행 가이드로 사용 |
| 과거 Runtime/Evidence | ARCHIVE | 현재 PASS 근거로 자동 승계하지 않음 |
| `report.sh`, `archive-logs.sh` | DEFER | 공식 보너스 범위이므로 필수 Mission Clear 이후 검토 |

## 새 기준에서 발견한 주요 보완

### 1. 제공 Agent 파일명과 monitor 기본 패턴 불일치

기존 기본값은 `agent_app.py`만 찾았다. 공식 제공 데이터에는 Linux x86/arm64 실행 파일이 있으므로 기본 패턴이 제공 바이너리도 인식하도록 수정했다. 실제 배포에서는 `AGENT_PROCESS_PATTERN`을 환경파일로 명시할 수 있다.

### 2. 로그 append 실패가 정상 종료로 보일 가능성

기존 스크립트는 로그 append가 실패해도 마지막 `exit 0`에 도달할 수 있었다. 기존 로그 파일 쓰기 권한과 실제 append 실패를 명시적으로 검사하여 `exit 2`로 종료하도록 수정했다.

### 3. 로그 파일 개수

`rotate 10`은 current file과 합치면 11개가 될 수 있으므로 공식 `최대 10개`를 보수적으로 만족하도록 `rotate 9`로 수정했다.

### 4. agent-core R/W 의도

logrotate 신규 파일을 `0660 agent-admin agent-core`로 생성하여 그룹 R/W 정책과 일치시켰다.

## 정적 검증

`tests/new-baseline-static.sh`가 다음을 확인한다.

- 모든 Bash script 문법
- Agent 필수 환경변수
- monitor mandatory threshold/health/logging contract
- cron 매분 실행
- logrotate 10MB / 총 10개 정책
- 새 Cycle/G1 Source Lock 연결

GitHub Actions의 `B1-1 New Baseline Checks`에서 동일 검사를 실행한다.

## G2 판정 규칙

CI가 통과하면 저장소 수준 필수 구현/설정은 `IMPLEMENTED`로 인정한다. 이것은 실제 Ubuntu 구성 완료를 의미하지 않는다. SSH/UFW/IAM/ACL/Agent/cron/logrotate 실제 상태는 G5 Runtime에서 별도 검증한다.
