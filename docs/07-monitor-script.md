# 07. `monitor.sh` 설계와 구현

> **기억 문장:** 죽어 있으면 실패하고, 위험하면 경고하고, 정상 상태는 로그로 남긴다.

B1-1의 핵심 결과물인 `monitor.sh`를 구현합니다. 실제 소스는 다음 파일입니다.

```text
scripts/monitor.sh
```

---

## 1. 목표

원본 미션의 필수 기능을 다음 세 종류로 나눕니다.

### Health Check — 실패하면 `exit 1`

```text
Agent 프로세스가 실행 중인가?
TCP 15034가 LISTEN 중인가?
```

### Warning — 경고만 하고 계속 진행

```text
방화벽이 비활성인가?
CPU > 20%인가?
MEM > 10%인가?
DISK_USED > 80%인가?
```

### Logging — 정상 상태를 기록

```text
[YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%
```

이 구분을 머릿속에 넣으면 스크립트 구조가 단순해집니다.

```text
죽음 = exit 1
위험 = WARNING
정상 = LOG
```

---

## 2. 파일 요구사항

실제 배치 위치:

```text
$AGENT_HOME/bin/monitor.sh
```

이 안내서의 `AGENT_HOME` 기준:

```text
/home/agent-admin/agent-app
```

따라서 최종 경로:

```text
/home/agent-admin/agent-app/bin/monitor.sh
```

원본 권한 요구사항:

```text
owner = agent-dev
group = agent-core
mode  = 750
cron 실행자 = agent-admin
```

---

## 3. 구현 상태

현재 저장소의 `scripts/monitor.sh`에는 다음 기능이 구현되어 있습니다.

| 기능 | 구현 |
|---|---|
| Agent 프로세스 확인 | 완료 |
| TCP 15034 LISTEN 확인 | 완료 |
| Health 실패 시 `exit 1` | 완료 |
| UFW/firewalld 활성 상태 확인 | 완료 |
| 방화벽 비활성 WARNING | 완료 |
| CPU 사용률 | 완료 |
| 메모리 사용률 | 완료 |
| Root 디스크 사용률 | 완료 |
| CPU >20% 경고 | 완료 |
| MEM >10% 경고 | 완료 |
| DISK >80% 경고 | 완료 |
| 지정 로그 포맷 | 완료 |
| `monitor.log` append | 완료 |
| cron 최소 환경 고려 | 환경 파일 로드 방식 반영 |
| 10MB/10개 회전 | 08장의 logrotate 담당 |

현재 상태는 **코드 구현 완료(IMPLEMENTED)**이며, 실제 Agent가 준비된 Ubuntu 환경에서 정상/실패 시나리오를 검증하기 전까지 `TESTED` 또는 `PASS`로 올리지 않습니다.

---

## 4. 환경 설정 로딩

스크립트는 기본적으로 다음 파일을 읽습니다.

```text
/etc/agent-app/agent.env
```

관련 코드 개념:

```bash
ENV_FILE="${AGENT_ENV_FILE:-/etc/agent-app/agent.env}"
```

환경 파일이 읽을 수 있으면 `source`하여 `AGENT_*` 값을 불러옵니다.

기본값도 가지고 있습니다.

```text
AGENT_HOME=/home/agent-admin/agent-app
AGENT_PORT=15034
AGENT_LOG_DIR=/var/log/agent-app
AGENT_PROCESS_PATTERN=agent_app.py
```

### 왜 환경 파일을 읽는가

cron은 일반 로그인 셸보다 환경변수가 적습니다. 따라서 사람이 터미널에서 `export`한 값에만 의존하면 수동 실행은 되지만 cron에서 실패할 수 있습니다.

```text
터미널 환경에만 의존 ❌
명시적 환경 파일 사용 ✅
```

---

## 5. Agent 프로세스 Health Check

기본 프로세스 패턴:

```text
agent_app.py
```

핵심 방식:

```bash
pgrep -f -- "$AGENT_PROCESS_PATTERN"
```

프로세스를 찾지 못하면:

```text
[ERROR] Agent process not found: ...
```

을 출력하고:

```bash
exit 1
```

합니다.

### 제공 앱 파일명이 다른 경우

원본 미션은 `agent_app.py(또는 제공 앱 파일명)`을 허용합니다.

ZIP을 확인한 뒤 실제 파일명이 다르면 환경에서 다음 값을 지정할 수 있습니다.

```bash
AGENT_PROCESS_PATTERN=<실제 제공 앱 파일명>
```

스크립트 자체를 파일명마다 다시 작성할 필요가 없습니다.

---

## 6. TCP 15034 Health Check

스크립트는 `ss`의 LISTEN 결과에서 `AGENT_PORT`를 확인합니다.

개념:

```bash
ss -lntH
```

목표 포트가 없으면:

```text
[ERROR] Agent port is not LISTEN: tcp/15034
```

후 `exit 1`입니다.

### 프로세스와 포트를 둘 다 보는 이유

다음 상태가 가능하기 때문입니다.

```text
프로세스 있음 + 포트 없음
```

즉 프로그램 프로세스가 살아 있다는 이유만으로 서비스가 정상이라고 판단할 수 없습니다.

---

## 7. 방화벽 상태 — WARNING만

원본 미션은 방화벽이 비활성인 경우 **경고는 출력하되 스크립트를 종료하지 않도록** 요구합니다.

cron에서 interactive sudo를 사용하지 않기 위해 구현은 `systemctl is-active` 기반으로 UFW 또는 firewalld 상태를 확인합니다.

```text
UFW active       → 계속
firewalld active → 계속
확인 실패/비활성 → [WARNING], 계속
```

### 왜 `exit 1`이 아닌가

Agent 자체가 죽었거나 포트가 열리지 않은 것은 즉시 서비스 장애입니다.

반면 방화벽 비활성은 심각한 보안 경고이지만 Agent 프로세스와 상태 수집 자체는 계속할 수 있습니다.

원본 미션이 이 둘을 명시적으로 구분하고 있습니다.

---

## 8. CPU 사용률 수집

`/proc/stat`의 CPU 누적 카운터를 두 번 읽어 짧은 구간의 사용률을 계산합니다.

```text
첫 번째 CPU snapshot
→ 0.2초
→ 두 번째 CPU snapshot
→ 두 시점 차이로 사용률 계산
```

단순히 `top` 화면 문자열을 파싱하는 것보다 locale과 출력 형식 의존성을 줄일 수 있습니다.

CPU 값은 소수점 둘째 자리까지 기록합니다.

예:

```text
CPU:7.42%
```

---

## 9. 메모리 사용률 수집

Linux의 `/proc/meminfo`에서 다음 값을 사용합니다.

```text
MemTotal
MemAvailable
```

개념식:

```text
사용 메모리 비율
= (MemTotal - MemAvailable) / MemTotal × 100
```

`MemAvailable`을 사용하는 이유는 Linux 캐시를 단순히 모두 '사용 불가 메모리'로 보지 않기 위해서입니다.

---

## 10. Root 디스크 사용률

```bash
df -P /
```

에서 Root 파티션(`/`)의 `Use%` 값을 추출합니다.

원본 요구사항은 **Root partition의 Used %**이므로 다른 마운트 포인트의 평균값을 사용하지 않습니다.

---

## 11. 임계값

원본 미션의 임계값을 그대로 사용합니다.

```text
CPU       > 20% → WARNING
MEM       > 10% → WARNING
DISK_USED > 80% → WARNING
```

중요한 부분은 `>`입니다.

```text
20.00% = 초과 아님
20.01% = 초과
```

경고가 발생해도 Health Check가 정상이라면 상태 수집과 로그 기록은 계속합니다.

---

## 12. 로그 기록

로그 파일:

```text
/var/log/agent-app/monitor.log
```

형식:

```text
[YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%
```

구현은 `>`가 아니라:

```bash
>>
```

방식으로 누적합니다.

### `>`와 `>>`

```text
>   기존 내용을 덮어씀
>>  기존 내용 뒤에 추가
```

모니터링 이력은 시간이 지날수록 누적되어야 하므로 `>>`가 필요합니다.

---

## 13. 로그 디렉터리 오류

Agent와 포트가 정상이어도 로그 디렉터리가 없거나 실행자가 쓸 수 없다면 운영 결과를 기록할 수 없습니다.

스크립트는 다음 상황을 별도 설정 오류로 처리합니다.

```text
로그 디렉터리 없음
로그 디렉터리 쓰기 불가
```

이 경우 종료 코드는 `2`를 사용합니다.

### 종료 코드 정책

```text
0 = 정상
1 = Agent Health Check 실패
2 = monitor 실행 환경/필수 명령/로그 설정 오류
```

원본에서 명시한 프로세스·포트 장애의 `exit 1` 요구를 유지하면서, 운영 설정 오류를 구분하기 위한 추가 코드입니다.

---

## 14. 저장소 코드 정적 검사

저장소 루트에서:

```bash
bash -n scripts/monitor.sh
```

출력이 없고 종료 코드가 `0`이면 Bash 문법 검사를 통과한 것입니다.

작성 과정에서도 이 코드에 대해 `bash -n` 구문 검사를 통과시켰습니다. 다만 **최종 증빙은 실제 B1-1 Ubuntu 환경에서 다시 실행하여 저장**합니다.

ShellCheck가 설치되어 있다면 추가 검토:

```bash
shellcheck scripts/monitor.sh
```

ShellCheck는 보조 정적 분석이며 원본 미션의 필수 도구로 가정하지 않습니다.

---

## 15. 실제 위치에 배치

06장의 Agent와 05장의 권한이 준비된 후 수행합니다.

```bash
sudo install -d -o agent-dev -g agent-core -m 0750 \
  /home/agent-admin/agent-app/bin
```

저장소 루트에서:

```bash
sudo install -o agent-dev -g agent-core -m 0750 \
  scripts/monitor.sh \
  /home/agent-admin/agent-app/bin/monitor.sh
```

검증:

```bash
stat -c 'owner=%U group=%G mode=%a path=%n' \
  /home/agent-admin/agent-app/bin/monitor.sh
```

목표:

```text
owner=agent-dev
group=agent-core
mode=750
```

---

## 16. 정상 실행 시험

Agent가 정상 실행되고 15034가 LISTEN 중일 때 `agent-admin`으로 실행합니다.

```bash
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
```

종료 코드:

```bash
echo $?
```

목표:

```text
0
```

출력 예시는 실제 값에 따라 달라집니다.

형태:

```text
[YYYY-MM-DD HH:MM:SS] PID:<pid> CPU:<value>% MEM:<value>% DISK_USED:<value>%
```

임계값을 넘으면 그 전에 `[WARNING]`이 추가로 표시될 수 있습니다.

---

## 17. 프로세스 실패 시험

Agent를 정상적인 방법으로 중지한 상태에서 실행합니다.

```bash
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
echo $?
```

목표 종료 코드:

```text
1
```

목표 오류 유형:

```text
[ERROR] Agent process not found
```

---

## 18. 포트 실패 시험

이 테스트는 **프로세스는 존재하지만 15034는 LISTEN하지 않는 안전한 테스트 조건**을 준비한 경우에 수행합니다.

목표:

```text
프로세스 발견
15034 LISTEN 없음
→ exit 1
```

실제 Agent를 임의로 깨뜨리는 대신 09장에서 통제된 장애 시나리오로 수행합니다.

---

## 19. 로그 확인

정상 실행 후:

```bash
tail -n 5 /var/log/agent-app/monitor.log
```

여러 번 실행했을 때 줄이 계속 추가되어야 합니다.

### 로그 형식 검증 예시

```bash
tail -n 1 /var/log/agent-app/monitor.log | \
  grep -E '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] PID:[0-9]+ CPU:[0-9]+(\.[0-9]+)?% MEM:[0-9]+(\.[0-9]+)?% DISK_USED:[0-9]+%$'
```

---

## 20. logrotate는 이 스크립트에서 분리한다

원본 미션은 `10MB / 10개` 보존 정책의 구현 방법을 자유롭게 허용합니다.

이 저장소에서는 역할을 분리합니다.

```text
monitor.sh = 상태 점검 + 로그 한 줄 기록
logrotate  = 로그 크기와 보관 개수 관리
```

따라서 `monitor.sh` 안에 별도의 파일 회전 코드를 중복 구현하지 않고 08장에서 `config/agent-monitor.logrotate`를 구성합니다.

---

## 21. 오류와 복구

### 프로세스가 있는데 못 찾음

실제 파일명과 `AGENT_PROCESS_PATTERN`을 비교합니다.

```bash
pgrep -af '<실제 앱 파일명>'
```

패턴을 지나치게 넓게 `python`처럼 지정하지 않습니다.

### 포트가 열렸는데 못 찾음

```bash
ss -lntH
```

에서 실제 Local Address:Port를 확인합니다. `AGENT_PORT`가 `15034`인지도 확인합니다.

### cron에서는 실패하고 수동 실행은 성공

환경 파일과 PATH 차이를 먼저 확인합니다.

```text
/etc/agent-app/agent.env
cron의 최소 PATH
실행 사용자 agent-admin
```

이 문제는 08·09장에서 별도로 재현합니다.

### 로그 Permission denied

```bash
id agent-admin
getfacl /var/log/agent-app
```

으로 05장 권한 정책을 다시 확인합니다. `chmod 777`로 우회하지 않습니다.

---

## 22. 검증과 요구사항 추적

현재 저장소 구현 기준:

| ID | 요구사항 | 코드 상태 | 실제 환경 테스트 |
|---|---|---|---|
| `MON-01` | 지정 위치 monitor.sh | 저장소 구현 | 배치 전 |
| `MON-02` | owner/dev, group/core, 750 | 배치 절차 작성 | 미검증 |
| `MON-03` | 프로세스 실패 exit 1 | 구현 | 미검증 |
| `MON-04` | 포트 실패 exit 1 | 구현 | 미검증 |
| `MON-05` | 방화벽 WARNING | 구현 | 미검증 |
| `MON-06` | CPU | 구현 | 미검증 |
| `MON-07` | MEM | 구현 | 미검증 |
| `MON-08` | Root DISK | 구현 | 미검증 |
| `MON-09~11` | 임계값 WARNING | 구현 | 미검증 |
| `MON-12` | 지정 로그 포맷 | 구현 | 미검증 |

즉 현재 07단계는 **IMPLEMENTED**이며, 06 Agent와 05 권한 구성이 실제로 완료된 뒤 런타임 테스트를 수행합니다.

---

## 23. 증빙 후보

```text
evidence/07-monitor/
├── monitor-file-permissions.txt
├── monitor-bash-syntax.txt
├── monitor-success.txt
├── monitor-process-failure.txt
├── monitor-port-failure.txt
├── monitor-warnings.txt
└── monitor-log-format.txt
```

실제 테스트를 하지 않은 예시 출력을 증빙으로 저장하지 않습니다.

---

## 24. 이번 단계 기억하기

### 한 문장

> **죽어 있으면 실패하고, 위험하면 경고하고, 정상 상태는 로그로 남긴다.**

### 핵심어 3개

```text
HEALTH · WARNING · LOG
```

### 핵심 명령 3개

```bash
pgrep -af '<앱 파일명>'
ss -lntH
tail -n 5 /var/log/agent-app/monitor.log
```

### 내가 설명할 수 있어야 할 것

> 왜 방화벽 비활성은 WARNING인데 Agent 프로세스나 포트 실패는 `exit 1`인가?

답의 핵심은 **서비스 자체가 사용할 수 없는 즉시 장애와, 운영상 위험하지만 상태 수집은 계속 가능한 경고를 분리하기 위해서**입니다.

---

## 25. 완료 체크

- [x] `scripts/monitor.sh` 코드 구현
- [x] 프로세스 Health Check 구현
- [x] 포트 Health Check 구현
- [x] Health 실패 `exit 1` 구현
- [x] 방화벽 WARNING 구현
- [x] CPU/MEM/DISK 수집 구현
- [x] 20/10/80 임계값 구현
- [x] 지정 로그 포맷 구현
- [x] append 방식 구현
- [x] cron 환경 파일 로딩 고려
- [x] 작성 과정 Bash 구문 검사
- [ ] 실제 위치 배치 및 750 권한 검증
- [ ] 정상 실행 `exit 0`
- [ ] 프로세스 실패 `exit 1`
- [ ] 포트 실패 `exit 1`
- [ ] 실제 `monitor.log` 누적 확인
- [ ] 11장에서 증빙 정리

현재 상태: **코드 IMPLEMENTED / 실제 환경 TEST 전**.

---

## 이동

- [이전: 06. Agent 실행환경](./06-agent-setup.md)
- [다음: 08. 로그와 cron](./08-logging-cron.md)
- [전체 목차](./README.md)
