# 05. 사용자·그룹·디렉터리·ACL 구성

> **기억 문장:** 사람마다 필요한 권한만 주고, 공유와 보안 영역을 분리한다.

이 장에서는 B1-1의 **사용자·그룹·디렉터리·권한 정책**을 구성합니다.

---

## 1. 목표

원본 미션에서 요구하는 계정과 그룹은 다음과 같습니다.

### 사용자

```text
agent-admin  운영·관리, cron 실행
agent-dev    개발·운영, monitor.sh 소유자
agent-test   QA·테스트
```

### 그룹

```text
agent-common = agent-admin + agent-dev + agent-test
agent-core   = agent-admin + agent-dev
```

### 디렉터리

이 안내서는 원본 미션의 `AGENT_HOME` 예시를 입문자용 표준 경로로 사용합니다.

```text
AGENT_HOME=/home/agent-admin/agent-app

/home/agent-admin/agent-app/
├── upload_files/
└── api_keys/

/var/log/agent-app/
```

최종 권한 목표:

```text
upload_files      → agent-common이 R/W
api_keys          → agent-core만 R/W
/var/log/agent-app→ agent-core만 R/W
```

---

## 2. 이해 — 사용자, 그룹, 권한을 왜 나누는가

핵심 원칙은 **Least Privilege(최소 권한)**입니다.

```text
agent-test
   └─ 업로드 영역은 사용 가능
   └─ API Key와 운영 로그는 접근 금지

agent-admin / agent-dev
   └─ 공용 영역 사용 가능
   └─ 핵심 영역 접근 가능
```

모든 사용자에게 `777`을 주면 동작은 쉬울 수 있지만 미션의 권한 설계 목적을 잃습니다.

### 기억할 두 그룹

```text
common = 세 사람 모두
core   = admin + dev만
```

---

## 3. 현재 실제 실습 상태

2026-08-07 현재까지 실제로 확인·수행한 상태는 다음과 같습니다.

```text
agent-admin 사용자 : 아직 없음
agent-dev 사용자   : 아직 없음
agent-test 사용자  : 아직 없음

agent-common 그룹  : 생성됨
agent-core 그룹    : 생성됨
```

즉 **그룹 이름만 생성된 중간 상태**이며, 아직 그룹 멤버십과 디렉터리/ACL은 완성되지 않았습니다.

따라서 05단계는 아직 `PASS` 또는 `TESTED`로 처리하지 않습니다.

---

## 4. 실행 전 확인

사용자 확인:

```bash
getent passwd agent-admin agent-dev agent-test
```

그룹 확인:

```bash
getent group agent-common agent-core
```

현재 최초 사용자 확인에서는 아무 출력이 없었고, 이후 다음 두 그룹을 생성했습니다.

```bash
sudo groupadd agent-common
sudo groupadd agent-core
```

두 명령 모두 오류 없이 완료되었습니다.

---

## 5. 사용자 생성

빠르게 수행할 때는 **없는 사용자만 생성**합니다.

```bash
for user in agent-admin agent-dev agent-test; do
  if id "$user" >/dev/null 2>&1; then
    echo "[SKIP] $user already exists"
  else
    sudo useradd -m -s /bin/bash "$user"
    echo "[OK] created $user"
  fi
done
```

### 명령의 의미

```text
-m            홈 디렉터리 생성
-s /bin/bash  로그인 셸을 Bash로 지정
```

생성 후 확인:

```bash
getent passwd agent-admin agent-dev agent-test
```

세 사용자 모두 보여야 합니다.

---

## 6. 그룹 멤버십 구성

### agent-common

세 사용자를 모두 넣습니다.

```bash
sudo usermod -aG agent-common agent-admin
sudo usermod -aG agent-common agent-dev
sudo usermod -aG agent-common agent-test
```

### agent-core

운영·개발 사용자만 넣습니다.

```bash
sudo usermod -aG agent-core agent-admin
sudo usermod -aG agent-core agent-dev
```

`agent-test`는 `agent-core`에 추가하지 않습니다.

### 검증

```bash
id agent-admin
id agent-dev
id agent-test
```

판정:

```text
agent-admin → agent-common + agent-core
agent-dev   → agent-common + agent-core
agent-test  → agent-common만
```

> 기존 로그인 세션에서는 새 그룹 멤버십이 즉시 반영되지 않을 수 있습니다. `id <사용자>`처럼 시스템 계정 정보를 직접 조회하여 먼저 확인합니다.

---

## 7. AGENT_HOME과 디렉터리 생성

기준값:

```bash
AGENT_HOME=/home/agent-admin/agent-app
```

필요 디렉터리:

```bash
sudo mkdir -p \
  "$AGENT_HOME/upload_files" \
  "$AGENT_HOME/api_keys" \
  /var/log/agent-app
```

현재 쉘에 `AGENT_HOME`이 없다면 먼저:

```bash
export AGENT_HOME=/home/agent-admin/agent-app
```

을 실행한 뒤 사용합니다.

---

## 8. `/home/agent-admin` 통과 권한

`AGENT_HOME`을 `agent-admin`의 홈 아래에 두면 다른 미션 사용자가 하위 디렉터리에 접근하기 위해 부모 디렉터리를 통과할 수 있어야 합니다.

홈 전체를 `755`로 넓게 열기보다 ACL로 `agent-common`에게 **통과(`x`) 권한만** 부여합니다.

```bash
sudo setfacl -m g:agent-common:--x /home/agent-admin
```

확인:

```bash
getfacl /home/agent-admin
```

핵심 목표:

```text
group:agent-common:--x
```

이 권한은 디렉터리 이름을 알고 있을 때 하위 경로로 통과할 수 있게 하지만, 홈 전체를 공용 읽기 디렉터리로 만드는 것과는 다릅니다.

---

## 9. AGENT_HOME 기본 권한

Agent 루트 디렉터리는 세 사용자가 하위 공용 영역에 접근할 수 있도록 읽기·통과 권한을 주되, 임의 수정은 제한합니다.

```bash
sudo chown agent-admin:agent-common "$AGENT_HOME"
sudo chmod 2750 "$AGENT_HOME"
```

의미:

```text
owner agent-admin  = rwx
group agent-common = r-x
others             = ---
setgid             = 설정
```

---

## 10. `upload_files` — 세 사용자 공용 R/W

소유 그룹을 `agent-common`으로 설정합니다.

```bash
sudo chown agent-admin:agent-common "$AGENT_HOME/upload_files"
sudo chmod 2770 "$AGENT_HOME/upload_files"
```

새 파일·디렉터리도 그룹 협업이 유지되도록 기본 ACL을 설정합니다.

```bash
sudo setfacl -m d:u::rwx,d:g::rwx,d:o::--- "$AGENT_HOME/upload_files"
```

확인:

```bash
ls -ld "$AGENT_HOME/upload_files"
getfacl "$AGENT_HOME/upload_files"
```

### 왜 `2`가 붙은 `2770`인가

앞의 `2`는 디렉터리의 **setgid bit**입니다. 이 디렉터리에서 새로 만들어지는 파일·하위 디렉터리가 공용 그룹을 이어받도록 돕습니다.

---

## 11. `api_keys` — agent-core만 R/W

```bash
sudo chown agent-admin:agent-core "$AGENT_HOME/api_keys"
sudo chmod 2770 "$AGENT_HOME/api_keys"
sudo setfacl -m d:u::rwx,d:g::rwx,d:o::--- "$AGENT_HOME/api_keys"
```

확인:

```bash
ls -ld "$AGENT_HOME/api_keys"
getfacl "$AGENT_HOME/api_keys"
```

목표:

```text
owner = agent-admin
group = agent-core
others = ---
```

`agent-test`는 이 디렉터리를 읽거나 쓸 수 없어야 합니다.

---

## 12. `/var/log/agent-app` — agent-core만 R/W

```bash
sudo chown agent-admin:agent-core /var/log/agent-app
sudo chmod 2770 /var/log/agent-app
sudo setfacl -m d:u::rwx,d:g::rwx,d:o::--- /var/log/agent-app
```

확인:

```bash
ls -ld /var/log/agent-app
getfacl /var/log/agent-app
```

이후 `agent-admin`이 cron으로 `monitor.sh`를 실행할 때 이 디렉터리에 로그를 기록할 수 있어야 합니다.

---

## 13. 실제 접근 시험

권한은 `ls -l`만 보고 끝내지 않고 **허용 사용자와 차단 사용자를 직접 시험**합니다.

### 13.1 agent-test가 upload_files에 쓸 수 있는가

```bash
sudo -u agent-test bash -c \
  'touch /home/agent-admin/agent-app/upload_files/.b1-1-test && rm /home/agent-admin/agent-app/upload_files/.b1-1-test'
```

정상: 오류 없이 완료.

### 13.2 agent-test가 api_keys에 접근하지 못하는가

```bash
sudo -u agent-test bash -c \
  'touch /home/agent-admin/agent-app/api_keys/.should-fail'
```

정상 목표:

```text
Permission denied
```

실패 시험 후 파일이 생기지 않았는지도 확인합니다.

```bash
sudo test ! -e /home/agent-admin/agent-app/api_keys/.should-fail \
  && echo "[OK] agent-test blocked"
```

### 13.3 agent-test가 로그 디렉터리에 쓰지 못하는가

```bash
sudo -u agent-test bash -c \
  'touch /var/log/agent-app/.should-fail'
```

정상 목표:

```text
Permission denied
```

### 13.4 agent-admin과 agent-dev가 핵심 영역을 사용할 수 있는가

각 사용자에 대해 `test -r`, `test -w` 또는 안전한 임시 파일 생성·삭제로 확인합니다.

---

## 14. 전체 권한 한 번에 확인

```bash
printf '\n[users]\n'
id agent-admin
id agent-dev
id agent-test

printf '\n[directories]\n'
ls -ld \
  /home/agent-admin \
  /home/agent-admin/agent-app \
  /home/agent-admin/agent-app/upload_files \
  /home/agent-admin/agent-app/api_keys \
  /var/log/agent-app

printf '\n[acl]\n'
getfacl /home/agent-admin
getfacl /home/agent-admin/agent-app/upload_files
getfacl /home/agent-admin/agent-app/api_keys
getfacl /var/log/agent-app
```

---

## 15. 왜 ACL과 일반 권한을 함께 사용하는가

일반 Linux 권한은 기본적으로:

```text
owner / group / others
```

세 범주를 사용합니다.

ACL은 여기에 특정 사용자·그룹 또는 **새 파일에 적용될 기본 권한**을 더 세밀하게 정의할 수 있습니다.

이번 설계에서는:

```text
chown/chgrp + chmod = 기본 소유권과 경계
setgid              = 새 파일의 그룹 일관성
ACL                  = 부모 통과와 기본 상속 정책
```

으로 역할을 나눕니다.

---

## 16. 하지 않는 것

다음 방식은 사용하지 않습니다.

```text
chmod -R 777 ...
모든 사용자를 sudo 그룹에 추가
agent-test를 agent-core에 추가
api_keys를 world-readable로 설정
실제 key 값을 증빙 파일에 출력
```

이런 방식은 미션의 최소 권한 목적과 충돌합니다.

---

## 17. 오류와 복구

### `Permission denied`가 예상하지 않은 곳에서 발생

다음 순서로 부모 디렉터리부터 확인합니다.

```bash
namei -l /home/agent-admin/agent-app/upload_files
getfacl /home/agent-admin
getfacl /home/agent-admin/agent-app
getfacl /home/agent-admin/agent-app/upload_files
```

하위 디렉터리 권한이 맞아도 부모 디렉터리에 `x` 권한이 없으면 접근할 수 없습니다.

### 그룹을 추가했는데 현재 세션에서 반영되지 않음

새 로그인 세션을 사용하거나 `id <사용자>`로 시스템 등록 상태를 먼저 확인합니다.

### ACL 때문에 예상 권한과 다름

```bash
getfacl <경로>
```

에서 `mask::` 값까지 확인합니다. ACL mask는 실제 유효 권한을 제한할 수 있습니다.

### 잘못된 권한을 광범위하게 적용함

`chmod -R`로 다시 덮어쓰기 전에 각 경로의 요구 정책을 분리하여 복구합니다.

```text
AGENT_HOME   → 공용 통과/읽기
upload_files → common R/W
api_keys     → core only R/W
log          → core only R/W
```

---

## 18. 검증과 요구사항 추적

이 장과 연결되는 항목:

| ID | 요구사항 | 현재 실제 상태 |
|---|---|---|
| `IAM-01` | 사용자 3개 생성 | `TODO` |
| `IAM-02` | agent-common 멤버십 | `TODO` — 그룹만 생성됨 |
| `IAM-03` | agent-core 멤버십 | `TODO` — 그룹만 생성됨 |
| `FS-01` | 디렉터리 구조 | `TODO` |
| `ACL-01` | upload_files common R/W | `TODO` |
| `ACL-02` | api_keys core only R/W | `TODO` |
| `ACL-03` | log core only R/W | `TODO` |

실제 사용자 환경에서 위 구현·시험을 수행한 뒤 상태를 `IMPLEMENTED`/`TESTED`로 올립니다. 증빙까지 정리한 뒤 최종 `PASS`로 처리합니다.

---

## 19. 증빙 후보

```text
evidence/05-users-groups-acl/
├── users-groups.txt
├── directory-permissions.txt
├── acl-upload-files.txt
├── acl-api-keys.txt
├── acl-log-dir.txt
└── access-tests.txt
```

`Permission denied` 같은 **의도된 실패 결과도 권한 정책을 증명하는 중요한 증빙**입니다.

---

## 20. 이번 단계 기억하기

### 한 문장

> **사람마다 필요한 권한만 주고, 공유와 보안 영역을 분리한다.**

### 핵심어 3개

```text
common · core · ACL
```

### 핵심 명령 3개

```bash
id <사용자>
getfacl <경로>
sudo -u <사용자> <테스트명령>
```

### 내가 설명할 수 있어야 할 것

> 왜 `agent-test`는 `upload_files`에는 쓸 수 있지만 `api_keys`에는 접근하면 안 되는가?

답의 핵심은 **업무 역할에 필요한 최소 권한만 주어 비밀정보와 운영 자원을 보호하기 위해서**입니다.

---

## 21. 완료 체크

현재 실제 환경 기준:

- [x] `agent-common` 그룹 생성
- [x] `agent-core` 그룹 생성
- [ ] `agent-admin` 생성
- [ ] `agent-dev` 생성
- [ ] `agent-test` 생성
- [ ] `agent-common` 멤버십 완성
- [ ] `agent-core` 멤버십 완성
- [ ] `$AGENT_HOME` 디렉터리 구성
- [ ] `upload_files` 권한·ACL 구성
- [ ] `api_keys` 권한·ACL 구성
- [ ] `/var/log/agent-app` 권한·ACL 구성
- [ ] 허용/차단 접근 시험
- [ ] 11장에서 증빙 정리

05단계는 **진행 중(TODO/부분 구성)**입니다.

---

## 이동

- [이전: 04. 방화벽과 네트워크](./04-firewall-network.md)
- [다음: 06. Agent 실행환경](./06-agent-setup.md)
- [전체 목차](./README.md)
