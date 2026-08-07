# 15. 보너스 과제 — 통과에서 고도화로

> **기억 문장:** 필수 미션이 끝나면 데이터를 요약하고 로그의 생명주기까지 관리한다.

보너스는 제거하지 않습니다. 원본 B1-1 미션에 포함된 선택 과제를 실제 Bash 코드로 구현하여 **필수 미션 → 운영 고도화**를 연결합니다.

---

## 1. 목표

원본 보너스는 두 가지입니다.

```text
Bonus 1
report.sh로 monitor.log 통계 요약

Bonus 2
7일 경과 로그 압축·아카이브
30일 경과 아카이브 삭제
```

저장소 구현:

```text
scripts/report.sh
scripts/archive-logs.sh
```

---

# Bonus 1 — `report.sh`

## 2. 요구사항

`monitor.log`를 분석해 다음을 출력합니다.

```text
CPU  평균 / 최소 / 최대
MEM  평균 / 최소 / 최대
DISK 평균 / 최소 / 최대
샘플 수
```

이 저장소에서는 학습 효과를 위해 다음도 함께 구현합니다.

```text
최소값 발생 시각
최대값 발생 시각
선택 시간 구간 필터
```

이는 원본의 선택 시간 구간 분석 요구와 연결됩니다.

---

## 3. 기본 실행

실제 운영 로그를 분석할 때:

```bash
bash scripts/report.sh
```

기본 로그 경로:

```text
/var/log/agent-app/monitor.log
```

다른 테스트 파일을 분석하려면:

```bash
bash scripts/report.sh --log /tmp/monitor-test.log
```

---

## 4. 시간 구간 분석

시작 시각만:

```bash
bash scripts/report.sh \
  --start '2026-08-07 09:00:00'
```

시작·종료 시각:

```bash
bash scripts/report.sh \
  --start '2026-08-07 09:00:00' \
  --end '2026-08-07 18:00:00'
```

지원 형식:

```text
YYYY-MM-DD HH:MM:SS
```

로그 자체가 같은 정렬 가능한 날짜 형식을 사용하므로 해당 구간의 샘플만 통계에 포함합니다.

---

## 5. 예상 출력 구조

실제 값은 로그에 따라 달라집니다.

형태:

```text
samples=<개수>
CPU  avg=<값>% min=<값>% (<시각>) max=<값>% (<시각>)
MEM  avg=<값>% min=<값>% (<시각>) max=<값>% (<시각>)
DISK avg=<값>% min=<값>% (<시각>) max=<값>% (<시각>)
```

실제 로그를 실행하기 전에는 임의의 수치를 증빙으로 사용하지 않습니다.

---

## 6. report.sh 예외 처리

다음 상황을 오류로 처리합니다.

```text
로그 파일을 읽을 수 없음
잘못된 옵션
잘못된 날짜 형식
시작 시각 > 종료 시각
조건에 맞는 샘플 없음
```

도움말:

```bash
bash scripts/report.sh --help
```

---

## 7. report.sh 안전 테스트

운영 로그를 기다리지 않고 작은 fixture를 만들어 통계를 검증할 수 있습니다.

예:

```bash
cat > /tmp/b1-1-monitor-fixture.log <<'EOF'
[2026-08-07 10:00:00] PID:100 CPU:10.00% MEM:20.00% DISK_USED:30%
[2026-08-07 11:00:00] PID:100 CPU:20.00% MEM:30.00% DISK_USED:40%
[2026-08-07 12:00:00] PID:100 CPU:30.00% MEM:40.00% DISK_USED:50%
EOF

bash scripts/report.sh --log /tmp/b1-1-monitor-fixture.log
```

검산 가능한 결과:

```text
samples = 3
CPU 평균  = 20
MEM 평균  = 30
DISK 평균 = 40
```

최소/최대는 각각 첫 번째와 세 번째 샘플이 되어야 합니다.

fixture는 테스트 후 삭제합니다.

```bash
rm -f /tmp/b1-1-monitor-fixture.log
```

---

# Bonus 2 — 시간 기반 로그 보존

## 8. 요구사항

원본 미션의 보너스 정책:

```text
/var/log/agent-app/*.log 중 7일 이상 경과
    ↓
압축
    ↓
/var/log/monitor/agent-app/archive/ 이동
    ↓
archive/*.gz 중 30일 이상 경과
    ↓
삭제
```

저장소 구현:

```text
scripts/archive-logs.sh
```

---

## 9. 기본 경로

```text
LOG_DIR     = /var/log/agent-app
ARCHIVE_DIR = /var/log/monitor/agent-app/archive
```

환경변수로 테스트 경로를 바꿀 수 있습니다.

```bash
AGENT_LOG_DIR=/tmp/b1-1-logs \
AGENT_ARCHIVE_DIR=/tmp/b1-1-archive \
bash scripts/archive-logs.sh
```

---

## 10. 먼저 DRY RUN

로그 삭제·이동은 파괴적 작업이므로 먼저 **Dry Run(실제 변경 없이 대상만 출력)**을 사용합니다.

```bash
sudo DRY_RUN=1 bash scripts/archive-logs.sh
```

출력에는 수행 예정 명령만 보이고 실제 파일은 바뀌지 않아야 합니다.

### 왜 먼저 Dry Run인가

```text
대상 파일이 맞는지 확인
→ 실제 압축·이동·삭제
```

순서로 수행하면 잘못된 파일 삭제 가능성을 줄일 수 있습니다.

---

## 11. 실제 실행

Dry Run 결과가 정확할 때:

```bash
sudo bash scripts/archive-logs.sh
```

스크립트는 다음을 수행합니다.

```text
7일 이상 경과 .log 찾기
→ gzip -n 압축
→ archive 디렉터리 이동
→ 30일 이상 경과 .gz 삭제
→ 처리 건수 요약
```

`gzip -n`은 gzip 헤더에 원본 파일명·시간 정보를 넣지 않아 재현 가능한 압축 결과를 만드는 데 도움이 됩니다.

---

## 12. 예외 처리와 안전장치

구현된 보호 장치:

```text
LOG_DIR가 없으면 중단
find/gzip 없으면 중단
보존 일수 값 검증
DRY_RUN 값 검증
archive 대상과 같은 이름이 이미 있으면 덮어쓰지 않고 오류
파일명을 NUL 구분(-print0)으로 처리
각 실패 건을 기록
오류가 있으면 최종 exit 1
```

공백이 들어간 파일명도 안전하게 다루기 위해 `find ... -print0`을 사용합니다.

---

## 13. 왜 현재 `monitor.log`가 보통 압축되지 않는가

원본 대상은 `/var/log/agent-app/*.log` 중 7일 이상 경과 파일입니다.

`monitor.log`가 cron으로 매분 갱신되고 있다면 수정 시각이 계속 최신으로 바뀌므로 정상 운영 중에는 7일 경과 조건을 만족하지 않습니다.

따라서 일반적으로 **오래되어 더 이상 갱신되지 않는 `.log` 파일**이 보존 정책의 대상이 됩니다.

---

## 14. 안전한 fixture 테스트

실제 `/var/log` 파일의 시간을 조작하지 않고 `/tmp`에서 시험합니다.

```bash
rm -rf /tmp/b1-1-logs /tmp/b1-1-archive
mkdir -p /tmp/b1-1-logs /tmp/b1-1-archive

printf 'old log\n' > /tmp/b1-1-logs/old.log
printf 'new log\n' > /tmp/b1-1-logs/new.log

touch -d '8 days ago' /tmp/b1-1-logs/old.log
```

먼저 Dry Run:

```bash
AGENT_LOG_DIR=/tmp/b1-1-logs \
AGENT_ARCHIVE_DIR=/tmp/b1-1-archive \
DRY_RUN=1 \
bash scripts/archive-logs.sh
```

그 다음 실제 fixture 실행:

```bash
AGENT_LOG_DIR=/tmp/b1-1-logs \
AGENT_ARCHIVE_DIR=/tmp/b1-1-archive \
bash scripts/archive-logs.sh
```

확인:

```bash
find /tmp/b1-1-logs /tmp/b1-1-archive -maxdepth 1 -type f -print
```

목표:

```text
new.log는 원래 위치 유지
old.log는 old.log.gz로 압축되어 archive로 이동
```

---

## 15. 30일 삭제 테스트

fixture archive 파일을 만든 뒤:

```bash
touch -d '31 days ago' /tmp/b1-1-archive/old.log.gz
```

다시 Dry Run:

```bash
AGENT_LOG_DIR=/tmp/b1-1-logs \
AGENT_ARCHIVE_DIR=/tmp/b1-1-archive \
DRY_RUN=1 \
bash scripts/archive-logs.sh
```

삭제 대상이 정확한지 확인한 후 실제 fixture 실행합니다.

테스트 완료 후:

```bash
rm -rf /tmp/b1-1-logs /tmp/b1-1-archive
```

---

## 16. 필수 미션과 보너스를 분리한다

보너스가 실패했다고 필수 B1-1 결과를 깨뜨리면 안 됩니다.

```text
01~14 필수 PASS
       ↓
15 Bonus
       ↓
고도화
```

따라서 보너스 파일은 기존 `monitor.sh`, SSH, UFW, cron 필수 구성을 임의로 변경하지 않습니다.

---

## 17. 검증과 요구사항 추적

보너스 추적 항목:

| ID | 요구사항 | 저장소 구현 | 실제 테스트 |
|---|---|---|---|
| `BONUS-01` | report.sh 평균·최대·최소·샘플 수 | `scripts/report.sh` 구현 | fixture/실로그 검증 전 |
| `BONUS-02` | 선택 시간 구간 분석 | `scripts/report.sh` 구현 | 검증 전 |
| `BONUS-03` | 7일 경과 로그 압축·아카이브 | `scripts/archive-logs.sh` 구현 | fixture 검증 전 |
| `BONUS-04` | 30일 경과 archive 삭제 | `scripts/archive-logs.sh` 구현 | fixture 검증 전 |
| `BONUS-05` | 예외 처리 | 두 스크립트에 구현 | 검증 전 |

현재 보너스는 **코드 IMPLEMENTED / 실제 fixture와 운영 로그 TEST 전**입니다.

---

## 18. 증빙 후보

```text
evidence/15-bonus/
├── report-fixture.txt
├── report-real-log.txt
├── archive-dry-run.txt
├── archive-fixture-before-after.txt
└── archive-delete-test.txt
```

현재 저장소의 기본 evidence 구조에 15번 폴더가 없다면 보너스 수행 시 추가합니다.

---

## 19. 이번 단계 기억하기

### 한 문장

> **필수 미션이 끝나면 데이터를 요약하고 로그의 생명주기까지 관리한다.**

### 핵심어 3개

```text
REPORT · ARCHIVE · RETENTION
```

### 핵심 명령 3개

```bash
bash scripts/report.sh
sudo DRY_RUN=1 bash scripts/archive-logs.sh
sudo bash scripts/archive-logs.sh
```

### 내가 설명할 수 있어야 할 것

> 왜 오래된 로그를 무조건 삭제하지 않고 압축·아카이브 후 일정 기간이 지나서 삭제하는가?

답의 핵심은 **장애 분석과 추적에 필요한 이력을 일정 기간 보존하면서도 디스크 사용량이 계속 증가하는 것을 막기 위해서**입니다.

---

## 20. 완료 체크

- [x] `scripts/report.sh` 구현
- [x] CPU/MEM/DISK 평균 구현
- [x] CPU/MEM/DISK 최소·최대 구현
- [x] 최소·최대 발생 시각 구현
- [x] 샘플 수 구현
- [x] 선택 시간 구간 구현
- [x] `scripts/archive-logs.sh` 구현
- [x] 7일 경과 압축·이동 구현
- [x] 30일 경과 archive 삭제 구현
- [x] Dry Run 구현
- [x] 기본 예외 처리 구현
- [ ] Bash 구문/정적 검증
- [ ] report fixture 테스트
- [ ] archive fixture 테스트
- [ ] 실제 monitor.log 통계 검증
- [ ] 보너스 증빙 정리

현재 15단계는 **코드 IMPLEMENTED / 실제 TEST 전**입니다.

---

## 이동

- [이전: 14. 최종 검수와 제출](./14-final-review-submission.md)
- [전체 목차](./README.md)
