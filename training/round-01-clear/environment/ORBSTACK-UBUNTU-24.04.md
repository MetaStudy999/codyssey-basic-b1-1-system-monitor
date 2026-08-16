# B1-1 R01 — macOS + OrbStack Ubuntu 24.04 Runtime

## 목적

현재 B1-1의 실제 Runtime 환경을 다음으로 고정합니다.

```text
macOS Host
└─ OrbStack
   └─ Ubuntu 24.04 Linux Machine
      └─ B1-1 Runtime
```

B1-1의 Linux 명령, 사용자/그룹, OpenSSH Server, UFW, cron, `/opt/agent-app`, `/var/log/agent-app`, Agent 실행과 `monitor.sh` 검증은 **macOS Host가 아니라 OrbStack Ubuntu 24.04 내부**에서 수행합니다.

OrbStack은 Linux machine을 실행할 수 있는 macOS용 Runtime이므로 B1-1에서는 Ubuntu machine을 실습 대상 Linux로 사용합니다. 다만 미션의 실제 요구 충족 여부는 OrbStack이라는 이름만으로 판정하지 않고 Ubuntu 내부의 실제 `systemd`, `sshd`, UFW, Port, 사용자·그룹, Agent 동작을 Runtime에서 검증합니다.

## R01 실제 Runtime 기준

- Host OS: **macOS**
- Linux Runtime: **OrbStack Ubuntu 24.04**
- Mission 작업 위치: **OrbStack Ubuntu 24.04 내부**
- Init/Service: `systemd` 실제 동작 확인
- SSH Server: `sshd` 실제 설치·동작 확인
- Firewall: UFW 실제 정책 확인
- Agent Home: `/opt/agent-app`
- Log: `/var/log/agent-app`
- SSH Mission Port: `20022/tcp`
- Agent Mission Port: `15034/tcp`

## Host와 Guest를 혼동하지 않는 규칙

### macOS Host에서 하는 일

- OrbStack 실행/종료
- Ubuntu machine 접속
- 필요 시 macOS Terminal에서 OrbStack machine으로 진입
- Repository clone 위치 또는 mount 위치 확인

### OrbStack Ubuntu 24.04에서 하는 일

- `apt` package 설치
- Linux 사용자/그룹 생성
- `/opt/agent-app` 권한/ACL 구성
- OpenSSH Server 설정
- UFW 설정
- Agent 실행
- `monitor.sh` 실행
- cron 등록
- `verify.sh` 실행
- Runtime Evidence 수집

`sudo apt`, `systemctl`, `ss`, `ufw`, `useradd`, `groupadd`, `setfacl`, `crontab` 같은 B1-1 Linux 명령은 Ubuntu 내부에서 실행합니다.

## STEP 01에서 OrbStack 환경을 확인하는 방법

B1-1 Repository root에서 다음을 실행합니다.

```bash
# Ubuntu 배포판 확인
cat /etc/os-release

# 실제 Guest CPU architecture 확인
uname -m
uname -a

# PID 1 / systemd 확인
ps -p 1 -o comm=
systemctl is-system-running || true

# OrbStack/가상화 단서 확인 — 판정 보조용
hostname
cat /proc/version

# 현재 사용자
whoami
id
```

### 기대 해석

- `/etc/os-release`에서 Ubuntu 24.04 계열인지 확인합니다.
- `uname -m` 결과를 Agent binary 선택의 기준으로 사용합니다.
- Apple Silicon Mac이라고 해서 Guest 결과를 임의로 `aarch64`로 가정하지 않습니다. **항상 Ubuntu 내부 `uname -m` 결과를 사용합니다.**
- `ps -p 1 -o comm=`가 `systemd`인지 확인합니다.
- 기존 WSL 판별 명령에서 `WSL marker not detected`가 나오는 것은 OrbStack에서는 정상적인 결과일 수 있습니다. B1-1에서 중요한 것은 WSL 여부가 아니라 필요한 Linux 기능의 실제 동작입니다.

## Network / SSH 주의

B1-1 공식 Runtime에서는 Ubuntu 내부 OpenSSH Server와 Mission Port `20022/tcp`를 실제로 검증합니다.

```text
현재 SSH 상태 확인
→ sshd 설치/상태 확인
→ 20022 설정
→ sshd -t
→ sshd -T
→ reload
→ Ubuntu 내부 20022 LISTEN 확인
→ 실제 접속 경로 확인
→ UFW 최종 정책 확인
```

OrbStack이 자체적으로 제공하는 machine 접속 편의 기능과 **B1-1에서 구성하는 Ubuntu OpenSSH Server `20022/tcp`는 같은 것으로 간주하지 않습니다.** 미션 Evidence는 Ubuntu 내부 `sshd`와 Port 상태를 기준으로 확인합니다.

## UFW 주의

가상화 환경에서는 Host/Guest networking과 Guest UFW가 서로 다른 계층입니다. 따라서 다음을 구분합니다.

```text
macOS / OrbStack networking
≠
Ubuntu 내부 UFW 정책
```

B1-1의 평가 대상 Firewall은 R01 기준 **Ubuntu 내부 UFW**입니다. `sudo ufw status verbose`와 실제 listen 상태를 함께 확인합니다.

## Evidence에 기록할 Runtime 정보

Secret 값을 제외하고 다음 정보를 Evidence 또는 `versions.md`에 기록할 수 있습니다.

```text
Host: macOS
Virtualization/Runtime: OrbStack
Guest: Ubuntu 24.04
Guest architecture: <uname -m 실제 결과>
PID 1: <실제 결과>
SSH Port: 20022
Agent Port: 15034
AGENT_HOME: /opt/agent-app
```

OrbStack/macOS 버전은 실제 Runtime 시작 시 확인한 값을 기록합니다. 추측하거나 현재 문서에 고정하지 않습니다.

## CLEAR 판정

OrbStack Ubuntu 24.04를 사용한다는 사실 자체는 PASS가 아닙니다. 다음 실제 Runtime 결과가 있어야 합니다.

- Ubuntu 내부 systemd 확인
- OpenSSH Server와 `20022/tcp` 실제 동작
- Root 원격 로그인 차단
- UFW 최종 정책
- 사용자/그룹/ACL effective permission
- Agent Boot 5/5 + READY
- `15034/tcp` LISTEN
- `monitor.sh` 정상/실패/Warning
- 10MB / 10개 로그 회전
- cron 실제 실행
- `verify.sh` 0 FAIL
- 필요한 Evidence

이 조건이 모두 확인되기 전에는 `✅ CLEAR`로 표시하지 않습니다.
