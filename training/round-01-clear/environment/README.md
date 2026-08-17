# B1-1 R01 Environment

## 역할

B1-1의 환경설정을 **재현 가능하고 검증 가능하게** 관리합니다.

Round 01의 주 학습 경로는 `BEGINNER-GUIDE.md`에서 사용자가 주요 명령을 직접 실행하는 방식입니다. 이 폴더의 스크립트는 재현·복구를 위한 보조수단입니다.

## 현재 실제 Runtime 환경

```text
macOS Host
└─ OrbStack
   └─ Ubuntu 24.04 Linux Machine
      └─ B1-1 Runtime
```

현재 Phase C에서는 **OrbStack Ubuntu 24.04 내부를 B1-1 실습 대상 Linux**로 사용합니다.

- macOS Host: OrbStack 및 Ubuntu machine 실행·접속
- OrbStack Ubuntu 24.04: Linux 시스템 설정, Agent, monitor, cron, verify 수행

상세 규칙: `ORBSTACK-UBUNTU-24.04.md`

## Ubuntu 24.04 Package

B1-1에서 Base 외에 추가로 필요한 Ubuntu APT 패키지는 `ubuntu-packages.txt`에서 관리합니다.

현재 목록:

```text
openssh-server
ufw
acl
cron
unzip
file
procps
iproute2
util-linux
```

공통 Base(`ca-certificates`, `curl`, `git`)는 Control Tower의 `environments/ubuntu/`에서 관리합니다.

운영 순서:

```text
Ubuntu Base 확인
→ B1-1 ubuntu-packages.txt 확인
→ 누락 패키지만 설치
→ 실제 command/service 확인
→ B1-1 Runtime
```

패키지가 이미 설치되어 있으면 재설치 자체를 목표로 하지 않습니다. 설치 여부와 실제 기능 동작을 구분합니다.

## VS Code Remote Workspace

macOS에서 VS Code를 실행하더라도 실제 B1-1 Repository와 Terminal은 Ubuntu 내부를 사용합니다.

```text
macOS VS Code
→ Remote-SSH `orb`
→ OrbStack Ubuntu 24.04
→ $HOME/codyssey/codyssey-basic-b1-1-system-monitor
→ Ubuntu Bash
```

Primary Workspace는 Ubuntu `$HOME/codyssey/...`에 두고 다음 macOS shared path는 기본 작업경로로 사용하지 않습니다.

```text
/Users/<mac-user>/...
/mnt/mac/Users/<mac-user>/...
```

Repository Root의 `.vscode/settings.json`은 새 Terminal을 `${workspaceFolder}`에서 Bash로 시작하도록 설정합니다.

상세 따라하기: `VS-CODE-REMOTE-UBUNTU.md`

## R01 Golden Path

- 현재 실제 Guest: **OrbStack Ubuntu 24.04**
- 일반 Reference: Ubuntu 22.04 LTS 또는 동등 Linux
- `systemd` 실제 동작 확인
- Bash
- OpenSSH Server
- **UFW**를 R01 기준 Firewall로 사용
- `ss`, `ps`, `pgrep`, `df`, `stat`, `getfacl`, `runuser`, `cron`
- 기준 `AGENT_HOME=/opt/agent-app`

기존 WSL2 Ubuntu도 필요한 기능이 정상 동작하면 사용할 수 있는 Reference 대상이지만, **현재 B1-1 Runtime은 WSL2가 아니라 OrbStack Ubuntu 24.04**입니다.

공식 Mission의 `$AGENT_HOME` 경로는 예시가 허용되는 변수입니다. R01에서는 공유 디렉터리를 한 사용자의 홈 아래에 두어 상위 디렉터리 권한에 막히는 문제를 피하고, `agent-common`/`agent-core` 최소 권한을 명확히 검증하기 위해 `/opt/agent-app`을 Golden Path로 사용합니다.

실제 검증된 macOS/OrbStack/Ubuntu/architecture 버전은 Runtime 단계에서 `versions.md`에 기록합니다. 현재 문서에서는 추측값을 고정하지 않습니다.

## OrbStack 환경 핵심 규칙

- B1-1 Linux 명령은 macOS에서 직접 실행하지 않고 Ubuntu Guest에서 실행합니다.
- `uname -m`은 **Ubuntu 내부 실제 결과**를 Agent binary 선택 기준으로 사용합니다.
- WSL 판별 결과가 `WSL marker not detected`여도 OrbStack에서는 이상이 아닐 수 있습니다.
- OrbStack 자체 machine 접속과 Mission의 Ubuntu OpenSSH Server `20022/tcp`를 구분합니다.
- macOS/OrbStack network와 Ubuntu 내부 UFW는 별도 계층으로 관리합니다.
- PASS/CLEAR는 제품명이나 버전이 아니라 실제 Runtime 결과로 판정합니다.

## 권한 모델

```text
/opt/agent-app               agent-admin:agent-common 0710
├── upload_files/            agent-admin:agent-common 2770 + default ACL
├── api_keys/                agent-admin:agent-core   2770 + default ACL
├── bin/                     agent-dev:agent-core     0750
└── env.sh                   agent-admin:agent-core   0640

/var/log/agent-app           agent-admin:agent-core   2770 + default ACL
```

핵심 의미:

- `agent-common` = admin/dev/test
- `agent-core` = admin/dev
- `upload_files`는 세 계정 모두 R/W
- `api_keys`와 `/var/log/agent-app`은 test가 읽기/쓰기 불가
- `$AGENT_HOME` 자체는 common 그룹에 **traverse(x)**만 주어 불필요한 목록 열람을 줄임

## 파일

- `ORBSTACK-UBUNTU-24.04.md` — 현재 macOS + OrbStack Ubuntu 24.04 Runtime 기준
- `VS-CODE-REMOTE-UBUNTU.md` — VS Code Remote-SSH, Ubuntu Workspace, Bash Terminal 기준
- `ubuntu-packages.txt` — B1-1 전용 Ubuntu APT 추가 패키지
- `prerequisites.md` — 시작 조건과 필요한 도구
- `versions.md` — 기준과 실제 검증 버전
- `setup.sh` — 계정/그룹/디렉터리/monitor 설치 재현 보조
- `verify.sh` — **검증만 수행**, 시스템 설정 변경 금지
- `reset.sh` — 이 보조 스크립트가 설치한 비밀이 아닌 파일만 보수적으로 제거

## SSH/Firewall은 자동 setup 대상에서 제외

SSH와 Firewall은 잘못 자동화하면 원격 접속을 잃을 수 있습니다. Round 01에서는 OrbStack Ubuntu 24.04 내부에서 다음 안전 순서를 사용합니다.

```text
현재 상태 확인
→ SSH/UFW 설정 백업
→ UFW가 이미 active면 20022를 먼저 추가 허용(기존 22 유지)
→ sshd 설정 작성
→ sshd -t 문법 검사
→ sshd -T effective config 확인
→ reload
→ Ubuntu 내부 20022 LISTEN
→ 실제 새 SSH 세션 성공
→ UFW를 20022/15034만 남도록 최종 정리
→ 최종 verify
```

`setup.sh`는 SSH 설정 파일과 Firewall 정책을 자동 변경하지 않습니다.

## Secret

실제 `t_secret.key`는 이 저장소에 만들지 않습니다.

Runtime 머신에서만 `$AGENT_HOME/api_keys/t_secret.key`를 생성하며 다음에 노출하지 않습니다.

- GitHub
- 채팅
- 터미널 캡처에서 값이 보이는 화면
- Evidence
- 로그

검증은 `test -s`, `stat` 등으로 **존재·소유권·권한만 확인**합니다.

## 안전 원칙

- `setup = 구축`
- `verify = 검증만`
- `reset = 현재 Round에서 안전하게 식별 가능한 설치물만 제거`
- 기존 계정/그룹/파일을 발견하면 무조건 삭제·덮어쓰기 하지 않음
- 광범위한 `rm -rf` 금지
- SSH/Firewall 자동 reset 금지
- 시스템 설정은 `현재 상태 → 백업 → 변경 → 문법 검사 → 적용 → 실제 상태 확인` 순서
- Host와 Guest를 혼동하지 않음
