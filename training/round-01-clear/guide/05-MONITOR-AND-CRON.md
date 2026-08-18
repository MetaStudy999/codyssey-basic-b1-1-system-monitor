# B1-1 모듈 05 — 모니터링·로그·cron

> 범위: **STEP 08~11**  
> [← 모듈 04](04-AGENT-RUNTIME.md) · [입문자 가이드 허브](../BEGINNER-GUIDE.md) · [다음: 모듈 06 →](06-VERIFICATION-AND-EVIDENCE.md)

## 📑 이 모듈 목차

- [STEP 08 — monitor.sh 설치와 정상 실행](#step-08)
- [STEP 09 — monitor.log 10MB / 총 10개 로그 회전 격리 검증](#step-09)
- [STEP 10 — agent-admin cron 매분 자동 실행 검증](#step-10)
- [STEP 11 — Health 실패와 Warning-only 분기 격리 검증](#step-11)

---

<a id="step-08"></a>
## STEP 08 — monitor.sh 설치와 정상 실행

## ① 왜 하는가

공식 B1-1의 핵심 구현물은 Bash `monitor.sh`입니다. 이 스크립트는 실행 중인 Agent 프로세스와 TCP `15034` 상태를 확인하고, 정상일 때 CPU·메모리·Root 파티션 디스크 사용률을 수집하며, 임계값을 넘으면 경고를 출력하고 `/var/log/agent-app/monitor.log`에 고정 형식으로 누적 기록해야 합니다.

또한 공식 권한 정책은 Runtime 파일을 `$AGENT_HOME/bin/monitor.sh`에 두고 **owner=`agent-dev`, group=`agent-core`, mode=`750`**, 실제 실행자는 `agent-admin`으로 분리합니다. 따라서 Repository에 Reference `monitor.sh`가 존재하는 것만으로는 충분하지 않고, **실제 Runtime 경로에 정확히 설치되어 `agent-admin`으로 정상 실행되고 로그가 실제 누적되어야** 합니다.

이 STEP은 **STEP 07 실제 Agent 유지 확인 → Repository source 정적 검사 → 기존 설치본 체크포인트 → Runtime 설치 → owner/group/mode·실행 권한 검증 → `agent-admin` 정상 실행 → 종료 코드 확인 → Agent Process/Port 재확인 → 실제 monitor.log 마지막 라인 형식 확인 → 필요 시 최소 복구** 순서로 진행합니다.

> STEP 08은 **정상 경로(Normal Path)**만 검증합니다. Process/Port를 의도적으로 실패시키는 `exit 1` 검증과 강제 Warning 검증은 STEP 11에서 수행하고, `10MB / 10개` 회전 경계는 STEP 09의 격리 테스트에서 검증합니다. 실제 Agent를 일부러 끄거나 운영 로그를 크게 만들어 이 STEP을 통과하려고 하지 않습니다.

## ② 무엇을 하는가

1. STEP 07에서 실제 Boot 5/5, `Agent READY`, `agent-admin` 프로세스, `0.0.0.0:15034` LISTEN을 확인한 Agent가 계속 살아 있는지 다시 확인합니다.
2. Repository의 `training/round-01-clear/monitor.sh`가 존재하고 Bash 문법, shebang, CRLF 문제가 없는지 정적으로 검사합니다.
3. 기존 `/opt/agent-app/bin/monitor.sh`가 있으면 owner/group/mode와 파일 메타데이터를 기록하고 덮어쓰기 전에 백업합니다.
4. Repository Reference를 `/opt/agent-app/bin/monitor.sh`에 owner=`agent-dev`, group=`agent-core`, mode=`0750`으로 설치합니다.
5. 설치본이 Repository source와 동일한지 비교하고, `agent-admin`은 실행 가능하며 `agent-test`는 읽을 수 없는지 유효 접근을 확인합니다.
6. 실행 전 현재 `monitor.log`의 존재 여부와 크기만 기록합니다. 실제 로그 내용을 미리 수정하거나 삭제하지 않습니다.
7. `agent-admin`으로 `env.sh`를 읽은 뒤 설치된 `monitor.sh`를 한 번 정상 실행하고 실제 종료 코드를 확인합니다.
8. 콘솔에서 Process/TCP `[OK]`, CPU/MEM/DISK 값, 필요 시 Warning, 로그 append 결과를 확인합니다.
9. 실행 후 Agent 프로세스와 `15034` LISTEN이 계속 유지되는지 재확인합니다.
10. `/var/log/agent-app/monitor.log`의 마지막 라인이 공식 고정 포맷인지 검증합니다.
11. 실패하면 Agent를 끄거나 Root로 monitor를 우회 실행하지 않고, 실패 항목을 STEP 05/07 또는 Repository source/설치본 중 하나로 좁혀 최소 수정합니다.

## ③ 이번 단계에서 알아야 할 용어

- **관제(Monitoring)** — 서비스와 시스템 상태를 지속적으로 확인하고 이상 징후를 기록하는 운영 활동입니다.
- **상태 점검(Health Check)** — 서비스가 실제로 동작하는지 핵심 조건을 검사하는 과정입니다. B1-1에서는 Process와 TCP Port가 hard failure 조건입니다.
- **정상 경로(Normal Path)** — 의도적인 장애를 만들지 않은 정상 서비스 상태에서 기대하는 실행 흐름입니다.
- **종료 코드(Exit Code)** — 프로세스가 호출자에게 성공/실패를 숫자로 전달하는 값입니다. 정상은 `0`, 공식 Health failure는 `1`입니다.
- **임계값(Threshold)** — 값을 넘었을 때 Warning을 발생시키는 경계입니다.
- **파싱(Parsing)** — 명령 출력에서 필요한 값만 추출하고 원하는 형식으로 정리하는 작업입니다.
- **Root 파티션(Root Filesystem)** — `/`에 마운트된 기본 파일시스템입니다. 공식 DISK_USED 수집 대상입니다.
- **누적 기록(Append)** — 기존 파일을 덮어쓰지 않고 끝에 새 내용을 추가하는 방식입니다. Shell의 `>>`가 사용됩니다.
- **기준 구현(Reference Implementation)** — Repository에서 학습·재현 기준으로 관리하는 소스입니다. Reference 존재 자체는 Runtime 성공을 의미하지 않습니다.
- **설치본(Runtime Copy)** — 실제 Linux 실행 경로에 배치되어 사용되는 파일입니다.
- **체크포인트(Checkpoint)** — 덮어쓰기 전에 기존 설치본 상태와 백업 경로를 기록하는 지점입니다.
- **CRLF(Carriage Return + Line Feed)** — Windows 계열 줄바꿈입니다. Linux에서 직접 실행하는 Bash shebang에 `\r`이 남으면 실행 오류 원인이 될 수 있습니다.

## ④ 필요한 핵심 개념

```mermaid
flowchart TD
    A[STEP 07 Agent 실제 유지] --> B[Reference monitor.sh 정적 검사]
    B --> C[기존 Runtime monitor Checkpoint]
    C --> D[agent-dev:agent-core 0750 설치]
    D --> E[Source = Runtime Copy 검증]
    E --> F[agent-admin Execute / agent-test Block]
    F --> G[monitor.log Before 메타데이터]
    G --> H[agent-admin 정상 실행]
    H --> I{Process + Port Health 정상?}
    I -->|아니오| X[STOP / STEP 07 상태 재확인]
    I -->|예| J[CPU / MEM / DISK 수집]
    J --> K[Threshold 초과 시 Warning만]
    K --> L[monitor.log Append]
    L --> M{exit=0?}
    M -->|아니오| Y[STOP / 실패 지점 최소 진단]
    M -->|예| N[Agent / 15034 재확인]
    N --> O[마지막 로그 포맷 검증]
    O -->|PASS| P[STEP 09]
    O -->|FAIL| Y
```

### 정상 실행과 이후 시험을 분리

```text
STEP 08
→ 실제 Agent가 정상인 상태
→ monitor.sh 정상 실행
→ exit=0
→ 실제 로그 한 줄 누적 확인

STEP 09
→ 10MB / 10개 로그 회전 경계 검증

STEP 11
→ Process failure → exit 1
→ Port failure → exit 1
→ Warning-only 경로 → exit 0
```

이렇게 분리하면 정상 동작, 로그 회전, 장애 처리라는 서로 다른 요구사항을 한 번에 섞지 않고 원인을 좁힐 수 있습니다.

### 구현상 Process와 Port는 별도 Health Check

```text
Process 존재
≠
TCP Port LISTEN
```

프로세스가 살아 있어도 앱이 포트 바인딩에 실패할 수 있고, 반대로 같은 포트를 다른 프로세스가 사용할 수도 있습니다. 현재 R01은 STEP 07에서 Agent PID/사용자/포트를 먼저 연결해 확인한 뒤 STEP 08에서 `monitor.sh`가 그 상태를 감시하도록 합니다.

## ⑤ 실행할 명령어 또는 코드

### 📍 실행 위치(Context)

```text
Host       : OrbStack Ubuntu 24.04 또는 WSL2 Ubuntu 24.04
Terminal A : STEP 07의 Agent foreground Terminal — 그대로 유지
Terminal B : Ubuntu Bash — monitor 설치·실행·검증
Repository : $HOME/codyssey/codyssey-basic-b1-1-system-monitor
권한       : 일반 사용자 + 설치/역할 전환에 필요한 줄에서만 sudo
venv       : 해당 없음
```

### A. STEP 07 실제 Runtime Gate 재확인 — 읽기 전용

**Terminal A의 Agent를 종료하지 않은 상태에서 Terminal B**에서 수행합니다.

```bash
cd "$HOME/codyssey/codyssey-basic-b1-1-system-monitor"
pwd
git branch --show-current
git status --short

AGENT_COUNT="$(pgrep -x agent-app | wc -l)"
printf '[INFO] agent-app count=%s\n' "$AGENT_COUNT"
ps -C agent-app -o user=,uid=,pid=,comm=,args=
sudo ss -lntp | grep ':15034'
sudo ss -lnt | awk '$4 == "0.0.0.0:15034" {ok=1} END {exit !ok}' \
  && echo '[PASS] STEP 07 bind target still active' \
  || echo '[STOP] STEP 07 bind target is no longer active'
```

정상 기준:

```text
agent-app count = 1
user = agent-admin
uid != 0
0.0.0.0:15034 LISTEN
```

하나라도 다르면 `monitor.sh`를 설치·실행해 오류를 덮지 않고 STEP 07 상태부터 복구합니다.

### B. Repository Reference `monitor.sh` 정적 검사

```bash
MONITOR_SRC="training/round-01-clear/monitor.sh"
MONITOR_DST="/opt/agent-app/bin/monitor.sh"
MONITOR_LOG="/var/log/agent-app/monitor.log"

command -v cmp

test -f "$MONITOR_SRC" \
  && echo '[PASS] Reference monitor.sh exists' \
  || echo '[STOP] Reference monitor.sh missing'

head -n 1 "$MONITOR_SRC"
grep -qx '#!/usr/bin/env bash' "$MONITOR_SRC" \
  && echo '[PASS] Bash shebang confirmed' \
  || echo '[STOP] unexpected shebang'

bash -n "$MONITOR_SRC" \
  && echo '[PASS] Reference Bash syntax' \
  || echo '[STOP] Reference Bash syntax failed'

if LC_ALL=C grep -q $'\r' "$MONITOR_SRC"; then
    echo '[STOP] CR character detected; normalize line endings before install'
else
    echo '[PASS] no CR character detected'
fi
```

`bash -n`은 source를 실행하지 않고 문법만 검사합니다. CR 문자가 발견되면 Linux Runtime에 설치하기 전에 원본의 줄바꿈부터 바로잡고 다시 검증합니다. 이 STEP에서 설치본만 임의 수정해 Repository source와 다른 상태를 만들지 않습니다.

### C. 기존 Runtime `monitor.sh` 체크포인트와 백업

```bash
STAMP="$(date +%Y%m%d%H%M%S)"
MONITOR_META_BEFORE="/tmp/b1-1-monitor-before.${STAMP}.txt"
MONITOR_CHECKPOINT="/tmp/b1-1-monitor-checkpoint.${STAMP}.txt"
MONITOR_BAK="${MONITOR_DST}.b1-1-r01.${STAMP}.bak"
MONITOR_EXISTED=no

{
    echo "===== MONITOR_DST: $MONITOR_DST ====="
    if sudo test -e "$MONITOR_DST"; then
        sudo stat -c '%U %G %a %s %n' "$MONITOR_DST"
        sudo file "$MONITOR_DST" 2>/dev/null || true
    else
        echo '[MISSING]'
    fi

    echo "===== MONITOR_LOG: $MONITOR_LOG ====="
    if sudo test -e "$MONITOR_LOG"; then
        sudo stat -c '%U %G %a %s %n' "$MONITOR_LOG"
    else
        echo '[MISSING]'
    fi
} | tee "$MONITOR_META_BEFORE" >/dev/null

if sudo test -e "$MONITOR_DST"; then
    MONITOR_EXISTED=yes
    if sudo cp -a "$MONITOR_DST" "$MONITOR_BAK"; then
        echo '[PASS] existing Runtime monitor.sh backed up'
    else
        echo '[STOP] Runtime monitor.sh backup failed'
    fi
fi

printf 'STAMP=%s\nMONITOR_EXISTED=%s\nMONITOR_META_BEFORE=%s\nMONITOR_BAK=%s\nMONITOR_SRC=%s\nMONITOR_DST=%s\nMONITOR_LOG=%s\n' \
  "$STAMP" "$MONITOR_EXISTED" "$MONITOR_META_BEFORE" "$MONITOR_BAK" \
  "$MONITOR_SRC" "$MONITOR_DST" "$MONITOR_LOG" \
  > "$MONITOR_CHECKPOINT"

printf '[CHECKPOINT] %s\n' "$MONITOR_CHECKPOINT"
```

기존 설치본이 다른 실습·서비스에서 온 것으로 보이거나 백업에 실패했다면 덮어쓰기 전에 STOP합니다. `monitor.log`는 용량이 커질 수 있는 실제 운영 기록이므로 이 STEP에서 복제하지 않고 메타데이터만 남깁니다.

### D. Runtime 경로에 공식 권한 정책으로 설치

B와 C가 모두 정상일 때만 설치합니다.

```bash
sudo install -o agent-dev -g agent-core -m 0750 \
  "$MONITOR_SRC" \
  "$MONITOR_DST"

sudo stat -c '%U %G %a %s %n' "$MONITOR_DST"
sudo bash -n "$MONITOR_DST"

if sudo cmp -s "$MONITOR_SRC" "$MONITOR_DST"; then
    echo '[PASS] Runtime monitor.sh matches Repository Reference'
else
    echo '[STOP] Runtime monitor.sh differs from Repository Reference'
fi
```

정상 기준:

```text
owner = agent-dev
group = agent-core
mode  = 750
Bash syntax = PASS
Runtime file content = Repository Reference와 동일
```

`/opt/agent-app/bin/monitor.sh`를 직접 편집하여 Repository source와 다른 수정본을 만들지 않습니다. 코드 수정이 필요하면 Repository의 Reference를 수정·검증한 뒤 다시 설치하는 흐름을 사용합니다.

### E. 역할별 유효 접근 검증

`agent-dev`는 owner로서 파일을 유지·수정할 수 있고, `agent-admin`은 `agent-core` 구성원으로서 실행할 수 있어야 합니다.

```bash
sudo runuser -u agent-dev -- test -w "$MONITOR_DST" \
  && echo '[PASS] agent-dev can write Runtime monitor.sh' \
  || echo '[STOP] agent-dev cannot write Runtime monitor.sh'

sudo runuser -u agent-admin -- test -x "$MONITOR_DST" \
  && echo '[PASS] agent-admin can execute Runtime monitor.sh' \
  || echo '[STOP] agent-admin cannot execute Runtime monitor.sh'
```

`agent-test`는 `agent-core`가 아니므로 Runtime monitor source를 읽을 수 없어야 합니다.

```bash
if ! sudo runuser -u agent-test -- test -r "$MONITOR_DST"; then
    echo '[PASS] agent-test cannot read Runtime monitor.sh'
else
    echo '[STOP] agent-test can read Runtime monitor.sh'
fi
```

하나라도 예상과 다르면 `chmod 777`이나 `sudo` Root 실행으로 우회하지 않고 STEP 05의 group/mode/ACL을 다시 확인합니다.

### F. 정상 실행 전 실제 로그 기준선 기록

```bash
sudo runuser -u agent-admin -- test -w /var/log/agent-app \
  && echo '[PASS] agent-admin can write log directory' \
  || echo '[STOP] agent-admin cannot write log directory'

if sudo test -e "$MONITOR_LOG"; then
    MONITOR_LOG_SIZE_BEFORE="$(sudo stat -c '%s' "$MONITOR_LOG")"
else
    MONITOR_LOG_SIZE_BEFORE=0
fi

printf '[INFO] monitor.log size before=%s bytes\n' "$MONITOR_LOG_SIZE_BEFORE"

if [ "$MONITOR_LOG_SIZE_BEFORE" -ge 10485760 ]; then
    echo '[INFO] existing active log is at/over 10MB; normal run may rotate it before appending'
fi
```

여기서는 `monitor.log`를 비우거나 삭제하지 않습니다. 기존 active 로그가 이미 10MB 이상이라면 현재 Reference 로직은 정상 실행 중 회전을 수행할 수 있으므로 단순 Before/After 줄 수 증가만으로 성공을 판단하지 않습니다. 회전 자체의 경계 검증은 STEP 09에서 별도 격리 테스트로 수행합니다.

### G. `agent-admin`으로 정상 실행하고 종료 코드 보존

```bash
sudo -u agent-admin -H bash -c '
  set -e
  set +x
  source /opt/agent-app/env.sh
  exec /opt/agent-app/bin/monitor.sh
'
MONITOR_RC=$?
printf '[INFO] monitor_exit=%s\n' "$MONITOR_RC"
```

이 실행은 Root로 `monitor.sh`를 직접 실행하지 않습니다. `env.sh`에는 Secret 값 자체가 들어 있지 않으며, `set +x`로 불필요한 명령 추적을 끈 상태에서 공식 경로·포트와 R01 process name을 적용합니다.

정상 경로의 필수 판정은:

```text
monitor_exit=0
```

입니다. `[WARNING]`이 자연스럽게 출력되더라도 Process와 Port Health가 정상이고 최종 종료 코드가 `0`이면 Warning-only 정책과 양립할 수 있습니다.

### H. 정상 실행 직후 Agent 상태와 로그 누적 검증

먼저 Agent가 monitor 실행 때문에 중단되지 않았는지 확인합니다.

```bash
pgrep -x agent-app | wc -l
ps -C agent-app -o user=,uid=,pid=,comm=
sudo ss -lntp | grep ':15034'
```

그리고 실제 active 로그의 마지막 라인을 확인합니다. `monitor.log`에는 Secret 값이 기록되지 않아야 합니다.

```bash
sudo stat -c '%U %G %a %s %n' "$MONITOR_LOG"
sudo tail -n 1 "$MONITOR_LOG"
```

공식 로그 포맷을 정규식으로 확인합니다.

```bash
sudo tail -n 1 "$MONITOR_LOG" \
  | grep -Eq '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] PID:[0-9]+ CPU:[0-9]+([.][0-9]+)?% MEM:[0-9]+([.][0-9]+)?% DISK_USED:[0-9]+([.][0-9]+)?%$' \
  && echo '[PASS] monitor.log last line matches official format' \
  || echo '[STOP] monitor.log last line format mismatch'
```

정상 로그 형태:

```text
[YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%
```

위 형태는 문서 설명용이고, PASS는 **실제 Runtime에서 방금 생성된 마지막 라인**으로만 판단합니다.

### I. 정상 콘솔 출력 해석

현재 Reference의 정상 실행에서는 대체로 다음 범주의 출력이 나타납니다.

```text
[HEALTH CHECK]
[OK] Process found ...
[OK] TCP 15034 is LISTEN
[OK] Firewall is active
또는 Firewall 확인 실패 시 [WARNING]

[RESOURCE MONITORING]
CPU Usage : ...%
MEM Usage : ...%
DISK Used : ...%
필요 시 CPU/MEM/DISK [WARNING]

[OK] Log appended: /var/log/agent-app/monitor.log
====== MONITOR COMPLETE ======
```

문구 전체를 Reference 예시와 문자 단위로 맞추는 것이 목표가 아닙니다. 공식 요구사항에 연결되는 실제 의미를 봅니다.

```text
Process Health 정상
TCP 15034 Health 정상
CPU/MEM/DISK 실제 값 수집
Threshold 초과는 Warning-only
실제 monitor.log append
최종 exit=0
```

방화벽 Warning은 공식 정책상 hard failure가 아닙니다. 다만 STEP 04에서 UFW가 실제 active임을 이미 검증했는데도 monitor가 확인하지 못한다면 `ufw` 상태와 Reference의 `firewall_is_active()` 판정을 별도로 조사합니다. Warning을 없애기 위해 `agent-admin`에 광범위한 NOPASSWD sudo를 추가하지 않습니다.

### J. 실패 시 최소 진단과 설치본 Recovery

#### 먼저 Runtime source/설치 상태를 확인

```bash
cat "$MONITOR_CHECKPOINT"
cat "$MONITOR_META_BEFORE"
sudo stat -c '%U %G %a %s %n' "$MONITOR_DST" 2>/dev/null || true
sudo bash -n "$MONITOR_DST" 2>/dev/null || true
sudo cmp -s "$MONITOR_SRC" "$MONITOR_DST" \
  && echo '[PASS] source/runtime still identical' \
  || echo '[FAIL] source/runtime differ'
```

#### Process 실패가 나오면

Agent를 Root로 다시 띄우거나 monitor 코드를 바로 수정하지 않습니다. STEP 07의 실제 대상부터 확인합니다.

```bash
pgrep -a -x agent-app || true
ps -C agent-app -o user=,uid=,pid=,comm=,args= || true
sudo ss -lntp | grep ':15034' || true
```

Agent가 사라졌다면 STEP 07을 다시 정상화한 뒤 monitor를 재실행합니다.

#### Port 실패가 나오면

Process가 있다고 포트를 정상으로 가정하지 않습니다.

```bash
sudo ss -lntp | grep ':15034' || true
```

다른 프로세스가 포트를 잡고 있는지, Agent가 LISTEN을 잃었는지 STEP 07 기준으로 좁혀 봅니다.

#### CPU/MEM/DISK 수집 실패가 나오면

```bash
PID="$(pgrep -x agent-app | head -n 1 || true)"
printf '[INFO] PID=%s\n' "$PID"
ps -p "$PID" -o %cpu=,%mem= 2>/dev/null || true
df -P / || true
```

이 진단은 값을 읽는 작업이며 시스템 자원을 인위적으로 올리지 않습니다. PID가 비어 있다면 자원 파싱보다 Agent Process 문제부터 해결합니다.

#### 로그 쓰기 실패가 나오면

```bash
sudo runuser -u agent-admin -- test -w /var/log/agent-app \
  && echo '[PASS] agent-admin can write log dir' \
  || echo '[FAIL] agent-admin cannot write log dir'

sudo stat -c '%U %G %a %n' /var/log/agent-app
sudo getfacl -p /var/log/agent-app
```

STEP 05의 `agent-core` membership, mode, ACL에서 실제 실패 원인 하나만 수정합니다. `chmod 777`로 우회하지 않습니다.

#### 설치 자체를 철회해야 할 때

먼저 체크포인트의 `MONITOR_EXISTED`를 확인합니다.

기존 설치본이 있었고 백업이 실제 존재하면:

```bash
sudo test -f "$MONITOR_BAK" && sudo cp -a "$MONITOR_BAK" "$MONITOR_DST"
sudo stat -c '%U %G %a %s %n' "$MONITOR_DST"
```

기존 설치본이 없었고 이번 STEP에서 처음 만든 파일임이 명확하면, 전체 `$AGENT_HOME/bin`이 아니라 해당 파일 하나만 제거하는 것을 검토합니다.

```bash
sudo rm -f "$MONITOR_DST"
```

`monitor.log`에 정상적으로 추가된 Runtime 기록은 설치본 Recovery를 이유로 자동 삭제하지 않습니다. 실제 운영 로그를 지워 실패를 숨기지 않습니다.

> STEP 08 실패를 복구하기 위해 STEP 07의 정상 Agent를 `pkill`/`kill -9`로 종료하거나, `monitor.sh`를 Root로 실행하거나, `/opt/agent-app` 전체를 삭제하지 않습니다.

### K. 현재 Reference `monitor.sh` 구현을 평가 관점에서 읽기

공식 Evaluation은 단순 실행뿐 아니라 `pgrep`/`ps`, `ss`, CPU/MEM/DISK 파싱과 권한 정책을 설명할 수 있는지도 확인합니다. 현재 Reference의 핵심 구조는 다음과 같습니다.

#### Process Health

```text
pgrep -x "$AGENT_PROCESS_NAME"
→ 정확한 프로세스 이름으로 PID 탐색
→ PID가 없으면 fail()
→ fail()은 exit 1
```

`-x`를 사용하는 이유는 `/opt/agent-app/...`처럼 경로 문자열에 우연히 `agent-app`이 들어 있는 다른 프로세스를 잘못 찾는 false positive를 줄이기 위해서입니다. 현재 구현은 첫 PID를 사용하므로 **STEP 07에서 process count=1을 먼저 검증하는 것이 중요**합니다.

#### TCP Port Health

```text
ss -lnt
→ LISTEN TCP socket 조회
→ awk로 local address가 :15034로 끝나는 행 탐색
→ 없으면 exit 1
```

Process와 Port를 둘 다 확인하는 이유는 프로세스 존재만으로 서비스 소켓 준비 상태를 보장할 수 없기 때문입니다.

#### Firewall 상태

```text
UFW/firewalld active 확인
→ 확인되면 [OK]
→ 확인되지 않으면 [WARNING]
→ 스크립트 종료하지 않음
```

방화벽 전체 허용 규칙은 STEP 04와 `verify.sh`에서 별도로 검증합니다. `monitor.sh`는 운영 중 active 상태를 경고 수준으로 관찰합니다.

#### CPU / MEM

```text
ps -p "$PID" -o %cpu=
ps -p "$PID" -o %mem=
→ awk로 숫자 값 추출
```

현재 R01 Reference는 **모니터링 대상 Agent 프로세스의 CPU/MEM 사용률**을 수집합니다.

#### DISK_USED

```text
df -P /
→ Root filesystem 한 줄 선택
→ Used%의 % 기호 제거
→ 숫자로 사용
```

`-P`는 POSIX 형식의 비교적 안정적인 한 줄 출력을 사용해 파싱하기 쉽게 합니다.

#### Threshold

```text
CPU > 20
MEM > 10
DISK_USED > 80
→ [WARNING]
→ 계속 실행
```

`is_over()`는 `awk`를 사용하여 정수뿐 아니라 소수값도 `>` 비교합니다. 경고는 장애와 달리 스크립트를 중단하지 않습니다.

#### 로그 누적

```text
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
printf ... >> "$MONITOR_LOG"
```

`>>`는 기존 로그를 유지하고 새 라인을 뒤에 붙입니다. `>`를 사용하면 매 실행마다 기존 로그를 덮어쓸 수 있으므로 공식 누적 기록 목적과 맞지 않습니다.

현재 Reference는 로그 append 전에 `rotate_log_if_needed`를 호출합니다. 이 회전 정책의 **10MB / 총 10개 파일** 경계 동작은 다음 STEP 09에서 실제 운영 로그를 훼손하지 않는 격리 경로로 검증합니다.

## ⑥ 명령어와 코드에 입문자가 이해할 수 있는 주석

### STEP 07 Gate와 Repository 확인

- `cd "$HOME/codyssey/codyssey-basic-b1-1-system-monitor"`
  - 실제 B1-1 Repository root로 이동합니다. Reference 파일을 다른 clone이나 Host 경로에서 잘못 설치하는 일을 줄입니다.
- `AGENT_COUNT="$(pgrep -x agent-app | wc -l)"`
  - `pgrep -x`가 찾은 정확한 이름의 PID 수를 `wc -l`로 세어 변수에 저장합니다.
  - 정상 R01은 STEP 07에서 단일 foreground Agent 1개를 기준으로 합니다.
- `ps -C ...`
  - Agent의 user/UID/PID/command를 다시 확인하여 Root나 다른 프로세스를 감시 대상으로 착각하지 않게 합니다.
- `ss ... awk '$4 == "0.0.0.0:15034"'`
  - 공식 STEP 07 바인드가 monitor 설치 직전에도 유지되는지 확인합니다.

### Reference 정적 검사

- `MONITOR_SRC=...`, `MONITOR_DST=...`, `MONITOR_LOG=...`
  - 이후 반복해서 사용하는 source, Runtime 설치 경로, 로그 경로를 변수로 고정합니다.
- `command -v cmp`
  - source와 설치본 byte 내용 비교에 사용할 `cmp` 명령의 존재를 확인합니다.
- `test -f "$MONITOR_SRC"`
  - Repository Reference 파일 존재 여부를 확인합니다.
- `head -n 1`
  - 첫 줄 shebang을 확인합니다. 파일 전체를 실행하는 명령이 아닙니다.
- `grep -qx '#!/usr/bin/env bash'`
  - `-q`는 일치 내용을 출력하지 않고 종료 코드만 사용하고, `-x`는 줄 전체가 정확히 해당 shebang인지 확인합니다.
- `bash -n "$MONITOR_SRC"`
  - 실제 동작 없이 Bash 문법만 검사합니다.
- `LC_ALL=C grep -q $'\r'`
  - byte 중심의 C locale에서 Carriage Return 문자가 남아 있는지 검사합니다.
  - `$'\r'`는 Bash ANSI-C quoting으로 CR 문자를 표현합니다.

### 체크포인트와 설치

- `STAMP="$(date +%Y%m%d%H%M%S)"`
  - 타임스탬프로 기존 설치본 백업 이름 충돌을 줄입니다.
- `stat -c '%U %G %a %s %n'`
  - owner/group/mode/byte size/path를 기록합니다.
- `cp -a`
  - 기존 설치본이 있으면 덮어쓰기 전에 속성을 가능한 한 보존하여 백업합니다.
- `install -o agent-dev -g agent-core -m 0750`
  - 복사와 동시에 공식 owner/group/mode를 적용합니다.
- `cmp -s source destination`
  - `-s`는 차이 내용을 출력하지 않고 동일/다름만 종료 코드로 알려 줍니다. 설치 과정에서 다른 내용이 들어가지 않았는지 확인합니다.

### 역할별 권한

- `runuser -u agent-dev -- test -w`
  - 실제 owner 역할인 `agent-dev`가 Runtime monitor 파일을 쓸 수 있는지 확인합니다.
- `runuser -u agent-admin -- test -x`
  - 실제 cron/수동 실행자인 `agent-admin`이 파일을 실행할 수 있는지 확인합니다.
- `! runuser -u agent-test -- test -r`
  - test 계정의 읽기 차단이 성공 조건이므로 `!`로 결과를 반전합니다.

### 로그 Before 확인

- `stat -c '%s' "$MONITOR_LOG"`
  - 기존 active 로그의 byte 크기만 읽습니다.
- `10485760`
  - 10 MiB에 해당하는 byte 수입니다. 현재 Reference의 기본 회전 기준입니다.
- 기존 로그가 기준 이상이면 다음 정상 실행에서 회전될 수 있으므로 단순 줄 수 증가만으로 성공을 판단하지 않습니다.

### `agent-admin` 정상 실행

- `sudo -u agent-admin -H`
  - Root가 아니라 실제 실행 계정 `agent-admin`으로 명령을 수행하고 target user HOME을 사용합니다.
- `bash -c '...'`
  - login profile을 추가로 읽지 않고 필요한 `env.sh`를 명시적으로 source하여 실행 환경의 변동을 줄입니다.
- `set -e`
  - `env.sh` source 같은 준비가 실패하면 monitor를 잘못된 환경으로 계속 실행하지 않게 합니다.
- `set +x`
  - Shell 명령 추적을 끕니다.
- `source /opt/agent-app/env.sh`
  - `AGENT_PORT`, `AGENT_LOG_DIR`, R01 `AGENT_PROCESS_NAME` 등 non-secret Runtime 설정을 현재 셸에 적용합니다.
- `exec /opt/agent-app/bin/monitor.sh`
  - 중간 Bash를 실제 monitor 프로세스로 교체하여 monitor 종료 코드가 `sudo` 호출 결과로 그대로 전달되게 합니다.
- `MONITOR_RC=$?`
  - 바로 앞 `sudo`/monitor 실행의 종료 코드를 저장합니다.
- 정상 경로는 `MONITOR_RC=0`이어야 합니다. 의도적 Health failure의 `1`은 STEP 11에서 별도로 검증합니다.

### 로그 포맷 검증

- `tail -n 1 "$MONITOR_LOG"`
  - 실제 active log의 가장 마지막 한 줄을 봅니다.
- `grep -E`
  - 확장 정규식으로 timestamp, PID, CPU, MEM, DISK_USED 필드 순서와 `%` 기호를 확인합니다.
- `[0-9]+([.][0-9]+)?`
  - 정수 또는 소수 숫자 형식을 허용합니다.
- 이 검사는 로그의 형식을 확인할 뿐 Secret 값을 읽거나 검색하지 않습니다.

### 진단 명령

- `PID="$(pgrep -x agent-app | head -n 1 || true)"`
  - 현재 Agent PID를 진단용 변수로 얻습니다. STEP 07에서 중복이 없어야 한다는 전제가 있습니다.
- `ps -p "$PID" -o %cpu=,%mem=`
  - monitor가 읽는 것과 같은 프로세스 자원 값을 직접 확인합니다.
- `df -P /`
  - Root filesystem 사용률 원본을 직접 확인합니다.
- `getfacl -p /var/log/agent-app`
  - 로그 쓰기 실패 시 실제 ACL을 확인합니다.

### 재실행 안전성

이 STEP 전체는 **🔴 DO NOT RERUN BLINDLY**입니다. Reference 조회와 검증은 안전하지만 설치는 파일을 덮어쓰고, monitor 정상 실행은 실제 로그를 append하며 기존 로그가 10MB 이상이면 회전을 수행할 수 있습니다.

```text
Git / pgrep / ps / ss / source 정적 조회                 → 🟢 SAFE TO RERUN
bash -n / shebang / CRLF / cmp 검사                      → 🟢 SAFE TO RERUN
체크포인트·기존 설치본 백업                              → 🟡 기존 파일 출처 확인 후
Runtime monitor install                                  → 🔴 Checkpoint + source 검사 후
stat / runuser test                                      → 🟢 SAFE TO RERUN
monitor 정상 실행                                        → 🟡 매 실행마다 실제 로그 append/회전 가능
로그 tail / regex 검증                                   → 🟢 SAFE TO RERUN
설치본 Recovery cp/rm                                    → 🔴 MONITOR_EXISTED 상태 확인 후
Agent 강제 종료 / Root monitor 실행                     → 🚫 이 STEP의 복구 방법 아님
```

> **STOP 기준:** STEP 07 실제 Runtime Gate 미통과, Repository Reference 없음, Bash 문법 실패, Bash shebang 불일치, CRLF/CR 문자 발견, 기존 Runtime monitor 출처 불명, 기존 파일 백업 실패, 설치 owner/group/mode 불일치, source/runtime 내용 불일치, `agent-admin` 실행 권한 없음, `agent-test`가 Runtime monitor를 읽을 수 있음, `monitor_exit != 0`, monitor 실행 후 Agent/15034가 사라짐, 실제 로그 마지막 라인 포맷 불일치 중 하나라도 발생하면 STEP 09로 진행하지 않습니다.

## ⑦ 예상되는 정상 결과

설치 검증:

```text
Reference monitor.sh Bash syntax = PASS
CR character = 없음
Runtime path = /opt/agent-app/bin/monitor.sh
owner = agent-dev
group = agent-core
mode = 750
Repository Reference와 Runtime Copy 동일
agent-dev write = 가능
agent-admin execute = 가능
agent-test read = 불가
```

정상 실행에서는 실제 환경에 따라 숫자와 Warning 유무는 달라질 수 있지만 다음 의미가 확인되어야 합니다.

```text
Process Health = [OK]
TCP 15034 Health = [OK]
CPU Usage = 실제 숫자
MEM Usage = 실제 숫자
DISK Used = 실제 숫자
Threshold 초과 시 [WARNING] 가능
Log appended = [OK]
monitor_exit = 0
```

실행 후:

```text
agent-app process count = 1 유지
user = agent-admin 유지
TCP 15034 LISTEN 유지
monitor.log 마지막 라인 = 공식 고정 포맷
```

## ⑧ 그 결과가 의미하는 것

Repository의 Reference 구현이 단순 예시 파일에 머무르지 않고 **실제 Runtime 설치본 → 공식 owner/group/mode → 역할별 실행 권한 → 정상 Agent Health Check → CPU/MEM/DISK 수집 → Warning-only 분리 → 실제 로그 누적 → exit 0**까지 연결되었다는 의미입니다.

이 단계가 실제로 성공한 뒤에야 `monitor.sh`의 정상 경로가 Runtime에서 동작한다고 말할 수 있습니다. 그러나 아직 `10MB / 10개` 회전 경계, cron 자동 실행, Process/Port 실패 `exit 1`, 강제 Warning 경로, 통합 검증(Verification), Evidence가 남아 있으므로 B1-1 전체 PASS/CLEAR는 아닙니다.

## ⑨ 자주 발생하는 오류와 해결 방법

- `bash -n` 실패 → 설치하지 말고 Repository Reference의 해당 문법 오류를 먼저 수정·재검증.
- shebang이 다름 → 공식 Bash-only 제약과 현재 Reference 의도를 확인. Runtime 설치본만 임의 수정하지 않음.
- CRLF/CR 발견 → Git/Editor의 line ending을 LF로 바로잡고 Reference에서 재검증한 뒤 설치. Linux 설치본만 `sed -i`로 임시 변환하여 source와 다르게 만들지 않음.
- 기존 `/opt/agent-app/bin/monitor.sh` 출처를 모름 → 덮어쓰기 STOP. 체크포인트와 이전 실습 여부 확인.
- `cmp` 결과가 다름 → 설치 대상/source 경로를 다시 확인. Runtime 파일을 직접 고치는 대신 Reference를 기준으로 다시 설치.
- owner/group/mode가 다름 → `install -o agent-dev -g agent-core -m 0750`이 실제 성공했는지와 상위 `bin` 경로 정책 확인.
- `agent-admin` 실행 불가 → `id agent-admin`, `agent-core` membership, `$AGENT_HOME`/`bin` traversal, mode를 STEP 05 기준으로 확인. `chmod 777` 금지.
- `agent-test`가 monitor를 읽음 → `agent-test`의 core membership, `bin`/파일 ACL·mode를 확인하고 문제 항목 하나만 수정.
- `Agent process not found` → monitor 코드를 먼저 바꾸지 말고 STEP 07 Agent가 여전히 실행 중인지 `pgrep/ps`로 확인.
- `TCP 15034 is not LISTEN` → Process가 있어도 Port는 별도이므로 `ss`와 STEP 07 Terminal A 상태 확인.
- CPU/MEM 값 수집 실패 → Agent PID가 실행 중인지 확인한 뒤 직접 `ps` 출력과 Reference parsing 비교.
- DISK_USED 수집 실패 → `df -P /` 원문 확인. Root filesystem 자체 문제를 우회하기 위해 다른 경로로 임의 변경하지 않음.
- Firewall `[WARNING]` → 공식상 Warning-only. STEP 04 UFW 실제 상태를 확인하고, active인데도 탐지 실패하면 `firewall_is_active()`의 non-root 판정 경로를 조사. NOPASSWD sudo를 광범위하게 추가하지 않음.
- CPU/MEM/DISK `[WARNING]` → 정상 환경에서 임계값을 실제로 초과했다면 경고 자체는 정상이며 스크립트는 계속 진행해야 함. 의도적인 Warning 검증은 STEP 11에서 수행.
- `Log directory is not writable` → `runuser`, `stat`, `getfacl`로 STEP 05 최소 권한 정책 확인. Root 실행으로 우회 금지.
- `monitor_exit`가 1 → 정상 경로 PASS 아님. 콘솔의 첫 `[FAIL]` 원인을 해결한 뒤 다시 실행.
- log 마지막 줄 형식 FAIL → Reference source/runtime 동일성, 실제 마지막 라인, append 로직을 확인. 예상 예시 문자열을 Evidence로 대체하지 않음.
- 기존 log가 10MB 이상이라 정상 실행 중 `.1`로 이동함 → Reference의 자동 회전 가능 동작. active log의 새 마지막 라인을 확인하고 STEP 09에서 격리된 10MB/10개 경계를 별도 검증.
- 복구 필요 → `MONITOR_CHECKPOINT`의 `MONITOR_EXISTED`와 백업 경로를 확인해 정확한 설치 파일 하나만 복구. 실제 monitor.log 전체 삭제 금지.

## ⑩ 완료 확인

- [ ] STEP 07 실제 Boot 5/5 / Agent READY / agent-admin process / 0.0.0.0:15034 Gate가 현재도 유지됨
- [ ] B1-1 Repository root / Branch / working tree 확인
- [ ] Reference `training/round-01-clear/monitor.sh` 존재
- [ ] Bash shebang 확인
- [ ] `bash -n` Reference 문법 PASS
- [ ] CRLF/CR 문자 없음
- [ ] 기존 Runtime monitor 존재 여부와 메타데이터 Checkpoint 저장
- [ ] 기존 Runtime monitor가 있었다면 덮어쓰기 전 백업 성공
- [ ] Runtime 경로 `/opt/agent-app/bin/monitor.sh`
- [ ] owner=`agent-dev`
- [ ] group=`agent-core`
- [ ] mode=`750`
- [ ] 설치본 Bash 문법 PASS
- [ ] Repository Reference = Runtime Copy 내용 동일
- [ ] `agent-dev` Runtime monitor write 가능
- [ ] `agent-admin` Runtime monitor execute 가능
- [ ] `agent-test` Runtime monitor read 차단
- [ ] `/var/log/agent-app`에 agent-admin write 가능
- [ ] 실행 전 monitor.log size 메타데이터 확인
- [ ] Root가 아닌 `agent-admin`으로 정상 실행
- [ ] Process Health `[OK]`
- [ ] TCP 15034 Health `[OK]`
- [ ] CPU/MEM/DISK 실제 값 수집
- [ ] 자연 발생 Warning은 hard failure와 구분
- [ ] `[OK] Log appended` 실제 확인
- [ ] `monitor_exit=0`
- [ ] monitor 실행 후 Agent process 1개 유지
- [ ] monitor 실행 후 TCP 15034 LISTEN 유지
- [ ] 실제 `monitor.log` 마지막 라인 확인
- [ ] 마지막 라인이 공식 `[YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%` 포맷에 맞음
- [ ] 실패 시 Agent 종료/Root 실행/광범위 권한 완화 없이 최소 진단
- [ ] 설치본 Recovery가 필요하면 `MONITOR_EXISTED` 기준으로 정확한 파일만 복구
- [ ] **아직 10MB/10개 회전 Runtime 검증은 STEP 09 전이므로 PASS로 기록하지 않음**
- [ ] **아직 Process/Port failure exit 1과 강제 Warning 경로는 STEP 11 전이므로 PASS로 기록하지 않음**

---

<a id="step-09"></a>
## STEP 09 — monitor.log 10MB / 총 10개 로그 회전 격리 검증

## ① 왜 하는가

공식 B1-1은 `monitor.log`가 계속 커져 디스크를 고갈시키지 않도록 **10MB / 10개 파일**의 로그 용량 관리 정책을 구현하고 실제 동작을 설명할 수 있어야 합니다. 현재 R01 Reference `monitor.sh`는 별도 `logrotate` 설정이 아니라 Bash 내부의 `rotate_log_if_needed()` 함수로 이 정책을 구현합니다.

운영 경로 `/var/log/agent-app`의 실제 로그를 10MB까지 인위적으로 키우거나 기존 회전 파일을 삭제해서 시험하면 실제 증빙과 운영 기록을 손상시킬 수 있습니다. 따라서 이 STEP은 **STEP 08 정상 실행 Gate 재확인 → 운영 로그 메타데이터 기준선 → `mktemp` 고유 격리 디렉터리 → 정확한 회전 경계와 기존 `.1~.9` 마커 구성 → 실제 설치된 `monitor.sh`를 `agent-admin`으로 격리 실행 → `.1~.9` 이동 관계와 총 개수 검증 → 새 active 로그 포맷 검증 → 운영 로그 불변 확인 → 증빙 수집 후 범위 제한 정리** 순서로 수행합니다.

> 공식 문서의 표현은 **10MB / 10개**입니다. 현재 R01 Reference 구현은 그 정책을 코드에서 `MAX_LOG_BYTES=10485760`, `MAX_TOTAL_LOG_FILES=10`으로 구체화합니다. `10485760` byte는 10 MiB에 해당하며, 이것은 **R01 구현 세부값**이지 공식 요구 문구를 다른 단위로 바꾸는 것이 아닙니다.

## ② 무엇을 하는가

1. STEP 08의 정상 경로가 실제로 성공했고, Agent 1개와 TCP `15034`가 계속 정상인지 다시 확인합니다.
2. Repository Reference와 `/opt/agent-app/bin/monitor.sh` 설치본이 같은지 확인합니다.
3. 실제 `/var/log/agent-app/monitor.log`의 크기와 수정 시각만 저장하여 격리 시험 전후 비교 기준으로 사용합니다.
4. 고정 `/tmp/b1-1-log-test`를 지우지 않고 `mktemp -d`로 이번 실행 전용 디렉터리를 만듭니다.
5. active `monitor.log`을 R01 회전 경계인 정확히 `10485760` byte로 만들고, `.1`~`.9`에는 서로 다른 식별 마커를 넣습니다.
6. 실행 전 active + `.1`~`.9`가 정확히 10개인지 확인합니다.
7. 실제 설치된 `monitor.sh`를 `agent-admin`으로 실행하되 `AGENT_LOG_DIR`, `MAX_LOG_BYTES`, `MAX_TOTAL_LOG_FILES`만 **이번 자식 프로세스에서** 격리 경로/시험값으로 override합니다.
8. 실행 후 old active가 `.1`로 이동했는지, old `.1→.2` … old `.8→.9`가 되었는지, 기존 old `.9`가 제거되었는지 확인합니다.
9. 새 active `monitor.log`가 다시 생성되어 실제 공식 포맷의 한 줄을 포함하는지 확인합니다.
10. active + `.1`~`.9`가 정확히 총 10개이고 `.10`은 존재하지 않는지 확인합니다.
11. 시험 전후 운영 `monitor.log` 메타데이터가 같아 격리 시험이 운영 로그를 건드리지 않았는지 확인합니다.
12. 필요한 Evidence를 먼저 남긴 뒤, 정확한 `mktemp` 경로와 예상 파일만 대상으로 정리합니다.

## ③ 이번 단계에서 알아야 할 용어

- **로그 회전(Log Rotation)** — 현재 active 로그가 기준 크기에 도달하면 이전 로그로 넘기고 새 active 로그를 시작하는 방식입니다.
- **보존 정책(Retention Policy)** — 얼마나 큰 로그를 몇 개까지 유지할지 정하는 규칙입니다.
- **활성 로그(Active Log)** — 현재 새 기록이 추가되는 `monitor.log`입니다.
- **회전 로그(Rotated Log)** — 이전 기록을 보관하는 `monitor.log.1`, `.2` 같은 파일입니다.
- **회전 경계(Rotation Boundary)** — 회전 여부를 결정하는 크기 기준입니다. 현재 R01 구현은 `10485760` byte입니다.
- **격리 시험(Isolated Test)** — 실제 운영 데이터 대신 별도 임시 경로에서 같은 코드를 실행해 동작을 재현하는 시험입니다.
- **마커(Marker)** — 파일이 회전 후 어느 번호로 이동했는지 추적하기 위해 넣는 식별 문자열입니다.
- **희소 파일(Sparse File)** — `truncate`처럼 논리적 파일 크기를 크게 만들되 실제 디스크 블록을 전부 데이터로 채우지 않을 수 있는 파일입니다.
- **메타데이터(Metadata)** — 파일 내용 자체가 아니라 크기, 수정 시각, owner/mode 같은 속성 정보입니다.
- **환경변수 재정의(Environment Override)** — 원본 설정 파일을 수정하지 않고 특정 실행에만 다른 환경값을 전달하는 방식입니다.

## ④ 필요한 핵심 개념

```mermaid
flowchart TD
    A[STEP 08 정상 경로 실제 PASS] --> B[운영 log 메타데이터 Before]
    B --> C[mktemp 격리 디렉터리]
    C --> D[active = 정확히 10485760 bytes]
    D --> E[old .1 ~ .9 marker 생성]
    E --> F[실행 전 총 10개 확인]
    F --> G[agent-admin으로 monitor 격리 실행]
    G --> H{active size >= threshold?}
    H -->|예| I[old .9 삭제]
    I --> J[old .8→.9 ... old .1→.2]
    J --> K[old active→.1]
    K --> L[new active에 실제 monitor 한 줄 append]
    L --> M[active + .1~.9 = 정확히 10개]
    M --> N[marker 이동 / 포맷 / size 검증]
    N --> O[운영 log 메타데이터 After 비교]
    O -->|동일| P[Evidence 후보 → 안전 정리]
    O -->|변경| X[STOP / 다른 writer·기존 cron 조사]
```

현재 Reference의 회전 순서를 파일 관점에서 보면 다음과 같습니다.

```text
실행 전
monitor.log      = ACTIVE-BEFORE, 10485760 bytes
monitor.log.1    = ROTATED-BEFORE-1
...
monitor.log.8    = ROTATED-BEFORE-8
monitor.log.9    = ROTATED-BEFORE-9

회전
old .9           → 삭제
old .8           → .9
...
old .1           → .2
old active       → .1

그 다음 append
새 monitor.log   → 방금 실행한 실제 monitor 기록 1줄
```

### “10개”의 의미

현재 R01 Reference는 `MAX_TOTAL_LOG_FILES=10`을 **active `monitor.log`까지 포함한 총 파일 수**로 해석합니다.

```text
monitor.log      1개
monitor.log.1~.9 9개
--------------------
총               10개
```

따라서 `.10`을 만드는 구조가 아닙니다.

### 경계값과 append 순서의 의미

현재 코드는 새 로그를 쓰기 **전에** active 파일 크기를 검사합니다.

```text
현재 active size >= 10485760
→ 먼저 rotation
→ 그 다음 새 active에 현재 한 줄 append
```

따라서 이 STEP은 **정확히 10485760 byte인 active 파일**을 만들어 회전 조건을 명확하게 시험합니다. “모든 순간에 active 파일이 절대로 10MB를 한 byte도 넘지 않는다”는 별도 보장을 이 시험 결과로 과장하지 않습니다.

## ⑤ 실행할 명령어 또는 코드

### 📍 실행 위치(Context)

```text
Host       : OrbStack Ubuntu 24.04 또는 WSL2 Ubuntu 24.04
Terminal A : STEP 07부터 유지 중인 Agent foreground Terminal
Terminal B : Ubuntu Bash — 격리 로그 회전 시험
Repository : $HOME/codyssey/codyssey-basic-b1-1-system-monitor
권한       : 일반 사용자 + 필요한 조회/소유권 변경 줄에서만 sudo
venv       : 해당 없음
```

### A. STEP 08 정상 경로와 설치본 재확인 — 읽기 전용

```bash
cd "$HOME/codyssey/codyssey-basic-b1-1-system-monitor"

AGENT_COUNT="$(pgrep -x agent-app | wc -l)"
printf '[INFO] agent-app count=%s\n' "$AGENT_COUNT"
ps -C agent-app -o user=,uid=,pid=,comm=
sudo ss -lntp | grep ':15034'

sudo cmp -s training/round-01-clear/monitor.sh /opt/agent-app/bin/monitor.sh \
  && echo '[PASS] Runtime monitor matches Repository Reference' \
  || echo '[STOP] Runtime monitor differs from Repository Reference'
```

정상 기준:

```text
agent-app count = 1
user = agent-admin
uid != 0
TCP 15034 LISTEN
Repository Reference = Runtime monitor
```

STEP 08의 실제 `monitor_exit=0`과 운영 로그 포맷 확인까지 성공하지 않았다면 이 STEP으로 강행하지 않습니다.

### B. 운영 monitor.log 메타데이터 기준선 저장

```bash
PROD_LOG="/var/log/agent-app/monitor.log"

if sudo test -e "$PROD_LOG"; then
    PROD_LOG_BEFORE="$(sudo stat -c '%s:%Y' "$PROD_LOG")"
else
    PROD_LOG_BEFORE='MISSING'
fi

printf '[INFO] production monitor.log before=%s\n' "$PROD_LOG_BEFORE"
```

`%s`는 byte 크기, `%Y`는 마지막 수정 시각(epoch seconds)입니다. 여기서는 운영 로그 내용을 읽거나 복사하지 않습니다.

### C. 이번 실행 전용 격리 디렉터리 만들기

```bash
LOG_TEST_DIR="$(sudo -u agent-admin mktemp -d /tmp/b1-1-log-rotation.XXXXXX)"
printf '[INFO] test dir=%s\n' "$LOG_TEST_DIR"

case "$LOG_TEST_DIR" in
    /tmp/b1-1-log-rotation.*)
        echo '[PASS] isolated test path pattern confirmed'
        ;;
    *)
        echo '[STOP] unexpected test path; do not create/delete test files'
        ;;
esac

sudo chown agent-admin:agent-core "$LOG_TEST_DIR"
sudo chmod 0770 "$LOG_TEST_DIR"
sudo stat -c '%U %G %a %n' "$LOG_TEST_DIR"

TEST_LOG="$LOG_TEST_DIR/monitor.log"
```

`LOG_TEST_DIR`가 비어 있거나 `/tmp/b1-1-log-rotation.*` 패턴과 맞지 않으면 여기서 STOP합니다. 이후 생성·삭제 명령을 실행하지 않습니다.

### D. 정확한 회전 경계와 `.1~.9` 마커 준비

먼저 active 파일에 마커를 넣고 R01 회전 경계인 정확히 `10485760` byte로 만듭니다.

```bash
printf '%s\n' 'ACTIVE-BEFORE' \
  | sudo -u agent-admin tee "$TEST_LOG" >/dev/null
sudo -u agent-admin truncate -s 10485760 "$TEST_LOG"
```

기존 회전 파일 `.1`~`.9`에는 서로 다른 마커를 넣습니다.

```bash
for i in 1 2 3 4 5 6 7 8 9; do
    printf 'ROTATED-BEFORE-%s\n' "$i" \
      | sudo -u agent-admin tee "${TEST_LOG}.${i}" >/dev/null
done
```

실행 전 총 개수와 크기를 확인합니다.

```bash
BEFORE_COUNT="$(sudo find "$LOG_TEST_DIR" -maxdepth 1 -type f -name 'monitor.log*' | wc -l)"
printf '[INFO] test log count before=%s\n' "$BEFORE_COUNT"

sudo find "$LOG_TEST_DIR" -maxdepth 1 -type f -name 'monitor.log*' \
  -printf '%f %s bytes\n' | sort -V
```

정상 기준은 **총 10개**, 그리고 `monitor.log`이 **10485760 bytes**입니다. 둘 중 하나라도 다르면 monitor를 실행하지 않고 시험 데이터 생성 단계부터 확인합니다.

### E. 실제 설치된 monitor.sh를 격리 경로로 한 번 실행

```bash
sudo -u agent-admin -H env LOG_TEST_DIR="$LOG_TEST_DIR" bash -c '
  set -e
  set +x
  source /opt/agent-app/env.sh
  export AGENT_LOG_DIR="$LOG_TEST_DIR"
  export MAX_LOG_BYTES=10485760
  export MAX_TOTAL_LOG_FILES=10
  exec /opt/agent-app/bin/monitor.sh
'
ROTATION_RC=$?
printf '[INFO] rotation_test_exit=%s\n' "$ROTATION_RC"
```

여기서 `env.sh` 자체는 수정하지 않습니다. `source`한 뒤 이번 자식 Shell에서만 `AGENT_LOG_DIR`을 임시 디렉터리로 바꾸고, 현재 R01 Reference의 회전 시험값을 명시합니다.

> `MAX_LOG_BYTES`, `MAX_TOTAL_LOG_FILES`는 현재 R01 `monitor.sh`가 안전한 경계 시험을 위해 허용하는 **내부 시험/구현 변수**입니다. 공식 Mission의 필수 환경변수 목록에 새 항목을 추가하는 것이 아닙니다.

정상 경로는 `rotation_test_exit=0`이어야 합니다.

### F. 실행 후 총 파일 수와 파일명 검증

```bash
AFTER_COUNT="$(sudo find "$LOG_TEST_DIR" -maxdepth 1 -type f -name 'monitor.log*' | wc -l)"
printf '[INFO] test log count after=%s\n' "$AFTER_COUNT"

for suffix in '' .1 .2 .3 .4 .5 .6 .7 .8 .9; do
    sudo test -f "${TEST_LOG}${suffix}" \
      && echo "[PASS] exists: monitor.log${suffix}" \
      || echo "[FAIL] missing: monitor.log${suffix}"
done

sudo test ! -e "${TEST_LOG}.10" \
  && echo '[PASS] no monitor.log.10' \
  || echo '[FAIL] unexpected monitor.log.10'
```

정상 기준:

```text
AFTER_COUNT = 10
monitor.log 존재
monitor.log.1 ~ monitor.log.9 모두 존재
monitor.log.10 없음
```

### G. 정확한 회전 이동 관계와 오래된 `.9` 제거 검증

old active가 `.1`로 갔는지 먼저 확인합니다.

```bash
ROTATED_SIZE="$(sudo stat -c '%s' "${TEST_LOG}.1")"
printf '[INFO] monitor.log.1 size=%s bytes\n' "$ROTATED_SIZE"

sudo head -n 1 "${TEST_LOG}.1" | grep -qx 'ACTIVE-BEFORE' \
  && echo '[PASS] old active log moved to .1' \
  || echo '[FAIL] old active log was not preserved as .1'
```

그 다음 old `.1→.2`부터 old `.8→.9`까지 마커를 확인합니다.

```bash
for n in 2 3 4 5 6 7 8 9; do
    old=$((n - 1))
    sudo head -n 1 "${TEST_LOG}.${n}" \
      | grep -qx "ROTATED-BEFORE-${old}" \
      && echo "[PASS] old .${old} moved to .${n}" \
      || echo "[FAIL] rotation mapping .${old} -> .${n}"
done
```

마지막 `.9`는 다음을 보여야 합니다.

```bash
sudo head -n 1 "${TEST_LOG}.9"
```

정상이라면 `ROTATED-BEFORE-8`입니다. 실행 전 `.9`였던 `ROTATED-BEFORE-9`가 그대로 남아 있지 않고 제거되었다는 뜻입니다.

또한 `.1`의 크기는 old active와 같은 `10485760` byte여야 합니다.

### H. 새 active monitor.log의 실제 기록 검증

```bash
ACTIVE_SIZE="$(sudo stat -c '%s' "$TEST_LOG")"
printf '[INFO] new active size=%s bytes\n' "$ACTIVE_SIZE"

sudo tail -n 1 "$TEST_LOG" \
  | grep -Eq '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] PID:[0-9]+ CPU:[0-9]+([.][0-9]+)?% MEM:[0-9]+([.][0-9]+)?% DISK_USED:[0-9]+([.][0-9]+)?%$' \
  && echo '[PASS] new active monitor.log has official format' \
  || echo '[FAIL] new active monitor.log format'

if [ "$ACTIVE_SIZE" -lt 10485760 ]; then
    echo '[PASS] new active log restarted below the R01 rotation threshold'
else
    echo '[FAIL] new active log did not restart below the threshold'
fi
```

이 마지막 라인은 **실제 현재 Agent PID와 자원 값으로 이번 격리 실행이 생성한 결과**여야 합니다. 문서 예시를 복사해 넣지 않습니다.

### I. 운영 monitor.log가 격리 시험 때문에 바뀌지 않았는지 확인

```bash
if sudo test -e "$PROD_LOG"; then
    PROD_LOG_AFTER="$(sudo stat -c '%s:%Y' "$PROD_LOG")"
else
    PROD_LOG_AFTER='MISSING'
fi

printf '[INFO] production monitor.log after=%s\n' "$PROD_LOG_AFTER"

if [ "$PROD_LOG_BEFORE" = "$PROD_LOG_AFTER" ]; then
    echo '[PASS] isolated rotation test did not touch production monitor.log metadata'
else
    echo '[STOP] production monitor.log changed; investigate another writer before STEP 10'
fi
```

이 시험의 `AGENT_LOG_DIR`은 임시 경로이므로 정상적으로 격리되었다면 운영 `monitor.log`는 이 실행 때문에 바뀌지 않아야 합니다.

만약 운영 로그가 달라졌다면 “시험이 운영 로그를 썼다”고 바로 단정하지 않습니다. STEP 10 전인데도 기존 cron이나 다른 monitor 프로세스가 이미 실행 중인지 먼저 조사합니다.

```bash
sudo crontab -u agent-admin -l 2>/dev/null || true
ps -ef | grep '[m]onitor.sh' || true
```

의도하지 않은 writer의 출처를 확인하기 전에는 STEP 10으로 진행하지 않습니다.

### J. Evidence 후보 확인 후 격리 디렉터리 정리

정리 전에 한 번 더 파일 목록과 크기를 남깁니다.

```bash
sudo find "$LOG_TEST_DIR" -maxdepth 1 -type f -name 'monitor.log*' \
  -printf '%f %s bytes\n' | sort -V
```

이 출력과 F~I의 실제 PASS 결과는 Secret이 없는 현재 R01 로그 회전 Evidence 후보가 될 수 있습니다.

필요한 Evidence를 확보한 뒤에만 다음처럼 **예상 패턴의 파일만** 삭제하고 빈 디렉터리를 제거합니다.

```bash
case "$LOG_TEST_DIR" in
    /tmp/b1-1-log-rotation.*)
        sudo find "$LOG_TEST_DIR" -mindepth 1 -maxdepth 1 \
          -type f -name 'monitor.log*' -delete
        sudo rmdir "$LOG_TEST_DIR"
        ;;
    *)
        echo '[STOP] unexpected path; nothing deleted'
        ;;
esac
```

`rmdir`은 디렉터리가 비어 있을 때만 성공합니다. 예상하지 않은 다른 파일이 있으면 디렉터리를 통째로 지우지 않고 남겨 원인을 확인합니다. 이 STEP에서는 고정 `/tmp` 경로에 `rm -rf`를 사용하지 않습니다.

## ⑥ 명령어와 코드에 입문자가 이해할 수 있는 주석

### 사전 Gate와 운영 로그 보호

- `pgrep -x agent-app | wc -l`
  - STEP 07부터 유지 중인 Agent가 정확히 한 개인지 확인합니다.
- `cmp -s Repository Runtime`
  - 실제 시험 대상 `monitor.sh`가 현재 Repository Reference와 동일한지 확인합니다.
- `PROD_LOG=/var/log/agent-app/monitor.log`
  - 운영 로그 경로를 별도 변수로 고정하여 시험용 `TEST_LOG`와 혼동하지 않습니다.
- `stat -c '%s:%Y'`
  - 파일 내용 대신 byte 크기와 수정 시각을 하나의 문자열로 기록합니다.
  - 시험 전후 값이 같으면 이 격리 실행이 운영 active 로그를 직접 건드리지 않았다는 중요한 근거가 됩니다.

### 고유 격리 디렉터리

- `mktemp -d /tmp/b1-1-log-rotation.XXXXXX`
  - 매 실행마다 충돌 가능성이 낮은 고유 디렉터리를 만듭니다.
  - 기존 고정 폴더를 `rm -rf`한 뒤 재사용하는 방식보다 안전합니다.
- `sudo -u agent-admin`
  - 시험 파일의 생성 주체를 실제 monitor 실행 계정과 맞춥니다.
- `case "$LOG_TEST_DIR" in /tmp/b1-1-log-rotation.*)`
  - 생성·삭제 전에 경로가 예상한 시험 패턴인지 검증합니다.
- `chown agent-admin:agent-core`, `chmod 0770`
  - 격리 디렉터리를 실제 실행 역할에 맞춰 읽기·쓰기 가능하게 하고 others 접근을 막습니다.

### 경계 파일과 마커

- `printf ... | tee "$TEST_LOG"`
  - `ACTIVE-BEFORE`라는 추적용 마커를 active 파일 첫 줄에 씁니다.
- `truncate -s 10485760`
  - 파일의 **논리적 크기**를 정확히 10,485,760 byte로 맞춥니다.
  - 많은 실제 데이터를 10 MiB만큼 반복 출력하는 대신 빠르게 경계 조건을 만들 수 있고, 파일시스템에 따라 희소 파일이 될 수 있습니다.
- `for i in 1 ... 9; do ... done`
  - `.1`부터 `.9`까지 같은 생성 명령을 반복하되 각 파일에 서로 다른 번호 마커를 넣습니다.
- `ROTATED-BEFORE-n`
  - 회전 후 파일이 어느 번호로 이동했는지 실제 내용으로 추적하는 비밀값 없는 테스트 마커입니다.

### 파일 개수와 목록

- `find "$LOG_TEST_DIR" -maxdepth 1`
  - 시험 디렉터리 바로 아래 한 단계만 조사합니다.
- `-type f`
  - 일반 파일만 대상으로 합니다.
- `-name 'monitor.log*'`
  - 시험용 monitor 로그 이름과 맞는 파일만 선택합니다.
- `wc -l`
  - `find`가 찾은 파일 경로 수를 세어 총 파일 수로 사용합니다.
- `-printf '%f %s bytes\n'`
  - 디렉터리 경로를 제외한 파일명과 byte 크기를 출력합니다.
- `sort -V`
  - `.1`, `.2`, `.9` 같은 버전형 숫자 접미사를 사람이 보기 쉬운 순서로 정렬합니다.

### 격리 monitor 실행

- `env LOG_TEST_DIR="$LOG_TEST_DIR" bash -c '...'`
  - 바깥 Shell에서 만든 임시 경로를 `agent-admin`의 자식 Shell에 전달합니다.
- `source /opt/agent-app/env.sh`
  - 공식 경로·포트·process name 같은 정상 Runtime 설정을 먼저 읽습니다.
- `export AGENT_LOG_DIR="$LOG_TEST_DIR"`
  - **이번 한 실행의 로그 출력 경로만** 격리 디렉터리로 바꿉니다. `env.sh` 파일 자체는 수정하지 않습니다.
- `export MAX_LOG_BYTES=10485760`
  - 현재 R01 구현의 회전 경계값을 이번 시험에 명시합니다.
- `export MAX_TOTAL_LOG_FILES=10`
  - active를 포함해 총 10개를 유지하는 현재 R01 구현값을 명시합니다.
- `exec /opt/agent-app/bin/monitor.sh`
  - 실제 설치된 Reference 동일본을 실행하여 mock 코드가 아니라 실제 구현을 검증합니다.
- `ROTATION_RC=$?`
  - 바로 전 monitor 실행 종료 코드를 저장합니다. 정상 Health와 회전 성공 경로는 `0`이어야 합니다.

### 회전 순서 검증

- `test -f "${TEST_LOG}${suffix}"`
  - active와 `.1`~`.9`가 모두 실제 존재하는지 확인합니다.
- `test ! -e "${TEST_LOG}.10"`
  - `.10`이 존재하지 않는 것을 성공 조건으로 검사합니다.
- `stat -c '%s' "${TEST_LOG}.1"`
  - old active가 `.1`로 이동하면서 원래의 정확한 경계 크기를 보존했는지 확인합니다.
- `head -n 1 ... | grep -qx ...`
  - 파일 첫 줄의 마커가 정확히 예상 문자열인지 출력 없이 비교합니다.
  - `-q`는 비교 결과만 사용하고, `-x`는 한 줄 전체가 정확히 일치해야 성공합니다.
- `old=$((n - 1))`
  - Bash 산술 확장으로 현재 `.n`에 들어 있어야 할 이전 번호를 계산합니다.

### 새 active와 공식 포맷

- `tail -n 1 "$TEST_LOG"`
  - 회전 후 새 active에 실제로 추가된 최신 monitor 한 줄을 읽습니다.
- `grep -Eq ...`
  - timestamp, PID, CPU, MEM, DISK_USED 순서와 숫자/`%` 형식을 검증합니다.
- `[ "$ACTIVE_SIZE" -lt 10485760 ]`
  - 회전 직후 새 active가 다시 작은 파일에서 시작했는지 확인합니다.

### 운영 로그 불변 확인

- `PROD_LOG_BEFORE` / `PROD_LOG_AFTER`
  - 운영 로그의 크기·수정 시각을 시험 앞뒤로 비교합니다.
- 값이 다르면
  - 격리 시험 실패로 단정하지 말고 기존 cron, 별도 monitor 실행 등 **다른 writer**를 조사합니다.
- `crontab -u agent-admin -l`
  - STEP 10 전에 과거 cron 등록이 남아 있는지 읽기 전용으로 확인합니다.
- `ps -ef | grep '[m]onitor.sh'`
  - 현재 실행 중인 monitor 프로세스 후보를 찾습니다. `[m]` 패턴은 grep 명령 자체가 결과에 잡히는 것을 줄입니다.

### 안전한 정리

- `find ... -delete`
  - 검증된 `LOG_TEST_DIR` 바로 아래의 `monitor.log*` 일반 파일만 삭제합니다.
  - 운영 `/var/log/agent-app`에는 적용하지 않습니다.
- `rmdir "$LOG_TEST_DIR"`
  - 디렉터리가 비어 있을 때만 제거합니다. 예상하지 않은 내용이 있으면 실패하고 그대로 남기므로 `rm -rf`보다 안전한 종료 경계가 됩니다.

### 재실행 안전성

STEP 09는 운영 로그를 직접 변경하지 않도록 설계했지만, 임시 파일을 실제로 생성·회전·삭제하므로 전체를 무조건 반복 실행하지 않습니다.

```text
Agent / ss / cmp / stat / crontab / ps 조회                 → 🟢 SAFE TO RERUN
mktemp 고유 디렉터리 생성                                  → 🟢 새 경로를 만들므로 낮은 위험
시험 디렉터리 chown/chmod                                   → 🟡 경로 패턴 확인 후
marker 생성 / truncate / .1~.9 생성                       → 🟡 검증된 mktemp 경로에서만
격리 AGENT_LOG_DIR로 monitor 실행                           → 🟡 실제 Health Check + 임시 로그 write
find/stat/head/tail/grep 검증                               → 🟢 SAFE TO RERUN
운영 monitor.log truncate/rm/인위적 10MB 생성               → 🚫 사용하지 않음
고정 /tmp 경로 rm -rf                                      → 🚫 사용하지 않음
find -delete / rmdir 정리                                   → 🔴 Evidence 확보 + 정확한 경로/패턴 확인 후
```

> **STOP 기준:** STEP 08 정상 경로 미통과, Agent가 1개가 아님, 실행 사용자가 `agent-admin`이 아님, TCP 15034 미확인, Runtime monitor와 Repository Reference 불일치, `mktemp` 경로 비정상, 시험 디렉터리 owner/mode 오류, 실행 전 파일 수가 10개가 아님, active 크기가 정확한 경계값이 아님, `rotation_test_exit != 0`, 실행 후 파일 수가 10개가 아님, active 또는 `.1~.9` 누락, `.10` 생성, `.1`의 크기/마커 불일치, `.1→.2`~`.8→.9` 매핑 실패, 새 active 공식 포맷 실패, 새 active가 경계보다 작게 재시작하지 않음, 운영 monitor.log 메타데이터가 예상치 않게 변경됨 중 하나라도 발생하면 STEP 10으로 진행하지 않습니다.

## ⑦ 예상되는 정상 결과

실행 전:

```text
시험 경로 = /tmp/b1-1-log-rotation.<고유문자>
총 파일 수 = 10
monitor.log = 10485760 bytes
monitor.log.1 ~ .9 = 각기 다른 marker
```

실행 후:

```text
rotation_test_exit = 0
총 파일 수 = 정확히 10
monitor.log 존재
monitor.log.1 ~ monitor.log.9 존재
monitor.log.10 없음
```

회전 매핑:

```text
old active  → .1   (size = 10485760, marker = ACTIVE-BEFORE)
old .1      → .2
old .2      → .3
...
old .8      → .9
old .9      → 제거
```

새 active:

```text
monitor.log
→ R01 threshold보다 작은 크기로 새로 시작
→ 실제 현재 Agent PID/CPU/MEM/DISK가 공식 로그 형식으로 1줄 append
```

운영 보호:

```text
PROD_LOG_BEFORE = PROD_LOG_AFTER
→ 이 격리 시험 자체가 /var/log/agent-app/monitor.log를 변경하지 않음
```

## ⑧ 그 결과가 의미하는 것

공식의 **10MB / 10개 로그 관리 요구사항**이 현재 R01의 Bash 구현에서 실제 회전 동작으로 연결된다는 것을, 실제 운영 로그를 인위적으로 키우거나 삭제하지 않고 검증한 것입니다.

특히 단순히 “파일 수가 10개 이하”만 보는 것이 아니라 다음을 함께 증명합니다.

```text
회전 경계에서 실제 trigger
old active → .1 보존
중간 세대 순서 이동
가장 오래된 .9 제거
active 포함 총 10개 제한
새 active 정상 생성과 실제 로그 append
운영 log 격리 유지
```

`verify.sh`의 production 파일 수 `<= 10` 검사는 최종 상태 확인에 유용하지만, **정확한 경계에서 실제 회전 순서가 동작했는지까지 단독으로 증명하지는 않습니다.** STEP 09의 격리 시험이 그 동작 증거를 보완합니다.

## ⑨ 자주 발생하는 오류와 해결 방법

- `mktemp` 결과가 비어 있음 → `/tmp` 권한/용량 확인. 고정 폴더를 만들고 `rm -rf`로 우회하지 않음.
- `test log count before != 10` → `find` 결과를 먼저 보고 누락/추가 파일 확인. monitor 실행 전 시험 fixture부터 수정.
- active size가 10485760이 아님 → `stat -c '%s'`로 확인 후 `truncate` 성공 여부를 점검. 운영 로그에는 적용 금지.
- `rotation_test_exit=1` → 회전 로직보다 먼저 Process/Port Health가 실패했을 수 있으므로 콘솔 첫 `[FAIL]`, STEP 07 Agent/15034부터 확인.
- `.1`이 `ACTIVE-BEFORE`가 아님 → active가 threshold에 도달하지 않았거나 다른 경로를 쓴 것인지 `AGENT_LOG_DIR`, `stat`, 실행 로그를 확인.
- `.2~.9` marker가 한 칸씩 이동하지 않음 → `monitor.sh`의 `rotate_log_if_needed()` 현재 설치본과 Repository Reference 동일성 확인.
- old `ROTATED-BEFORE-9`가 남음 → 최고 세대 삭제 로직이 동작하지 않은 것. 파일 수와 `.9` marker를 함께 확인.
- `.10`이 생김 → 현재 R01의 “active 포함 총 10개” 구현과 다름. `MAX_TOTAL_LOG_FILES`, 설치본 코드, 기존 파일을 확인.
- 새 active가 없음 → 회전 후 append 전에 monitor가 실패했을 수 있음. 콘솔 종료 코드와 로그 디렉터리 쓰기 권한 확인.
- 새 active 포맷 FAIL → STEP 08의 실제 로그 포맷과 설치본 코드를 다시 확인. 시험 marker를 실제 로그처럼 꾸며 PASS 처리하지 않음.
- 운영 `monitor.log` 메타데이터가 바뀜 → 먼저 `agent-admin` crontab과 현재 monitor 프로세스를 조사. 과거 cron이 남아 있으면 STEP 10에서 중복을 만들기 전에 정리 계획 수립.
- cleanup에서 `rmdir` 실패 → 예상하지 않은 파일이 있다는 뜻일 수 있음. `ls -la "$LOG_TEST_DIR"`로 확인하고 디렉터리 전체 `rm -rf` 금지.
- 디스크 사용량이 걱정됨 → `truncate`의 논리 크기와 실제 block 사용량이 다를 수 있음. 필요하면 시험 디렉터리의 `du -h`와 `ls -lh`를 구분해 확인하되 운영 로그는 건드리지 않음.

## ⑩ 완료 확인

- [ ] STEP 08 실제 정상 실행 `monitor_exit=0`과 공식 로그 포맷 Gate를 이미 통과
- [ ] Agent process count=1 / user=`agent-admin` / TCP 15034 정상 유지
- [ ] Runtime monitor = Repository Reference
- [ ] 운영 `monitor.log` Before 메타데이터 저장
- [ ] `mktemp -d /tmp/b1-1-log-rotation.XXXXXX` 고유 시험 경로 사용
- [ ] 시험 경로 패턴 확인
- [ ] 시험 디렉터리 owner=`agent-admin`, group=`agent-core`, mode=`770`
- [ ] active marker `ACTIVE-BEFORE` 생성
- [ ] active 크기 정확히 `10485760` byte
- [ ] `.1~.9` 각기 다른 marker 생성
- [ ] 실행 전 active 포함 총 10개
- [ ] `AGENT_LOG_DIR` override는 이번 자식 실행에만 적용
- [ ] `MAX_LOG_BYTES` / `MAX_TOTAL_LOG_FILES`가 R01 내부 시험값임을 구분
- [ ] `rotation_test_exit=0`
- [ ] 실행 후 active + `.1~.9` 정확히 총 10개
- [ ] `.10` 없음
- [ ] old active → `.1`
- [ ] `.1` 크기 `10485760` byte
- [ ] old `.1→.2` ... old `.8→.9` marker 매핑 PASS
- [ ] 기존 old `.9` 제거 확인
- [ ] 새 active `monitor.log` 존재
- [ ] 새 active 크기 R01 threshold 미만
- [ ] 새 active 마지막 라인이 공식 로그 포맷
- [ ] 운영 `monitor.log` Before/After 메타데이터 동일
- [ ] 운영 로그가 바뀌었다면 기존 cron/다른 writer 조사 후 STOP
- [ ] Evidence 후보를 먼저 확보한 뒤 시험 파일만 정리
- [ ] 고정 `/tmp` 경로 `rm -rf` 사용 안 함
- [ ] 실제 `/var/log/agent-app/monitor.log`를 truncate/delete하지 않음
- [ ] **실제 격리 시험을 실행하기 전에는 10MB/10개 Runtime PASS로 기록하지 않음**

---

<a id="step-10"></a>
## STEP 10 — agent-admin cron 매분 자동 실행 검증

## ① 왜 하는가

공식 B1-1은 `monitor.sh`를 사람이 수동으로 실행하는 데서 끝내지 않고 **`agent-admin` 계정의 crontab으로 매분 자동 실행**하도록 등록하고, 등록 뒤 **1~2분 내 `/var/log/agent-app/monitor.log`에 새 라인이 실제로 누적되는지 확인**하도록 요구합니다.

cron은 로그인 터미널보다 환경변수와 `PATH`가 제한적이고, 기존 사용자 crontab에 다른 작업이 이미 있을 수 있습니다. 따라서 단순히 `crontab -e`를 열어 같은 줄을 반복해서 붙이면 중복 실행, 기존 작업 손상, 복구 불가 문제가 생길 수 있습니다.

이 STEP은 **STEP 09 실제 PASS 확인 → Agent/monitor/권한 재확인 → cron 서비스와 기존 crontab 조사 → root-only 체크포인트 → cron과 비슷한 최소 환경에서 수동 사전 실행 → cron 서비스 활성 상태 확보 → 기존 항목을 보존하는 정확히 1개 등록 → 등록 결과 재검증 → monitor.log Before → 75초 대기 → After 변화와 공식 로그 포맷 확인 → Agent 상태 유지 확인 → 필요 시 체크포인트 기반 복구** 순서로 진행합니다.

> 이번 STEP의 PASS는 “crontab 줄이 존재한다”만으로 결정하지 않습니다. **정확히 한 개의 매분 항목 + cron 서비스 active + 실제 1~2분 내 monitor.log의 새로운 Runtime 라인**이 모두 확인되어야 합니다.

## ② 무엇을 하는가

1. STEP 09의 실제 격리 회전 검증을 이미 통과했는지 확인하고, Agent 1개와 TCP `15034`, Runtime `monitor.sh`, `env.sh`, 로그 쓰기 권한을 다시 점검합니다.
2. `cron` 서비스의 현재 active/enabled 상태와 `agent-admin` 기존 crontab 존재 여부를 읽기 전용으로 확인합니다.
3. 기존 crontab 전체 내용은 화면에 뿌리지 않고, B1-1 관련 경로를 가진 항목의 **개수**만 먼저 확인합니다.
4. 기존 사용자 crontab은 `/root` 아래 mode `0600`의 root-only 파일로 백업합니다. crontab 안에 민감한 환경값이 있을 가능성을 고려해 `/tmp` 평문 백업을 만들지 않습니다.
5. 실제 cron과 비슷한 최소 환경(`env -i`)에서 동일한 Bash 실행 본문을 `agent-admin`으로 한 번 수동 실행해 환경·권한·PATH 문제를 cron 등록 전에 찾습니다.
6. `cron` 서비스가 이미 active면 그대로 두고, inactive면 시작한 뒤 active를 확인합니다. 시작 전 상태를 체크포인트에 기록합니다.
7. R01 기준 cron 한 줄이 이미 정확히 1개이면 중복 추가하지 않습니다. 관련 항목이 전혀 없을 때만 기존 crontab 복사본 뒤에 정확한 한 줄을 추가해 전체 crontab을 재설치합니다.
8. 기존 B1-1 관련 줄이 있으나 형식이 다르거나, 중복이 있으면 자동 삭제·필터링하지 않고 STOP하여 해당 줄을 로컬에서 확인합니다.
9. 최종 crontab에서 정확한 B1-1 항목이 1개인지 다시 확인합니다.
10. `monitor.log`의 Before 메타데이터와 마지막 라인을 기록한 뒤 **수동 monitor 실행이나 STEP 11 시험을 하지 않고 75초** 기다립니다.
11. After 메타데이터·마지막 라인이 바뀌고 새 라인이 공식 포맷인지 확인합니다.
12. cron 실행 뒤에도 Agent process 1개와 TCP `15034`가 유지되는지 확인합니다.
13. 실패하면 `cron` 서비스 로그, 정확한 crontab 개수, `agent-admin` 권한과 최소 환경 수동 실행을 순서대로 진단합니다.
14. 등록을 철회해야 하면 시작 전 crontab이 있었는지 여부에 따라 root-only 백업을 복원하거나, 원래 crontab이 없었던 경우에만 전체 crontab 제거를 검토합니다.

## ③ 이번 단계에서 알아야 할 용어

- **크론(cron)** — 정해진 시간 규칙에 따라 명령을 자동 실행하는 Linux 스케줄러 서비스입니다.
- **크론탭(crontab)** — 사용자별 cron 일정과 실행 명령을 저장하는 작업 목록입니다.
- **스케줄 표현식(Cron Schedule Expression)** — `* * * * *`처럼 분·시·일·월·요일 실행 시점을 지정하는 다섯 필드입니다.
- **최소 실행 환경(Minimal Environment)** — 로그인 프로필에 의존하지 않고 필요한 환경값만 가진 제한된 실행 환경입니다.
- **중복 작업(Duplicate Job)** — 같은 작업이 여러 번 등록되어 같은 시점에 반복 실행되는 상태입니다.
- **멱등적 등록(Idempotent Registration)** — 이미 올바른 항목이 있으면 다시 추가하지 않아 반복 수행해도 중복을 만들지 않는 등록 방식입니다.
- **체크포인트(Checkpoint)** — 기존 crontab과 서비스 상태를 보존해 문제가 생겼을 때 원래 상태로 복구할 수 있게 하는 지점입니다.
- **표준 출력(Standard Output, stdout)** — 프로그램의 일반 출력 스트림입니다.
- **표준 오류(Standard Error, stderr)** — 오류·경고 메시지를 위한 별도 출력 스트림입니다.
- **리다이렉션(Redirection)** — `>`, `2>&1`처럼 출력이 향할 위치를 바꾸는 Shell 기능입니다.

## ④ 필요한 핵심 개념

```mermaid
flowchart TD
    A[STEP 09 실제 PASS] --> B[Agent / monitor / log 권한 재확인]
    B --> C[cron service + 기존 crontab 조사]
    C --> D[root-only Checkpoint]
    D --> E[cron-like 최소 환경 수동 실행]
    E -->|exit 0| F{cron service active?}
    E -->|실패| X[STOP / 환경·권한 진단]
    F -->|아니오| G[cron start 후 active 확인]
    F -->|예| H[기존 상태 유지]
    G --> I{B1-1 관련 cron 상태}
    H --> I
    I -->|정확한 1개| J[중복 추가 없음]
    I -->|0개| K[기존 crontab 복사 + 한 줄 추가]
    I -->|충돌/중복| Y[STOP / 자동 삭제 금지]
    K --> L[agent-admin crontab 재설치]
    J --> M[최종 exact=1 검증]
    L --> M
    M --> N[monitor.log Before]
    N --> O[75초 동안 수동 실행 금지]
    O --> P[monitor.log After]
    P --> Q{메타데이터·마지막 라인 변화 + 공식 포맷?}
    Q -->|예| R[Agent / 15034 재확인]
    Q -->|아니오| Z[cron 로그·권한·환경 최소 진단]
    R --> S[STEP 11]
```

### 공식 요구와 R01 구현을 구분

```text
공식 요구
→ agent-admin crontab
→ 매분 실행
→ 1~2분 내 monitor.log 새 라인 자동 누적

R01 구현 선택
→ cron 명령 안에서 PATH를 명시
→ /bin/bash -c로 env.sh를 명시적으로 읽음
→ stdout/stderr를 /dev/null로 보내 별도 cron.log 무한 증가를 만들지 않음
```

`/dev/null` 출력 폐기는 공식 요구사항이 아니라 R01 운영 선택입니다. cron 동작 증거는 `monitor.log`의 실제 증가와 필요 시 `journalctl -u cron` 같은 서비스 로그로 확인합니다.

## ⑤ 실행할 명령어 또는 코드

### 📍 실행 위치(Context)

```text
Host       : OrbStack Ubuntu 24.04 또는 WSL2 Ubuntu 24.04
Terminal A : STEP 07부터 유지 중인 Agent foreground Terminal
Terminal B : Ubuntu Bash — cron 점검·등록·검증
Repository : $HOME/codyssey/codyssey-basic-b1-1-system-monitor
권한       : 일반 사용자 + crontab/service 조회·변경 줄에서만 sudo
venv       : 해당 없음
```

### A. STEP 09 이후 Runtime Gate 재확인 — 읽기 전용

```bash
cd "$HOME/codyssey/codyssey-basic-b1-1-system-monitor"
pwd
git branch --show-current
git status --short

AGENT_COUNT="$(pgrep -x agent-app | wc -l)"
printf '[INFO] agent-app count=%s\n' "$AGENT_COUNT"
ps -C agent-app -o user=,uid=,pid=,comm=
sudo ss -lntp | grep ':15034'

sudo cmp -s training/round-01-clear/monitor.sh /opt/agent-app/bin/monitor.sh \
  && echo '[PASS] Runtime monitor matches Repository Reference' \
  || echo '[STOP] Runtime monitor differs from Repository Reference'

sudo runuser -u agent-admin -- test -r /opt/agent-app/env.sh \
  && echo '[PASS] agent-admin can read env.sh' \
  || echo '[STOP] agent-admin cannot read env.sh'

sudo runuser -u agent-admin -- test -x /opt/agent-app/bin/monitor.sh \
  && echo '[PASS] agent-admin can execute monitor.sh' \
  || echo '[STOP] agent-admin cannot execute monitor.sh'

sudo runuser -u agent-admin -- test -w /var/log/agent-app \
  && echo '[PASS] agent-admin can write log directory' \
  || echo '[STOP] agent-admin cannot write log directory'

sudo test -s /var/log/agent-app/monitor.log \
  && echo '[PASS] production monitor.log exists and is non-empty' \
  || echo '[STOP] production monitor.log missing or empty'
```

정상 기준:

```text
STEP 09 실제 Runtime PASS를 이미 확인
agent-app count = 1
user = agent-admin
uid != 0
TCP 15034 LISTEN
Runtime monitor = Repository Reference
agent-admin이 env.sh read / monitor execute / log dir write 가능
production monitor.log 존재 + non-empty
```

STEP 09의 격리 회전 시험을 실제로 수행하지 않았다면 문서만 준비된 상태이므로 cron Runtime PASS를 이어서 기록하지 않습니다.

### B. cron 서비스와 기존 `agent-admin` crontab 조사 — 읽기 전용

```bash
command -v crontab
sudo systemctl is-active cron || true
sudo systemctl is-enabled cron || true

if sudo crontab -u agent-admin -l >/dev/null 2>&1; then
    echo '[INFO] agent-admin already has a crontab'
else
    echo '[INFO] agent-admin has no existing crontab'
fi
```

B1-1 R01에서 사용할 정확한 cron 한 줄을 Shell 변수로 고정합니다.

```bash
CRON_LINE="* * * * * PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /bin/bash -c 'set -e; . /opt/agent-app/env.sh; exec /opt/agent-app/bin/monitor.sh' >/dev/null 2>&1"
```

현재 crontab에 **정확히 같은 줄**이 몇 개인지, `/opt/agent-app`의 B1-1 env/monitor 경로를 가진 관련 줄이 몇 개인지 개수만 확인합니다.

```bash
EXACT_COUNT="$(sudo crontab -u agent-admin -l 2>/dev/null \
  | grep -Fxc "$CRON_LINE" || true)"

RELATED_COUNT="$(sudo crontab -u agent-admin -l 2>/dev/null \
  | grep -Ec '(/opt/agent-app/env\.sh|/opt/agent-app/bin/monitor\.sh)' || true)"

printf '[INFO] exact B1-1 cron lines=%s\n' "$EXACT_COUNT"
printf '[INFO] related B1-1 cron lines=%s\n' "$RELATED_COUNT"
```

판정:

```text
EXACT=1, RELATED=1
→ 이미 정확히 등록됨. 새 항목을 추가하지 않음.

EXACT=0, RELATED=0
→ 신규 등록 가능 후보. Checkpoint 이후 한 줄만 추가.

그 외
→ 중복 또는 이전 형식/충돌 가능성. 자동 삭제·교체 금지, STOP.
```

충돌/중복일 때 필요한 경우 **B1-1 관련 줄만 로컬에서** 확인합니다.

```bash
sudo crontab -u agent-admin -l 2>/dev/null \
  | grep -nE '(/opt/agent-app/env\.sh|/opt/agent-app/bin/monitor\.sh)' || true
```

기존 crontab 전체를 채팅·Evidence에 붙이지 않습니다. 사용자 crontab은 미션 외 작업이나 민감한 명령을 포함할 수 있습니다.

### C. 기존 crontab과 cron 서비스 상태 체크포인트

```bash
STAMP="$(date +%Y%m%d%H%M%S)"
CRON_BAK="$(sudo mktemp /root/b1-1-agent-admin-crontab.before.XXXXXX)"
CRON_NEW="$(sudo mktemp /root/b1-1-agent-admin-crontab.new.XXXXXX)"
CRON_CHECKPOINT="/tmp/b1-1-cron-checkpoint.${STAMP}.txt"

if sudo crontab -u agent-admin -l >/dev/null 2>&1; then
    CRON_EXISTED=yes
    sudo crontab -u agent-admin -l 2>/dev/null \
      | sudo tee "$CRON_BAK" >/dev/null
else
    CRON_EXISTED=no
    sudo truncate -s 0 "$CRON_BAK"
fi

sudo chmod 0600 "$CRON_BAK" "$CRON_NEW"

CRON_SERVICE_BEFORE="$(sudo systemctl is-active cron 2>/dev/null || true)"
CRON_ENABLED_BEFORE="$(sudo systemctl is-enabled cron 2>/dev/null || true)"

printf 'STAMP=%s\nCRON_EXISTED=%s\nCRON_BAK=%s\nCRON_NEW=%s\nCRON_SERVICE_BEFORE=%s\nCRON_ENABLED_BEFORE=%s\nEXACT_COUNT_BEFORE=%s\nRELATED_COUNT_BEFORE=%s\n' \
  "$STAMP" "$CRON_EXISTED" "$CRON_BAK" "$CRON_NEW" \
  "$CRON_SERVICE_BEFORE" "$CRON_ENABLED_BEFORE" \
  "$EXACT_COUNT" "$RELATED_COUNT" \
  > "$CRON_CHECKPOINT"

sudo stat -c '%U %G %a %s %n' "$CRON_BAK" "$CRON_NEW"
printf '[CHECKPOINT] %s\n' "$CRON_CHECKPOINT"
```

> 실제 crontab 백업 내용은 `/root`의 mode `0600` 파일에 둡니다. `/tmp` 체크포인트에는 **백업 경로·존재 여부·서비스 상태·개수**만 기록합니다. `CRON_BAK`을 `cat`하여 공개하지 않습니다.

### D. cron과 비슷한 최소 환경에서 수동 사전 실행

먼저 `agent-admin`의 실제 home을 계정 DB에서 얻습니다.

```bash
AGENT_ADMIN_HOME="$(getent passwd agent-admin | cut -d: -f6)"
printf '[INFO] agent-admin home=%s\n' "$AGENT_ADMIN_HOME"
```

home이 비어 있지 않은 것을 확인한 뒤, 일반 로그인 환경을 지운 최소 환경에서 cron 실행 본문을 한 번 테스트합니다.

```bash
sudo -u agent-admin env -i \
  HOME="$AGENT_ADMIN_HOME" \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  SHELL=/bin/sh \
  /bin/bash -c 'set -e; . /opt/agent-app/env.sh; exec /opt/agent-app/bin/monitor.sh'

PRECRON_RC=$?
printf '[INFO] cron-like manual test exit=%s\n' "$PRECRON_RC"
```

정상 기준은 `PRECRON_RC=0`입니다. 이 실행은 실제 `monitor.log`에 한 줄을 추가할 수 있지만 **cron 자동 실행 증거는 아닙니다.** cron 등록 전에 제한된 환경에서도 같은 실행 본문이 정상인지 확인하는 사전 시험입니다.

`PRECRON_RC != 0`이면 crontab을 등록하지 않고 환경·권한·Agent 상태를 먼저 해결합니다.

### E. cron 서비스 active 확보

```bash
if sudo systemctl is-active --quiet cron; then
    echo '[PASS] cron service is already active'
else
    echo '[INFO] cron service is inactive; starting it for B1-1 Runtime'
    sudo systemctl start cron
fi

sudo systemctl is-active cron
```

`active`가 확인되어야 합니다. `systemctl start cron`은 현재 서비스를 시작하지만 enable/disable 부팅 정책을 바꾸지는 않습니다. `is-enabled` 결과는 별도로 기록해 두고, 공식 요구에 없는 부팅 정책을 임의 변경하지 않습니다.

### F. 정확한 B1-1 항목 1개만 등록 — 기존 다른 항목 보존

먼저 B 단계에서 구한 개수를 다시 사용합니다.

```bash
if [ "$EXACT_COUNT" -eq 1 ] && [ "$RELATED_COUNT" -eq 1 ]; then
    echo '[PASS] exact B1-1 cron entry already exists; no duplicate added'
elif [ "$EXACT_COUNT" -eq 0 ] && [ "$RELATED_COUNT" -eq 0 ]; then
    sudo cp -a "$CRON_BAK" "$CRON_NEW"
    sudo sh -c 'printf "\n%s\n" "$1" >> "$2"' sh "$CRON_LINE" "$CRON_NEW"

    NEW_EXACT_COUNT="$(sudo grep -Fxc "$CRON_LINE" "$CRON_NEW" || true)"
    printf '[INFO] exact lines in staged crontab=%s\n' "$NEW_EXACT_COUNT"

    if [ "$NEW_EXACT_COUNT" -eq 1 ]; then
        sudo crontab -u agent-admin "$CRON_NEW"
        echo '[PASS] B1-1 cron entry installed for agent-admin'
    else
        echo '[STOP] staged crontab does not contain exactly one B1-1 entry'
    fi
else
    echo '[STOP] conflicting or duplicate B1-1-related cron entry detected; no automatic edit performed'
fi
```

이 방식은 기존 crontab이 있을 때 **백업 복사본 전체를 그대로 유지한 뒤 마지막에 한 줄만 추가**합니다. 기존 항목을 `grep -v`로 자동 삭제하거나 전체 crontab을 새 B1-1 한 줄로 덮어쓰지 않습니다.

### G. 등록 결과 재검증 — 정확히 1개

```bash
FINAL_EXACT_COUNT="$(sudo crontab -u agent-admin -l 2>/dev/null \
  | grep -Fxc "$CRON_LINE" || true)"

FINAL_RELATED_COUNT="$(sudo crontab -u agent-admin -l 2>/dev/null \
  | grep -Ec '(/opt/agent-app/env\.sh|/opt/agent-app/bin/monitor\.sh)' || true)"

printf '[INFO] final exact B1-1 cron lines=%s\n' "$FINAL_EXACT_COUNT"
printf '[INFO] final related B1-1 cron lines=%s\n' "$FINAL_RELATED_COUNT"

if [ "$FINAL_EXACT_COUNT" -eq 1 ] && [ "$FINAL_RELATED_COUNT" -eq 1 ]; then
    echo '[PASS] exactly one B1-1 cron entry is installed'
else
    echo '[STOP] B1-1 cron entry is missing, duplicated, or conflicting'
fi

sudo crontab -u agent-admin -l 2>/dev/null \
  | grep -F "$CRON_LINE" || true
```

마지막 출력에는 B1-1의 non-secret cron 한 줄만 보입니다. 전체 사용자 crontab은 Evidence에 복사하지 않습니다.

등록이 정상이라면 staging 파일은 더 이상 필요하지 않습니다. 정확한 `mktemp` 경로 패턴을 확인한 뒤 staging 복사본만 제거합니다.

```bash
case "$CRON_NEW" in
    /root/b1-1-agent-admin-crontab.new.*)
        sudo rm -f -- "$CRON_NEW"
        ;;
    *)
        echo '[STOP] unexpected staging path; nothing removed'
        ;;
esac
```

복구용 `CRON_BAK`은 STEP 15 CLEAR 전까지 유지합니다.

### H. 공식 1~2분 자동 실행 검증 — Before

여기서부터 After 확인까지는 **수동으로 `monitor.sh`를 실행하지 않고 STEP 11도 시작하지 않습니다.** 그래야 로그 변화가 cron 실행과 연결됩니다.

```bash
MONITOR_LOG="/var/log/agent-app/monitor.log"

CRON_BEFORE_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
CRON_BEFORE_META="$(sudo stat -c '%s:%Y' "$MONITOR_LOG")"
CRON_BEFORE_LAST="$(sudo tail -n 1 "$MONITOR_LOG")"

printf '[INFO] cron observation start=%s\n' "$CRON_BEFORE_TIME"
printf '[INFO] monitor.log before meta=%s\n' "$CRON_BEFORE_META"
sudo tail -n 1 "$MONITOR_LOG"
```

`%s:%Y`는 byte 크기와 마지막 수정 시각(epoch seconds)입니다. 마지막 라인은 monitor의 고정 형식이며 Secret 값을 포함하면 안 됩니다.

### I. 75초 기다린 뒤 After 확인

```bash
sleep 75

CRON_AFTER_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
CRON_AFTER_META="$(sudo stat -c '%s:%Y' "$MONITOR_LOG")"
CRON_AFTER_LAST="$(sudo tail -n 1 "$MONITOR_LOG")"

printf '[INFO] cron observation end=%s\n' "$CRON_AFTER_TIME"
printf '[INFO] monitor.log after meta=%s\n' "$CRON_AFTER_META"
sudo tail -n 3 "$MONITOR_LOG"
```

Before와 After를 비교합니다.

```bash
if [ "$CRON_BEFORE_META" != "$CRON_AFTER_META" ] \
   && [ "$CRON_BEFORE_LAST" != "$CRON_AFTER_LAST" ]; then
    echo '[PASS] monitor.log changed automatically during the cron observation window'
else
    echo '[STOP] automatic monitor.log growth was not confirmed'
fi
```

최신 라인이 공식 포맷인지도 다시 확인합니다.

```bash
printf '%s\n' "$CRON_AFTER_LAST" \
  | grep -Eq '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] PID:[0-9]+ CPU:[0-9]+([.][0-9]+)?% MEM:[0-9]+([.][0-9]+)?% DISK_USED:[0-9]+([.][0-9]+)?%$' \
  && echo '[PASS] cron-produced latest monitor.log line has official format' \
  || echo '[STOP] latest monitor.log line format mismatch'
```

`75초`는 특정 초에 등록해도 다음 분 경계를 한 번 이상 지나도록 하기 위한 R01 관찰값입니다. 공식 요구는 **등록 후 1~2분 내 새 라인 누적 확인**입니다.

### J. cron 실행 후 Agent 상태 유지 재확인

```bash
pgrep -x agent-app | wc -l
ps -C agent-app -o user=,uid=,pid=,comm=
sudo ss -lntp | grep ':15034'
sudo systemctl is-active cron
```

정상 기준:

```text
agent-app count = 1
user = agent-admin
TCP 15034 LISTEN
cron service = active
```

### K. 자동 실행 실패 시 최소 진단

먼저 crontab 자체를 다시 개수로 확인합니다.

```bash
sudo crontab -u agent-admin -l 2>/dev/null \
  | grep -Fxc "$CRON_LINE" || true
sudo systemctl status cron --no-pager
```

최근 cron 서비스 기록을 봅니다.

```bash
sudo journalctl -u cron --since '5 minutes ago' --no-pager | tail -n 80
```

Ubuntu 환경에 `/var/log/syslog`가 있고 cron 기록이 그쪽에도 남는 경우 보조로 확인할 수 있습니다.

```bash
sudo test -r /var/log/syslog \
  && sudo grep 'CRON' /var/log/syslog | tail -n 50 \
  || true
```

`agent-admin`의 환경·권한을 다시 확인합니다.

```bash
sudo runuser -u agent-admin -- test -r /opt/agent-app/env.sh \
  && echo '[PASS] env.sh readable' \
  || echo '[FAIL] env.sh unreadable'

sudo runuser -u agent-admin -- test -x /opt/agent-app/bin/monitor.sh \
  && echo '[PASS] monitor executable' \
  || echo '[FAIL] monitor not executable'

sudo runuser -u agent-admin -- test -w /var/log/agent-app \
  && echo '[PASS] log directory writable' \
  || echo '[FAIL] log directory not writable'
```

그리고 D의 **cron-like 최소 환경 수동 실행**을 다시 수행해 cron 스케줄 문제와 실행 본문 문제를 분리합니다. 수동 실행이 성공하지만 cron만 실패하면 service/crontab 쪽을, 수동 실행도 실패하면 env.sh/권한/Agent 쪽을 먼저 봅니다.

> 실패했다고 `chmod 777`, Root cron으로 변경, `sudo`를 cron 한 줄 안에 삽입, 동일 cron 줄 반복 추가로 우회하지 않습니다.

### L. 실패 시 체크포인트 기반 Recovery

체크포인트에는 Secret이나 crontab 내용 자체가 없습니다.

```bash
cat "$CRON_CHECKPOINT"
```

#### 시작 전에 `agent-admin` crontab이 있었던 경우

`CRON_EXISTED=yes`이고 `CRON_BAK`이 이번 STEP의 root-only 백업이라는 것을 확인한 뒤 기존 전체 crontab을 복원합니다.

```bash
sudo crontab -u agent-admin "$CRON_BAK"
```

#### 시작 전에 crontab이 없었던 경우

`CRON_EXISTED=no`였다는 체크포인트를 확인하고, 이번 STEP에서 처음 만든 crontab 전체를 철회해야 할 때만 다음을 사용합니다.

```bash
sudo crontab -u agent-admin -r
```

`crontab -r`은 해당 사용자의 **전체 crontab을 제거**하므로 `CRON_EXISTED=no`라는 시작 상태가 확실할 때만 사용합니다.

복구 후 B1-1 관련 항목 수를 다시 확인합니다.

```bash
sudo crontab -u agent-admin -l 2>/dev/null \
  | grep -Ec '(/opt/agent-app/env\.sh|/opt/agent-app/bin/monitor\.sh)' || true
```

이번 STEP 시작 전 cron 서비스가 inactive였고 **B1-1 전체 변경을 철회해 원래 외부 환경으로 되돌리는 경우에만** 서비스 원복을 검토합니다.

```bash
sudo systemctl stop cron
```

이 명령은 `CRON_SERVICE_BEFORE`가 inactive였다는 체크포인트를 확인한 전체 rollback에서만 사용합니다. B1-1 최종 상태에서 cron 자동 실행을 유지하려면 cron 서비스는 active여야 합니다.

> Recovery를 이유로 `monitor.log`의 실제 Runtime 기록을 삭제하지 않습니다. 이미 생성된 관제 로그는 수행 이력이며, crontab 복구와 별개입니다.

## ⑥ 명령어와 코드에 입문자가 이해할 수 있는 주석

### cron 서비스와 기존 crontab 조사

- `command -v crontab`
  - `crontab` 명령이 설치되어 현재 `PATH`에서 실행 가능한지 확인합니다.
- `systemctl is-active cron`
  - cron 서비스가 현재 실제 실행 중인지 확인합니다.
- `systemctl is-enabled cron`
  - 부팅 시 자동 시작 설정을 읽기 전용으로 확인합니다. 이 STEP은 공식 요구에 없는 enable 정책을 무조건 변경하지 않습니다.
- `crontab -u agent-admin -l`
  - `-u agent-admin`은 대상 사용자를 지정하고, `-l`은 그 사용자의 현재 작업 목록을 읽습니다.
  - 다른 사용자의 crontab을 조회하므로 관리자 권한이 필요합니다.

### 정확한 cron 한 줄

- `* * * * *`
  - 첫 번째 `*`: 모든 분
  - 두 번째 `*`: 모든 시
  - 세 번째 `*`: 모든 일(day of month)
  - 네 번째 `*`: 모든 월
  - 다섯 번째 `*`: 모든 요일(day of week)
  - 결과적으로 **매분** 실행됩니다.
- `PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`
  - cron의 제한된 기본 `PATH`에 의존하지 않고 `pgrep`, `ss`, `ps`, `df`, `ufw`, `systemctl` 같은 명령 탐색 경로를 명시합니다.
- `/bin/bash -c '...'`
  - cron의 바깥 실행 셸에 의존하지 않고 실제 실행 본문을 Bash로 처리합니다.
- `set -e`
  - `env.sh`를 읽는 과정이 실패하면 잘못된 환경으로 monitor를 계속 실행하지 않습니다.
- `. /opt/agent-app/env.sh`
  - 현재 Bash 프로세스에 R01의 non-secret 환경변수를 읽습니다. `.`은 `source`와 같은 역할의 POSIX 표기입니다.
- `exec /opt/agent-app/bin/monitor.sh`
  - Bash 프로세스를 실제 monitor 실행으로 교체합니다.
- `>/dev/null`
  - cron 실행의 일반 콘솔 출력을 별도 파일로 계속 쌓지 않고 버립니다.
- `2>&1`
  - 표준 오류(fd 2)를 이미 `/dev/null`로 향한 표준 출력(fd 1)과 같은 곳으로 보냅니다.
- 이 R01 선택은 별도 `cron.log`가 무한히 커지는 부수 로그 문제를 만들지 않기 위한 것입니다. 오류 조사 시 수동 최소환경 실행과 cron service journal을 사용합니다.

### 기존 항목 개수 검사

- `grep -Fxc "$CRON_LINE"`
  - `-F`는 정규식이 아닌 고정 문자열로 비교하고, `-x`는 줄 전체가 같아야 하며, `-c`는 일치 줄 수만 출력합니다.
  - 정확한 항목이 1개인지 판단할 때 사용합니다.
- `grep -Ec '(...env.sh|...monitor.sh)'`
  - 이전 형식 또는 중복 가능성이 있는 B1-1 관련 줄의 개수를 확인합니다.
- 개수만 먼저 보는 이유
  - 사용자 crontab 전체 내용을 불필요하게 화면·Evidence에 노출하지 않으면서 중복 여부를 판정하기 위해서입니다.

### root-only 체크포인트

- `mktemp /root/...XXXXXX`
  - root만 접근하는 `/root`에 충돌 가능성이 낮은 고유 파일을 만듭니다.
- `tee "$CRON_BAK" >/dev/null`
  - 기존 crontab 내용을 root-only 백업 파일에 기록하면서 화면에는 출력하지 않습니다.
- `chmod 0600`
  - root만 읽기·쓰기 가능하게 합니다.
- `/tmp/b1-1-cron-checkpoint...txt`
  - 실제 crontab 내용이 아니라 백업 경로, 존재 여부, 서비스 상태, 개수 같은 비민감 메타데이터만 둡니다.

### 최소 환경 수동 사전 실행

- `getent passwd agent-admin | cut -d: -f6`
  - 계정 DB의 colon 구분 필드 중 home 경로를 얻습니다.
- `env -i`
  - 현재 사용자의 로그인 환경을 상속하지 않고 거의 빈 환경에서 시작합니다.
- `HOME=...`, `PATH=...`, `SHELL=/bin/sh`
  - cron 환경에서 필요한 최소 기본값을 명시합니다.
- `/bin/bash -c ...`
  - 실제 cron 한 줄과 같은 실행 본문을 Bash로 수행합니다.
- `PRECRON_RC=$?`
  - 수동 사전 실행의 실제 종료 코드를 저장합니다. `0`이어야 등록으로 진행합니다.

### cron 서비스 상태 변경

- `systemctl is-active --quiet cron`
  - 화면 출력 없이 종료 코드로 active 여부를 확인합니다.
- `systemctl start cron`
  - 서비스가 inactive인 경우 현재 Runtime에서 cron을 시작합니다.
  - 부팅 enable 설정 자체를 바꾸는 명령은 아닙니다.
- 서비스 시작 전 상태를 체크포인트에 기록한 이유
  - 전체 rollback 시 원래 inactive였는지 구분하기 위해서입니다.

### 기존 crontab을 보존하면서 한 줄 추가

- `cp -a "$CRON_BAK" "$CRON_NEW"`
  - 기존 전체 crontab 백업을 staging 파일로 복사합니다.
- `printf "\n%s\n" "$1" >> "$2"`
  - 기존 내용 끝에 줄바꿈과 정확한 B1-1 한 줄만 추가합니다.
- `crontab -u agent-admin "$CRON_NEW"`
  - staging 파일 전체를 `agent-admin`의 새 crontab으로 설치합니다.
  - 이 명령은 사용자 crontab 전체를 교체하므로 **CRON_NEW가 기존 백업 + 정확한 한 줄인지 검증한 뒤에만** 실행합니다.
- `grep -v` 자동 삭제를 사용하지 않는 이유
  - 비슷한 문자열을 가진 다른 작업까지 잘못 제거하는 것을 막기 위해서입니다.

### 1~2분 실제 자동 실행 검증

- `stat -c '%s:%Y' monitor.log`
  - active 로그의 byte 크기와 수정 시각을 함께 기록합니다.
  - 로그 회전 가능성 때문에 줄 수 하나만 비교하는 것보다 Before/After 변화를 보기 쉽습니다.
- `tail -n 1`
  - 관찰 시작 시점의 최신 라인을 저장합니다.
- `sleep 75`
  - Shell을 약 75초 기다리게 해 적어도 다음 분 경계를 지나도록 합니다.
  - 기다리는 동안 수동 monitor 실행이나 STEP 11을 하지 않아야 자동 변화와 cron을 연결하기 쉽습니다.
- `CRON_BEFORE_LAST != CRON_AFTER_LAST`
  - 최신 Runtime 라인의 timestamp를 포함한 실제 내용이 달라졌는지 확인합니다.
- 공식 정규식 검사
  - cron이 만들어 낸 최신 라인도 수동 실행과 동일한 공식 `PID/CPU/MEM/DISK_USED` 포맷이어야 합니다.

### 실패 진단

- `systemctl status cron --no-pager`
  - cron service 현재 상태와 최근 메시지를 화면 페이저 없이 확인합니다.
- `journalctl -u cron --since '5 minutes ago'`
  - 최근 5분의 cron service journal을 확인합니다.
- `/var/log/syslog`
  - 환경에 따라 cron 이벤트가 syslog에도 남을 수 있어 보조 진단에 사용합니다.
- 최소 환경 수동 실행
  - cron 스케줄러 문제와 실제 monitor 실행 본문 문제를 분리하는 핵심 검사입니다.

### Recovery

- `crontab -u agent-admin "$CRON_BAK"`
  - 시작 전에 기존 crontab이 있었다면 root-only 전체 백업으로 원래 내용을 복원합니다.
- `crontab -u agent-admin -r`
  - 사용자의 전체 crontab을 제거합니다. 시작 전에 **crontab이 전혀 없었다는 체크포인트가 있을 때만** 사용합니다.
- `systemctl stop cron`
  - 이번 STEP 시작 전 서비스가 inactive였고 전체 작업을 원래 외부 상태로 rollback할 때만 검토합니다.
- `monitor.log` 삭제 금지
  - cron 설정 복구와 이미 생성된 실제 관제 이력 삭제는 별개이므로 Runtime 로그를 지워 실패를 숨기지 않습니다.

### 재실행 안전성

STEP 10은 실제 사용자 crontab과 system service 상태를 변경할 수 있으므로 전체를 무조건 반복하지 않습니다.

```text
Agent / ss / stat / 권한 / service / 개수 조회              → 🟢 SAFE TO RERUN
CRON_LINE 변수 정의 / exact·related count                  → 🟢 SAFE TO RERUN
root-only crontab Checkpoint 생성                           → 🟡 기존 crontab 민감성 인지 후
cron-like 수동 사전 실행                                   → 🟡 실제 monitor.log 한 줄 append 가능
systemctl start cron                                       → 🟡 Checkpoint 후, inactive일 때만
정확한 기존 항목 1개 발견                                  → 🟢 중복 추가 없이 유지
staging crontab 생성                                       → 🟡 root-only 경로에서만
crontab -u agent-admin CRON_NEW                            → 🔴 전체 crontab 교체이므로 staged 내용 검증 후
75초 관찰                                                  → 🟢 상태 변경 없음, 단 수동 monitor 실행 금지
crontab 복원                                               → 🔴 CRON_BAK / CRON_EXISTED 확인 후
crontab -r                                                 → 🔴 원래 crontab이 없었을 때만
systemctl stop cron                                        → 🔴 원래 inactive였던 전체 rollback에서만
```

> **STOP 기준:** STEP 09 실제 Runtime PASS 미확인, Agent count/user/15034 이상, Runtime monitor와 Repository Reference 불일치, `agent-admin` env/monitor/log 권한 실패, 기존 B1-1 related cron이 중복·충돌 상태, root-only 백업 실패, cron-like 수동 실행 `exit != 0`, cron service active 미확인, staged crontab의 exact count가 1이 아님, 최종 exact/related count가 1/1이 아님, 75초 관찰 후 monitor.log 변화 미확인, 최신 라인 공식 포맷 실패 중 하나라도 발생하면 STEP 11로 진행하지 않습니다.

## ⑦ 예상되는 정상 결과

등록 상태:

```text
cron service = active
agent-admin crontab의 B1-1 exact line = 1개
B1-1 related line = 1개
중복 없음
```

R01 cron 한 줄:

```text
* * * * * PATH=... /bin/bash -c 'set -e; . /opt/agent-app/env.sh; exec /opt/agent-app/bin/monitor.sh' >/dev/null 2>&1
```

위 표시는 구조 설명용이며 실제 등록된 전체 PATH 문자열은 이 STEP의 `CRON_LINE`과 정확히 일치해야 합니다.

자동 실행 관찰:

```text
Before time / meta / last line
          ↓
75초 동안 수동 monitor 실행 없음
          ↓
After time / meta / last line
          ↓
monitor.log metadata 변화
latest line 변화
latest line 공식 포맷 PASS
```

그리고:

```text
agent-app process count = 1 유지
user = agent-admin 유지
TCP 15034 LISTEN 유지
```

## ⑧ 그 결과가 의미하는 것

공식 요구의 세 요소가 실제 Runtime에서 연결된 것입니다.

```text
agent-admin 사용자 스케줄
        +
* * * * * 매분
        +
제한된 cron 환경에서 env.sh 명시 적용
        ↓
monitor.sh 자동 실행
        ↓
/var/log/agent-app/monitor.log 실제 신규 라인
```

즉 단순한 crontab 설정 화면이 아니라 **스케줄 등록 → cron service → 실제 실행 → 실제 로그 변화**까지 증명합니다. 또한 기존 crontab을 root-only로 체크포인트하고 중복·충돌을 자동 삭제하지 않으므로 미션 외 사용자 작업을 덜 훼손하는 방식입니다.

이 STEP이 실제로 성공해도 Process/Port failure `exit 1`, 강제 Warning 경로, 통합 검증(Verification), Evidence 정리는 아직 남아 있으므로 전체 B1-1 CLEAR는 아닙니다.

## ⑨ 자주 발생하는 오류와 해결 방법

- `crontab: command not found` → STEP 02 `cron` 패키지 설치 상태 확인. 임의 다른 scheduler로 공식 cron 요구를 대체하지 않음.
- `cron` service inactive → 체크포인트 후 `systemctl start cron`, 다시 `is-active`. 서비스 시작 실패 원인을 `status/journalctl`로 확인.
- `EXACT=0`, `RELATED=1` → 이전 형식의 B1-1 cron일 가능성. 자동 삭제하지 말고 관련 한 줄을 로컬에서 확인하고 현재 의도와 비교.
- `EXACT=2` 또는 `RELATED>1` → 중복 가능성. 더 추가하지 않고 STOP. 어떤 줄이 이전 작업인지 확인 후 최소 수정 계획 수립.
- root-only backup 생성 실패 → crontab 변경 금지. `/root` filesystem/권한/공간을 확인.
- `PRECRON_RC=1` → cron 등록 문제가 아니라 실행 본문이 제한 환경에서 실패한 것. 콘솔의 첫 `[FAIL]`, Agent/15034, env.sh, PATH, log 권한을 확인.
- `crontab`은 정확한데 monitor.log가 안 변함 → `systemctl status cron`, `journalctl -u cron`, 권한 검사, 최소 환경 수동 실행 순서로 확인.
- cron이 실행되지만 Firewall `[WARNING]`이 예상됨 → hard failure가 아니며 monitor는 계속 로그를 써야 함. 명시 PATH에 `/usr/sbin`이 포함되어 현재 Reference의 UFW fallback 판정 경로를 사용할 수 있게 함.
- `Permission denied` → `agent-admin`의 `agent-core` membership, env.sh read, monitor execute, `/var/log/agent-app` write를 STEP 05/08 기준으로 확인. cron 안에 `sudo`를 넣어 우회하지 않음.
- Before/After 최신 줄이 같음 → 관찰 중 수동 실행 여부, cron service active, exact entry, journal을 확인. 같은 줄을 또 추가하지 않음.
- Before/After meta는 변했는데 last line이 같음 → 다른 writer/회전/mtime 변화 가능성을 조사. 자동 PASS 처리하지 않음.
- `monitor.log`가 회전됨 → active 줄 수는 줄 수 있으므로 단순 `wc -l`만으로 판단하지 않음. 최신 라인·mtime·공식 포맷과 `.1` 상태를 함께 확인.
- cron output을 `/var/log/agent-app/cron.log`에 계속 쌓고 싶음 → 공식 필수 사항은 아님. 별도 로그 보존정책 없이 무한 누적되는 추가 로그를 기본 R01로 만들지 않음.
- `crontab -e` 편집 중 실수 → 이번 R01은 수동 editor보다 checkpoint + staged file 설치를 우선. 기존 다른 항목을 보존할 수 있음.
- Recovery 필요 → `CRON_EXISTED=yes`면 backup 전체 복원, `no`였을 때만 `crontab -r`. 시작 상태를 확인하지 않고 `-r` 금지.

## ⑩ 완료 확인

- [ ] STEP 09 실제 10MB/10개 격리 회전 PASS를 이미 확인
- [ ] Agent process count=1 / user=`agent-admin` / TCP 15034 정상 유지
- [ ] Runtime monitor = Repository Reference
- [ ] `agent-admin` env.sh read 가능
- [ ] `agent-admin` monitor.sh execute 가능
- [ ] `agent-admin` `/var/log/agent-app` write 가능
- [ ] production `monitor.log` 존재 + non-empty
- [ ] `crontab` 명령 존재
- [ ] cron service 시작 전 active/enabled 상태 확인
- [ ] 기존 `agent-admin` crontab 존재 여부 확인
- [ ] exact/related B1-1 cron line count 확인
- [ ] 기존 crontab 전체 내용을 공개하지 않음
- [ ] root-only `CRON_BAK` 생성 및 mode `600`
- [ ] `/tmp` checkpoint에는 crontab 내용이 아닌 메타데이터만 기록
- [ ] cron-like 최소 환경 수동 실행 `PRECRON_RC=0`
- [ ] cron service active
- [ ] 기존 exact 1개면 중복 추가 안 함
- [ ] related 0개일 때만 기존 crontab + 정확한 한 줄 staged install
- [ ] 관련 중복/충돌이 있으면 자동 삭제하지 않고 STOP
- [ ] 최종 exact B1-1 cron line = 1
- [ ] 최종 related B1-1 cron line = 1
- [ ] cron 실행 계정 = `agent-admin`
- [ ] `* * * * *` 매분 스케줄
- [ ] cron line에서 PATH 명시
- [ ] `/bin/bash -c`로 `env.sh` 명시 적용
- [ ] cron command 안에 `sudo` 없음
- [ ] 별도 무제한 `cron.log`를 기본으로 만들지 않음
- [ ] Before 시간/메타데이터/마지막 라인 기록
- [ ] 75초 관찰 중 수동 monitor 실행·STEP 11 시험 안 함
- [ ] After 메타데이터가 Before와 달라짐
- [ ] After 최신 라인이 Before와 달라짐
- [ ] After 최신 라인이 공식 로그 포맷
- [ ] cron 실행 후 Agent process 1개 유지
- [ ] cron 실행 후 TCP 15034 LISTEN 유지
- [ ] 실패 시 service journal + 최소 환경 수동 실행으로 원인 분리
- [ ] Recovery가 필요하면 `CRON_EXISTED`와 root-only backup 기준으로 최소 복구
- [ ] `crontab -r`은 시작 시 crontab이 없었던 경우에만 사용
- [ ] Runtime 로그를 Recovery 이유로 삭제하지 않음
- [ ] **실제 1~2분 자동 로그 증가를 확인하기 전에는 cron Runtime PASS로 기록하지 않음**

---

<a id="step-11"></a>
## STEP 11 — Health 실패와 Warning-only 분기 격리 검증

## ① 왜 하는가

공식 B1-1은 `monitor.sh`에서 **Agent 프로세스가 없거나 TCP `15034`가 LISTEN 상태가 아니면 `exit 1`로 실패**해야 하고, 반대로 CPU·메모리·Root 디스크 사용률이 임계값을 넘으면 `[WARNING]`만 출력한 뒤 **계속 실행**해야 합니다. 정상 실행만 확인하면 이 두 정책이 실제로 분리되어 있는지 증명하기 어렵습니다.

실제 Agent를 종료하거나 실제 `15034` 소켓을 막고 시험하면 STEP 07~10에서 확보한 정상 Runtime을 손상시킬 수 있습니다. 따라서 이 STEP은 **실제 Agent/15034/cron 상태를 유지한 채, 현재 자식 프로세스에만 환경변수를 재정의(Environment Override)** 하여 실패·경고 분기를 격리 검증합니다.

또한 STEP 10 이후에는 cron이 production `/var/log/agent-app/monitor.log`를 매분 계속 갱신할 수 있으므로, STEP 11의 수동 시험 로그는 `mktemp`로 만든 별도 디렉터리에 기록합니다. 이렇게 해야 cron의 정상 production writer와 수동 분기 시험을 서로 섞지 않고 판정할 수 있습니다.

> 이 STEP은 실제 UFW를 끄지 않습니다. 공식 정책상 Firewall 비활성은 Warning-only이지만, 그 분기를 강제로 확인하려고 정상 방화벽을 비활성화하는 것은 미션 최종 보안 상태를 불필요하게 훼손합니다. Firewall active 상태는 STEP 04/08/10과 통합 검증에서 확인하고, STEP 11의 강제 Warning Runtime 시험은 CPU/MEM/DISK 임계값 분기에 집중합니다.

## ② 무엇을 하는가

1. STEP 10의 **실제 cron Runtime PASS**가 끝났는지 확인하고, Agent 1개·user=`agent-admin`·TCP `15034`·cron active·Runtime monitor 동일성을 다시 확인합니다.
2. 이번 시험 전용 `mktemp` 디렉터리를 `agent-admin` 소유로 생성하여 production 로그와 분리합니다.
3. Process failure 시험 전 `definitely-not-running-b1-1`이라는 가짜 프로세스 이름이 실제로 존재하지 않는지 확인합니다.
4. 실제 Agent는 그대로 둔 채 `AGENT_PROCESS_NAME`만 가짜 값으로 덮어써 `Process Health` 실패를 유도하고 종료 코드가 정확히 `1`인지 확인합니다.
5. Process failure가 자원 수집·로그 append 전에 중단되는 현재 구현과 일치하도록 격리 `monitor.log`가 생성되지 않았는지 확인합니다.
6. 실제 Agent/15034가 그대로 유지되는지 다시 확인합니다.
7. Port failure용 높은 포트 `65534`가 현재 LISTEN 중이 아닌지 먼저 확인합니다. 사용 중이면 임의로 계속하지 않고 다른 미사용 포트를 먼저 찾습니다.
8. 실제 `AGENT_PROCESS_NAME=agent-app`은 유지한 채 `AGENT_PORT`만 미사용 포트로 덮어써 Process는 `[OK]`, Port는 `[FAIL]`, 종료 코드는 `1`인지 확인합니다.
9. Port failure 후에도 격리 로그가 생기지 않았고 실제 Agent/15034가 정상인지 확인합니다.
10. Warning 시험에서는 실제 Process/Port를 유지하고 `CPU_WARN_THRESHOLD`, `MEM_WARN_THRESHOLD`, `DISK_WARN_THRESHOLD`만 이번 자식 프로세스에서 `-1`로 낮춥니다.
11. CPU/MEM/DISK 세 경고가 모두 실제 출력되고, 스크립트가 계속 진행해 격리 `monitor.log`를 공식 포맷으로 append하며 종료 코드가 `0`인지 확인합니다.
12. 모든 시험 뒤 실제 Agent 1개·user=`agent-admin`·TCP `15034`·cron active가 그대로인지 확인합니다.
13. Evidence 후보를 먼저 확보한 뒤 예상 패턴의 임시 `monitor.log*`만 삭제하고 빈 시험 디렉터리를 제거합니다.

## ③ 이번 단계에서 알아야 할 용어

- **실패 경로(Failure Path)** — 정상 조건이 깨졌을 때 의도한 오류 처리로 이동하는 실행 흐름입니다.
- **경고 전용 경로(Warning-only Path)** — 이상 징후를 알리되 프로세스를 실패로 종료하지 않는 흐름입니다.
- **종료 코드(Exit Code)** — 프로그램이 호출자에게 성공/실패를 숫자로 전달하는 값입니다. 현재 공식 Health failure 기준은 `1`, 정상/Warning-only 완료는 `0`입니다.
- **환경변수 재정의(Environment Override)** — 파일을 수정하지 않고 특정 프로세스 실행에서만 기존 환경값을 임시로 바꾸는 방법입니다.
- **격리 시험(Isolated Test)** — 실제 운영 대상이나 로그 대신 별도 안전 경로에서 같은 구현의 분기를 재현하는 시험입니다.
- **시험 픽스처(Test Fixture)** — 특정 분기를 재현하기 위해 준비한 입력·상태입니다. 여기서는 가짜 프로세스 이름, 미사용 포트, 낮춘 임계값이 해당합니다.
- **하드 실패(Hard Failure)** — 뒤 동작을 계속하면 결과를 신뢰할 수 없어 즉시 실패 종료하는 상태입니다.
- **부작용(Side Effect)** — 파일 쓰기, 프로세스 종료, 설정 변경처럼 실행 외부 상태를 바꾸는 동작입니다.

## ④ 필요한 핵심 개념

```mermaid
flowchart TD
    A[STEP 10 실제 cron PASS] --> B[Agent 1개 + 15034 + cron active]
    B --> C[mktemp 격리 로그 디렉터리]

    C --> D[Process failure: 가짜 process name]
    D --> E{Process 발견?}
    E -->|아니오| F[FAIL 즉시 + exit 1]
    F --> G[격리 log 없음 + 실제 Agent/15034 유지]

    G --> H[Port failure: 실제 process + 미사용 test port]
    H --> I{test port LISTEN?}
    I -->|아니오| J[Process OK → Port FAIL + exit 1]
    J --> K[격리 log 없음 + 실제 15034 유지]

    K --> L[Warning test: 실제 process + 실제 15034]
    L --> M[CPU/MEM/DISK threshold=-1]
    M --> N[세 WARNING 출력]
    N --> O[계속 실행]
    O --> P[격리 monitor.log append]
    P --> Q[exit 0]
    Q --> R[실제 Agent/15034/cron 재확인]
    R --> S[Evidence 후보 → 안전 정리]
```

### 왜 실제 Agent를 멈추지 않는가

```text
좋지 않은 시험
→ 실제 agent-app 종료
→ Process failure 확인
→ 다시 Agent Boot
→ cron/monitor 상태까지 재복구 필요

R01 격리 시험
→ 실제 agent-app은 계속 실행
→ AGENT_PROCESS_NAME만 가짜 값
→ monitor.sh 내부 Process failure 분기만 재현
```

Port도 같은 원리입니다.

```text
실제 15034를 닫지 않음
→ AGENT_PORT만 현재 LISTEN하지 않는 높은 포트로 임시 변경
→ 실제 Agent 서비스 상태는 보존
```

### Warning 시험에서 시스템 자원을 일부러 과부하시키지 않는 이유

실제 CPU를 20% 이상 만들거나 메모리를 10% 이상 소비하거나 디스크를 80% 이상 채우는 방식은 불필요하고 위험합니다. 현재 R01 Reference는 시험을 위해 threshold 값을 환경변수로 덮어쓸 수 있으므로:

```text
실제 CPU/MEM/DISK를 위험하게 올림  X
threshold를 이번 실행에서만 -1로 낮춤 O
```

으로 같은 Warning 분기를 안전하게 재현합니다. `-1`은 **R01 시험용 값**일 뿐 공식 기본 임계값을 변경하는 것이 아닙니다. `env.sh`와 `monitor.sh` 기본값은 그대로 유지합니다.

## ⑤ 실행할 명령어 또는 코드

### 📍 실행 위치(Context)

```text
Host       : OrbStack Ubuntu 24.04 또는 WSL2 Ubuntu 24.04
Terminal A : STEP 07부터 유지 중인 Agent foreground Terminal
Terminal B : Ubuntu Bash — STEP 11 분기 격리 검증
Repository : $HOME/codyssey/codyssey-basic-b1-1-system-monitor
권한       : 일반 사용자 + 실제 agent-admin 실행/소켓 상세 확인에 필요한 sudo
venv       : 해당 없음
전제       : STEP 10 실제 cron 자동 실행 PASS 완료
```

### A. STEP 10 이후 실제 Runtime Gate 재확인 — 읽기 전용

```bash
cd "$HOME/codyssey/codyssey-basic-b1-1-system-monitor"
pwd
git branch --show-current
git status --short

AGENT_COUNT="$(pgrep -x agent-app | wc -l)"
printf '[INFO] agent-app count=%s\n' "$AGENT_COUNT"
ps -C agent-app -o user=,uid=,pid=,comm=
sudo ss -lntp | grep ':15034'
sudo systemctl is-active cron

sudo cmp -s training/round-01-clear/monitor.sh /opt/agent-app/bin/monitor.sh \
  && echo '[PASS] Runtime monitor matches Repository Reference' \
  || echo '[STOP] Runtime monitor differs from Repository Reference'
```

정상 기준:

```text
STEP 10 실제 cron 자동 로그 증가 PASS를 이미 확인
agent-app count = 1
user = agent-admin
uid != 0
TCP 15034 LISTEN
cron = active
Runtime monitor = Repository Reference
```

하나라도 다르면 분기 시험으로 강행하지 않습니다. 먼저 해당 이전 STEP의 Runtime을 정상화합니다.

### B. 이번 STEP 전용 격리 로그 디렉터리 생성

```bash
BRANCH_TEST_DIR="$(sudo -u agent-admin mktemp -d /tmp/b1-1-monitor-branches.XXXXXX)"
printf '[INFO] branch test dir=%s\n' "$BRANCH_TEST_DIR"

case "$BRANCH_TEST_DIR" in
    /tmp/b1-1-monitor-branches.*)
        echo '[PASS] isolated branch-test path confirmed'
        ;;
    *)
        echo '[STOP] unexpected test path; do not run branch tests'
        ;;
esac

sudo chown agent-admin:agent-core "$BRANCH_TEST_DIR"
sudo chmod 0770 "$BRANCH_TEST_DIR"
sudo stat -c '%U %G %a %n' "$BRANCH_TEST_DIR"

BRANCH_TEST_LOG="$BRANCH_TEST_DIR/monitor.log"
```

이 경로는 STEP 11 수동 시험 전용입니다. STEP 10에서 등록한 cron은 계속 production `/var/log/agent-app/monitor.log`를 사용할 수 있으므로 두 writer가 서로 다른 로그를 사용하게 됩니다.

### C. Process failure 시험 전 가짜 프로세스 이름 충돌 확인

```bash
FAKE_PROCESS_NAME='definitely-not-running-b1-1'

if pgrep -x "$FAKE_PROCESS_NAME" >/dev/null 2>&1; then
    echo '[STOP] fake process name unexpectedly exists; choose another unique name'
else
    echo '[PASS] fake process name is not running'
fi
```

가짜 이름이 실제로 존재한다면 Process failure가 재현되지 않으므로 다른 고유 문자열로 바꾼 뒤 다시 확인합니다. 실제 `agent-app`은 건드리지 않습니다.

### D. Process failure 실행 — 실제 Agent는 그대로 유지

```bash
if PROCESS_OUTPUT="$(
  sudo -u agent-admin -H env BRANCH_TEST_DIR="$BRANCH_TEST_DIR" /bin/bash -c '
    set +x
    source /opt/agent-app/env.sh
    export AGENT_LOG_DIR="$BRANCH_TEST_DIR"
    export AGENT_PROCESS_NAME="definitely-not-running-b1-1"
    exec /opt/agent-app/bin/monitor.sh
  ' 2>&1
)"; then
    PROCESS_RC=0
else
    PROCESS_RC=$?
fi

printf '%s\n' "$PROCESS_OUTPUT"
printf '[INFO] process_failure_exit=%s\n' "$PROCESS_RC"
```

필수 판정:

```bash
printf '%s\n' "$PROCESS_OUTPUT" \
  | grep -Fq '[FAIL] Agent process not found' \
  && echo '[PASS] process failure message confirmed' \
  || echo '[STOP] expected process failure message missing'

if [ "$PROCESS_RC" -eq 1 ]; then
    echo '[PASS] process health failure exits 1'
else
    echo '[STOP] process health failure did not exit 1'
fi
```

현재 Reference는 Process Health에서 실패하면 자원 수집과 로그 append 전에 종료합니다. 따라서 새 격리 디렉터리에서는 아직 `monitor.log`가 생기지 않아야 합니다.

```bash
sudo test ! -e "$BRANCH_TEST_LOG" \
  && echo '[PASS] process failure stopped before log append' \
  || echo '[STOP] unexpected isolated monitor.log after process failure'
```

### E. Process failure 이후 실제 Agent/15034가 손상되지 않았는지 확인

```bash
pgrep -x agent-app | wc -l
ps -C agent-app -o user=,uid=,pid=,comm=
sudo ss -lntp | grep ':15034'
```

정상 기준은 기존과 동일하게 **1개 / `agent-admin` / TCP 15034 LISTEN**입니다. 이 시험은 실제 Agent를 종료하거나 포트를 닫지 않았어야 합니다.

### F. Port failure용 시험 포트가 실제 미사용인지 확인

기본 후보는 `65534`입니다.

```bash
TEST_PORT=65534

if sudo ss -lnt | awk -v port=":${TEST_PORT}" 'NR > 1 && $4 ~ (port "$" ) {found=1} END {exit !found}'; then
    echo "[STOP] TCP $TEST_PORT is already LISTEN; choose and verify another unused high port"
else
    echo "[PASS] TCP $TEST_PORT is not LISTEN and can be used as the failure fixture"
fi
```

`65534`가 실제로 사용 중이면 그대로 강행하지 않습니다. 예를 들어 `65533`처럼 다른 높은 포트를 선택한 뒤 **같은 `ss` 검사로 먼저 미사용임을 확인**합니다.

### G. Port failure 실행 — Process는 실제 Agent를 사용

```bash
if PORT_OUTPUT="$(
  sudo -u agent-admin -H env BRANCH_TEST_DIR="$BRANCH_TEST_DIR" TEST_PORT="$TEST_PORT" /bin/bash -c '
    set +x
    source /opt/agent-app/env.sh
    export AGENT_LOG_DIR="$BRANCH_TEST_DIR"
    export AGENT_PORT="$TEST_PORT"
    exec /opt/agent-app/bin/monitor.sh
  ' 2>&1
)"; then
    PORT_RC=0
else
    PORT_RC=$?
fi

printf '%s\n' "$PORT_OUTPUT"
printf '[INFO] port_failure_exit=%s\n' "$PORT_RC"
```

Process Health는 실제 `agent-app`을 그대로 사용하므로 먼저 `[OK] Process found`가 나와야 하고 그 다음 시험 포트에서 실패해야 합니다.

```bash
printf '%s\n' "$PORT_OUTPUT" \
  | grep -Fq '[OK] Process found' \
  && echo '[PASS] process health remained OK during port test' \
  || echo '[STOP] process health failed before port branch'

printf '%s\n' "$PORT_OUTPUT" \
  | grep -Fq "[FAIL] TCP ${TEST_PORT} is not LISTEN" \
  && echo '[PASS] port failure message confirmed' \
  || echo '[STOP] expected port failure message missing'

if [ "$PORT_RC" -eq 1 ]; then
    echo '[PASS] port health failure exits 1'
else
    echo '[STOP] port health failure did not exit 1'
fi
```

Port failure도 자원 수집·로그 append 전에 종료하므로, Process 시험과 마찬가지로 격리 로그는 아직 없어야 합니다.

```bash
sudo test ! -e "$BRANCH_TEST_LOG" \
  && echo '[PASS] port failure stopped before log append' \
  || echo '[STOP] unexpected isolated monitor.log after port failure'
```

### H. Port failure 이후 실제 Agent/15034 재확인

```bash
pgrep -x agent-app | wc -l
ps -C agent-app -o user=,uid=,pid=,comm=
sudo ss -lntp | grep ':15034'
```

시험용 `AGENT_PORT` 값은 자식 Bash 안에서만 사용되었으므로 실제 Agent가 LISTEN 중인 `15034`와 `env.sh`의 기본 `AGENT_PORT=15034`는 바뀌지 않아야 합니다.

### I. CPU/MEM/DISK Warning-only 분기 강제 검증

이제 실제 Process와 실제 TCP `15034`가 정상인 상태에서 세 threshold만 이번 실행에서 낮춥니다.

```bash
if WARNING_OUTPUT="$(
  sudo -u agent-admin -H env BRANCH_TEST_DIR="$BRANCH_TEST_DIR" /bin/bash -c '
    set +x
    source /opt/agent-app/env.sh
    export AGENT_LOG_DIR="$BRANCH_TEST_DIR"
    export CPU_WARN_THRESHOLD=-1
    export MEM_WARN_THRESHOLD=-1
    export DISK_WARN_THRESHOLD=-1
    exec /opt/agent-app/bin/monitor.sh
  ' 2>&1
)"; then
    WARNING_RC=0
else
    WARNING_RC=$?
fi

printf '%s\n' "$WARNING_OUTPUT"
printf '[INFO] warning_test_exit=%s\n' "$WARNING_RC"
```

세 자원 경고를 각각 확인합니다. Firewall 관련 Warning은 환경에 따라 별도로 보일 수 있으므로 단순 `[WARNING]` 총 개수가 아니라 **세 threshold 문구를 각각 검사**합니다.

```bash
printf '%s\n' "$WARNING_OUTPUT" | grep -Fq 'CPU threshold exceeded' \
  && echo '[PASS] CPU warning branch' \
  || echo '[STOP] CPU warning missing'

printf '%s\n' "$WARNING_OUTPUT" | grep -Fq 'MEM threshold exceeded' \
  && echo '[PASS] MEM warning branch' \
  || echo '[STOP] MEM warning missing'

printf '%s\n' "$WARNING_OUTPUT" | grep -Fq 'DISK_USED threshold exceeded' \
  && echo '[PASS] DISK warning branch' \
  || echo '[STOP] DISK warning missing'

if [ "$WARNING_RC" -eq 0 ]; then
    echo '[PASS] warning-only path continued and exited 0'
else
    echo '[STOP] warning-only path did not exit 0'
fi
```

### J. Warning 이후 격리 monitor.log append와 공식 포맷 검증

세 Warning이 나와도 스크립트는 계속 실행되어 격리 로그를 만들어야 합니다.

```bash
sudo test -s "$BRANCH_TEST_LOG" \
  && echo '[PASS] warning test appended isolated monitor.log' \
  || echo '[STOP] warning test did not append isolated monitor.log'

sudo tail -n 1 "$BRANCH_TEST_LOG"

sudo tail -n 1 "$BRANCH_TEST_LOG" \
  | grep -Eq '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] PID:[0-9]+ CPU:[0-9]+([.][0-9]+)?% MEM:[0-9]+([.][0-9]+)?% DISK_USED:[0-9]+([.][0-9]+)?%$' \
  && echo '[PASS] warning test log matches official format' \
  || echo '[STOP] warning test log format mismatch'
```

이 결과가 바로 **Warning은 실패가 아니라 관제 메시지이며 이후 logging까지 계속된다**는 Runtime 증거입니다.

### K. 모든 분기 시험 후 실제 서비스 상태 재확인

```bash
pgrep -x agent-app | wc -l
ps -C agent-app -o user=,uid=,pid=,comm=
sudo ss -lntp | grep ':15034'
sudo systemctl is-active cron
sudo cmp -s training/round-01-clear/monitor.sh /opt/agent-app/bin/monitor.sh \
  && echo '[PASS] Runtime monitor still matches Repository Reference' \
  || echo '[STOP] Runtime monitor drift detected'
```

정상 기준:

```text
agent-app count = 1
user = agent-admin
TCP 15034 LISTEN
cron = active
Runtime monitor = Repository Reference
```

production `/var/log/agent-app/monitor.log`는 STEP 10 cron 때문에 이 STEP 수행 중에도 자연스럽게 증가할 수 있습니다. 따라서 **STEP 11은 production 로그의 Before/After 동일성을 성공 조건으로 사용하지 않습니다.** 수동 분기 시험의 기록은 `BRANCH_TEST_DIR`로 격리합니다.

### L. Evidence 후보 확보 후 격리 파일 안전 정리

정리 전에 시험 로그의 파일명·크기와 마지막 실제 라인을 확인합니다.

```bash
sudo find "$BRANCH_TEST_DIR" -maxdepth 1 -type f -name 'monitor.log*' \
  -printf '%f %s bytes\n' | sort -V
sudo tail -n 1 "$BRANCH_TEST_LOG"
```

필요한 Evidence 후보를 확보한 뒤에만 예상 경로의 `monitor.log*` 파일을 삭제하고 빈 디렉터리를 제거합니다.

```bash
case "$BRANCH_TEST_DIR" in
    /tmp/b1-1-monitor-branches.*)
        sudo find "$BRANCH_TEST_DIR" -mindepth 1 -maxdepth 1 \
          -type f -name 'monitor.log*' -delete
        sudo rmdir "$BRANCH_TEST_DIR"
        ;;
    *)
        echo '[STOP] unexpected branch-test path; nothing deleted'
        ;;
esac
```

`rmdir`이 실패하면 예상하지 않은 파일이 있다는 뜻일 수 있으므로 디렉터리를 `rm -rf`로 통째로 지우지 않습니다. `sudo ls -la "$BRANCH_TEST_DIR"`로 남은 항목부터 확인합니다.

## ⑥ 명령어와 코드에 입문자가 이해할 수 있는 주석

### Runtime Gate

- `pgrep -x agent-app | wc -l`
  - 실제 Agent가 정확히 한 개인지 다시 확인합니다.
- `ps -C agent-app -o user=,uid=,pid=,comm=`
  - 그 프로세스가 여전히 `agent-admin`으로 실행되는지 확인합니다.
- `ss -lntp | grep ':15034'`
  - 실제 서비스 포트가 계속 LISTEN인지 확인합니다.
- `systemctl is-active cron`
  - STEP 10의 cron 자동 실행 기반이 유지되는지 확인합니다.
- `cmp -s`
  - 시험 중 Runtime `monitor.sh`를 직접 수정하지 않았는지 Repository Reference와 비교합니다.

### 격리 디렉터리

- `mktemp -d /tmp/b1-1-monitor-branches.XXXXXX`
  - 각 실행마다 고유한 시험 디렉터리를 만듭니다.
- `sudo -u agent-admin`
  - 실제 monitor 실행 계정이 직접 쓸 수 있는 임시 경로를 만듭니다.
- `chown agent-admin:agent-core`, `chmod 0770`
  - 시험 로그를 core 역할 안에서 관리하고 others 접근을 막습니다.
- `BRANCH_TEST_LOG=.../monitor.log`
  - production `/var/log/agent-app/monitor.log`와 수동 시험 로그를 명시적으로 분리합니다.

### Process failure

- `FAKE_PROCESS_NAME='definitely-not-running-b1-1'`
  - 실제 시스템에 존재하지 않아야 하는 시험 전용 process name입니다.
- `pgrep -x "$FAKE_PROCESS_NAME"`
  - 시험 전에 정말 대상 프로세스가 없는지 확인합니다.
- `export AGENT_PROCESS_NAME=...`
  - `env.sh` 파일을 수정하지 않고 이번 자식 Bash 안에서만 monitor가 찾을 process name을 바꿉니다.
- 실제 `agent-app` 프로세스는 종료하지 않습니다.

### 종료 코드와 출력 보존

- `if OUTPUT="$(command 2>&1)"; then ... else RC=$?; fi`
  - command의 stdout/stderr를 변수에 모으면서 성공/실패 종료 코드를 별도로 저장합니다.
  - 실패가 예상되는 시험을 `|| true`로 뭉개지 않고 실제 `1`을 판정할 수 있습니다.
- `2>&1`
  - stderr도 stdout과 함께 캡처해 `[FAIL]` 메시지를 한 결과에서 확인합니다.
- `printf '%s\n' "$OUTPUT"`
  - 캡처한 비밀값 없는 monitor 시험 출력을 화면에 다시 보여 줍니다.
- Secret 값은 이 출력에 포함시키지 않으며, `env.sh`에도 실제 Secret 값은 없습니다.

### Port failure

- `TEST_PORT=65534`
  - 흔히 미사용인 높은 포트를 기본 후보로 사용하지만 **미사용이라고 가정하지 않고 먼저 `ss`로 검사**합니다.
- `awk -v port=":${TEST_PORT}" ...`
  - `ss -lnt`의 local address가 해당 포트로 끝나는 LISTEN 소켓이 있는지 확인합니다.
- `export AGENT_PORT="$TEST_PORT"`
  - 실제 `15034` 소켓은 건드리지 않고 monitor의 검사 대상 포트만 이번 실행에서 바꿉니다.
- Process name은 바꾸지 않으므로 Port 시험에서 Process Health가 먼저 `[OK]`여야 Port 분기를 제대로 시험한 것입니다.

### Warning-only

- `CPU_WARN_THRESHOLD=-1`
- `MEM_WARN_THRESHOLD=-1`
- `DISK_WARN_THRESHOLD=-1`
  - 실제 자원 사용률은 음수가 될 수 없으므로 현재 구현에서 세 비교가 모두 `value > -1`을 만족해 Warning을 재현합니다.
  - 이 값은 **시험 프로세스에만 적용**되고 공식 기본값 `20/10/80`을 바꾸지 않습니다.
- 세 Warning 문자열을 각각 찾는 이유
  - Firewall Warning이 추가로 나타날 수 있으므로 `[WARNING]`이라는 단어 총 개수만 세면 자원별 분기를 정확히 증명하기 어렵습니다.
- `WARNING_RC=0`
  - Warning이 발생해도 프로그램이 실패 종료하지 않았다는 핵심 판정입니다.
- 격리 `monitor.log` 생성과 고정 포맷
  - 경고 후에도 resource 수집 → logging → 정상 종료까지 계속됐다는 별도 증거입니다.

### Firewall Warning 분기를 강제로 만들지 않는 이유

공식 구현은 Firewall active 상태를 확인하지 못하면 Warning만 출력하고 종료하지 않아야 합니다. 하지만 현재 최종 Runtime의 UFW를 일부러 disable하면 STEP 04의 보안 상태를 깨뜨립니다.

따라서 R01에서는:

```text
Firewall active Runtime 확인
→ STEP 04 / STEP 08 / STEP 10 / verify.sh

Firewall inactive 시 Warning-only 구현 구조 확인
→ Reference source review

강제 Warning Runtime 분기 시험
→ CPU / MEM / DISK threshold override
```

로 책임을 분리합니다. 방화벽을 끈 실제 장애 실험이 공식 제출에 별도로 요구되지 않는 한, 보안 설정을 파괴해서 Warning 하나를 더 얻지 않습니다.

### 정리와 재실행 안전성

```text
Agent / Port / cron / cmp 조회                         → 🟢 SAFE TO RERUN
mktemp 격리 경로 생성                                  → 🟢 새 고유 경로 생성
가짜 process name 존재 여부 확인                       → 🟢 SAFE TO RERUN
Process failure env override 실행                       → 🟡 실제 monitor failure branch 실행
미사용 test port 조회                                  → 🟢 SAFE TO RERUN
Port failure env override 실행                          → 🟡 실제 monitor failure branch 실행
Warning threshold override 실행                         → 🟡 격리 로그 1줄 append
실제 Agent/15034 종료·차단                              → 🚫 사용하지 않음
UFW disable로 Warning 강제                             → 🚫 사용하지 않음
env.sh / monitor.sh 기본값 직접 수정                   → 🚫 사용하지 않음
find -delete / rmdir                                   → 🔴 Evidence 확보 + 정확한 임시 경로 확인 후
```

> **STOP 기준:** STEP 10 실제 cron Runtime PASS 미확인, Agent count가 1이 아님, Agent user가 `agent-admin`이 아님, 실제 TCP 15034 미확인, cron inactive, Runtime monitor와 Reference 불일치, 임시 경로 패턴 이상, 가짜 process name이 실제 존재, Process failure 메시지 누락, Process failure `exit != 1`, Process failure 뒤 격리 log 생성, 실제 Agent/15034 손상, test port가 이미 LISTEN인데 강행, Port 시험에서 Process Health 먼저 실패, Port failure 메시지 누락, Port failure `exit != 1`, Port failure 뒤 격리 log 생성, CPU/MEM/DISK Warning 중 하나라도 누락, Warning test `exit != 0`, Warning 격리 log 미생성/포맷 불일치, 시험 후 실제 Agent/15034/cron 이상 중 하나라도 발생하면 STEP 12로 진행하지 않습니다.

## ⑦ 예상되는 정상 결과

Process failure:

```text
가짜 process name = 실제로 없음
[FAIL] Agent process not found ...
process_failure_exit = 1
격리 monitor.log = 없음
실제 agent-app = 1개 유지
실제 TCP 15034 = LISTEN 유지
```

Port failure:

```text
TEST_PORT = 사전에 미사용 확인
[OK] Process found ...
[FAIL] TCP <TEST_PORT> is not LISTEN
port_failure_exit = 1
격리 monitor.log = 없음
실제 TCP 15034 = LISTEN 유지
```

Warning-only:

```text
Process Health = [OK]
TCP 15034 Health = [OK]
CPU threshold Warning = 확인
MEM threshold Warning = 확인
DISK_USED threshold Warning = 확인
warning_test_exit = 0
격리 monitor.log = 생성됨
마지막 라인 = 공식 고정 포맷
```

전체 시험 후:

```text
agent-app process count = 1
user = agent-admin
TCP 15034 LISTEN
cron = active
Runtime monitor = Repository Reference
```

## ⑧ 그 결과가 의미하는 것

`monitor.sh`가 단순히 정상 환경에서만 동작하는 것이 아니라 **실패와 경고를 서로 다른 운영 정책으로 처리**한다는 것을 실제 Runtime 분기로 증명합니다.

```text
Process 없음
→ 서비스 자체를 신뢰할 수 없음
→ 즉시 exit 1
→ 이후 logging 없음

Process 정상 + Port 없음
→ 서비스가 요청을 받을 준비가 아님
→ 즉시 exit 1
→ 이후 logging 없음

Process + Port 정상 + 자원 임계값 초과
→ 서비스는 살아 있음
→ WARNING
→ 자원 측정/로그 기록 계속
→ exit 0
```

그리고 이 세 시험을 실제 Agent 종료, 실제 `15034` 차단, UFW 비활성화 없이 수행하므로 **시험 때문에 정상 Runtime을 망가뜨리지 않는 검증 구조**가 됩니다.

## ⑨ 자주 발생하는 오류와 해결 방법

- Process 시험이 `exit=0` → 가짜 이름이 실제 존재하는지 `pgrep -x`부터 확인. `monitor.sh`를 수정하기 전에 fixture가 정말 실패 조건인지 확인.
- Process 시험에서 격리 `monitor.log`가 생김 → 시험 디렉터리가 새 경로가 맞는지, 이전 Warning 시험 로그가 남아 있는지 확인. 시험 순서를 Process → Port → Warning으로 유지.
- Port `65534`가 이미 LISTEN → 다른 높은 포트를 선택하고 동일한 `ss` 검사로 미사용을 먼저 확인. 점유 프로세스를 죽여 자리를 만들지 않음.
- Port 시험에서 `Process not found`가 먼저 발생 → 실제 Agent가 사라졌거나 `AGENT_PROCESS_NAME`이 이전 Shell에서 잘못 유지된 것인지 확인. 각 시험은 독립 child shell이므로 outer shell의 불필요한 export를 만들지 않음.
- Port 시험 `exit=0` → 실제 `TEST_PORT`가 LISTEN인지 재확인하고 command output을 확인. 임의로 다른 오류를 숨기지 않음.
- Warning 시험에서 CPU Warning만 없음 → `WARNING_OUTPUT` 원문과 현재 설치본/Reference 동일성 확인. 실제 CPU를 억지로 올리지 않음.
- Warning 시험에서 `exit=1` → Warning 분기 전에 Process/Port Health가 실패했을 가능성이 큼. 첫 `[FAIL]`, 실제 Agent, 실제 15034를 먼저 확인.
- Warning은 3개인데 격리 로그가 없음 → log dir write 권한과 `BRANCH_TEST_DIR` 전달을 확인. Root로 monitor 실행해 우회하지 않음.
- Firewall `[WARNING]`이 함께 보임 → 자원 Warning 시험의 실패가 아님. STEP 04의 UFW 실제 상태와 현재 Reference firewall 판정을 별도로 조사하되, UFW를 끄거나 광범위 NOPASSWD sudo를 추가하지 않음.
- production `monitor.log`가 시험 중 바뀜 → STEP 10 cron이 active라면 자연스러운 변화일 수 있음. STEP 11의 수동 시험 로그는 격리 경로로 판정하므로 production mtime 변화만으로 실패 처리하지 않음.
- cleanup `rmdir` 실패 → 예상하지 않은 파일이 남았는지 `ls -la`로 확인. `rm -rf`로 강제 삭제하지 않음.
- 시험 중 실제 Agent가 사라짐 → STEP 12 금지. Terminal A와 STEP 07으로 돌아가 실제 Agent Runtime부터 복구.

## ⑩ 완료 확인

- [ ] STEP 10 실제 cron 자동 실행 Runtime PASS를 이미 확인
- [ ] Agent process count=1 / user=`agent-admin` / TCP 15034 정상
- [ ] cron service active
- [ ] Runtime monitor = Repository Reference
- [ ] `mktemp -d /tmp/b1-1-monitor-branches.XXXXXX` 사용
- [ ] 임시 경로 owner=`agent-admin`, group=`agent-core`, mode=`770`
- [ ] fake process name 실제 미존재 확인
- [ ] 실제 Agent를 종료하지 않고 Process failure 재현
- [ ] Process failure `[FAIL]` 확인
- [ ] Process failure `exit=1`
- [ ] Process failure 뒤 격리 monitor.log 없음
- [ ] Process 시험 후 실제 Agent/15034 유지
- [ ] Port test candidate가 실제 미사용인지 사전 확인
- [ ] 실제 15034를 닫지 않고 Port failure 재현
- [ ] Port 시험에서 Process Health `[OK]`
- [ ] Port failure `[FAIL]` 확인
- [ ] Port failure `exit=1`
- [ ] Port failure 뒤 격리 monitor.log 없음
- [ ] Port 시험 후 실제 Agent/15034 유지
- [ ] CPU threshold Warning 확인
- [ ] MEM threshold Warning 확인
- [ ] DISK_USED threshold Warning 확인
- [ ] Warning test `exit=0`
- [ ] Warning 이후 격리 monitor.log 실제 append
- [ ] Warning test 로그 마지막 라인 공식 포맷
- [ ] UFW를 일부러 disable하지 않음
- [ ] `env.sh` / `monitor.sh` 공식 기본값을 수정하지 않음
- [ ] 모든 시험 후 Agent process count=1 유지
- [ ] 모든 시험 후 user=`agent-admin` 유지
- [ ] 모든 시험 후 TCP 15034 LISTEN 유지
- [ ] 모든 시험 후 cron active 유지
- [ ] Runtime monitor와 Reference 동일성 유지
- [ ] Evidence 후보 확보 후 예상 임시 로그만 안전 정리
- [ ] **실제 세 분기 시험을 실행하기 전에는 STEP 11 Runtime PASS로 기록하지 않음**

---

---

## 다음 이동

[← 모듈 04](04-AGENT-RUNTIME.md) · [입문자 가이드 허브](../BEGINNER-GUIDE.md) · [다음: 모듈 06 →](06-VERIFICATION-AND-EVIDENCE.md)
