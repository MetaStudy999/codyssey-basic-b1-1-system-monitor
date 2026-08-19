# B1-1 Runtime / Optional Docker Labs

## 목적

B1-1의 공식 Mission CLEAR는 실제 Linux 시스템 Runtime에서 수행하고, Docker는 **선택 학습**으로 분리합니다.

현재 B1-1 Workcell은 **⏸ PAUSED / READY TO RESUME**이며 실패나 CLEAR 상태가 아닙니다. 재개 시 사용자가 선택한 `MAC-V` 또는 `WIN-V`를 Current Runtime Context로 사용합니다.

## Runtime Profiles

- Supported Runtime: `MAC-V` — macOS → OrbStack → Ubuntu 24.04 Linux Machine
- Supported Runtime: `WIN-V` — Windows 11 Pro → WSL2 → Ubuntu 24.04 direct runtime
- Optional Docker Lab: `MAC-D`, `WIN-D`

`MAC-V`와 `WIN-V`는 합격 우선순위의 Primary/Secondary 관계가 아닙니다.

## CLEAR 계약

B1-1의 Mission CLEAR는 다음으로 판정합니다.

```text
공식 Mission/Evaluation
+ 선택한 지원 Runtime의 실제 실행
+ Verification
+ Evidence
+ Evaluation
```

Docker Lab은 다음의 최종 Evidence를 대체하지 않습니다.

- SSH `20022`
- UFW 최종 정책
- Linux users/groups
- ACL/effective permission
- system-level cron
- Agent `15034` 전체 시스템 상태

따라서 **Supported Linux Runtime → Verify → Evidence → Evaluation → CLEAR**가 우선이며, Docker 미수행은 B1-1 CLEAR를 막지 않습니다.

공식 Mission/Evaluation이 두 플랫폼 모두를 요구하지 않는 한 한 지원 Runtime에서 공식 요구를 충족하면 다른 지원 Runtime 미수행만으로 CLEAR를 자동 차단하지 않습니다. 두 환경 모두 실제 PASS하면 내부 품질 상태로 `CROSS-PLATFORM VERIFIED`를 추가할 수 있습니다.

---

# Lab A — MAC-V Linux Runtime

## ① 왜 하는가

macOS 학교 환경에서 OrbStack Ubuntu 24.04를 실제 Linux Runtime으로 사용해 B1-1의 systemd, sshd, UFW, 사용자/그룹, ACL, cron을 검증합니다.

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
→ Evaluation
→ CLEAR 판정
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

# Lab B — WIN-V Linux Runtime

## ① 목적

Windows 11 Pro + WSL2 Ubuntu 24.04에서 같은 B1-1 공식 요구가 재현되는지 실제 Runtime으로 수행할 수 있습니다.

## ② 범위

필요한 경우 전체 B1-1 Runtime을 같은 기준으로 수행합니다.

- Ubuntu 24.04 / architecture
- systemd
- sshd
- UFW 및 네트워크 해석
- users/groups/ACL
- Agent process/port/log
- cron
- Verification / Evidence

WIN-V는 `Persistent` 환경이므로 정상 상태를 매번 재설치하지 않고 `VERIFY BEFORE REINSTALL` 원칙을 사용합니다.

## ③ 상태 해석

```text
MAC-V PASS ≠ WIN-V PASS
WIN-V 미수행 ≠ B1-1 FAIL
MAC-V + WIN-V 실제 PASS → CROSS-PLATFORM VERIFIED 가능
```

---

# Lab C — Optional Docker Practice

## ① 왜 하는가

B1-1 CLEAR에는 필요하지 않지만 Bash monitor와 Agent 관찰 로직을 재현 가능한 격리 환경에서 반복해 보고 싶을 때 사용합니다.

## ② 선택 판단

```text
B1-1 공식 Runtime 진행 중인가?
→ YES: Docker Lab보다 선택한 MAC-V/WIN-V Runtime 우선

공식 Runtime 이후 Docker 반복 학습이 필요한가?
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
B1-1 Workcell               [⏸ PAUSED / READY TO RESUME]
B1-1 Mission CLEAR          [ ]
MAC-V Runtime               [ ]
WIN-V Runtime               [ ]
CROSS-PLATFORM VERIFIED     [ ] optional quality status
MAC-D Docker Lab            [ ] optional
WIN-D Docker Lab            [ ] optional
```

## FAST TRACK과 현재 Workcell 포커스

FAST TRACK의 정식 순서는 Control Tower에서 관리합니다. 현재 B1-1 Workcell이 일시정지되어 있어도 B1-1을 FAIL 또는 CLEAR로 바꾸지 않습니다.

재개 시:

```text
Current Runtime Context 선택
→ Bootstrap / Identity 확인
→ B1-1 Runtime
→ Verify / Evidence / Evaluation
→ 공식 조건 충족 시에만 ✅ B1-1 CLEAR
```

Docker Lab을 하지 않았다는 이유로 B1-1 Runtime을 지연시키지 않습니다.
