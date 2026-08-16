# B1-1 Round 01 — Mission Clear Checklist

> 상태는 `⬜ NOT STARTED`, `🟡 ACTIVE`, `⛔ BLOCKED`, `✅ CLEAR`만 사용합니다. 실제 실행·검증·Evidence가 끝나기 전에는 CLEAR로 판정하지 않습니다.

## 현재 상태

- Training Round: **R01 — CLEAR**
- Mission: **B1-1**
- Mission 상태: **🟡 ACTIVE**
- 현재 Step: **STEP 01 — 현재 실행 환경 Baseline 확인**

## A. Source

- [x] 공식 `b1-1-mission.pdf` 확인
- [x] 공식 `b1-1-mission.md` 확인
- [x] 공식 `b1-1-evaluation.md` 확인
- [x] 공식 `agent-app.zip` 존재 확인
- [ ] `agent-app.zip` 내부 파일/CPU 아키텍처 안전 확인
- [x] 필수 요구사항과 보너스 요구사항 분리
- [x] Reference Complete Path 설계

## B. 공식 필수 요구사항

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

- [ ] 경로 `$AGENT_HOME/bin/monitor.sh`
- [ ] 소유자 `agent-dev`
- [ ] 그룹 `agent-core`
- [ ] 권한 `750`
- [ ] Bash로 구현
- [ ] 대상 프로세스 Health Check
- [ ] 프로세스 비정상 시 `exit 1`
- [ ] TCP `15034` Health Check
- [ ] 포트 비정상 시 `exit 1`
- [ ] Firewall 비활성 시 `[WARNING]` 후 계속 실행
- [ ] CPU 사용률 수집
- [ ] MEM 사용률 수집
- [ ] Root filesystem DISK 사용률 수집
- [ ] CPU `> 20%` WARNING
- [ ] MEM `> 10%` WARNING
- [ ] DISK_USED `> 80%` WARNING
- [ ] `/var/log/agent-app/monitor.log` 누적 기록
- [ ] 공식 로그 포맷 충족
- [ ] 로그 관리 `10MB / 10개` 적용

### B5. cron

- [ ] `agent-admin` crontab에 매분 실행 등록
- [ ] cron 실행 권한 확인
- [ ] 등록 후 1~2분 내 `monitor.log` 실제 증가 확인

## C. STEP 01 — Baseline

> 이번 Step은 읽기 전용 확인 단계입니다. 시스템 변경을 하지 않습니다.

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
- [ ] STEP 01 완료

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

- [ ] 프로세스 확인 명령과 선택 이유 설명
- [ ] 포트 확인 명령과 선택 이유 설명
- [ ] CPU/MEM/DISK 추출·파싱 방식 설명
- [ ] 로그 포맷을 고정한 이유 설명
- [ ] `agent-dev` 소유자 / `agent-admin` 실행자 구조 설명
- [ ] owner/group/mode 관점에서 cron 실행 권한 설명
- [ ] `10MB / 10개` 로그 관리 구현 방식 설명

## F. Evaluation — 항목 3: 보안·권한·운영 원리

- [ ] SSH 포트 변경과 Root 원격 차단의 보안 의미 설명
- [ ] `agent-core`로 보안 디렉터리를 제한한 최소 권한 원칙 설명
- [ ] Health Check 실패와 WARNING을 구분한 운영 이유 설명
- [ ] `>`와 `>>` 차이와 로그 누적에서 `>>`가 필요한 이유 설명

## G. Evaluation — 항목 4: 응용 및 장애 대응

- [ ] Nginx 등 다른 서버 관제로 변경 시 수정할 핵심 항목 설명
- [ ] 프로세스는 실행 중이나 포트가 열리지 않을 때 확인 순서 설명
- [ ] 로그 급증/디스크 고갈 위험의 단기 대응 설명
- [ ] 로그 급증/디스크 고갈 위험의 중기 대응 설명

## H. Learn

- [ ] 필요한 용어를 각 Step 직전에 JIT 방식으로 설명
- [ ] 핵심 개념 설명
- [ ] 필요한 경우 Mermaid 개념도 제공
- [ ] 개념도 아래 일반 문장 설명 제공
- [ ] 명령/코드에 입문자용 주석 제공
- [ ] 주요 평가 질문을 자기 말로 설명할 수 있음

## I. Environment

- [ ] Golden Path 확정
- [ ] 사전 요구사항 확인
- [ ] 실제 검증한 버전 기록
- [ ] 필요한 환경 파일만 JIT 방식으로 생성
- [ ] `setup = 구축`, `verify = 검증`, `reset = 현재 Round 자원만 안전 제거` 원칙 유지
- [ ] 시스템 변경 전 백업
- [ ] 설정 변경 후 문법 검사
- [ ] 서비스 적용 후 실제 상태 확인
- [ ] Secret이 Git에 포함되지 않음

## J. Verify

- [ ] 자동 검증 가능한 항목 PASS
- [ ] 실제 Ubuntu/WSL 실행이 필요한 항목은 사용자 Runtime으로 확인
- [ ] 정상 경로 확인
- [ ] 프로세스 실패 경로 확인
- [ ] 포트 실패 경로 확인
- [ ] WARNING 경로 확인
- [ ] cron 자동 실행 확인
- [ ] 로그 회전/관리 동작 확인
- [ ] 실제 실행하지 않은 항목을 PASS로 표시하지 않음

## K. Evidence

각 증거는 다음 연결을 만족해야 합니다.

`Requirement → Implementation → Verification → Evidence`

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

B1-1이 `✅ CLEAR`가 되기 전에는 B1-2를 시작하지 않습니다.
