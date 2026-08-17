# B1-1 R01 — Prerequisites

## 현재 실제 실행 환경

```text
macOS Host
└─ OrbStack
   └─ Ubuntu 24.04 Linux Machine
      └─ B1-1 Runtime
```

현재 R01 Phase C에서 B1-1은 **macOS Host 위의 OrbStack Ubuntu 24.04**를 실제 Runtime 환경으로 사용합니다.

B1-1의 Linux 관련 명령과 시스템 설정은 macOS에서 직접 실행하지 않고 **OrbStack Ubuntu 24.04 내부**에서 수행합니다.

상세 환경 규칙은 `ORBSTACK-UBUNTU-24.04.md`를 먼저 확인합니다.

## 시작 조건

- OrbStack Ubuntu 24.04 Linux machine
- 일반 사용자 계정
- 필요한 시스템 작업을 위한 `sudo` 권한
- Git으로 현재 저장소를 확인할 수 있는 환경
- 공식 `agent-app.zip`
- R01 Golden Path: `AGENT_HOME=/opt/agent-app`
- R01 Firewall: Ubuntu 내부 UFW
- `systemd`, `sshd`가 실제로 동작 가능한지 Runtime에서 확인

> 기존 업무/서비스가 동작하는 Linux보다 **전용 OrbStack Ubuntu machine/VM/실습 Linux**를 권장합니다. 공식 요구사항은 인바운드 허용을 `20022/tcp`, `15034/tcp`만 남겨야 하므로 다른 서비스가 필요한 환경에서는 충돌할 수 있습니다.

## Host / Guest 구분

### macOS Host

- OrbStack 실행
- Ubuntu machine 실행·접속
- 필요 시 저장소 위치 확인

### OrbStack Ubuntu 24.04

- `apt`
- `systemctl`
- OpenSSH Server
- UFW
- Linux 사용자/그룹
- ACL
- Agent
- `monitor.sh`
- cron
- `verify.sh`

B1-1의 평가와 Evidence는 Ubuntu Guest 내부의 실제 결과를 기준으로 합니다.

## Ubuntu Developer Bootstrap

공통 개발도구는 Control Tower에서 먼저 확인합니다.

```bash
CONTROL_TOWER="${CONTROL_TOWER:-$HOME/codyssey/codyssey-basic}"
bash "$CONTROL_TOWER/environments/ubuntu/bootstrap.sh" --check
```

필수 공통 도구가 누락된 경우에만:

```bash
bash "$CONTROL_TOWER/environments/ubuntu/bootstrap.sh" --install
```

공통 필수 계층에는 Git/SSH client/입문자 편집기/API·파일 도구가 포함됩니다.

```text
git
openssh-client
nano
jq
curl
wget
file
unzip
zip
rsync
bash-completion
```

GitHub CLI `gh`도 공통 Developer CLI로 관리하지만 설치와 인증을 분리합니다. `gh auth login`은 필요한 시점에 사용자가 직접 수행합니다.

`vim`, `tree`, `ripgrep`, `fd-find`는 선택 권장 도구이며 B1-1 CLEAR Gate가 아닙니다.

## B1-1 Mission Package

B1-1에 추가로 필요한 APT 패키지는 `ubuntu-packages.txt`가 Source of Truth입니다.

```text
openssh-server
ufw
acl
cron
procps
iproute2
util-linux
```

확인:

```bash
bash "$CONTROL_TOWER/environments/ubuntu/setup-mission-packages.sh" \
  training/round-01-clear/environment/ubuntu-packages.txt --check
```

누락된 경우만:

```bash
bash "$CONTROL_TOWER/environments/ubuntu/setup-mission-packages.sh" \
  training/round-01-clear/environment/ubuntu-packages.txt --install
```

Package 설치 여부와 실제 command/service 동작은 구분합니다. 설치 후 B1-1 Runtime에서 `sshd`, UFW, ACL, process/network command가 실제로 동작하는지 별도로 검증합니다.

## 필요한 명령

Runtime 시작 전 Ubuntu 내부에서 다음 명령 존재 여부를 확인합니다.

```bash
for c in bash ssh sshd ss ps pgrep df stat getfacl setfacl crontab unzip file runuser git awk grep find; do
    command -v "$c" || echo "[MISSING] $c"
done
```

## OrbStack Runtime Baseline

Ubuntu 내부에서 먼저 다음을 확인합니다.

```bash
cat /etc/os-release
uname -m
uname -a
ps -p 1 -o comm=
systemctl is-system-running || true
hostname
cat /proc/version
whoami
id
```

해석 기준:

- `/etc/os-release` → Ubuntu 24.04 계열 확인
- `uname -m` → 실제 Agent binary 선택 기준
- `ps -p 1 -o comm=` → `systemd` 여부 확인
- `WSL marker not detected`가 나오는 것은 OrbStack에서는 이상이 아닐 수 있음
- macOS CPU 종류만 보고 Guest architecture를 추측하지 않음

## B1-1 중요 포트

- `20022/tcp` — Ubuntu OpenSSH Server
- `15034/tcp` — Agent application

OrbStack 자체의 machine 접속 기능과 B1-1에서 구성하는 `sshd:20022`는 동일한 것으로 간주하지 않습니다. Mission Runtime에서는 Ubuntu 내부 OpenSSH Server와 Port 상태를 별도로 검증합니다.

## 중요 계정/그룹

사용자:

- `agent-admin`
- `agent-dev`
- `agent-test`

그룹:

- `agent-common` — admin/dev/test
- `agent-core` — admin/dev

## 기준 디렉터리

```text
/opt/agent-app
├── upload_files
├── api_keys
└── bin

/var/log/agent-app
```

## UFW / Network 사전조건

```text
macOS / OrbStack network
≠
Ubuntu 내부 UFW
```

R01의 Firewall 판정은 Ubuntu 내부 UFW를 기준으로 합니다.

```bash
sudo ufw status verbose
sudo ss -lntp | grep -E ':(22|20022|15034)\b' || true
```

Host의 network 상태만 보고 UFW PASS를 판정하지 않습니다.

## Secret 사전조건

실제 Secret은 Repository에 저장하지 않습니다.

Runtime에서 필요한 경로만 준비합니다.

```text
$AGENT_HOME/api_keys/t_secret.key
```

값은 사용자가 공식 Mission 원본을 보고 실제 환경에서 직접 입력합니다. 검증 시에도 파일 존재·소유권·권한만 확인하고 `cat` 또는 Secret 값이 보이는 캡처를 Evidence로 남기지 않습니다.

## Runtime 전 안전 확인

- 현재 shell이 **OrbStack Ubuntu 24.04 내부**인지 확인
- Git working tree에 예상하지 못한 변경이 있으면 먼저 검토
- Ubuntu Developer Bootstrap 필수 항목과 B1-1 Mission package 누락 여부 확인
- SSH 변경 전 현재 연결과 설정을 백업
- UFW가 이미 active라면 새 SSH 포트 `20022/tcp`를 먼저 허용하고 기존 SSH 경로는 새 접속 검증까지 유지
- 기존 `agent-*` 사용자/그룹/디렉터리가 있으면 자동 삭제하지 않음
- Agent binary는 반드시 Ubuntu 내부 `uname -m` 실제 결과를 보고 선택
- 실제 Runtime/Evidence 전에는 `✅ CLEAR`로 표시하지 않음
