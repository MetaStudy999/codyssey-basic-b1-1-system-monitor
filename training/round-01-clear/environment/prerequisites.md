# B1-1 R01 — Prerequisites

## 시작 조건

- Ubuntu 22.04 LTS 또는 동등 Linux 환경
- 일반 사용자 계정
- 필요한 시스템 작업을 위한 `sudo` 권한
- Git으로 현재 저장소를 확인할 수 있는 환경
- 공식 `agent-app.zip`

## 필요한 명령

Runtime 시작 전 다음 명령 존재 여부를 확인합니다.

```bash
command -v bash
command -v ssh
command -v sshd
command -v ss
command -v ps
command -v pgrep
command -v df
command -v stat
command -v getfacl
command -v crontab
command -v unzip
```

Ubuntu에서 누락된 도구가 있을 경우 필요한 패키지만 설치합니다.

```bash
sudo apt update
sudo apt install -y openssh-server ufw acl cron unzip procps iproute2
```

> 위 설치 명령은 Runtime 단계에서 현재 상태를 먼저 확인한 뒤 필요한 경우에만 사용합니다.

## B1-1 중요 포트

- `20022/tcp` — SSH
- `15034/tcp` — Agent application

## 중요 계정/그룹

사용자:

- `agent-admin`
- `agent-dev`
- `agent-test`

그룹:

- `agent-common`
- `agent-core`

## Secret 사전조건

실제 Secret은 Repository에 저장하지 않습니다.

Runtime에서 필요한 경로만 준비합니다.

```text
$AGENT_HOME/api_keys/t_secret.key
```

값은 사용자가 실제 환경에서 직접 입력하고, 검증 시에도 파일 존재·권한만 확인합니다. `cat`으로 Evidence를 남기지 않습니다.
