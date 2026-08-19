# Codyssey Basic B1-1

## 구분

- 필수 미션 (REQUIRED)
- 현재 훈련 체계: **Round 01 — CLEAR**
- Workcell 상태: **⏸ PAUSED / READY TO RESUME**
- Mission CLEAR: **아님**
- Phase A Reference 상태: **CORE READY**
- 지원 실행 환경(Supported Runtime): **MAC-V / WIN-V 동등 지원**

B1-1은 실패(FAIL)나 완료(CLEAR) 상태가 아닙니다. 현재 Workcell만 일시정지되어 있으며, 재개할 때 실제 Runtime 상태를 다시 확인한 뒤 이어서 수행합니다.

## 시작 위치

- `training/round-01-clear/REFERENCE-STATUS.md` — Reference 자체감사 결과
- `training/round-01-clear/REFERENCE-BUILD.md` — 기준 구현/검증 설계
- `training/round-01-clear/BEGINNER-GUIDE.md` — Phase C 실제 실행 중앙 허브
- `training/round-01-clear/guide/` — 3계층 입문자 학습 모듈
- `training/round-01-clear/environment/README.md` — B1-1 환경 기준
- `training/round-01-clear/environment/ORBSTACK-UBUNTU-24.04.md` — MAC-V 세부 가이드
- `training/round-01-clear/environment/DUAL-RUNTIME-LABS.md` — MAC-V/WIN-V와 선택 Lab 구분
- `training/round-01-clear/CHECKLIST.md` — 공식 Mission/Evaluation + Runtime CLEAR Gate

Phase A에서는 실제 환경 없이 만들 수 있는 기준 구현·학습자료·검증 도구·Evidence 구조를 먼저 완성했습니다. 현재 전역 운영 단계는 Phase C이며, B1-1 Workcell을 재개하면 선택한 현재 실행 환경(Current Runtime Context)에서 실제 실행 → 검증 → Evidence를 이어갑니다.

## 공식 원본

- `b1-1-mission.pdf`
- `b1-1-mission.md`
- `b1-1-evaluation.md`
- `agent-app.zip`

공식 원본은 수정하지 않습니다. 훈련 결과는 `training/` 아래에서 차수별로 독립 관리합니다.

## 지원 Runtime

Control Tower 기준으로 다음 두 직접 Linux Runtime을 동등하게 지원합니다.

```text
MAC-V
학교 macOS Host
└─ OrbStack
   └─ Ubuntu 24.04

WIN-V
Windows 11 Pro
└─ WSL2
   └─ Ubuntu 24.04
```

```text
MAC-V PASS ≠ WIN-V PASS
한 플랫폼 PASS ≠ CROSS-PLATFORM VERIFIED
플랫폼별 Runtime Record ≠ Mission CLEAR
```

B1-1을 다시 수행할 때는 사용자가 실제 작업하는 위치를 Current Runtime Context로 선택합니다. 이전 MAC-V 작업 경험은 참고할 수 있지만, 현재 장비 상태를 추정해 PASS 처리하지 않습니다.

## B1-1 Runtime 핵심 요구

선택한 Ubuntu 24.04 Runtime 내부에서 다음을 실제로 확인합니다.

```text
systemd
OpenSSH Server
SSH 20022/tcp
UFW
Linux users/groups/ACL
AGENT_HOME=/opt/agent-app
Agent READY + 15034/tcp
monitor.sh
log rotation
cron
Verification
Evidence
```

제공 Agent archive의 실행 파일은 Host CPU를 보고 추측하지 않고 **실제 Ubuntu 내부 `uname -m` 결과**를 확인한 뒤 선택합니다.

`/opt/agent-app`을 선택한 이유는 `upload_files`를 `agent-common` 전체가 사용하면서 `api_keys`와 로그는 `agent-core`만 사용하도록 상위 경로까지 포함한 최소 권한을 안정적으로 구성하기 위해서입니다.

## MAC-V 주의

MAC-V를 사용할 때:

- macOS는 Host이고 **OrbStack Ubuntu 24.04가 실습 대상 Linux**입니다.
- WSL 환경이 아니므로 `WSL marker not detected`가 나와도 이상이 아닐 수 있습니다.
- OrbStack 자체 machine 접속과 Mission의 Ubuntu OpenSSH Server `20022/tcp`를 구분합니다.
- Host/OrbStack networking과 Ubuntu 내부 UFW는 서로 다른 계층입니다.

상세 기준은 `training/round-01-clear/environment/ORBSTACK-UBUNTU-24.04.md`를 사용합니다.

## WIN-V 주의

WIN-V를 사용할 때:

- Windows 11 Pro는 Host이고 **WSL2 Ubuntu 24.04가 실습 대상 Linux**입니다.
- 정상적인 WSL2/Repository 상태를 매 작업마다 재설치하지 않습니다.
- `VERIFY BEFORE REINSTALL` 원칙으로 현재 상태 확인과 최소 Repair를 우선합니다.

## Reference 구현

- `training/round-01-clear/monitor.sh` — Process/Port/Resource/Warning/Log/10MB·10개 회전
- `training/round-01-clear/environment/setup.sh` — SSH/UFW를 건드리지 않는 재현 보조
- `training/round-01-clear/environment/verify.sh` — UFW strict policy와 역할별 effective permission까지 확인하는 검증 전용 스크립트
- `training/round-01-clear/environment/reset.sh` — 식별 가능한 비밀이 아닌 helper 설치물만 제거하는 보수적 reset
- `training/round-01-clear/docs/requirements-mapping.md` — Requirement → Implementation → Verification → Evidence
- `training/round-01-clear/docs/evaluation-qa.md` — 평가 설명형 기준 답안
- `training/round-01-clear/evidence/README.md` — 실제 Evidence 수집 계획

## Round 01 원칙

1. 공식 Mission/Evaluation/제공 파일을 Source of Truth로 사용합니다.
2. Phase A Reference Build와 Phase C Runtime PASS를 구분합니다.
3. MAC-V와 WIN-V는 합격 우선순위가 아니라 동등한 Supported Runtime입니다.
4. 시스템 변경은 `현재 상태 → 백업 → 변경 → 문법 검사 → 적용 → 실제 검증` 순서를 지킵니다.
5. SSH는 새 20022 세션 성공 전 기존 접속 경로를 제거하지 않습니다.
6. Secret/Password/API Key/Token/Private Key는 GitHub·채팅·로그·Evidence에 저장하지 않습니다.
7. 실제 실행·검증·Evidence가 끝나기 전에는 `✅ CLEAR`로 표시하지 않습니다.
8. Workcell 일시정지는 FAIL이 아니며 재개 시 현재 Runtime 상태를 다시 확인합니다.

## 현재 상태

```text
Phase A Reference = ✅ CORE READY
B1-1 Workcell     = ⏸ PAUSED / READY TO RESUME
Mission CLEAR     = ❌ 아직 아님
MAC-V Record      = 실제 Evidence 확인 전 PASS로 승격하지 않음
WIN-V Record      = 실제 Evidence 확인 전 PASS로 승격하지 않음
```
