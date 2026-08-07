# 07. `monitor.sh` 설계와 구현

> **기억 문장:** 죽어 있으면 실패하고, 위험하면 경고하고, 기록 실패도 성공으로 숨기지 않는다.

B1-1의 핵심 제출물인 `monitor.sh`를 구현하고 실제 Ubuntu 환경에서 검증하는 단계입니다.

---

## 1. 목표

원본 미션 요구사항은 세 종류로 나뉩니다.

### Health Check — 실패 시 `exit 1`

```text
Agent 프로세스 실행 여부
TCP 15034 LISTEN 여부
```

### Warning — 출력 후 계속

```text
방화벽 비활성
CPU > 20%
MEM > 10%
DISK_USED > 80%
```

### Logging

```text
/var/log/agent-app/monitor.log
[YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%
```

이 저장소는 실행환경·필수명령·로그 쓰기 오류를 `exit 2`로 구분합니다. 원본이 명시한 프로세스/포트 장애의 `exit 1`은 그대로 유지합니다.

---

## 2. 파일 위치와 권한

최종 배치:

```text
/home/agent-admin/agent-app/bin/monitor.sh
owner = agent-dev
group = agent-core
mode  = 750
cron executor = agent-admin
```

`agent-admin`이 `agent-core`에 포함되어 있어 group `r-x` 권한으로 실행할 수 있어야 합니다.

---

## 3. 제공 Agent 프로세스 이름 처리

원본 데이터 설명에는 아키텍처별 제공 파일명이 있습니다.

```text
x86_64 / amd64  → agent-app-linux-x86
aarch64 / arm64 → agent-app-linux-arm64
```

따라서 `monitor.sh`는 `AGENT_PROCESS_PATTERN`이 명시되면 검증된 command signature로 사용하고, 없으면 아키텍처에 따라 위 파일명을 선택합니다. 그 외 아키텍처에서는 임의 Python 파일을 추측하지 않고 설정 오류(`exit 2`)로 종료합니다.

실제 ZIP을 확인한 뒤 `/etc/agent-app/agent.env`에 다음처럼 명시하는 것을 권장합니다.

```text
AGENT_PROCESS_PATTERN=agent-app-linux-x86
```

---

## 4. 환경 파일 로딩

기본 환경 파일:

```text
/etc/agent-app/agent.env
```

cron의 최소 환경에서도 동작하도록 `monitor.sh`가 직접 읽습니다. 단, 셸 코드로 `source`하지 않고 허용된 Agent 단순 `KEY=VALUE`만 파싱합니다. symlink, 명령·함수, 알 수 없는 키와 중복 키는 거부하며 실제 파일은 `root:agent-core:0640`으로 검증합니다. 미션 임계값 20/10/80을 설정 파일이 바꾸지 못하도록 threshold override는 이 파일에서 허용하지 않고 격리 테스트의 프로세스 환경에서만 사용합니다.

기본 핵심값:

```text
AGENT_HOME=/home/agent-admin/agent-app
AGENT_PORT=15034
AGENT_LOG_DIR=/var/log/agent-app
```

---

## 5. 프로세스 Health Check

첫 후보 검색 명령:

```bash
pgrep -f -- "$AGENT_PROCESS_PATTERN"
```

`pgrep -f` 결과만 신뢰하지 않습니다. 각 후보에서 `/proc/<PID>/exe`, NUL 구분 `cmdline`, UID를 확인해 실제 실행 파일/command signature가 일치하고 monitor 자신·부모 셸이 아니며 실행 계정과 같은 PID만 선택합니다. 따라서 파일 경로를 인자로 가진 `tail`, grep류 명령은 Agent로 오인하지 않습니다.

프로세스를 찾지 못하면:

```text
[ERROR] Agent process not found: ...
exit 1
```

입니다.

`pgrep`는 후보 PID를 좁히는 데 사용하고, `/proc` 검사는 신원을 확정하는 데 사용합니다. 실제 소유자는 `verify.sh`에서도 `ps`로 다시 확인합니다.

---

## 6. 포트 Health Check

핵심 명령:

```bash
ss -lntp4H
```

선택한 Agent PID가 IPv4 wildcard `0.0.0.0:15034` LISTEN을 소유하지 않으면:

```text
[ERROR] Agent PID ... does not own 0.0.0.0:15034 LISTEN
exit 1
```

입니다.

프로세스 존재와 서비스 포트 LISTEN은 서로 다른 상태이므로 둘 다 확인하고, 무관한 두 프로세스가 각각 조건 하나씩을 만족하는 false positive를 막기 위해 PID까지 연결합니다. 숫자가 아니거나 `1~65535` 밖인 포트 값은 정규식으로 사용하지 않고 설정 오류로 거부합니다.

---

## 7. 방화벽 점검

방화벽 비활성은 `[WARNING]`만 출력하고 종료하지 않습니다.

현재 구현은 가능한 경우 `ufw status`를 확인하고, 비권한 환경에서는 `/etc/ufw/ufw.conf`와 systemd 상태를 보조 신호로 사용합니다. firewalld 환경에서는 `firewall-cmd --state`를 확인합니다.

이 점검은 **보안 경고**이며 SSH/UFW 최종 정책 검증 자체는 04장과 `verify.sh`가 담당합니다.

---

## 8. CPU 사용률

`/proc/stat`을 두 번 읽어 누적 CPU counter 차이로 짧은 구간 사용률을 계산합니다.

```text
snapshot 1
→ 0.2초
→ snapshot 2
→ total/idle 차이 계산
```

`guest` 계열 값을 중복 합산하지 않도록 user~steal 범위를 사용합니다.

두 snapshot의 counter 차이가 0 이하이거나 결과가 `0~100` 범위를 벗어나면 `0%`로 꾸미지 않고 `exit 2`로 종료합니다.

---

## 9. 메모리 사용률

`/proc/meminfo`의:

```text
MemTotal
MemAvailable
```

을 사용합니다.

```text
MEM% = (MemTotal - MemAvailable) / MemTotal × 100
```

`MemAvailable` 또는 `MemTotal`이 없거나 범위가 잘못되면 빈 값/100%를 기록하지 않고 수집 실패로 처리합니다.

---

## 10. Root 디스크 사용률

```bash
df -P /
```

에서 `/`의 `Use%`를 추출합니다. 원본 요구사항의 **Root partition Used %**에 직접 대응합니다.

`LC_ALL=C`, `df -P`로 형식을 고정하고 `df` 종료 코드와 `Use%` 숫자 범위를 모두 검사합니다.

---

## 11. 임계값

```text
CPU       > 20% → WARNING
MEM       > 10% → WARNING
DISK_USED > 80% → WARNING
```

경계값 자체는 초과가 아닙니다.

```text
20.00 = 경고 아님
20.01 = 경고
```

---

## 12. 로그 쓰기 실패를 성공으로 처리하지 않는다

로그 디렉터리가 존재하고 쓰기 가능한지만 보는 것으로는 부족합니다. 기존 `monitor.log` 자체가 잘못된 소유권으로 쓰기 불가능할 수 있습니다.

현재 구현은 다음을 모두 확인합니다.

```text
로그 디렉터리 존재
로그 디렉터리 쓰기 가능
기존 monitor.log가 있으면 파일 쓰기 가능
실제 >> append 성공 여부
```

append가 실패하면 `exit 2`로 종료합니다.

이 보완으로 logrotate나 권한 오류 때문에 로그 기록이 실패했는데도 마지막에 `exit 0`이 되는 상황을 막습니다.

---

## 13. 로그 파일 권한 정책

05장의 정책은 `/var/log/agent-app`를 `agent-core`가 R/W 가능하도록 구성합니다.

따라서 새 `monitor.log`도 다음 상태를 목표로 합니다.

```text
agent-admin:agent-core
0660
```

`monitor.sh`의 `umask 0007`과 08장의 logrotate `create 0660 agent-admin agent-core`를 일치시킵니다.

---

## 14. 저장소 정적 검증

저장소 루트에서 실제로 실행합니다.

```bash
bash -n scripts/monitor.sh
```

출력이 없고 종료 코드가 `0`이어야 합니다.

선택 검증:

```bash
shellcheck scripts/monitor.sh
```

Codex 감사 환경과 GitHub Actions에서는 저장소 작성본의 구문·격리 테스트를 실행했습니다. 실제 배치본과 사용자 Ubuntu runtime은 별도 `NEEDS-RUNTIME`이며, 정적 성공만으로 최종 `PASS`가 되지 않습니다.

---

## 15. 실제 위치에 배치

```bash
sudo install -d -o agent-dev -g agent-core -m 0750 \
  /home/agent-admin/agent-app/bin

sudo install -o agent-dev -g agent-core -m 0750 \
  scripts/monitor.sh \
  /home/agent-admin/agent-app/bin/monitor.sh
```

확인:

```bash
stat -c '%U:%G:%a %n' \
  /home/agent-admin/agent-app/bin/monitor.sh
```

목표:

```text
agent-dev:agent-core:750
```

---

## 16. 정상 실행

Agent가 정상 실행되고 15034가 LISTEN 중일 때:

```bash
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
echo $?
```

목표:

```text
exit 0
monitor.log 한 줄 증가
```

---

## 17. 장애·경고 테스트

안전한 통합 테스트는 다음 스크립트로 묶습니다.

```bash
sudo bash scripts/acceptance-test.sh \
  --agent-boot-log <Agent 시작 출력 파일>
```

핵심 검증:

```text
프로세스 없음 → exit 1
프로세스 있음 + 미사용 포트 → exit 1
임계값 override → WARNING + exit 0
로그 포맷
ACL 허용 사용자 R/W와 agent-test 읽기·쓰기 차단
cron 자동 증가
```

실제 CPU·메모리·디스크를 위험하게 채우지 않고 임계값을 테스트합니다.

---

## 18. 상태

현재 저장소 코드 기준:

```text
monitor.sh 구현            IMPLEMENTED
저장소 Bash/ShellCheck      TESTED
격리 장애/경고 fixture       TESTED
실제 Ubuntu 배치           NEEDS-RUNTIME
실제 Agent 연동            NEEDS-RUNTIME
실제 장애/경고 테스트       NEEDS-RUNTIME
증빙                         TODO (actual files 0)
```

최종 `PASS`는 실제 Ubuntu 결과와 evidence가 연결된 뒤 부여합니다.

---

## 19. 이번 단계 기억하기

### 한 문장

> **죽어 있으면 실패하고, 위험하면 경고하고, 기록 실패도 성공으로 숨기지 않는다.**

### 핵심어 3개

```text
HEALTH · WARNING · LOG
```

### 핵심 명령

```bash
pgrep -f
ss -lntp4H
tail -n 1 /var/log/agent-app/monitor.log
```

---

## 이동

- [이전: 06. Agent 실행환경](./06-agent-setup.md)
- [다음: 08. 로그와 cron](./08-logging-cron.md)
- [전체 목차](./README.md)
