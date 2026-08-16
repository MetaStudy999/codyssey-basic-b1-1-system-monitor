# B1-1 · 2026-08-16 New Baseline

## 목적

B1-1을 기존 급행 수행 상태에서 이어서 PASS 처리하지 않는다. 기존 결과는 `archive/pre-restart-20260816`에 보존하고, 공식 Mission과 Evaluation을 기준으로 필요한 부분만 재사용하여 빠르게 다시 검증한다.

## 현재 상태

- Cycle: `restart-20260816`
- Current Gate: `G1_SOURCE`
- Execution: `ACTIVE`
- Current PASS: 없음
- 과거 상태: Snapshot branch에서만 참고

## 공식 Source

1. `b1-1-mission.pdf` — 최우선 공식 Mission Source
2. `b1-1-mission.md` — PDF 요구사항을 Markdown 구조로 정리한 문서
3. `b1-1-evaluation.md` — 평가 체크리스트
4. `agent-app.zip` — 제공 실행 데이터

## 최소 Mission Clear 체크리스트

### A. 보안·네트워크

- SSH 포트 `20022`
- Root 원격 로그인 차단
- 방화벽 활성화
- 인바운드 TCP `20022`, `15034`만 허용

### B. 사용자·그룹·권한

- 사용자: `agent-admin`, `agent-dev`, `agent-test`
- 그룹: `agent-common`, `agent-core`
- `upload_files`: `agent-common` R/W
- `api_keys`, `/var/log/agent-app`: `agent-core`만 R/W
- ACL/소유권/권한 실제 확인

### C. Agent 실행

- `AGENT_HOME`
- `AGENT_PORT=15034`
- `AGENT_UPLOAD_DIR`
- `AGENT_KEY_PATH`
- `AGENT_LOG_DIR`
- `t_secret.key` 생성
- 일반 계정 실행
- Boot Sequence 5개 `[OK]`
- `Agent READY`
- `0.0.0.0:15034` LISTEN

### D. `monitor.sh`

- Bash로 작성
- `$AGENT_HOME/bin/monitor.sh`
- owner `agent-dev`
- group `agent-core`
- mode `750`
- 프로세스 실패 시 `exit 1`
- TCP 15034 실패 시 `exit 1`
- 방화벽 비활성은 WARNING만 출력
- CPU / MEM / Root DISK 수집
- CPU > 20%, MEM > 10%, DISK > 80% WARNING
- `/var/log/agent-app/monitor.log` 지정 포맷 누적

### E. 자동 실행·로그 관리

- `agent-admin` crontab 매분 실행
- 1~2분 후 로그 자동 증가 확인
- `monitor.log` 최대 `10MB / 10개` 유지

### F. 제출·설명

- 요구사항 수행 내역서
- `monitor.sh` 소스
- 설정/명령/로그/화면 Evidence
- 구현 명령과 선택 이유 설명
- 최소 권한·경고/종료 분리·로그 누적 원리 설명
- 장애 대응 질문 설명

## 이번에는 하지 않는 것

Mission Clear 전에 다음은 우선순위에서 제외한다.

- 보너스 `report.sh`
- 7일 압축 / 30일 삭제 고도화
- 불필요한 리팩터링
- 추가 프레임워크
- 평가와 직접 관련 없는 문서 확장

필수 Clear 후 필요하면 별도 단계에서 수행한다.

## 기존 파일 재사용 규칙

- `KEEP`: Mission PDF/Markdown, Evaluation, 제공 `agent-app.zip`
- `REUSE`: 기존 `monitor.sh`, 설정, 테스트 중 새 요구사항과 다시 검증되는 부분
- `REWRITE`: 현재 상태를 과거 PASS/진도와 섞는 README·상태·실행순서 문서
- `ARCHIVE`: 과거 Evidence와 급행 수행 기록

## 실행 순서

`G1 Source Lock → G2 최소 구현 재사용/보완 → G3 자동 테스트 → G4 평가 기준 리뷰 → G5 실제 Ubuntu Runtime → G6 Evidence → G7 핵심 설명 → G8 Merge/Clear`

검증은 매 파일마다 하지 않고 다음 네 Checkpoint에서 수행한다.

1. Source/설계 확정
2. 구현·자동테스트 완료
3. 실제 Runtime·Evidence 완료
4. Mission Clear

## G1 완료 조건

- Mission/Evaluation의 필수 요구사항을 위 체크리스트로 고정
- 보너스/선택 범위를 필수 Clear와 분리
- 기존 결과가 현재 PASS로 자동 승계되지 않음을 명확히 함
- 다음 단계에서 재사용할 기존 구현을 요구사항 기준으로만 판정
