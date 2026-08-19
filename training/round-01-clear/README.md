# B1-1 Round 01 — CLEAR

## 현재 상태

- Workcell: **⏸ PAUSED / READY TO RESUME**
- Mission CLEAR: **아님**
- Phase A Reference Build: **CORE READY**
- 지원 Runtime: **MAC-V / WIN-V 동등 지원**
- MAC-V Runtime Record: **실제 Evidence 확인 전 PASS로 승격하지 않음**
- WIN-V Runtime Record: **실제 Evidence 확인 전 PASS로 승격하지 않음**
- Docker Practice: **MAC-D / WIN-D — 선택 학습**

B1-1은 실패 상태가 아닙니다. 현재 Workcell만 일시정지되어 있으며, 재개 시 선택한 Current Runtime Context에서 Bootstrap/Identity와 실제 시스템 상태를 확인한 뒤 이어서 수행합니다.

## 시작 순서

1. `REFERENCE-STATUS.md` — Phase A 자체감사 결과
2. `REFERENCE-BUILD.md` — Reference 설계와 보완 내용
3. `BEGINNER-GUIDE.md` — Quick Start + 전체 학습 지도
4. `guide/` — 세부 학습 모듈
5. `environment/README.md` — 공통 환경 진입
6. `environment/ORBSTACK-UBUNTU-24.04.md` — MAC-V 세부 Runtime 가이드
7. `environment/DUAL-RUNTIME-LABS.md` — MAC-V/WIN-V/선택 Docker Lab 구분
8. `CHECKLIST.md` — Mission/Evaluation/CLEAR Gate

## 지원 Runtime 구조

```text
MAC-V
학교 macOS Host
└─ OrbStack
   └─ Ubuntu 24.04
      └─ B1-1 Runtime

WIN-V
Windows 11 Pro
└─ WSL2
   └─ Ubuntu 24.04
      └─ B1-1 Runtime

Optional Docker Practice
├─ MAC-D: OrbStack Docker
└─ WIN-D: WSL2 Ubuntu + Docker
```

`MAC-V`와 `WIN-V`는 Primary/Secondary 관계가 아닙니다. 공식 Mission/Evaluation, 검증(Verification), 증빙(Evidence), CLEAR 기준은 동일합니다. 실제 작업 시 사용자가 선택한 환경이 Current Runtime Context가 됩니다.

## R01 Runtime 핵심 기준

선택한 Ubuntu 24.04 Runtime에서 다음을 실제로 확인합니다.

```text
systemd
OpenSSH Server
UFW
Bash
AGENT_HOME=/opt/agent-app
SSH 20022/tcp
Agent 15034/tcp
users/groups/ACL
monitor.sh
log rotation
cron
verify.sh
Evidence
```

Ubuntu 버전이나 가상화 제품명만으로 PASS하지 않고 필요한 기능을 실제 Runtime에서 검증합니다.

### MAC-V 해석 규칙

- WSL 환경이 아니므로 `WSL marker not detected`가 나와도 정상일 수 있습니다.
- Agent binary는 macOS Host CPU가 아니라 **Ubuntu 내부 `uname -m` 결과**로 선택합니다.
- OrbStack 자체 machine 접속 기능과 Mission의 Ubuntu OpenSSH Server `20022/tcp`는 구분합니다.
- macOS/OrbStack network와 Ubuntu 내부 UFW는 별도 계층으로 봅니다.

### WIN-V 해석 규칙

- Windows Host와 WSL2 Ubuntu Runtime을 구분합니다.
- 정상 상태의 WSL2/Repository를 매 작업마다 재설치하지 않습니다.
- `VERIFY BEFORE REINSTALL` 원칙으로 현재 상태 확인과 최소 Repair를 우선합니다.

## Docker/VM 학습 원칙

- Mission `✅ CLEAR`와 추가 Lab Coverage를 분리합니다.
- Docker에서는 process/port/resource/log/rotation 같은 관찰 로직을 연습할 수 있습니다.
- Docker 결과는 SSH/UFW/system-level 권한/cron의 실제 Runtime Evidence를 대신하지 않습니다.
- 공식 Mission/Evaluation이 두 플랫폼 모두를 요구하지 않는 한 한 지원 Runtime의 미수행만으로 CLEAR를 자동 차단하지 않습니다.

## 폴더 역할

- `guide/` — 3계층 입문자 세부 학습 문서
- `environment/` — prerequisites, Runtime guide, versions, setup/verify/reset
- `docs/` — requirements mapping, evaluation Q&A
- `evidence/` — 실제 Runtime Evidence 수집 규칙
- `monitor.sh` — 기준 Bash 관제 구현

## 핵심 운영 규칙

Phase A에서 Reference가 준비되었더라도 선택한 Ubuntu 24.04 Runtime에서 SSH/UFW/사용자 권한/Agent/15034/monitor/cron/로그 회전/Evidence를 확인하지 않았다면 `✅ CLEAR`가 아닙니다.

실제 Secret 값은 GitHub·채팅·로그·Evidence에 저장하지 않습니다.

```text
Workcell PAUSED ≠ FAIL
Workcell PAUSED ≠ CLEAR
재개 → Current Runtime 확인 → Runtime → Verification → Evidence → Evaluation → CLEAR 판정
```
