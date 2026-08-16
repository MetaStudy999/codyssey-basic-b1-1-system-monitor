# B1-1 Runtime / Optional Docker Labs

## 목적

B1-1의 공식 Mission CLEAR는 실제 Linux 시스템 Runtime에서 수행하고, Docker는 **선택 학습**으로 분리합니다.

## Runtime Profiles

- Primary CLEAR: `MAC-V` — macOS → OrbStack → Ubuntu 24.04 Linux Machine
- Secondary Check: `WIN-V` — Windows 11 Pro → WSL2 → Ubuntu 24.04 direct runtime
- Optional Docker Lab: `MAC-D`, `WIN-D`

## CLEAR 계약

B1-1의 Mission CLEAR는 다음으로 판정합니다.

```text
공식 Mission/Evaluation
+ MAC-V 실제 Runtime
+ verify
+ Evidence
```

Docker Lab은 다음의 최종 Evidence를 대체하지 않습니다.

- SSH `20022`
- UFW 최종 정책
- Linux users/groups
- ACL/effective permission
- system-level cron
- Agent `15034` 전체 시스템 상태

따라서 **Primary Linux Runtime → Verify → Evidence → CLEAR**가 우선이며, Docker 미수행은 B1-1 CLEAR를 막지 않습니다.

---

# Lab A — Primary Linux Runtime

## ① 왜 하는가

B1-1의 핵심은 Linux 시스템 운영입니다. systemd, sshd, UFW, 사용자/그룹, ACL, cron을 실제 Ubuntu 24.04 환경에서 검증해야 합니다.

## ② 무엇을 하는가

`BEGINNER-GUIDE.md`의 전체 Runtime 경로를 수행합니다.

```text
Baseline
→ prerequisites
→ SSH 20022
→ UFW
→ users/groups/ACL
→ Agent archive/secret
→ Agent READY + 15034
→ monitor.sh
→ log rotation
→ cron
→ failure/warning
→ verify
→ Evidence
→ CLEAR
```

## ③ 실행 환경

```text
macOS
└─ OrbStack
   └─ Ubuntu 24.04
```

## ④ 시작 확인

Ubuntu 내부에서 수행합니다.

```bash
cat /etc/os-release
uname -m
ps -p 1 -o comm=
```

Architecture는 Host CPU 이름으로 추측하지 않고 `uname -m` 결과로 Agent binary를 선택합니다.

## ⑤ 실제 수행

주 절차는 상위 `BEGINNER-GUIDE.md`를 사용합니다. 이 문서에서 두 번째 명령 집합을 복제하지 않습니다.

## ⑥ 검증

```bash
sudo bash training/round-01-clear/environment/verify.sh
```

## ⑦ Evidence

```text
training/round-01-clear/evidence/
```

Secret 값은 저장하지 않습니다.

---

# Lab B — Windows/WSL2 Secondary Check (권장)

## ① 목적

B1-1 CLEAR 이후 또는 별도 Portability 시간에 핵심 Linux 경로가 Windows 11 Pro + WSL2 Ubuntu 24.04에서도 재현되는지 확인합니다.

## ② 범위

전체 미션을 다시 반복하지 않고 다음을 중심으로 확인합니다.

- Ubuntu 24.04 / architecture
- systemd
- sshd 서비스 가능 여부
- users/groups/ACL
- process/port/log/cron
- OrbStack과 WSL2의 network/service 차이

Secondary Check 미완료만으로 B1-1을 BLOCKED 처리하지 않습니다.

---

# Lab C — Optional Docker Practice

## ① 왜 하는가

B1-1 CLEAR에는 필요하지 않지만 Bash monitor와 Agent 관찰 로직을 재현 가능한 격리 환경에서 반복해 보고 싶을 때 사용합니다.

## ② 선택 판단

```text
B1-1 CLEAR 진행 중인가?
→ YES: Docker Lab보다 MAC-V Runtime 우선

B1-1 CLEAR 완료 후 Docker 학습이 필요한가?
├─ YES: Optional Docker Lab
└─ NO: SKIP / 후속 Docker Track
```

## ③ Docker에서 연습할 수 있는 것

- process 확인
- TCP listen 확인
- CPU/MEM/DISK 수집 로직
- monitor log 생성
- warning/failure 로직
- log rotation 로직

## ④ 실행 환경

- `MAC-D`: macOS → OrbStack Docker
- `WIN-D`: Windows 11 Pro → WSL2 Ubuntu 24.04 → Docker

예시:

```bash
docker run --rm -it ubuntu:24.04 bash
```

필요 package는 container 내부에서만 설치하고 실제 Mission Secret을 image에 포함하지 않습니다.

## ⑤ Docker에서 최종 판정하지 않는 항목

```text
Host/Guest SSH migration
UFW strict inbound policy
실제 system-level user/group/ACL 모델
실제 cron daemon 운영
OrbStack/WSL2 Linux Machine의 최종 network state
```

## ⑥ 완료 기록

Mission 상태와 환경 학습 상태를 분리합니다.

```text
B1-1 Mission CLEAR        [ ]
MAC-V Primary             [ ]
WIN-V Secondary Check     [ ]
MAC-D Docker Lab          [ ] optional
WIN-D Docker Lab          [ ] optional
```

## FAST TRACK 운영 순서

```text
MAC-V Primary Runtime
→ Verify / Evidence
→ ✅ B1-1 CLEAR
→ B1-2

WIN-V / Docker Labs
→ 필요한 경우 별도 Portability/Training 시간에 수행
```

Docker를 하지 않았다는 이유로 B1-1 FAST TRACK을 지연시키지 않습니다.
