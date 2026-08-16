# B1-1 Dual Runtime Labs

## 목적

B1-1을 **Docker Lab**과 **VM/Linux Machine Lab** 두 관점에서 학습합니다. 다만 공식 Mission/Evaluation의 시스템 요구를 정확히 검증해야 하므로 R01의 Mission CLEAR는 `MAC-V`를 Primary로 사용합니다.

## Runtime Profiles

- Primary: `MAC-V` — macOS → OrbStack → Ubuntu 24.04 Linux Machine
- Twin: `WIN-V` — Windows 11 Pro → WSL2 → Ubuntu 24.04 direct runtime
- Docker Practice: `MAC-D`, `WIN-D`

## CLEAR 계약

B1-1에서 Docker는 다음의 최종 Evidence를 대체하지 않습니다.

- SSH `20022`
- UFW 최종 정책
- Linux users/groups
- ACL/effective permission
- system-level cron
- Agent `15034` 전체 시스템 상태

따라서 **Primary VM/Linux Machine Runtime → Verify → Evidence → CLEAR**가 우선입니다.

---

# Lab A — VM/Linux Machine Primary

## ① 왜 하는가

B1-1의 핵심은 Linux 시스템 운영입니다. systemd, sshd, UFW, 사용자/그룹, ACL, cron을 실제 Ubuntu 24.04 환경에서 검증해야 합니다.

## ② 무엇을 하는가

`BEGINNER-GUIDE.md`의 15-Step 전체 경로를 수행합니다.

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

현재 Primary:

```text
macOS
└─ OrbStack
   └─ Ubuntu 24.04
```

Twin:

```text
Windows 11 Pro
└─ WSL2
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

주 절차는 상위 `BEGINNER-GUIDE.md`를 사용합니다. 이 문서에서 별도의 두 번째 명령 집합을 복제하지 않습니다.

## ⑥ 검증

Runtime 구성이 끝난 뒤:

```bash
sudo bash training/round-01-clear/environment/verify.sh
```

## ⑦ Evidence

```text
training/round-01-clear/evidence/
```

Secret 값은 저장하지 않습니다.

## ⑧ Twin WIN-V에서 확인할 핵심

B1-1 CLEAR 후 또는 별도 Portability 시간에 전체 미션을 처음부터 다시 반복하지 않고 다음을 중심으로 확인합니다.

- Ubuntu 24.04 / architecture
- systemd 동작
- sshd 서비스 가능 여부
- users/groups/ACL
- process/port/log/cron 동작
- OrbStack과 WSL2 차이

WSL2에서 host/network/firewall 계층이 OrbStack과 다르므로 차이를 기록하되 공식 요구를 임의로 바꾸지 않습니다.

---

# Lab B — Docker Practice

## ① 왜 하는가

B1-1의 Bash monitor와 Agent 관찰 로직을 재현 가능한 격리 환경에서 빠르게 반복하기 위해 사용합니다.

## ② 무엇을 하는가

Docker에서는 다음 **애플리케이션/관찰 부분만** 연습합니다.

- process 확인
- TCP listen 확인
- CPU/MEM/DISK 수집 로직
- monitor log 생성
- warning/failure 로직
- log rotation 로직

## ③ 실행 환경

- `MAC-D`: macOS → OrbStack Docker
- `WIN-D`: Windows 11 Pro → WSL2 Ubuntu 24.04 → Docker

## ④ 기본 Container 확인

예시 실습용 Ubuntu 24.04 container를 사용할 수 있습니다.

```bash
docker run --rm -it ubuntu:24.04 bash
```

필요한 package는 실습 범위에 맞게 container 내부에서만 설치합니다. 실제 Mission repository의 Secret을 image에 포함하지 않습니다.

## ⑤ Docker에서 하지 않는 최종 판정

다음은 Docker Lab 결과만으로 PASS/CLEAR하지 않습니다.

```text
Host/Guest SSH migration
UFW strict inbound policy
실제 system-level user/group/ACL 모델
실제 cron daemon 운영
OrbStack/WSL2 Linux Machine의 최종 network state
```

## ⑥ Portability 확인

Docker Lab은 아래 정도로 짧게 끝냅니다.

```text
Container 기동
→ monitor 핵심 로직 실행
→ process/port/log 확인
→ failure 1회 확인
→ container 제거
```

## ⑦ 완료 기록

Mission 상태와 별도로 기록합니다.

```text
B1-1 Mission CLEAR    [ ]
MAC-V Primary         [ ]
WIN-V Twin            [ ]
MAC-D Docker Lab      [ ]
WIN-D Docker Lab      [ ]
```

Docker/Win Twin이 미완료라는 이유만으로 공식 B1-1 CLEAR를 BLOCKED 처리하지 않습니다.

## 운영 순서

FAST TRACK에서는 다음 순서를 권장합니다.

```text
MAC-V Primary Runtime
→ Verify / Evidence
→ ✅ B1-1 CLEAR
→ 다음 필수 Mission

Docker/Windows Twin
→ 별도 Portability Coverage로 필요한 범위만 수행
```

이렇게 하여 Docker/VM 학습을 추가하면서도 FAST TRACK의 CLEAR 속도를 유지합니다.
