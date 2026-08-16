# Codyssey Basic B1-1

## 구분

- 필수 미션 (REQUIRED)
- 현재 훈련 체계: **Round 01 — CLEAR**
- Runtime 상태: **🟡 ACTIVE**
- Phase A Reference 상태: **CORE READY**
- 현재 실제 Runtime 환경: **macOS Host + OrbStack Ubuntu 24.04**

## 시작 위치

- `training/round-01-clear/REFERENCE-STATUS.md` — 현재 Reference 자체감사 결과
- `training/round-01-clear/REFERENCE-BUILD.md` — 기준 구현/검증 설계
- `training/round-01-clear/environment/ORBSTACK-UBUNTU-24.04.md` — 현재 실제 Runtime 환경 기준
- `training/round-01-clear/BEGINNER-GUIDE.md` — Phase C에서 처음부터 따라가는 15-Step 가이드
- `training/round-01-clear/CHECKLIST.md` — 공식 Mission/Evaluation + Runtime CLEAR Gate

Phase A에서는 실제 환경 없이 만들 수 있는 기준 구현·학습자료·검증 도구·Evidence 구조를 먼저 완성했습니다. Phase C의 현재 실제 실행 환경은 **macOS에서 OrbStack으로 구동하는 Ubuntu 24.04 Linux machine**입니다.

B1-1의 `apt`, `systemctl`, `sshd`, UFW, 사용자/그룹/ACL, `/opt/agent-app`, Agent, `monitor.sh`, cron, `verify.sh` 작업은 **macOS Host가 아니라 OrbStack Ubuntu 24.04 내부**에서 수행합니다.

## 공식 원본

- `b1-1-mission.pdf`
- `b1-1-mission.md`
- `b1-1-evaluation.md`
- `agent-app.zip`

공식 원본은 수정하지 않습니다. 훈련 결과는 `training/` 아래에서 차수별로 독립 관리합니다.

## R01 Golden Path

현재 Runtime 기준:

```text
macOS Host
└─ OrbStack
   └─ Ubuntu 24.04
      + systemd 실제 확인
      + OpenSSH Server
      + UFW
      + Bash
      + AGENT_HOME=/opt/agent-app
```

일반적인 Reference 기준은 Ubuntu 22.04 LTS 또는 동등 Linux였으며, 현재 Phase C에서는 **OrbStack Ubuntu 24.04를 실제 Runtime 대상으로 사용**합니다. Ubuntu 24.04라는 버전만으로 PASS 처리하지 않고 필요한 Linux 기능을 실제로 검증합니다.

제공 Agent archive의 실행 파일은 macOS CPU를 보고 추측하지 않고 **OrbStack Ubuntu 내부 `uname -m` 실제 결과**를 확인한 뒤 선택하여 canonical `agent-app`으로 설치합니다.

`/opt/agent-app`을 선택한 이유는 `upload_files`를 `agent-common` 전체가 사용하면서 `api_keys`와 로그는 `agent-core`만 사용하도록 상위 경로까지 포함한 최소 권한을 안정적으로 구성하기 위해서입니다.

## OrbStack Runtime 주의

- macOS는 Host이고 **Ubuntu 24.04가 B1-1 실습 대상 Linux**입니다.
- 기존 STEP 01의 WSL 판별에서 `WSL marker not detected`가 출력되어도 OrbStack에서는 이상이 아닙니다.
- 중요한 판정은 `systemd`, `sshd`, UFW, Port, 사용자·그룹, Agent가 Ubuntu 내부에서 실제로 동작하는지입니다.
- OrbStack 자체의 machine 접속 기능과 B1-1에서 요구하는 Ubuntu OpenSSH Server `20022/tcp`를 동일하게 취급하지 않습니다.
- Host/OrbStack networking과 Ubuntu 내부 UFW는 서로 다른 계층이므로 UFW는 Guest 내부에서 별도로 검증합니다.

상세 기준은 `training/round-01-clear/environment/ORBSTACK-UBUNTU-24.04.md`를 사용합니다.

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
3. 현재 Runtime은 macOS Host의 OrbStack Ubuntu 24.04 내부에서 수행합니다.
4. 시스템 변경은 `현재 상태 → 백업 → 변경 → 문법 검사 → 적용 → 실제 검증` 순서를 지킵니다.
5. SSH는 새 20022 세션 성공 전 기존 접속 경로를 제거하지 않습니다.
6. Secret/Password/API Key/Token/Private Key는 GitHub·채팅·로그·Evidence에 저장하지 않습니다.
7. 실제 실행·검증·Evidence가 끝나기 전에는 `✅ CLEAR`로 표시하지 않습니다.

## 현재 상태

**Phase A: CORE READY**

**Runtime: 🟡 ACTIVE — macOS + OrbStack Ubuntu 24.04 / 실제 검증 전 / CLEAR 아님**
