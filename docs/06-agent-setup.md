# 06. Agent 애플리케이션 실행환경 구성

> **기억 문장:** 환경을 고정하고, 일반 사용자로 실행하고, READY와 15034를 확인한다.

이 장에서는 제공된 `agent-app.zip`을 실제 구조에 맞춰 배치하고, 원본 B1-1 요구사항에 따라 Agent를 **Root가 아닌 일반 사용자**로 실행합니다.

---

## 1. 목표

최종 성공 조건은 다음과 같습니다.

```text
환경변수 5개 설정
키 파일 지정 경로에 존재
Agent non-root 실행
Boot Sequence 5단계 모두 [OK]
Agent READY 출력
0.0.0.0:15034 LISTEN
```

### 원본 미션의 핵심 환경변수

```text
AGENT_HOME       = /home/agent-admin/agent-app   # 원본 예시를 이 안내서 표준으로 사용
AGENT_PORT       = 15034
AGENT_UPLOAD_DIR = $AGENT_HOME/upload_files
AGENT_KEY_PATH   = $AGENT_HOME/api_keys/t_secret.key
AGENT_LOG_DIR    = /var/log/agent-app
```

저장소의 예시 파일:

```text
config/agent.env.example
```

---

## 2. 이해 — ZIP 내부 구조를 추측하지 않는다

원본 미션은 제공 Python 앱을 실행하도록 요구하지만, 현재 GitHub 연결에서는 ZIP 바이너리 내부를 직접 펼쳐 검증할 수 없습니다.

따라서 다음 원칙을 사용합니다.

```text
ZIP 목록 확인
→ 임시 디렉터리에 해제
→ 실제 엔트리 파일 확인
→ 필요한 파일만 AGENT_HOME에 배치
→ 실행
```

원본 미션은 프로세스 확인 대상에 대해 `agent_app.py(또는 제공 앱 파일명)`이라고 표현하므로 **파일명을 임의로 고정하지 않습니다.**

---

## 3. 실행 전 조건

05장이 완료되어 다음이 준비되어 있어야 합니다.

```text
agent-admin 존재
agent-dev 존재
agent-test 존재
agent-common / agent-core 멤버십 정상
/home/agent-admin/agent-app 존재
upload_files 존재
api_keys 존재
/var/log/agent-app 존재
권한·ACL 정상
```

확인 예시:

```bash
id agent-admin
id agent-dev
id agent-test
ls -ld /home/agent-admin/agent-app \
       /home/agent-admin/agent-app/upload_files \
       /home/agent-admin/agent-app/api_keys \
       /var/log/agent-app
```

05장이 미완료라면 Agent 실행으로 넘어가지 않습니다.

---

## 4. 저장소 루트와 ZIP 확인

Git 저장소 안에서 실행합니다.

```bash
REPO_DIR="$(git rev-parse --show-toplevel)"
printf 'REPO_DIR=%s\n' "$REPO_DIR"
ls -lh "$REPO_DIR/agent-app.zip"
```

파일이 없으면 `[STOP]`입니다.

### ZIP 목록 먼저 확인

```bash
unzip -l "$REPO_DIR/agent-app.zip"
```

여기서 다음을 확인합니다.

```text
Python 파일명
최상위 디렉터리 존재 여부
requirements.txt 등 의존성 파일 존재 여부
README 또는 실행 안내 존재 여부
```

> ZIP 목록을 확인하기 전에 특정 내부 경로를 가정하지 않습니다.

---

## 5. 임시 디렉터리에 안전하게 해제

기존 Agent 디렉터리에 곧바로 덮어쓰지 않고 임시 위치에서 구조를 확인합니다.

```bash
rm -rf /tmp/b1-1-agent-extract
mkdir -p /tmp/b1-1-agent-extract
unzip -q "$REPO_DIR/agent-app.zip" -d /tmp/b1-1-agent-extract
find /tmp/b1-1-agent-extract -maxdepth 4 -type f -print | sort
```

### Python 엔트리 후보 확인

```bash
find /tmp/b1-1-agent-extract -maxdepth 4 -type f -name '*.py' -print | sort
```

`agent_app.py`가 있으면 원본 미션의 대표 파일명과 일치합니다.

없다면 임의로 다른 Python 파일을 실행하지 말고 ZIP 안의 README·파일명·코드 구조를 확인해 실제 제공 앱 엔트리를 결정합니다.

---

## 6. Agent 파일 배치

실제 엔트리 파일이 들어 있는 디렉터리를 확인한 뒤 그 디렉터리의 내용을 `AGENT_HOME`에 배치합니다.

예를 들어 엔트리 파일이 `/tmp/b1-1-agent-extract/agent_app.py`에 직접 있다면:

```bash
sudo cp -a /tmp/b1-1-agent-extract/. /home/agent-admin/agent-app/
sudo chown -R agent-admin:agent-common /home/agent-admin/agent-app
```

### `[CHECK]`

ZIP에 최상위 `agent-app/` 같은 디렉터리가 한 번 더 들어 있다면 위 명령을 그대로 사용하지 않습니다.

예:

```text
/tmp/b1-1-agent-extract/agent-app/agent_app.py
```

이라면 실제 앱 루트의 내용만 배치해야 합니다.

```bash
sudo cp -a /tmp/b1-1-agent-extract/agent-app/. /home/agent-admin/agent-app/
```

### 중요

05장에서 만든 `upload_files`, `api_keys`의 보안 그룹·ACL을 덮어쓰지 않도록 배치 후 반드시 권한을 다시 확인합니다.

```bash
ls -ld /home/agent-admin/agent-app/upload_files \
       /home/agent-admin/agent-app/api_keys
getfacl /home/agent-admin/agent-app/upload_files
getfacl /home/agent-admin/agent-app/api_keys
```

필요하면 05장의 권한 정책을 다시 적용합니다.

---

## 7. 환경변수 설정 파일 설치

저장소의 예시 파일에는 비밀값이 없으므로 시스템용 환경 파일로 복사할 수 있습니다.

```bash
sudo install -d -o root -g agent-core -m 0750 /etc/agent-app
sudo install -o root -g agent-core -m 0640 \
  "$REPO_DIR/config/agent.env.example" \
  /etc/agent-app/agent.env
```

확인:

```bash
sudo -u agent-admin bash -c \
  'set -a; source /etc/agent-app/agent.env; set +a; printenv | grep "^AGENT_" | sort'
```

목표:

```text
AGENT_HOME=/home/agent-admin/agent-app
AGENT_KEY_PATH=/home/agent-admin/agent-app/api_keys/t_secret.key
AGENT_LOG_DIR=/var/log/agent-app
AGENT_PORT=15034
AGENT_UPLOAD_DIR=/home/agent-admin/agent-app/upload_files
```

---

## 8. 키 파일 생성

원본 미션은 다음 위치에 **미션에서 지정한 1줄 테스트 키 값**을 요구합니다.

```text
/home/agent-admin/agent-app/api_keys/t_secret.key
```

새 문서나 증빙에 키 값을 다시 기록하지 않고, 로컬 터미널에서 입력받아 파일을 생성합니다.

```bash
read -rsp 'Enter mission test key: ' B1_KEY
printf '\n'
printf '%s\n' "$B1_KEY" | sudo tee /home/agent-admin/agent-app/api_keys/t_secret.key >/dev/null
unset B1_KEY
```

소유권과 권한:

```bash
sudo chown agent-admin:agent-core /home/agent-admin/agent-app/api_keys/t_secret.key
sudo chmod 0660 /home/agent-admin/agent-app/api_keys/t_secret.key
```

### 키 파일 검증

값 자체를 출력하지 않습니다.

```bash
sudo stat -c 'owner=%U group=%G mode=%a path=%n' \
  /home/agent-admin/agent-app/api_keys/t_secret.key
sudo wc -l /home/agent-admin/agent-app/api_keys/t_secret.key
```

목표:

```text
owner=agent-admin
group=agent-core
mode=660
1줄
```

`agent-test` 접근 차단도 다시 확인합니다.

```bash
sudo -u agent-test test -r /home/agent-admin/agent-app/api_keys/t_secret.key \
  && echo "[ERROR] agent-test can read key" \
  || echo "[OK] agent-test blocked"
```

---

## 9. Python 실행 준비 확인

Python 파일이 제공 앱 엔트리라면 다음을 확인합니다.

```bash
python3 --version
```

엔트리 파일 후보가 `agent_app.py`라면:

```bash
find /home/agent-admin/agent-app -maxdepth 3 -type f -name 'agent_app.py' -print
```

### 의존성 파일이 있는 경우

ZIP 내부에 실제로 `requirements.txt`가 있을 때만 그 파일을 기준으로 의존성을 설치합니다. 존재하지 않는 의존성 목록을 문서에서 임의로 만들지 않습니다.

가상환경이 필요하면 Agent 앱의 실제 구조를 확인한 뒤 별도 환경을 구성합니다.

---

## 10. Agent를 일반 사용자로 실행

### 엔트리 파일이 `agent_app.py`인 경우

아래 명령은 `agent-admin` 계정으로 실행합니다.

```bash
sudo -u agent-admin -H bash -c '
  set -a
  source /etc/agent-app/agent.env
  set +a
  exec python3 "$AGENT_HOME/agent_app.py"
'
```

### 엔트리 파일명이 다른 경우

원본 미션이 허용한 **실제 제공 앱 파일명**을 확인해 위 마지막 실행 경로만 바꿉니다.

### 금지

```text
sudo python3 agent_app.py
root 계정으로 Agent 실행
```

Agent는 일반 사용자로 실행해야 합니다.

---

## 11. Boot Sequence와 READY 확인

실행 터미널에서 다음 성공 기준을 확인합니다.

```text
Boot Sequence 1 [OK]
Boot Sequence 2 [OK]
Boot Sequence 3 [OK]
Boot Sequence 4 [OK]
Boot Sequence 5 [OK]
...
Agent READY
```

정확한 부가 문구는 제공 앱 출력에 따라 다를 수 있지만 원본 요구사항은:

```text
5단계 모두 [OK]
마지막 Agent READY
```

입니다.

하나라도 실패하면 `READY`만 보고 넘어가지 않습니다.

---

## 12. 프로세스 소유자 확인

다른 터미널에서 실제 Agent PID를 찾습니다.

`agent_app.py`일 경우:

```bash
pgrep -af 'agent_app.py'
```

PID를 확인한 뒤:

```bash
ps -o user,pid,ppid,cmd -p <PID>
```

목표:

```text
USER = agent-admin 또는 지정한 일반 사용자
USER != root
```

실제 제공 앱 파일명이 다르면 프로세스 검색 문자열도 그 파일명에 맞춥니다.

---

## 13. 15034 LISTEN 확인

```bash
sudo ss -lntp | grep ':15034\b'
```

원본 요구사항의 목표:

```text
0.0.0.0:15034
```

즉 모든 IPv4 인터페이스에서 TCP 15034 연결을 기다리는 상태입니다.

### 방화벽과 함께 확인

```bash
sudo ufw status verbose
```

04장에서 이미 `15034/tcp ALLOW`가 설정되어 있어야 합니다.

성공 상태:

```text
Agent process        = running
process owner        = non-root
0.0.0.0:15034        = LISTEN
UFW 15034/tcp        = ALLOW
```

---

## 14. 환경변수 실제 프로세스 적용 확인

가능하면 Agent 실행 계정에서 환경 파일을 다시 확인합니다.

```bash
sudo -u agent-admin bash -c '
  set -a
  source /etc/agent-app/agent.env
  set +a
  printf "AGENT_HOME=%s\n" "$AGENT_HOME"
  printf "AGENT_PORT=%s\n" "$AGENT_PORT"
  printf "AGENT_UPLOAD_DIR=%s\n" "$AGENT_UPLOAD_DIR"
  printf "AGENT_KEY_PATH=%s\n" "$AGENT_KEY_PATH"
  printf "AGENT_LOG_DIR=%s\n" "$AGENT_LOG_DIR"
'
```

이 명령은 **키 내용이 아니라 키 파일 경로만** 출력합니다.

---

## 15. Agent 종료

원본 미션 안내대로 foreground 실행 중이라면:

```text
Ctrl+C
```

로 종료합니다.

07장과 09장에서 `monitor.sh`의 정상/비정상 테스트를 위해 Agent 실행·종료를 반복할 수 있습니다.

---

## 16. 오류와 복구

### `Permission denied`

먼저 사용자와 경로 권한을 확인합니다.

```bash
id agent-admin
namei -l /home/agent-admin/agent-app
getfacl /home/agent-admin/agent-app/api_keys
getfacl /var/log/agent-app
```

05장의 권한 정책이 깨졌다면 Agent 실행보다 권한부터 복구합니다.

### 환경변수 누락

```bash
sudo -u agent-admin bash -c \
  'set -a; source /etc/agent-app/agent.env; set +a; printenv | grep "^AGENT_" | sort'
```

로 실제 값을 확인합니다.

### 키 오류

키 값을 화면에 출력하지 말고 다음만 확인합니다.

```bash
sudo stat /home/agent-admin/agent-app/api_keys/t_secret.key
sudo wc -l /home/agent-admin/agent-app/api_keys/t_secret.key
```

### `Agent READY`가 나오지 않음

Boot Sequence에서 처음 실패한 단계의 메시지를 기준으로 원인을 찾습니다. READY를 억지로 만들기 위해 권한을 `777`로 넓히지 않습니다.

### 프로세스는 있는데 15034가 없음

다음을 구분해서 확인합니다.

```bash
pgrep -af '<실제 앱 파일명>'
sudo ss -lntp | grep ':15034\b' || true
```

가능한 범주는:

```text
앱 초기화 실패
환경변수 오류
포트 바인딩 실패
다른 프로세스가 15034 사용
앱이 다른 주소/포트에 바인딩
```

입니다.

### 15034 포트가 이미 사용 중

```bash
sudo ss -lntp | grep ':15034\b'
```

으로 기존 프로세스를 확인한 뒤 원인을 파악합니다. 확인 없이 프로세스를 강제 종료하지 않습니다.

---

## 17. 검증과 요구사항 추적

이 장의 주요 추적 항목:

| ID | 요구사항 | 현재 상태 |
|---|---|---|
| `AGENT-01` | AGENT_HOME | `TODO` |
| `AGENT-02` | AGENT_PORT=15034 | `TODO` |
| `AGENT-03` | AGENT_UPLOAD_DIR | `TODO` |
| `AGENT-04` | AGENT_KEY_PATH | `TODO` |
| `AGENT-05` | AGENT_LOG_DIR | `TODO` |
| `KEY-01` | 키 파일·권한·마스킹 | `TODO` |
| `AGENT-06` | non-root 실행 | `TODO` |
| `AGENT-07` | Boot Sequence 5 `[OK]` | `TODO` |
| `AGENT-08` | Agent READY | `TODO` |
| `AGENT-09` | 0.0.0.0:15034 LISTEN | `TODO` |

현재는 문서와 설정 예시를 준비한 상태이며 **실제 Agent 실행 결과는 아직 검증하지 않았으므로 상태를 올리지 않습니다.**

---

## 18. 증빙 후보

```text
evidence/06-agent/
├── agent-files.txt
├── agent-env-masked.txt
├── key-permissions.txt
├── agent-boot.txt
├── agent-process-owner.txt
└── agent-listen-15034.txt
```

`agent-env-masked.txt`에는 환경변수 경로·포트는 기록할 수 있지만 **키 파일의 실제 내용은 기록하지 않습니다.**

---

## 19. 이번 단계 기억하기

### 한 문장

> **환경을 고정하고, 일반 사용자로 실행하고, READY와 15034를 확인한다.**

### 핵심어 3개

```text
ENV · READY · 15034
```

### 핵심 명령 3개

```bash
printenv | grep '^AGENT_'
pgrep -af '<실제 앱 파일명>'
sudo ss -lntp | grep ':15034\b'
```

### 내가 설명할 수 있어야 할 것

> 왜 Agent를 Root가 아니라 일반 사용자로 실행하는가?

답의 핵심은 **애플리케이션 장애나 취약점이 시스템 전체 권한으로 확대되는 위험을 줄이기 위해서**입니다.

---

## 20. 완료 체크

- [ ] 05단계 사용자·권한 구성 완료
- [ ] ZIP 내부 실제 구조 확인
- [ ] 실제 Agent 엔트리 파일 확인
- [ ] Agent 파일 배치
- [ ] 환경변수 적용
- [ ] 키 파일 생성·권한 설정
- [ ] agent-test 키 접근 차단
- [ ] 일반 사용자로 Agent 실행
- [ ] Boot Sequence 5단계 `[OK]`
- [ ] `Agent READY`
- [ ] 프로세스 non-root 확인
- [ ] `0.0.0.0:15034` LISTEN
- [ ] 11장에서 증빙 정리

현재 06단계는 **실행 준비 문서화 완료 / 실제 환경 검증 전 `TODO`**입니다.

---

## 이동

- [이전: 05. 사용자·그룹·ACL](./05-users-groups-acl.md)
- [다음: 07. monitor.sh](./07-monitor-script.md)
- [전체 목차](./README.md)
