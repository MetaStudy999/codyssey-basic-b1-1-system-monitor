# 06. Agent 애플리케이션 실행환경 구성

> **기억 문장:** 아키텍처에 맞는 제공 Agent를 선택하고, 일반 사용자로 실행해 Boot 5단계·READY·15034를 확인한다.

이 장에서는 원본 B1-1 미션의 제공 애플리케이션을 실제 환경에 배치하고 실행합니다.

---

## 1. 목표

최종 성공 조건은 다음과 같습니다.

```text
환경변수 설정
키 파일 지정 경로에 존재
제공 Agent의 실제 실행 파일 확인
Agent non-root 실행
Boot Sequence 5단계 모두 [OK]
Agent READY 출력
0.0.0.0:15034 LISTEN
```

원본 미션 환경변수:

```text
AGENT_HOME       = /home/agent-admin/agent-app   # 원본 예시를 이 안내서 표준 경로로 사용
AGENT_PORT       = 15034
AGENT_UPLOAD_DIR = $AGENT_HOME/upload_files
AGENT_KEY_PATH   = $AGENT_HOME/api_keys/t_secret.key
AGENT_LOG_DIR    = /var/log/agent-app
```

---

## 2. 제공 Agent 형식을 원본 기준으로 이해한다

원본 미션은 애플리케이션을 "제공 Python 앱"이라고 설명하지만, 데이터파일 설명에는 다음 실행 대상이 명시되어 있습니다.

```text
agent-app-linux-x86   (x86)
agent-app-linux-arm64 (arm apple)
```

따라서 이 저장소는 `agent_app.py`가 반드시 ZIP 내부에 있다고 가정하지 않습니다.

```text
원본 데이터 설명
→ 아키텍처 확인
→ ZIP 실제 목록 확인
→ 해당 실행 파일 선택
→ 실행
```

`monitor.sh`의 원본 요구사항도 `agent_app.py(또는 제공 앱 파일명)`을 허용하므로, 실제 제공 파일명을 기준으로 프로세스를 식별합니다.

---

## 3. 사전 조건

05장이 먼저 완료되어야 합니다.

```text
agent-admin / agent-dev / agent-test 존재
agent-common = admin + dev + test
agent-core   = admin + dev
/home/agent-admin/agent-app
/home/agent-admin/agent-app/upload_files
/home/agent-admin/agent-app/api_keys
/var/log/agent-app
권한·ACL 정상
```

확인:

```bash
id agent-admin
id agent-dev
id agent-test
ls -ld \
  /home/agent-admin/agent-app \
  /home/agent-admin/agent-app/upload_files \
  /home/agent-admin/agent-app/api_keys \
  /var/log/agent-app
```

05장이 미완료라면 Agent 파일을 복사하지 않습니다.

---

## 4. 현재 CPU 아키텍처 확인

```bash
uname -m
```

선택 원칙:

```text
x86_64 / amd64  → agent-app-linux-x86
aarch64 / arm64 → agent-app-linux-arm64
그 외           → [STOP] 제공 파일 호환성 확인
```

현재 실제 실습 환경은 `x86_64`이므로 원본 데이터 설명상 `agent-app-linux-x86`이 대상입니다. 다만 실제 ZIP 내부 경로와 파일 존재 여부는 다음 단계에서 반드시 확인합니다.

---

## 5. ZIP 목록 확인

저장소 루트에서:

```bash
REPO_DIR="$(git rev-parse --show-toplevel)"
unzip -l "$REPO_DIR/agent-app.zip"
```

확인할 항목:

```text
agent-app-linux-x86 존재 여부
agent-app-linux-arm64 존재 여부
최상위 디렉터리 구조
추가 README 또는 실행 안내
```

ZIP 목록을 확인하기 전에 내부 경로를 추측하지 않습니다.

---

## 6. 임시 위치에 안전하게 해제

```bash
rm -rf /tmp/b1-1-agent-extract
mkdir -p /tmp/b1-1-agent-extract
unzip -q "$REPO_DIR/agent-app.zip" -d /tmp/b1-1-agent-extract
find /tmp/b1-1-agent-extract -maxdepth 4 -type f -print | sort
```

x86_64 환경에서는:

```bash
find /tmp/b1-1-agent-extract -type f -name 'agent-app-linux-x86' -print
```

ARM64 환경에서는:

```bash
find /tmp/b1-1-agent-extract -type f -name 'agent-app-linux-arm64' -print
```

정확히 사용할 파일 경로를 확인하지 못하면 `[STOP]`입니다.

---

## 7. Agent 실행 파일만 배치한다

### 중요한 보안 원칙

05장에서 다음 보안 경계를 이미 만들었습니다.

```text
upload_files → agent-common
api_keys     → agent-core only
log          → agent-core only
```

따라서 다음과 같은 재귀 변경은 **사용하지 않습니다.**

```bash
# 금지
sudo chown -R agent-admin:agent-common /home/agent-admin/agent-app
```

이 명령은 `api_keys`를 `agent-common`으로 바꿔 최소 권한 정책을 깨뜨릴 수 있습니다.

### x86_64 예시

실제 해제 경로를 확인한 뒤:

```bash
sudo install -o agent-admin -g agent-core -m 0750 \
  /tmp/b1-1-agent-extract/<실제경로>/agent-app-linux-x86 \
  /home/agent-admin/agent-app/agent-app-linux-x86
```

ARM64라면 파일명만 `agent-app-linux-arm64`로 바꿉니다.

배치 후 보안 디렉터리가 유지되는지 확인합니다.

```bash
stat -c '%U:%G:%a %n' \
  /home/agent-admin/agent-app \
  /home/agent-admin/agent-app/upload_files \
  /home/agent-admin/agent-app/api_keys \
  /var/log/agent-app
```

---

## 8. 환경 파일 설치

저장소 예시 파일에는 비밀값을 넣지 않습니다.

```bash
sudo install -d -o root -g agent-core -m 0750 /etc/agent-app
sudo install -o root -g agent-core -m 0640 \
  "$REPO_DIR/config/agent.env.example" \
  /etc/agent-app/agent.env
```

실행 파일명은 현재 환경에 맞게 별도 설정할 수 있습니다.

x86_64:

```bash
echo 'AGENT_PROCESS_PATTERN=agent-app-linux-x86' | \
  sudo tee -a /etc/agent-app/agent.env >/dev/null
```

ARM64:

```bash
echo 'AGENT_PROCESS_PATTERN=agent-app-linux-arm64' | \
  sudo tee -a /etc/agent-app/agent.env >/dev/null
```

`AGENT_PROCESS_PATTERN`은 제공 Agent 자체의 필수 환경변수가 아니라 `monitor.sh`가 실제 제공 파일명을 찾기 위한 저장소 확장 설정입니다.

검증:

```bash
sudo -u agent-admin bash -c \
  'set -a; source /etc/agent-app/agent.env; set +a; printenv | grep "^AGENT_" | sort'
```

키의 **내용은 출력하지 않습니다.**

---

## 9. 키 파일 생성

원본 미션은 지정 경로에 1줄 테스트 키를 요구합니다. 실제 값은 원본 미션을 보고 로컬에서 입력하며, README·reports·evidence에는 다시 기록하지 않습니다.

```bash
read -rsp 'Enter mission test key: ' B1_KEY
printf '\n'
printf '%s\n' "$B1_KEY" | sudo tee \
  /home/agent-admin/agent-app/api_keys/t_secret.key >/dev/null
unset B1_KEY
```

권한:

```bash
sudo chown agent-admin:agent-core \
  /home/agent-admin/agent-app/api_keys/t_secret.key
sudo chmod 0660 \
  /home/agent-admin/agent-app/api_keys/t_secret.key
```

검증은 값이 아니라 메타데이터만 사용합니다.

```bash
sudo stat -c 'owner=%U group=%G mode=%a path=%n' \
  /home/agent-admin/agent-app/api_keys/t_secret.key
sudo wc -l /home/agent-admin/agent-app/api_keys/t_secret.key
```

---

## 10. Agent를 일반 사용자로 실행

### x86_64

```bash
sudo -u agent-admin -H bash -c '
  set -a
  source /etc/agent-app/agent.env
  set +a
  exec "$AGENT_HOME/agent-app-linux-x86"
'
```

### ARM64

```bash
sudo -u agent-admin -H bash -c '
  set -a
  source /etc/agent-app/agent.env
  set +a
  exec "$AGENT_HOME/agent-app-linux-arm64"
'
```

### 금지

```text
root로 Agent 실행
제공 파일을 확인하지 않고 임의 Python 파일 실행
실행 편의를 위해 api_keys 권한을 넓힘
```

---

## 11. Boot Sequence와 READY 확인

성공 기준:

```text
[1/5] ... [OK]
[2/5] ... [OK]
[3/5] ... [OK]
[4/5] ... [OK]
[5/5] ... [OK]
...
Agent READY
```

부가 문구는 제공 실행 파일에 따라 다를 수 있지만, **5개 `[OK]` + `Agent READY`**는 원본 요구사항입니다.

증빙을 저장할 때 실제 테스트 키 문자열이 노출되지 않는지 먼저 확인합니다.

---

## 12. 프로세스 소유자 확인

x86_64 예시:

```bash
pgrep -af 'agent-app-linux-x86'
```

PID 확인 후:

```bash
ps -o user,pid,ppid,cmd -p <PID>
```

목표:

```text
USER != root
```

---

## 13. 15034 LISTEN 확인

```bash
sudo ss -lntp | grep ':15034\b'
```

원본 목표:

```text
0.0.0.0:15034
```

방화벽도 함께 확인합니다.

```bash
sudo ufw status verbose
```

최종 상태:

```text
Agent process = running
owner         = non-root
0.0.0.0:15034 = LISTEN
15034/tcp     = ALLOW
```

---

## 14. 오류와 복구

### `Exec format error`

아키텍처가 맞지 않는 파일을 실행했을 가능성이 있습니다.

```bash
uname -m
file /home/agent-admin/agent-app/agent-app-linux-*
```

으로 다시 확인합니다.

### `Permission denied`

실행 파일의 `x` 권한과 부모 디렉터리 통과 권한을 확인합니다.

```bash
namei -l /home/agent-admin/agent-app/agent-app-linux-x86
```

### Boot 단계 실패

처음 실패한 Boot 단계부터 환경변수·키 경로·포트·로그 권한을 확인합니다. `READY`만 따로 확인하고 넘어가지 않습니다.

### 15034가 열리지 않음

```text
프로세스 소유자
Boot 출력
AGENT_PORT
다른 프로세스의 15034 사용 여부
실제 bind address
```

순서로 확인합니다.

---

## 15. 요구사항 추적

현재 저장소 단계:

```text
원본 데이터 설명에서 아키텍처별 제공 파일명 확인 = 확인
실제 ZIP 내부 경로 확인                         = TODO
실제 Agent 배치                                = TODO
Boot 5 [OK]                                    = TODO
Agent READY                                     = TODO
0.0.0.0:15034                                  = TODO
```

실제 런타임 검증 전에는 `PASS`로 올리지 않습니다.

---

## 16. 이번 단계 기억하기

### 한 문장

> **아키텍처에 맞는 제공 Agent를 선택하고, 일반 사용자로 실행해 Boot 5단계·READY·15034를 확인한다.**

### 핵심어 3개

```text
ARCH · NON-ROOT · READY
```

### 핵심 명령

```bash
uname -m
unzip -l agent-app.zip
sudo ss -lntp | grep ':15034\b'
```

---

## 17. 완료 체크

- [x] 원본 데이터 설명의 x86/ARM64 제공 파일명 반영
- [x] 재귀 `chown -R` 금지 및 보안 디렉터리 보존 원칙 반영
- [ ] 실제 ZIP 목록 확인
- [ ] 현재 아키텍처용 실행 파일 확인
- [ ] Agent 파일 배치
- [ ] 환경변수 실제 적용
- [ ] 키 파일 생성·권한 검증
- [ ] Agent non-root 실행
- [ ] Boot Sequence 5단계 `[OK]`
- [ ] `Agent READY`
- [ ] `0.0.0.0:15034` LISTEN
- [ ] 증빙 정리

---

## 이동

- [이전: 05. 사용자·그룹·ACL](./05-users-groups-acl.md)
- [다음: 07. monitor.sh](./07-monitor-script.md)
- [전체 목차](./README.md)
