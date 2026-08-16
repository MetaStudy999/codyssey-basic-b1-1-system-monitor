# B1-1 Round 01 — Mission Clear Checklist

> 상태는 `⬜ NOT STARTED`, `🟡 ACTIVE`, `⛔ BLOCKED`, `✅ CLEAR`만 사용합니다. 실제 실행·검증·Evidence가 끝나기 전에는 CLEAR로 판정하지 않습니다.

## 현재 상태

- Training Round: **R01 — CLEAR**
- Mission: **B1-1**
- Mission 상태: **🟡 ACTIVE**
- 현재 운영 모드: **Phase A — REFERENCE BUILD**

Reference Build는 기준 구현과 학습·검증 자료를 미리 준비하는 단계입니다. 아래 공식 Runtime 요구사항은 실제 환경에서 확인하기 전까지 체크하지 않습니다.

## A. Source

- [x] 공식 `b1-1-mission.pdf` 확인
- [x] 공식 `b1-1-mission.md` 확인
- [x] 공식 `b1-1-evaluation.md` 확인
- [x] 공식 `agent-app.zip` 존재 확인
- [ ] `agent-app.zip` 내부 파일/CPU 아키텍처 안전 확인
- [x] 필수 요구사항과 보너스 요구사항 분리
- [x] Reference Complete Path 설계

## A-1. Reference Build 준비물

- [x] `REFERENCE-BUILD.md`
- [x] 기준 `monitor.sh`
- [x] `environment/README.md`
- [x] `environment/prerequisites.md`
- [x] `environment/versions.md`
- [x] 재현 보조 `environment/setup.sh`
- [x] 검증 전용 `environment/verify.sh`
- [x] 보수적 `environment/reset.sh`
- [x] `docs/requirements-mapping.md`
- [x] `docs/evaluation-qa.md`
- [x] `evidence/README.md`
- [x] 실제 Secret 값을 Reference 파일에 저장하지 않음
- [ ] `BEGINNER-GUIDE.md` 전체 Runtime Step 구체화
- [ ] Reference Build 자체 검토 완료

## B. 공식 필수 요구사항 — Runtime에서 검증

### B1. SSH / Firewall

- [ ] SSH 포트 `20022` 설정
- [ ] Root 원격 로그인 차단
- [ ] SSH 설정 변경 전 원본 백업
- [ ] SSH 설정 문법 검사
- [ ] `20022` 실제 LISTEN 확인
- [ ] 새 SSH 접속 경로 확인 후 기존 경로 정리
- [ ] UFW 또는 firewalld 활성화
- [ ] 인바운드 `20022/tcp`, `15034/tcp`만 허용
- [ ] Firewall 실제 상태 검증

### B2. 사용자 / 그룹 / 권한

- [ ] `agent-admin` 생성 및 역할 확인
- [ ] `agent-dev` 생성 및 역할 확인
- [ ] `agent-test` 생성 및 역할 확인
- [ ] `agent-common` 생성 및 admin/dev/test 구성
- [ ] `agent-core` 생성 및 admin/dev 구성
- [ ] `$AGENT_HOME` 구성
- [ ] `$AGENT_HOME/upload_files` 구성
- [ ] `$AGENT_HOME/api_keys` 구성
- [ ] `/var/log/agent-app` 구성
- [ ] `upload_files`가 `agent-common` R/W 정책 충족
- [ ] `api_keys`가 `agent-core` 전용 R/W 정책 충족
- [ ] `/var/log/agent-app`가 `agent-core` 전용 R/W 정책 충족
- [ ] `id`, `ls`, `getfacl` 등으로 실제 권한 확인

### B3. Agent 실행 환경

- [ ] CPU 아키텍처에 맞는 제공 Agent 실행 파일 확인
- [ ] `AGENT_HOME` 설정
- [ ] `AGENT_PORT=15034` 설정
- [ ] `AGENT_UPLOAD_DIR` 설정
- [ ] `AGENT_KEY_PATH` 설정
- [ ] `AGENT_LOG_DIR` 설정
- [ ] 실제 Secret은 GitHub/채팅/로그/Evidence에 노출하지 않음
- [ ] Agent를 root가 아닌 일반 사용자로 실행
- [ ] Boot Sequence 5단계 `[OK]`
- [ ] `Agent READY` 확인
- [ ] `0.0.0.0:15034` LISTEN 확인

### B4. `monitor.sh`

- [ ] Runtime 경로 `$AGENT_HOME/bin/monitor.sh`
- [ ] 소유자 `agent-dev`
- [ ] 그룹 `agent-core`
- [ ] 권한 `750`
- [x] Reference 구현은 Bash로 작성
- [x] Reference 구현에 대상 프로세스 Health Check 포함
- [x] Reference 구현에 프로세스 비정상 `exit 1` 포함
- [x] Reference 구현에 TCP `15034` Health Check 포함
- [x] Reference 구현에 포트 비정상 `exit 1` 포함
- [x] Reference 구현에 Firewall 비활성 `[WARNING]` 후 계속 실행 포함
- [x] Reference 구현에 CPU 사용률 수집 포함
- [x] Reference 구현에 MEM 사용률 수집 포함
- [x] Reference 구현에 Root filesystem DISK 사용률 수집 포함
- [x] Reference 구현에 CPU `> 20%` WARNING 포함
- [x] Reference 구현에 MEM `> 10%` WARNING 포함
- [x] Reference 구현에 DISK_USED `> 80%` WARNING 포함
- [x] Reference 구현에 `/var/log/agent-app/monitor.log` 누적 포함
- [x] Reference 구현에 공식 로그 포맷 포함
- [x] Reference 구현에 로그 관리 `10MB / 10개` 포함
- [ ] 위 `monitor.sh` 항목 실제 Runtime 동작 검증

### B5. cron

- [ ] `agent-admin` crontab에 매분 실행 등록
- [ ] cron 실행 권한 확인
- [ ] 등록 후 1~2분 내 `monitor.log` 실제 증가 확인

## C. Baseline — Runtime 시작 시

> 읽기 전용 확인 단계입니다. 시스템 변경을 하지 않습니다.

- [ ] OS / Version 확인
- [ ] CPU Architecture 확인
- [ ] WSL 여부 확인
- [ ] 현재 사용자 / 그룹 확인
- [ ] sudo 상태 확인
- [ ] systemd 상태 확인
- [ ] SSH 설치/서비스 상태 확인
- [ ] `22 / 20022 / 15034` LISTEN 상태 확인
- [ ] UFW/firewalld 상태 확인
- [ ] 기존 `agent-admin/dev/test` 상태 확인
- [ ] 기존 `agent-common/core` 상태 확인
- [ ] Git branch 확인
- [ ] Git working tree 확인
- [ ] Git remote 확인
- [ ] Baseline 결과를 `[PASS]/[FAIL]` 형식으로 판정

## D. Evaluation — 항목 1: 요구사항 구현 및 동작

- [ ] SSH `20022` + Root 원격 접속 차단
- [ ] Firewall 활성 + `20022/tcp`, `15034/tcp`만 허용
- [ ] 계정/그룹 구성 충족
- [ ] Agent Boot Sequence 5단계 + `Agent READY`
- [ ] `monitor.sh` 프로세스/포트 점검 + 비정상 `exit 1`
- [ ] `monitor.log` 지정 포맷 누적
- [ ] cron 매분 실행으로 로그 자동 증가
- [ ] 로그 관리 `10MB / 10개`

## E. Evaluation — 항목 2: 구현 방식 및 명령어 설명

- [x] Reference Q&A에 프로세스 확인 명령과 선택 이유 정리
- [x] Reference Q&A에 포트 확인 명령과 선택 이유 정리
- [x] Reference Q&A에 CPU/MEM/DISK 추출·파싱 방식 정리
- [x] Reference Q&A에 로그 포맷을 고정한 이유 정리
- [x] Reference Q&A에 `agent-dev` 소유자 / `agent-admin` 실행자 구조 정리
- [x] Reference Q&A에 owner/group/mode 관점의 cron 실행 권한 정리
- [x] Reference Q&A에 `10MB / 10개` 로그 관리 구현 방식 정리
- [ ] 사용자가 Runtime 결과를 근거로 자기 말로 설명

## F. Evaluation — 항목 3: 보안·권한·운영 원리

- [x] Reference Q&A에 SSH 포트 변경과 Root 원격 차단의 보안 의미 정리
- [x] Reference Q&A에 `agent-core` 최소 권한 원칙 정리
- [x] Reference Q&A에 Health Check 실패와 WARNING 구분 이유 정리
- [x] Reference Q&A에 `>`와 `>>` 차이 정리
- [ ] 사용자가 자기 말로 설명

## G. Evaluation — 항목 4: 응용 및 장애 대응

- [x] Reference Q&A에 Nginx 등 다른 서버 관제 변경점 정리
- [x] Reference Q&A에 프로세스는 실행 중이나 포트가 열리지 않을 때 확인 순서 정리
- [x] Reference Q&A에 로그 급증/디스크 고갈 단기·중기 대응 정리
- [ ] 사용자가 자기 말로 설명

## H. Learn

- [x] STEP 01 용어를 JIT 방식으로 설명
- [x] STEP 01 핵심 개념 설명 및 Mermaid 제공
- [x] 개념도 아래 일반 문장 설명 제공
- [x] STEP 01 명령/코드에 입문자용 주석 제공
- [ ] 이후 모든 Runtime Step을 동일 형식으로 완성
- [ ] 주요 평가 질문을 자기 말로 설명할 수 있음

## I. Environment

- [ ] Runtime Golden Path 확정
- [x] Reference 사전 요구사항 문서 준비
- [ ] 실제 검증한 버전 기록
- [x] 필요한 환경 파일만 JIT 방식으로 생성
- [x] `setup = 구축`, `verify = 검증`, `reset = 현재 Round 자원만 안전 제거` 원칙 유지
- [ ] 시스템 변경 전 백업
- [ ] 설정 변경 후 문법 검사
- [ ] 서비스 적용 후 실제 상태 확인
- [x] Reference 파일에 실제 Secret 값 없음

## J. Verify

- [x] 통합 `environment/verify.sh` 기준 구현 준비
- [ ] `verify.sh` 실제 환경 실행
- [ ] 자동 검증 가능한 항목 PASS
- [ ] 실제 Ubuntu/WSL 실행이 필요한 항목 확인
- [ ] 정상 경로 확인
- [ ] 프로세스 실패 경로 확인
- [ ] 포트 실패 경로 확인
- [ ] WARNING 경로 확인
- [ ] cron 자동 실행 확인
- [ ] 로그 회전/관리 동작 확인
- [x] 실제 실행하지 않은 항목을 PASS로 표시하지 않음

## K. Evidence

각 증거는 다음 연결을 만족해야 합니다.

`Requirement → Implementation → Verification → Evidence`

- [x] Evidence 수집 계획 문서 준비
- [ ] SSH 설정/실제 LISTEN Evidence
- [ ] Firewall Evidence
- [ ] 계정/그룹 Evidence
- [ ] 디렉터리/권한/ACL Evidence
- [ ] Agent Boot Sequence 5/5 + `Agent READY` Evidence
- [ ] `15034` LISTEN Evidence
- [ ] `monitor.sh` 정상 실행 Evidence
- [ ] `monitor.sh` 실패 시 `exit 1` Evidence
- [ ] `monitor.log` 누적 Evidence
- [ ] cron 자동 로그 증가 Evidence
- [ ] `10MB / 10개` 로그 관리 Evidence
- [ ] Evidence에 Secret/Password/Token/Private Key 없음
- [ ] 평가자가 재확인 가능한 형태로 정리

## L. Final CLEAR

- [ ] 공식 Mission 요구사항 누락 없음
- [ ] 공식 Evaluation 요구사항 누락 없음
- [ ] 필수 구현 완료
- [ ] 자동 검증 항목 PASS
- [ ] 실제 환경 검증 완료
- [ ] 필요한 Evidence 확보
- [ ] Secret 노출 없음
- [ ] `BEGINNER-GUIDE.md`가 처음부터 끝까지 연결됨
- [ ] `CHECKLIST.md` 최종 확인 완료
- [ ] **✅ MISSION CLEAR**

**운영 규칙:** B1-1이 `✅ CLEAR`가 되기 전에는 B1-2의 **Runtime**을 시작하지 않습니다. 다만 Phase A에서는 B1-2 이후 미션의 **Reference Build**를 선제 준비할 수 있습니다.
