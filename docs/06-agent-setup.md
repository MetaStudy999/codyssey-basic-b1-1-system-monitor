# 06. Agent 실행환경 · New Baseline

> **현재 기준:** 2026-08-16 새 기준에서 실제 `agent-app.zip` 구조를 먼저 확인하고, 제공 실행 파일을 일반 사용자로 실행합니다.

이 문서는 과거 급행 수행 문서를 그대로 이어 쓰지 않고 **B1-1 G5 Runtime에서 사용할 안전한 실행 절차**만 남깁니다.

## 1. 성공 조건

다음을 모두 실제 Ubuntu에서 확인해야 합니다.

```text
AGENT_HOME       = /home/agent-admin/agent-app
AGENT_PORT       = 15034
AGENT_UPLOAD_DIR = /home/agent-admin/agent-app/upload_files
AGENT_KEY_PATH   = /home/agent-admin/agent-app/api_keys/t_secret.key
AGENT_LOG_DIR    = /var/log/agent-app

Agent 실행 계정 = 일반 사용자(agent-admin)
Boot Sequence 1~5 = 모두 [OK]
마지막 출력 = Agent READY
LISTEN = 0.0.0.0:15034
```

## 2. 먼저 ZIP 구조를 확인합니다

저장소 루트에서:

```bash
REPO_DIR="$(git rev-parse --show-toplevel)"
rm -rf /tmp/b1-1-agent-extract
mkdir -p /tmp/b1-1-agent-extract
unzip -q "$REPO_DIR/agent-app.zip" -d /tmp/b1-1-agent-extract
find /tmp/b1-1-agent-extract -maxdepth 4 -type f -print | sort
```

여기서 실제 제공 실행 파일명을 확인합니다. **파일명을 추측해서 실행하지 않습니다.**

예를 들어 제공 데이터가 다음처럼 보일 수 있습니다.

```text
agent-app-linux-x86
agent-app-linux-arm64
```

현재 장비 아키텍처 확인:

```bash
uname -m
```

일반적인 대응:

```text
x86_64 / amd64 → x86 실행 파일
aarch64 / arm64 → arm64 실행 파일
```

## 3. 사용자·권한 선행조건 확인

```bash
id agent-admin
id agent-dev
id agent-test
id agent-admin | grep agent-common
id agent-admin | grep agent-core
id agent-dev   | grep agent-common
id agent-dev   | grep agent-core
id agent-test  | grep agent-common
```

디렉터리 확인:

```bash
AGENT_HOME=/home/agent-admin/agent-app
ls -ld \
  "$AGENT_HOME" \
  "$AGENT_HOME/upload_files" \
  "$AGENT_HOME/api_keys" \
  /var/log/agent-app
```

아직 준비되지 않았다면 [05. 사용자·그룹·ACL](./05-users-groups-acl.md)을 먼저 수행합니다.

## 4. Agent 파일 배치 — 보안 디렉터리를 덮어쓰지 않습니다

**다음 명령은 사용하지 않습니다.**

```bash
# 금지
sudo chown -R agent-admin:agent-common /home/agent-admin/agent-app
```

이 명령은 `api_keys`까지 `agent-common` 그룹으로 바꿔 `agent-test`가 접근할 위험을 만들 수 있습니다.

대신 실제 실행 파일을 확인한 뒤 **실행 파일만** 설치합니다. 예를 들어 x86_64 바이너리가 ZIP 최상위에 있다면:

```bash
sudo install -o agent-admin -g agent-core -m 0750 \
  /tmp/b1-1-agent-extract/agent-app-linux-x86 \
  "$AGENT_HOME/agent-app-linux-x86"
```

arm64라면 실제 arm64 파일명으로 바꿉니다.

Python 파일이 실제 제공 엔트리라면 그 파일만 필요한 소유권으로 복사하고, `upload_files`와 `api_keys`의 기존 권한을 유지합니다.

배치 후 반드시 다시 확인합니다.

```bash
ls -ld "$AGENT_HOME/upload_files" "$AGENT_HOME/api_keys"
getfacl "$AGENT_HOME/upload_files"
getfacl "$AGENT_HOME/api_keys"
```

목표:

```text
upload_files → agent-common R/W
api_keys     → agent-core only R/W
```

## 5. 환경파일 설치

먼저 실제 아키텍처에 맞게 `AGENT_PROCESS_PATTERN`을 확인합니다.

```bash
cat config/agent.env.example
```

x86_64 기본 예시를 그대로 쓴다면:

```text
AGENT_PROCESS_PATTERN=agent-app-linux-x86
```

arm64라면 시스템용 파일에서 `agent-app-linux-arm64`로 변경합니다.

```bash
sudo install -d -o root -g agent-core -m 0750 /etc/agent-app
sudo install -o root -g agent-core -m 0640 \
  "$REPO_DIR/config/agent.env.example" \
  /etc/agent-app/agent.env
sudo editor /etc/agent-app/agent.env
```

설정 확인:

```bash
sudo -u agent-admin bash -c '
  set -a
  source /etc/agent-app/agent.env
  set +a
  printenv | grep "^AGENT_" | sort
'
```

키 내용은 출력하지 않습니다.

## 6. `t_secret.key` 생성

미션에서 제공받은 테스트 키는 채팅·Git·증빙 문서에 적지 않고 로컬 터미널에서만 입력합니다.

```bash
read -rsp 'Enter B1-1 mission test key: ' B1_KEY
printf '\n'
printf '%s\n' "$B1_KEY" | sudo tee \
  /home/agent-admin/agent-app/api_keys/t_secret.key >/dev/null
unset B1_KEY

sudo chown agent-admin:agent-core \
  /home/agent-admin/agent-app/api_keys/t_secret.key
sudo chmod 0660 \
  /home/agent-admin/agent-app/api_keys/t_secret.key
```

값을 출력하지 않고 확인합니다.

```bash
sudo stat -c 'owner=%U group=%G mode=%a path=%n' \
  /home/agent-admin/agent-app/api_keys/t_secret.key
sudo wc -l /home/agent-admin/agent-app/api_keys/t_secret.key
sudo -u agent-test test -r \
  /home/agent-admin/agent-app/api_keys/t_secret.key \
  && echo '[ERROR] agent-test can read key' \
  || echo '[OK] agent-test blocked'
```

정상 목표:

```text
owner=agent-admin
 group=agent-core
 mode=660
1줄
[OK] agent-test blocked
```

## 7. 일반 사용자로 Agent 실행

실제 제공 파일에 실행권한이 있는지 확인합니다.

```bash
ls -l "$AGENT_HOME"/agent-app-linux-*
```

x86_64 예:

```bash
sudo -u agent-admin -H bash -c '
  set -a
  source /etc/agent-app/agent.env
  set +a
  exec "$AGENT_HOME/agent-app-linux-x86"
'
```

arm64라면 실제 arm64 실행 파일로 바꿉니다.

Python 엔트리가 실제 제공된 경우에만 `python3 <실제 파일>` 형태를 사용합니다.

**Root로 Agent를 실행하지 않습니다.**

## 8. Boot Sequence와 READY

Agent 실행 터미널에서 다음을 확인합니다.

```text
Boot Sequence 1 [OK]
Boot Sequence 2 [OK]
Boot Sequence 3 [OK]
Boot Sequence 4 [OK]
Boot Sequence 5 [OK]
...
Agent READY
```

하나라도 실패하면 최초 실패 메시지를 기준으로 원인을 해결합니다.

## 9. 프로세스와 포트 확인

다른 터미널에서:

```bash
pgrep -af 'agent-app-linux|agent_app.py'
```

PID를 확인한 뒤:

```bash
ps -o user,pid,ppid,cmd -p <PID>
```

목표:

```text
USER != root
```

TCP 확인:

```bash
sudo ss -lntp | grep ':15034\b'
```

목표:

```text
0.0.0.0:15034
```

## 10. G5에서 저장할 증빙

키 값은 절대 저장하지 않습니다.

```text
evidence/06-agent/
├── agent-files.txt
├── agent-env-paths.txt
├── key-permissions.txt
├── agent-boot.txt
├── agent-process-owner.txt
└── agent-listen-15034.txt
```

## 11. GO / STOP

### GO

- 5개 환경변수 확인
- 키 파일 소유권/권한 정상
- agent-test 키 접근 차단
- Agent 일반 사용자 실행
- Boot Sequence 1~5 `[OK]`
- `Agent READY`
- `0.0.0.0:15034` LISTEN

### STOP

- ZIP 내부 파일명을 아직 모름
- `api_keys`가 agent-common 소유/접근 가능
- Root로 Agent 실행
- Boot Sequence 실패
- 15034 미LISTEN

이 문서의 성공 결과가 실제 Ubuntu에서 확인되기 전까지 G5 Runtime은 PASS가 아닙니다.
