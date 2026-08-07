# 15. 보너스 과제 — 통과에서 고도화로

> **기억 문장:** 필수 미션이 끝나면 데이터를 요약하고 로그의 생명주기까지 안전하게 관리한다.

보너스는 원본 B1-1 미션의 선택 과제를 그대로 유지하며 실제 Bash 코드로 구현합니다.

---

## 1. 원본 보너스

### Bonus 1

```text
report.sh
CPU/MEM/DISK 평균·최대·최소
샘플 수
선택적으로 시작/종료 시간 구간 분석
```

### Bonus 2

```text
/var/log/agent-app/*.log 중 7일 이상 경과
→ gzip 압축
→ /var/log/monitor/agent-app/archive/ 이동
→ archive/*.gz 중 30일 이상 경과 파일 삭제
```

권장 예외 처리:

```text
디렉터리 미존재
권한 부족
대상 파일 0개
기타 처리 오류
```

저장소 구현:

```text
scripts/report.sh
scripts/archive-logs.sh
```

---

## 2. `report.sh`

기본 실행:

```bash
bash scripts/report.sh
```

테스트 로그 지정:

```bash
bash scripts/report.sh --log /tmp/b1-1-monitor-fixture.log
```

시간 구간:

```bash
bash scripts/report.sh \
  --start '2026-08-07 09:00:00' \
  --end '2026-08-07 18:00:00'
```

출력 구조:

```text
samples=<n>
CPU  avg=... min=... max=...
MEM  avg=... min=... max=...
DISK avg=... min=... max=...
```

최소·최대 발생 시각도 함께 출력합니다.

시작·종료 시각은 모양만 보지 않고 UTC 기준 GNU `date`로 실제 달력·시각 유효성을 검사하므로 `2026-02-30` 같은 값은 `exit 2`로 거부합니다.

---

## 3. `report.sh` fixture 검증

```bash
(
set -euo pipefail
REPORT_FIXTURE_ROOT="$(mktemp -d /tmp/b1-1-report-fixture.XXXXXX)"
trap 'rm -rf -- "$REPORT_FIXTURE_ROOT"' EXIT
REPORT_FIXTURE_LOG="$REPORT_FIXTURE_ROOT/monitor.log"

cat > "$REPORT_FIXTURE_LOG" <<'EOF'
[2026-08-07 10:00:00] PID:100 CPU:10.00% MEM:20.00% DISK_USED:30%
[2026-08-07 11:00:00] PID:100 CPU:20.00% MEM:30.00% DISK_USED:40%
[2026-08-07 12:00:00] PID:100 CPU:30.00% MEM:40.00% DISK_USED:50%
EOF

bash scripts/report.sh --log "$REPORT_FIXTURE_LOG"
)
```

검산:

```text
samples = 3
CPU avg  = 20
MEM avg  = 30
DISK avg = 40
```

실제 실행 전에는 이 예상값을 증빙으로 사용하지 않습니다.

---

## 4. 시간 기반 로그 보존

기본 경로:

```text
LOG_DIR     = /var/log/agent-app
ARCHIVE_DIR = /var/log/monitor/agent-app/archive
```

먼저 Dry Run:

```bash
sudo DRY_RUN=1 bash scripts/archive-logs.sh
```

실제 변경은 대상이 정확한지 확인한 후에만:

```bash
sudo bash scripts/archive-logs.sh
```

---

## 5. 보완된 안전장치

현재 `archive-logs.sh`는 다음을 명시적으로 처리합니다.

```text
필수 명령 존재 확인
보존 일수는 overflow를 막는 1~36500 범위 정수만 허용
DRY_RUN 값 검증
LOG_DIR 존재 확인
LOG_DIR read/traverse 권한 확인
실제 실행 시 LOG_DIR/ARCHIVE_DIR write 권한 확인
find 자체 실패를 종료 코드로 검출
일반 파일·dangling symlink를 포함한 동일 archive 대상 덮어쓰기 거부
gzip 실패 검출
압축 후 `mv -n` no-clobber 또는 이동 실패 시 원본 복원 시도
rm 실패 검출
대상 파일 0개면 정상 안내
오류가 있으면 최종 비정상 종료
```

기존의 process substitution 방식처럼 `find` 오류가 바깥 스크립트에서 숨겨질 수 있는 구조를 피하고, 임시 목록 파일에 `find` 결과를 기록한 뒤 성공 여부를 직접 확인합니다.

---

## 6. 안전한 archive fixture

실제 `/var/log` 시간을 조작하지 않습니다.

```bash
(
set -euo pipefail
ARCHIVE_FIXTURE_ROOT="$(mktemp -d /tmp/b1-1-archive-fixture.XXXXXX)"
trap 'rm -rf -- "$ARCHIVE_FIXTURE_ROOT"' EXIT
FIXTURE_LOG_DIR="$ARCHIVE_FIXTURE_ROOT/logs"
FIXTURE_ARCHIVE_DIR="$ARCHIVE_FIXTURE_ROOT/archive"
mkdir "$FIXTURE_LOG_DIR" "$FIXTURE_ARCHIVE_DIR"
printf 'old\n' > "$FIXTURE_LOG_DIR/old file.log"
printf 'new\n' > "$FIXTURE_LOG_DIR/new.log"
touch -d '8 days ago' "$FIXTURE_LOG_DIR/old file.log"

AGENT_LOG_DIR="$FIXTURE_LOG_DIR" \
AGENT_ARCHIVE_DIR="$FIXTURE_ARCHIVE_DIR" \
DRY_RUN=1 \
bash scripts/archive-logs.sh

AGENT_LOG_DIR="$FIXTURE_LOG_DIR" \
AGENT_ARCHIVE_DIR="$FIXTURE_ARCHIVE_DIR" \
bash scripts/archive-logs.sh

test -f "$FIXTURE_ARCHIVE_DIR/old file.log.gz"
test -f "$FIXTURE_LOG_DIR/new.log"
)
```

목표:

```text
new.log 유지
old.log → old.log.gz → archive 이동
```

---

## 7. 30일 삭제 fixture

```bash
(
set -euo pipefail
DELETE_FIXTURE_ROOT="$(mktemp -d /tmp/b1-1-delete-fixture.XXXXXX)"
trap 'rm -rf -- "$DELETE_FIXTURE_ROOT"' EXIT
FIXTURE_LOG_DIR="$DELETE_FIXTURE_ROOT/logs"
FIXTURE_ARCHIVE_DIR="$DELETE_FIXTURE_ROOT/archive"
mkdir "$FIXTURE_LOG_DIR" "$FIXTURE_ARCHIVE_DIR"
printf 'expired\n' | gzip -n > "$FIXTURE_ARCHIVE_DIR/old.log.gz"
touch -d '31 days ago' "$FIXTURE_ARCHIVE_DIR/old.log.gz"

AGENT_LOG_DIR="$FIXTURE_LOG_DIR" \
AGENT_ARCHIVE_DIR="$FIXTURE_ARCHIVE_DIR" \
DRY_RUN=1 \
bash scripts/archive-logs.sh

AGENT_LOG_DIR="$FIXTURE_LOG_DIR" \
AGENT_ARCHIVE_DIR="$FIXTURE_ARCHIVE_DIR" \
bash scripts/archive-logs.sh

test ! -e "$FIXTURE_ARCHIVE_DIR/old.log.gz"
)
```

---

## 8. 필수 미션과 분리

```text
01~14 필수 미션 검증
        ↓
15 Bonus 구현·검증
        ↓
운영 고도화
```

보너스 실패가 필수 SSH/UFW/Agent/monitor 구성을 임의로 변경하게 만들지 않습니다.

---

## 9. 현재 상태

```text
report.sh               TESTED (격리 fixture) / 실제 monitor.log NEEDS-RUNTIME
시간 구간 분석           TESTED (격리 fixture)
archive-logs.sh          TESTED (격리 fixture) + 오류처리 보완
7일 압축/이동            TESTED (격리 fixture)
30일 삭제                TESTED (격리 fixture)
권한/find 실패 처리       TESTED (격리 fixture)
보너스 evidence           TODO (actual files 0)
```

---

## 10. 이번 단계 기억하기

### 한 문장

> **필수 미션이 끝나면 데이터를 요약하고, 오래된 로그는 압축·보관·삭제하되 실패를 숨기지 않는다.**

### 핵심어 3개

```text
REPORT · ARCHIVE · RETENTION
```

---

## 이동

- [이전: 14. 최종 검수와 제출](./14-final-review-submission.md)
- [전체 목차](./README.md)
