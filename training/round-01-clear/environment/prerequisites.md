# B1-1 R01 — Prerequisites

## 시작 조건

- Ubuntu 22.04 LTS 또는 동등 Linux 환경
- 일반 사용자 계정
- 필요한 시스템 작업을 위한 `sudo` 권한
- Git으로 현재 저장소를 확인할 수 있는 환경
- 공식 `agent-app.zip`
- R01 Golden Path: `AGENT_HOME=/opt/agent-app`
- R01 Firewall: UFW

> 기존 업무/서비스가 동작하는 서버보다 **전용 WSL2/VM/실습 Linux**를 권장합니다. 공식 요구사항은 인바운드 허용을 `20022/tcp`, `15034/tcp`만 남겨야 하므로 다른 서비스가 필요한 서버에서는 충돌할 수 있습니다.

## 필요한 명령

Runtime 시작 전 다음 명령 존재 여부를 확인합니다.

```bash
for c in bash ssh sshd ss ps pgrep df stat getfacl setfacl crontab unzip file runuser git awk grep find; do
    command -v "$c" || echo "[MISSING] $c"
done
```

Ubuntu에서 누락된 도구가 있을 경우 현재 상태를 먼저 확인한 뒤 필요한 패키지만 설치합니다.

```bash
sudo apt update
sudo apt install -y openssh-server ufw acl cron unzip file procps iproute2 util-linux
```

## B1-1 중요 포트

- `20022/tcp` — SSH
- `15034/tcp` — Agent application

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

## Secret 사전조건

실제 Secret은 Repository에 저장하지 않습니다.

Runtime에서 필요한 경로만 준비합니다.

```text
$AGENT_HOME/api_keys/t_secret.key
```

값은 사용자가 공식 Mission 원본을 보고 실제 환경에서 직접 입력합니다. 검증 시에도 파일 존재·소유권·권한만 확인하고 `cat` 또는 Secret 값이 보이는 캡처를 Evidence로 남기지 않습니다.

## Runtime 전 안전 확인

- Git working tree에 예상하지 못한 변경이 있으면 먼저 검토
- SSH 변경 전 현재 연결과 설정을 백업
- UFW가 이미 active라면 새 SSH 포트 `20022/tcp`를 먼저 허용하고 기존 SSH 경로는 새 접속 검증까지 유지
- 기존 `agent-*` 사용자/그룹/디렉터리가 있으면 자동 삭제하지 않음
