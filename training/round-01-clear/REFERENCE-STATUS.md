# B1-1 R01 — Reference Status

## 판정

**Reference Build: CORE READY**

**Runtime Mission: 🟡 ACTIVE / CLEAR 아님**

이 판정은 실제 Ubuntu/WSL Runtime 성공을 의미하지 않습니다. Phase A에서 공식 Mission/Evaluation을 수행할 기준 구현·학습 경로·검증 절차·Evidence 구조가 닫혔다는 의미입니다.

## Source of Truth

- `b1-1-mission.pdf`
- `b1-1-mission.md`
- `b1-1-evaluation.md`
- `agent-app.zip`

## 자체감사에서 보완한 핵심 사항

1. **공유 디렉터리 상위 권한 문제 해결**
   - Golden Path를 `AGENT_HOME=/opt/agent-app`으로 고정
   - parent는 `agent-common` traverse, upload는 common R/W, api/log는 core R/W
   - `runuser`로 실제 역할별 접근을 검증

2. **Process false-positive 방지**
   - 제공 바이너리를 canonical `agent-app`으로 설치
   - `pgrep -x agent-app` 사용
   - `/opt/agent-app/...` 경로 문자열을 프로세스로 오인하지 않도록 개선

3. **SSH lockout 위험 감소**
   - UFW active 시 20022를 먼저 추가 허용
   - `sshd -t` + `sshd -T`를 reload 전에 확인
   - 새 20022 세션 성공 전 기존 SSH 경로 제거 금지

4. **Firewall '두 포트만' 검증 강화**
   - UFW active
   - default deny incoming
   - 20022/tcp, 15034/tcp 존재
   - 그 외 `ALLOW IN`이 있으면 verify FAIL

5. **Warning/Failure 안전 재현**
   - Process failure: `AGENT_PROCESS_NAME` override
   - Port failure: `AGENT_PORT` override
   - Warning: threshold override
   - 실제 Agent/Firewall/디스크 상태를 위험하게 변경하지 않고 분기 검증

6. **10MB / 10개 로그 관리 검증**
   - 기본값은 공식 요구사항 유지
   - `/tmp` 격리 경로의 10MB sparse file로 실제 회전 테스트
   - active log 포함 전체 10개 이하 확인

7. **Secret 안전성**
   - Reference 파일에 실제 Secret 값 추가 금지
   - Runtime에서 `read -s`로 직접 입력
   - 검증은 `test -s`, `stat`만 사용

## Phase A 준비 완료

- [x] 공식 요구사항 분석
- [x] Evaluation 분석
- [x] Reference Complete Path
- [x] STEP 01~15 Beginner Guide
- [x] Bash `monitor.sh`
- [x] setup / verify / reset
- [x] Requirement → Implementation → Verification → Evidence mapping
- [x] Evaluation Q&A
- [x] Evidence 수집 계획
- [x] Secret-safe 설계
- [x] 정상/실패/Warning/회전/cron 검증 절차
- [x] 자체감사에서 발견한 BLOCKER/MAJOR 설계 문제 보완

## Phase C에서만 PASS 처리할 항목

- [ ] 실제 OS/architecture
- [ ] 실제 archive 내부/바이너리 선택
- [ ] 실제 SSH 20022 + Root remote block + 새 세션
- [ ] 실제 UFW 최종 정책
- [ ] 실제 역할별 effective permission
- [ ] 실제 Agent Boot 5/5 + READY
- [ ] 실제 TCP 15034
- [ ] 실제 monitor 정상/실패/Warning
- [ ] 실제 10MB/10개 회전
- [ ] 실제 cron 1~2분 로그 증가
- [ ] verify `0 FAIL`
- [ ] 실제 Evidence
- [ ] `✅ CLEAR`

## Phase A Gate 결과

- BLOCKER: **0**
- MAJOR: **0**
- Runtime-required: **분리 완료**
- 허위 Runtime PASS: **없음**

따라서 B1-1은 Phase A 기준 **CORE READY**로 분류합니다.
