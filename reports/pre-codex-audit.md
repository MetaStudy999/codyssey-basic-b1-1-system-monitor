# B1-1 Pre-Codex Audit

## 목적

Codex 독립 검토 전에 저장소를 원본 `b1-1-mission.md`와 `b1-1-evaluation.md` 기준으로 다시 점검하고, 구현자가 스스로 발견 가능한 P0/P1 문제를 먼저 제거했습니다.

작업 브랜치:

```text
fix/b1-1-pre-codex-audit
```

## Source of Truth

1. `b1-1-mission.md` / `b1-1-mission.pdf`
2. `b1-1-evaluation.md`
3. 실제 `scripts/`, `config/`
4. `docs/reference/requirements-evidence-map.md`
5. `docs/00~15`
6. `tests/`, `reports/`, `evidence/`

원본 파일은 수정하지 않았습니다.

---

## P0 발견 및 수정

### P0-01 — Agent 실행 파일 가정 오류

문제:

기존 06장은 Python `agent_app.py`를 중심으로 실행 절차를 설계했으나, 원본 미션 데이터 설명에는:

```text
agent-app-linux-x86
agent-app-linux-arm64
```

가 제공 파일로 명시되어 있습니다.

수정:

```text
uname -m
→ unzip -l agent-app.zip
→ 아키텍처용 제공 실행 파일 선택
→ 일반 사용자 실행
```

으로 변경했습니다.

관련 파일:

```text
docs/06-agent-setup.md
scripts/preflight.sh
scripts/monitor.sh
scripts/verify.sh
config/agent.env.example
```

### P0-02 — Agent 배치 시 ACL 파괴 가능성

문제:

기존 문서의:

```bash
chown -R agent-admin:agent-common /home/agent-admin/agent-app
```

은 `api_keys`의 `agent-core ONLY` 정책을 깨뜨릴 수 있었습니다.

수정:

```text
재귀 chown 금지
제공 Agent 실행 파일만 install
배치 후 upload_files/api_keys/log 경계 재검증
```

으로 변경했습니다.

### P0-03 — 로그 append 실패가 성공으로 끝날 가능성

문제:

기존 `monitor.sh`는 로그 디렉터리의 쓰기 가능 여부만 확인하고, 기존 `monitor.log` 파일 자체 또는 실제 `>>` append 실패를 최종 exit code에 반영하지 못할 수 있었습니다.

수정:

```text
기존 monitor.log가 있으면 -w 검사
실제 printf >> LOG_FILE 실패 검사
실패 시 exit 2
```

로 보완했습니다.

### P0-04 — `pgrep -f` false positive 가능성

자체 격리 테스트에서 process failure용 문자열이 부모 테스트 command line에 포함되면 `pgrep -f`가 잘못된 프로세스를 찾을 수 있음을 확인했습니다.

수정:

```text
AGENT_PROCESS_PATTERN
→ regex 특수문자 escape
→ 실행 파일/token 경계 regex 생성
→ pgrep -f로 경계 매칭
```

으로 보완했습니다.

---

## P1 발견 및 수정

### P1-01 — `verify.sh` 역할 과대평가

기존 `verify.sh`는 현재 상태만 확인하면서도 최종 검증 PASS처럼 보일 수 있었습니다.

수정:

```text
verify.sh          = read-only current-state verification
acceptance-test.sh = runtime acceptance
```

로 분리했습니다.

`verify.sh` 성공 후에도 다음이 남았음을 명시합니다.

```text
Boot/READY evidence
failure injection
cron automatic growth
runtime acceptance
evidence review
```

### P1-02 — logrotate 10개 파일 해석

원본:

```text
최대 10MB / 10개 파일 유지
```

기존:

```text
rotate 10
```

은 logrotate 의미상 `current 1 + rotated 10 = 최대 11개`가 될 수 있습니다.

수정:

```text
size 10M
rotate 9
current 1 + rotated 9 = maximum 10 files
```

로 엄격하게 해석했습니다.

또한 `agent-core R/W` 정책과 일치하도록:

```text
create 0660 agent-admin agent-core
```

로 변경했습니다.

### P1-03 — 테스트 정의/결과 불일치

기존:

```text
test-cases: T-001~T-034
test-results: 사실상 T-001 한 행
```

수정:

```text
test-cases: T-001~T-040
test-results: T-001~T-040 1:1 ledger
```

로 동기화했습니다.

### P1-04 — 실제 Troubleshooting 보고서 비어 있음

실제 발생했던 SSH/systemd/UFW 이력 3건을:

```text
TS-001 /run/sshd RuntimeDirectory
TS-002 ssh.socket / daemon-reload / generator
TS-003 UFW 15034 재확인
```

으로 `reports/troubleshooting-report.md`에 기록했습니다.

### P1-05 — 미검증 정적검사 완료 주장

문서에 실제 사용자 Ubuntu 증빙 없이 `bash -n`을 이미 통과한 것처럼 읽히는 표현이 있었습니다.

수정:

```text
보완 브랜치에서 수행한 자체 정적검증
!=
사용자 Ubuntu 최종 증빙
```

으로 분리했습니다.

### P1-06 — Bonus archive 오류 누락 가능성

`archive-logs.sh`에서 process substitution 안의 `find` 실패가 바깥 상태로 명확히 드러나지 않을 수 있었습니다.

수정:

```text
read/traverse/write 권한 사전검사
find 결과를 temp list에 기록하고 exit 직접 검사
gzip/mv/rm 오류 확인
동일 target overwrite 거부
mv 실패 시 원본 복원 시도
대상 0개 정상 안내
```

를 추가했습니다.

---

## 자체 정적 검증

보완 과정의 격리 Linux 도구 환경에서 다음 작성본에 대해 `bash -n`을 실행했습니다.

```text
preflight.sh       PASS
monitor.sh         PASS
verify.sh          PASS
acceptance-test.sh PASS
archive-logs.sh    PASS
report.sh          PASS
```

이 결과는 **사용자 Ubuntu 24.04.4 미션 환경의 runtime PASS가 아닙니다.** 문법/격리 로직 검토 근거일 뿐입니다.

---

## 격리 로직 테스트 결과

### report fixture

3개 샘플:

```text
CPU 10 / 20 / 30 → avg 20
MEM 20 / 30 / 40 → avg 30
DISK 30 / 40 / 50 → avg 40
```

실제 출력이 기대값과 일치했습니다.

시간 구간 `11:00~12:00`도 2개 샘플만 선택되어:

```text
CPU avg 25
MEM avg 35
DISK avg 45
```

로 확인했습니다.

### archive fixture

8일 된 `old.log`와 새 `new.log`를 사용했습니다.

결과:

```text
old.log → archive/old.log.gz
new.log → 원래 위치 유지
```

이후 archive 파일 시간을 31일 전으로 설정한 테스트에서 해당 `.gz`만 삭제됨을 확인했습니다.

### monitor process failure

false positive 보완 후 존재하지 않는 process pattern 테스트:

```text
[ERROR] Agent process not found
exit 1
```

확인.

### monitor port failure

짧은 `sleep` 프로세스를 존재하게 하고 미사용 포트를 지정:

```text
[ERROR] Agent port is not LISTEN
exit 1
```

확인.

### monitor 정상/threshold

임시 TCP listener를 사용하고 threshold를 `-1`로 낮춘 격리 테스트에서:

```text
CPU WARNING
MEM WARNING
DISK WARNING
로그 append
exit 0
```

확인.

### monitor.log 쓰기 불가

비권한 사용자 + read-only `monitor.log` fixture에서:

```text
[ERROR] log file exists but is not writable
exit 2
```

확인.

---

## 아직 실제 Ubuntu에서 필요한 검증

다음은 이 Audit에서 완료했다고 주장하지 않습니다.

```text
agent-admin/dev/test 실제 생성
그룹 멤버십
ACL 실제 허용/차단
agent-app.zip 실제 내부 목록
실제 제공 Agent 실행
Boot 5 [OK]
Agent READY
0.0.0.0:15034
monitor.sh 실제 배치 owner/group/750
사용자 Ubuntu의 bash -n
monitor 실제 runtime
cron 자동 증가
logrotate 실제 설치/dry-run/force
외부 SSH 20022 새 접속
evidence 실제 파일 생성
재부팅/깨끗한 Ubuntu 재현
사용자 구두 평가
```

---

## Codex에게 확인받아야 할 핵심

Codex는 특히 다음을 독립적으로 확인해야 합니다.

```text
1. 원본 미션/평가 누락 여부
2. 아키텍처별 제공 Agent 해석이 원본과 일치하는가
3. monitor.sh false positive/exit code/logging semantics
4. strict max-10-file logrotate 해석의 타당성
5. acceptance-test.sh의 안전성 및 false PASS 가능성
6. ACL 설계와 Agent 배치가 충돌하지 않는가
7. requirements-evidence-map과 실제 파일 일치
8. TODO/IMPLEMENTED/TESTED 상태 과대 표시 여부
9. secret/민감정보 노출 위험
10. 실제 Ubuntu 없이 검증할 수 없는 항목이 명확히 분리됐는가
```

## 현재 판단

```text
Codex 투입 준비도: 이전보다 개선됨
P0 known issues: 수정 완료
P1 known issues: 수정 완료/문서 동기화
실제 mission runtime: 아직 미완료
FINAL PASS: 아님
```

Codex는 이 문서의 결론을 그대로 신뢰하지 말고 원본 미션과 실제 코드에서 다시 독립 감사해야 합니다.
