# B1-1 Round 01 — CLEAR

## 현재 상태

- Runtime Mission: **🟡 ACTIVE**
- Phase A Reference Build: **CORE READY**
- 현재 Runtime 환경: **macOS Host + OrbStack Ubuntu 24.04**
- Runtime/Evidence: **미검증**
- CLEAR: **아님**

## 시작 순서

1. `REFERENCE-STATUS.md` — Phase A 자체감사 결과
2. `REFERENCE-BUILD.md` — Reference 설계와 보완 내용
3. `environment/ORBSTACK-UBUNTU-24.04.md` — 현재 실제 Runtime 환경 기준
4. `BEGINNER-GUIDE.md` — Phase C 실제 15-Step 따라하기
5. `CHECKLIST.md` — Mission/Evaluation/CLEAR Gate

## 현재 Runtime 구조

```text
macOS Host
└─ OrbStack
   └─ Ubuntu 24.04
      └─ B1-1 Runtime
```

B1-1의 Linux 명령과 시스템 설정은 **OrbStack Ubuntu 24.04 내부에서 수행**합니다. macOS Host는 OrbStack과 Ubuntu machine을 실행·접속하는 역할입니다.

## R01 Golden Path

```text
OrbStack Ubuntu 24.04
+ systemd 실제 확인
+ OpenSSH Server
+ UFW
+ Bash
+ AGENT_HOME=/opt/agent-app
```

기존 Reference의 `Ubuntu 22.04 LTS 또는 동등 Linux` 기준을 유지하되, Phase C의 실제 대상 환경은 **Ubuntu 24.04 on OrbStack**으로 명시합니다. Ubuntu 버전이나 가상화 제품명만으로 PASS하지 않고 필요한 기능을 실제 Runtime에서 검증합니다.

### OrbStack 환경 해석 규칙

- WSL 환경이 아니므로 STEP 01에서 `WSL marker not detected`가 나와도 정상일 수 있습니다.
- Agent binary는 macOS Host CPU가 아니라 **Ubuntu 내부 `uname -m` 결과**로 선택합니다.
- OrbStack 자체 machine 접속 기능과 Mission의 Ubuntu OpenSSH Server `20022/tcp`는 구분합니다.
- macOS/OrbStack network와 Ubuntu 내부 UFW는 별도 계층으로 보고 Guest UFW를 실제 검증합니다.
- `systemd`, `sshd`, `20022`, `15034`, 사용자/그룹/ACL, cron은 모두 Ubuntu 내부 결과를 Evidence 기준으로 사용합니다.

## 폴더 역할

- `environment/` — prerequisites, OrbStack runtime guide, versions, setup/verify/reset
- `docs/` — requirements mapping, evaluation Q&A
- `evidence/` — 실제 Runtime Evidence 수집 규칙
- `monitor.sh` — 기준 Bash 관제 구현

## 핵심 운영 규칙

Phase A에서 Reference가 준비되었더라도 실제 OrbStack Ubuntu 24.04 안에서 SSH/UFW/사용자 권한/Agent/15034/monitor/cron/로그 회전/Evidence를 확인하지 않았다면 `✅ CLEAR`가 아닙니다.

실제 Secret 값은 GitHub·채팅·로그·Evidence에 저장하지 않습니다.
