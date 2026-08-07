# 12. 평가 대비 설명 자료

> **기억 문장:** 동작만 보여 주지 말고, 왜 그렇게 만들었는지 실제 근거와 함께 설명한다.

이 장은 `b1-1-evaluation.md`의 네 평가 영역을 **WHAT → WHY → HOW → PROOF** 구조로 연결합니다.

---

## 1. 평가 항목 1 — 요구사항 구현 및 동작

### SSH

```text
Port 20022
PermitRootLogin no
```

검증:

```bash
sudo sshd -t
sudo sshd -T | grep -E '^(port|permitrootlogin) '
sudo ss -lntp | grep -E ':(22|20022)\b' || true
```

설명 핵심: **설정 파일 → sshd 최종 해석값 → 실제 LISTEN**을 분리해 확인합니다.

### 방화벽

```bash
sudo ufw status verbose
```

목표:

```text
active
default deny incoming
20022/tcp ALLOW
15034/tcp ALLOW
그 외 불필요한 ALLOW 없음
```

### 사용자·그룹·ACL

```text
agent-common = admin + dev + test
agent-core   = admin + dev
upload_files = common R/W
api_keys/log = core ONLY R/W
```

검증:

```bash
id agent-admin
id agent-dev
id agent-test
getfacl <path>
```

실제 허용/차단 시험은 `acceptance-test.sh`와 09장에서 확인합니다.

### Agent

원본 데이터 설명의 제공 파일:

```text
agent-app-linux-x86
agent-app-linux-arm64
```

성공 기준:

```text
현재 아키텍처용 제공 실행 파일
non-root 실행
Boot Sequence 5개 [OK]
Agent READY
0.0.0.0:15034
```

`agent_app.py`를 반드시 실행한다고 고정하지 않고 **실제 제공 앱 파일명**을 기준으로 설명합니다.

### monitor.sh

```text
process 없음 → exit 1
port 없음    → exit 1
firewall inactive → WARNING 후 계속
CPU/MEM/DISK threshold → WARNING 후 계속
정상 → 지정 로그 append + exit 0
로그 쓰기 실패 → exit 2
```

### cron

```text
agent-admin crontab
* * * * *
1~2분 내 monitor.log 자동 증가
```

### 10MB / 최대 10개

현재 저장소는 원본의 **최대 10개 파일**을 엄격히 해석합니다.

```text
current monitor.log = 1
rotated files       = 최대 9
전체                = 최대 10
```

따라서:

```text
size 10M
rotate 9
create 0660 agent-admin agent-core
```

입니다.

`rotate 10`이면 logrotate 의미상 current 1 + rotated 10으로 최대 11개가 될 수 있으므로 이 저장소에서는 사용하지 않습니다.

---

## 2. 평가 항목 2 — 구현 방식과 명령어 설명

### 왜 `pgrep`인가?

```bash
pgrep -f -- "$AGENT_PROCESS_PATTERN"
```

PID 후보를 직접 찾을 수 있고 `ps | grep | grep -v grep`보다 의도가 명확합니다. 다만 `-f`만으로는 파일명을 인자로 가진 무관한 프로세스를 오인할 수 있으므로, 현재 구현은 후보의 `/proc/<PID>/exe`, `cmdline`, UID와 self/ancestor 여부를 추가 검사합니다.

소유자 확인은:

```bash
ps -o user,pid,ppid,cmd -p <PID>
```

를 사용합니다.

### 왜 `ss`인가?

```bash
ss -lntp4H
```

프로세스 존재와 별도로 실제 TCP LISTEN 상태를 확인해야 하기 때문입니다. 또한 `-p`의 PID를 선택한 Agent PID와 연결하고 IPv4 wildcard `0.0.0.0:15034`를 요구해 무관한 리스너나 IPv6-only 리스너의 false positive를 막습니다.

### CPU

`/proc/stat`의 누적 counter를 두 번 읽고 total/idle 차이로 짧은 구간 사용률을 계산합니다.

### MEM

```text
(MemTotal - MemAvailable) / MemTotal × 100
```

Linux cache를 단순히 모두 사용 불가 메모리로 간주하지 않기 위해 `MemAvailable`을 사용합니다.

### DISK

```bash
df -P /
```

원본이 요구한 Root partition의 Used %를 사용합니다.

### 로그 포맷을 왜 고정하는가?

```text
[시간] PID CPU MEM DISK_USED
```

사람이 비교하기 쉽고, `report.sh`가 안정적으로 파싱할 수 있기 때문입니다.

### `agent-dev` 소유인데 `agent-admin`이 왜 실행 가능한가?

```text
monitor.sh = agent-dev:agent-core 750
agent-admin ∈ agent-core
```

따라서 owner는 작성·관리하고, cron executor는 group `r-x`로 실행하며, `agent-test`는 접근할 수 없습니다.

### 로그 회전을 왜 monitor.sh에서 분리했는가?

```text
monitor.sh = 상태 수집/기록
logrotate  = 로그 생명주기
```

책임을 분리해 각각 독립적으로 테스트하고 운영할 수 있기 때문입니다.

---

## 3. 평가 항목 3 — 보안·권한·운영 원리

### SSH 포트 변경

22번 자동 스캔 노이즈를 줄이는 효과가 있지만 **강한 인증을 대체하지는 않습니다.** 미션 요구사항의 일부로 설명하고 과장하지 않습니다.

### Root 원격 로그인 차단

Root 계정 침해는 영향 범위가 최대이므로 일반 사용자 로그인 후 필요한 작업만 sudo하는 편이 최소 권한과 추적성에 유리합니다.

### 왜 `agent-core`인가?

```text
api_keys = 인증 관련 민감 자원
log      = 운영 정보 및 기록
```

QA 역할의 `agent-test`에게 불필요한 접근을 주지 않습니다.

### WARNING vs exit 1

```text
process/port 실패 = 서비스 Health 자체 실패 → exit 1
firewall/resource = 위험 신호지만 상태 수집 가능 → WARNING
```

### `>`와 `>>`

```text
>  = 덮어쓰기
>> = 기존 로그 뒤에 누적
```

시간 흐름을 보존해야 하므로 `>>`를 사용합니다.

---

## 4. 평가 항목 4 — 응용·장애 대응

### Nginx로 바뀐다면

```text
process pattern
service port
운영 로그/상태 항목
threshold
```

을 서비스 특성에 맞춰 바꿉니다.

### 프로세스는 있는데 포트가 없다면

```text
1. 실제 PID/명령
2. Agent Boot 출력/로그
3. AGENT_PORT
4. ss LISTEN
5. 다른 프로세스의 포트 점유
6. bind address
7. key/권한/env 오류
```

순서로 확인합니다.

### 로그 급증·디스크 부족

단기:

```text
현재 디스크 사용률
증가 원인
회전 상태
필요 공간 확보
```

중기:

```text
로그 폭증 원인 수정
회전/보존 정책 조정
모니터링/알림 추가
7일 압축·30일 삭제 보너스 적용 검토
```

원인 확인 없이 로그를 무조건 삭제하지 않습니다.

---

## 5. 평가 답변 공식

각 질문은 네 문장으로 정리합니다.

```text
1. 무엇을 했는가 — WHAT
2. 왜 했는가 — WHY
3. 어떻게 구현했는가 — HOW
4. 무엇으로 검증했는가 — PROOF
```

마지막 `PROOF`에는 실제 명령 출력 또는 evidence를 연결합니다.

---

## 6. 검증 도구 역할

```text
verify.sh          = 현재 설정·상태 확인
acceptance-test.sh = 실제 기능·장애·cron 관찰
```

`verify.sh` 단독 PASS를 평가 전체 PASS로 설명하지 않습니다.

---

## 7. 현재 상태

```text
평가 설명 문서       IMPLEMENTED
SSH/UFW 실제 상태    TESTED / evidence pending
IAM/ACL runtime      NEEDS-RUNTIME
Agent runtime        NEEDS-RUNTIME
monitor 격리 fixture TESTED / target NEEDS-RUNTIME
cron/logrotate       NEEDS-RUNTIME
acceptance test      NEEDS-RUNTIME
사용자 구두 검증     BLOCKED (runtime 선행)
```

---

## 8. 이번 단계 기억하기

> **WHAT → WHY → HOW → PROOF 순서로 실제 결과를 설명한다.**

핵심어:

```text
WHAT · WHY · HOW · PROOF
```

---

## 이동

- [이전: 11. 수행 내역과 증빙](./11-execution-evidence.md)
- [다음: 13. 재현 시험](./13-reproducibility-test.md)
- [전체 목차](./README.md)
