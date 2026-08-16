# B1-1 R01 — Reference Build

## 목적

이 문서는 B1-1의 **Reference Complete Version** 준비 상태를 기록합니다.

Reference Build는 실제 Ubuntu/WSL에서 미션을 통과했다고 주장하는 단계가 아닙니다. 실제 Runtime, sudo 작업, SSH/UFW 적용, 프로세스 실행, 포트 LISTEN, cron 자동 실행, Evidence 확보는 Phase C에서 별도로 수행합니다.

## Source of Truth

1. `b1-1-mission.pdf`
2. `b1-1-mission.md`
3. `b1-1-evaluation.md`
4. `agent-app.zip`

공식 원본은 수정하지 않습니다.

## R01 Golden Path

- Ubuntu 22.04 LTS 또는 동등 Linux
- systemd + OpenSSH Server
- UFW
- Bash
- `AGENT_HOME=/opt/agent-app`
- 제공 archive는 Runtime에서 CPU를 확인한 뒤 선택 파일을 canonical `agent-app`으로 설치

`/opt/agent-app`을 사용하는 이유는 `upload_files`를 agent-common 전체가 사용하면서 `api_keys`와 로그는 agent-core만 사용하도록 상위 경로의 effective permission까지 명확하게 제어하기 위해서입니다.

## Reference Complete Path

1. Source/Evaluation 분석
2. Baseline 확인
3. Golden Path/Prerequisites
4. SSH 20022 안전 전환
5. UFW 20022/15034-only 정책
6. 계정/그룹/ACL/effective permission
7. Agent archive/환경변수/Secret(local only)
8. Agent Boot 5/5 + READY + 15034
9. `monitor.sh` 설치/정상 실행
10. Process/Port failure `exit 1`
11. CPU/MEM/DISK + Warning
12. `monitor.log` 공식 포맷
13. 10MB/10개 실제 회전 테스트
14. `agent-admin` cron 매분 + Before/After
15. 통합 `verify.sh`
16. Requirement → Implementation → Verification → Evidence
17. Evaluation Q&A
18. Secret 점검
19. CLEAR Gate

## Phase A 준비 결과

- [x] 공식 요구사항 분석
- [x] Evaluation 분석
- [x] STEP 01~15 `BEGINNER-GUIDE.md`
- [x] `CHECKLIST.md` Reference/Runtime 분리
- [x] `monitor.sh` 기준 구현
- [x] `environment/README.md`
- [x] `environment/prerequisites.md`
- [x] `environment/versions.md`
- [x] 재현 보조 `setup.sh`
- [x] 검증 전용 `verify.sh`
- [x] 보수적 `reset.sh`
- [x] `docs/requirements-mapping.md`
- [x] `docs/evaluation-qa.md`
- [x] `evidence/README.md`
- [x] `REFERENCE-STATUS.md`
- [x] 실제 Secret 값을 Reference 파일에 새로 저장하지 않음
- [x] 실제 Runtime 미수행 항목을 PASS/CLEAR로 표시하지 않음

## 자체감사에서 발견하고 수정한 주요 문제

### 1. 공유 디렉터리 상위 경로

한 사용자 홈 아래에 `AGENT_HOME`을 두고 root를 core-only로 만들면 `agent-test`가 common upload 디렉터리까지 traverse하지 못할 수 있습니다. Golden Path를 `/opt/agent-app`으로 정하고 parent는 common traverse, upload는 common R/W, api/log는 core R/W로 분리했습니다.

### 2. Process 오인 가능성

광범위한 `pgrep -f 'agent-app...'`는 monitor 경로 자체의 `agent-app` 문자열을 잘못 잡을 수 있습니다. 제공 실행 파일을 canonical `agent-app`으로 설치하고 `pgrep -x`를 사용하도록 변경했습니다.

### 3. SSH/UFW 순서

UFW가 이미 active인 서버에서 sshd 포트부터 바꾸면 20022가 Firewall에 막힐 수 있습니다. 20022 사전 허용 → 설정/문법/effective 확인 → reload → 새 세션 → Firewall 최종 정리 순서로 수정했습니다.

### 4. Firewall strict verification

`verify.sh`가 두 필수 포트의 존재만 보는 것이 아니라 default deny incoming과 extra `ALLOW IN` 부재까지 확인하도록 강화했습니다.

### 5. 실제 권한 검증

`ls/getfacl`뿐 아니라 `runuser -u <role> -- test ...`를 사용해 admin/dev/test의 effective access를 직접 확인합니다.

### 6. 안전한 실패/Warning/회전 테스트

실제 서비스를 중단하거나 디스크를 채우는 대신 환경변수 override와 `/tmp` 격리 로그를 이용해 Process/Port failure, Warning, 10MB/10개 회전을 재현하도록 설계했습니다.

## Phase C Runtime에서만 완료할 것

- [ ] 실제 OS/버전/CPU 재검증
- [ ] `agent-app.zip` 내부 파일과 실제 실행 바이너리 확인
- [ ] 실제 SSH 20022/Root 차단/새 접속
- [ ] 실제 UFW 최종 정책
- [ ] 실제 계정/그룹/effective permission
- [ ] 실제 Agent Boot 5/5 + `Agent READY`
- [ ] 실제 `15034` LISTEN
- [ ] 실제 `monitor.sh` 정상/실패/Warning
- [ ] 실제 10MB/10개 회전
- [ ] 실제 cron 자동 로그 증가
- [ ] `verify.sh` 실제 `0 FAIL`
- [ ] 실제 Evidence
- [ ] 최종 `✅ CLEAR`

## 현재 판정

**Reference Build: CORE READY**

**Mission Runtime 상태: 🟡 ACTIVE / CLEAR 아님**

다음 Phase A 작업은 B1-2의 자체감사/정합성 마감입니다. B1-2 Runtime은 B1-1 CLEAR 이후에 시작합니다.
