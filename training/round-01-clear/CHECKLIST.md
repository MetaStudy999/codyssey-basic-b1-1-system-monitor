# B1-1 Round 01 — Mission Clear Checklist

> 상태는 `⬜ NOT STARTED`, `🟡 ACTIVE`, `⛔ BLOCKED`, `✅ CLEAR`만 사용합니다. **Reference Build가 완료되어도 실제 Runtime/Evidence 전에는 CLEAR가 아닙니다.**

## 현재 상태

- Training Round: **R01 — CLEAR**
- Mission: **B1-1**
- Runtime 상태: **🟡 ACTIVE**
- Phase A Reference 판정: **CORE READY**
- Golden Path: **Ubuntu 22.04 LTS 또는 동등 Linux + systemd + UFW + Bash**
- `AGENT_HOME`: **`/opt/agent-app`**

## A. Source / Reference Build

- [x] `b1-1-mission.pdf` 기준 요구사항 분석
- [x] `b1-1-mission.md` 기준 요구사항 분석
- [x] `b1-1-evaluation.md` 평가 항목 분석
- [x] `agent-app.zip` 제공 여부 확인
- [x] 실제 archive 내부/CPU 선택은 Runtime 전용으로 분리
- [x] 필수/보너스 요구사항 분리
- [x] Reference Complete Path 설계
- [x] `BEGINNER-GUIDE.md` STEP 01~15 전체 구체화
- [x] 각 Runtime Step을 ①~⑩ 구조로 작성
- [x] `monitor.sh` 기준 구현
- [x] `environment/setup.sh` 재현 보조
- [x] `environment/verify.sh` 검증 전용
- [x] `environment/reset.sh` 보수적 reset
- [x] `docs/requirements-mapping.md`
- [x] `docs/evaluation-qa.md`
- [x] `evidence/README.md`
- [x] 실제 Secret 값을 Reference 산출물에 새로 저장하지 않음
- [x] 실제 실행하지 않은 항목에 허위 PASS/CLEAR 없음
- [x] Reference Build 자체감사 완료

## B. Reference 구현 자체감사

### B1. SSH / Firewall 설계

- [x] SSH 변경 전 baseline/backup 절차
- [x] UFW active 환경에서 20022 사전 허용 후 SSH 전환
- [x] `sshd -t` 문법 검사 후 적용
- [x] `sshd -T` effective config 확인 후 reload
- [x] 새 20022 실제 접속 전 기존 SSH 경로 제거 금지
- [x] 최종 UFW는 default deny incoming + 20022/15034만 허용하도록 설계
- [x] verify가 extra inbound ALLOW 규칙을 FAIL 처리

### B2. 사용자 / 그룹 / 권한 설계

- [x] `agent-admin`, `agent-dev`, `agent-test`
- [x] `agent-common` = admin/dev/test
- [x] `agent-core` = admin/dev
- [x] `/opt/agent-app`을 공유 tree Golden Path로 선택
- [x] `upload_files` = agent-common R/W
- [x] `api_keys`, `/var/log/agent-app` = agent-core R/W
- [x] setgid + default ACL 설계
- [x] `agent-test`의 민감 디렉터리 접근 차단 설계
- [x] verify가 `runuser ... test`로 실제 effective access 확인

### B3. Agent 환경 설계

- [x] `uname -m` + `unzip -l` + `file`로 실제 archive 선택 절차
- [x] 선택 바이너리를 canonical `/opt/agent-app/bin/agent-app`으로 설치하도록 설계
- [x] `AGENT_HOME=/opt/agent-app`
- [x] `AGENT_PORT=15034`
- [x] `AGENT_UPLOAD_DIR=/opt/agent-app/upload_files`
- [x] `AGENT_KEY_PATH=/opt/agent-app/api_keys/t_secret.key`
- [x] `AGENT_LOG_DIR=/var/log/agent-app`
- [x] `AGENT_PROCESS_NAME=agent-app`
- [x] Secret은 `read -s`로 Runtime에서만 입력
- [x] Secret 검증은 존재/owner/group/mode만 확인

### B4. `monitor.sh`

- [x] Bash 전용
- [x] canonical process name을 `pgrep -x`로 확인해 path false-positive 방지
- [x] Process 미존재 `exit 1`
- [x] TCP 15034 미LISTEN `exit 1`
- [x] Firewall 상태는 Warning-only
- [x] Agent CPU/MEM 수집
- [x] Root filesystem DISK_USED 수집
- [x] 기본 CPU Warning `>20%`
- [x] 기본 MEM Warning `>10%`
- [x] 기본 DISK_USED Warning `>80%`
- [x] 테스트에서만 threshold override 가능
- [x] `/var/log/agent-app/monitor.log` append
- [x] 공식 로그 포맷
- [x] 기본 10MB / 전체 10개 회전
- [x] 회전 로직의 max file count 동적 계산

### B5. Runtime 검증 설계

- [x] Process failure를 실제 Agent 중단 없이 override로 재현
- [x] Port failure를 미사용 검사 포트 override로 재현
- [x] Warning을 threshold override로 안전하게 재현
- [x] 로그 회전은 `/tmp` 격리 디렉터리에서 실제 10MB 경계로 검증
- [x] cron Before/After 로그 증가 검증
- [x] `verify.sh`는 sudo로 읽기/권한검사만 하고 시스템 설정은 변경하지 않음
- [x] verify 최종 형식 `[PASS] / [FAIL] / Result`

## C. 공식 필수 요구사항 — Phase C Runtime에서 실제 확인

### C1. Baseline

- [ ] OS / Version
- [ ] CPU Architecture
- [ ] WSL/VM/일반 Linux
- [ ] systemd
- [ ] 현재 SSH/UFW/포트
- [ ] 기존 사용자/그룹
- [ ] Git branch/working tree/remote

### C2. SSH / UFW

- [ ] SSH 설정 백업
- [ ] `sshd -t` 성공
- [ ] effective `port 20022`
- [ ] effective `permitrootlogin no`
- [ ] 실제 TCP 20022 LISTEN
- [ ] 실제 새 SSH 세션 성공
- [ ] UFW active
- [ ] default deny incoming
- [ ] 20022/tcp ALLOW IN
- [ ] 15034/tcp ALLOW IN
- [ ] 그 외 불필요한 ALLOW IN 없음

### C3. 사용자 / 그룹 / 권한

- [ ] 사용자 3개 실제 존재
- [ ] 그룹 2개 실제 존재
- [ ] admin/dev = common+core
- [ ] test = common, not core
- [ ] `/opt/agent-app` 구조
- [ ] upload_files 세 계정 R/W
- [ ] api_keys admin/dev R/W, test 차단
- [ ] log dir admin/dev R/W, test 차단
- [ ] `ls -ld`, `getfacl`, `runuser test` 결과 확보

### C4. 제공 Agent

- [ ] archive 내부 파일 실제 확인
- [ ] CPU와 실행 파일 일치
- [ ] canonical `agent-app` 설치
- [ ] env.sh 실제 적용
- [ ] Secret 파일 실제 준비, 값 미노출
- [ ] root 아닌 계정 실행
- [ ] Boot Sequence 5단계 `[OK]`
- [ ] `Agent READY`
- [ ] `0.0.0.0:15034` 실제 LISTEN (`[::]:15034` 또는 임의의 `:15034`만으로 PASS 처리하지 않음)

### C5. monitor / log / cron

- [ ] monitor Runtime owner `agent-dev`
- [ ] group `agent-core`
- [ ] mode `750`
- [ ] agent-admin 실행 가능
- [ ] 정상 실행 `exit=0`
- [ ] Process failure `exit=1`
- [ ] Port failure `exit=1`
- [ ] Warning 분기 후 `exit=0`
- [ ] monitor.log 지정 포맷 누적
- [ ] 실제 10MB 회전
- [ ] 전체 monitor log 파일 10개 이하
- [ ] agent-admin cron 매분 등록
- [ ] 1~2분 후 실제 monitor.log 증가

### C6. 통합 verify

- [ ] `sudo bash training/round-01-clear/environment/verify.sh`
- [ ] `Result: N PASS / 0 FAIL`

## D. Evaluation 설명형 항목

- [x] `pgrep -x`/`ps`와 `ss` 선택 이유 기준 답안
- [x] CPU/MEM/DISK 추출·파싱 기준 답안
- [x] owner/group/mode/ACL/cron 실행권한 기준 답안
- [x] 10MB/10개 회전 기준 답안
- [x] SSH/Root 위협 모델 기준 답안
- [x] agent-core 최소 권한 기준 답안
- [x] Health failure vs Warning 기준 답안
- [x] `>` vs `>>` 기준 답안
- [x] Nginx 전환 기준 답안
- [x] Process는 있으나 Port가 없는 장애 확인 순서
- [x] 로그 폭증/디스크 고갈 대응
- [ ] 사용자가 실제 Runtime 결과를 근거로 자신의 말로 설명

## E. Evidence

`Requirement → Implementation → Verification → Evidence`

- [x] Evidence 수집 계획 준비
- [x] Requirement mapping 준비
- [ ] SSH effective config / LISTEN / 새 접속 Evidence
- [ ] UFW 전체 정책 Evidence
- [ ] 계정/그룹/effective permission Evidence
- [ ] Agent Boot 5/5 + READY Evidence
- [ ] 15034 LISTEN Evidence
- [ ] monitor 정상/실패/Warning Evidence
- [ ] monitor.log 포맷 Evidence
- [ ] 10MB/10개 회전 Evidence
- [ ] cron Before/After Evidence
- [ ] verify 0 FAIL Evidence
- [ ] Evidence Secret 검토 완료

## F. Final CLEAR Gate

- [ ] 공식 Mission 필수 요구사항 누락 없음
- [ ] 공식 Evaluation 요구사항 누락 없음
- [ ] 실제 Runtime 완료
- [ ] 자동 검증 0 FAIL
- [ ] 실제 Evidence 완료
- [ ] Secret 노출 없음
- [ ] 설명형 평가 대응 가능
- [ ] **✅ B1-1 MISSION CLEAR**

**운영 규칙:** B1-1이 `✅ CLEAR`가 되기 전에는 B1-2 Runtime을 시작하지 않습니다. Phase A Reference Build는 후속 미션까지 선제 준비할 수 있습니다.
