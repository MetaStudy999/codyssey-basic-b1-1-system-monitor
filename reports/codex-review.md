# B1-1 Codex Independent Review

## 1. Review Scope

이 문서는 GitHub PR #5 `fix: B1-1 Codex 전 감사 보완`을 ChatGPT의 사전 판정과 독립적으로 다시 감사한 결과다.

| 항목 | 감사 기준 |
|---|---|
| 감사일 | 2026-08-07 (Asia/Seoul) |
| 브랜치 | `fix/b1-1-pre-codex-audit` |
| 원격 PR HEAD | `96c05e663958d5a7544cdcb9726ae6882859d959` |
| 비교 기준 | `main`, PR HEAD, Codex 로컬 working tree를 각각 구분 |
| Source of Truth | `b1-1-mission.md` → PDF → `b1-1-evaluation.md` → requirement map → 구현/테스트/보고서/evidence |
| 실행 컨텍스트 | GitHub 원격 HEAD, Codex 격리 namespace, target-reported Ubuntu 기록을 서로 대체하지 않음 |

직접 확인한 범위는 PR 메타데이터와 diff, 원본 미션·평가 전 문항, ZIP 목록/ELF 아키텍처, Bash 스크립트, 설정, CI, T-001~T-040, 상태표, 보고서, 실제 evidence 파일 수와 secret 후보를 포함한다.

다음 원본은 수정하지 않았다.

- `b1-1-mission.md`
- `b1-1-evaluation.md`
- `b1-1-mission.pdf`
- `agent-app.zip`

Codex 수정은 아직 커밋하거나 push하지 않은 working-tree 변경이다. 따라서 원격 PR HEAD의 기존 GitHub Actions 성공은 이 보고서의 로컬 수정본을 검증한 결과가 아니다.

## 2. Overall Result

| 판정 항목 | 결과 |
|---|---|
| 전체 판정 | **FINAL PASS 아님** |
| BLOCKER | 4건 발견: 3건 수정, 1건 미해결 |
| MAJOR | 12건 발견: 12건 수정 |
| MINOR | 5건 발견: 5건 수정 |
| IMPROVEMENT | 4건 제안 |
| 실제 evidence 파일 | **0개** |
| 최종 PASS 요구사항 | 0개 (`evidence` 연결 미완료) |
| Merge 권고 | **DO NOT MERGE** |

저장소 코드와 격리 fixture의 신뢰도는 크게 향상됐고 최신 트리에서 남은 코드 BLOCKER/MAJOR는 발견되지 않았다. 그러나 미션이 요구하는 실제 Ubuntu runtime, 원출력 evidence, 재현 시험과 사용자 인수가 남아 있다. 특히 `evidence/`에 실제 증적이 하나도 없으므로 제출 흐름은 완성되지 않았다.

## 3. BLOCKER

### B-01. Agent 프로세스와 LISTEN 소켓이 상호 연계되지 않음 — FIXED

- **Severity:** BLOCKER
- **파일/위치:** `scripts/monitor.sh` PR HEAD 128~143행, 수정본 139~190행·298~330행; `scripts/verify.sh` 수정본 151~213행·470~500행
- **문제:** PR HEAD는 `pgrep -f` 첫 PID와 별개로 “어떤 프로세스든” 해당 포트를 열면 정상으로 판정했다. 이름이 인자에만 있는 decoy, 자기/부모 shell, 동일 이름의 비-Agent 프로세스, 첫 번째 non-listener와 두 번째 실제 listener가 섞인 경우도 오판할 수 있었다.
- **왜 문제인가:** 미션은 제공 Agent 프로세스와 TCP 15034가 모두 정상이어야 하며 둘 중 하나 실패 시 `exit 1`을 요구한다. 무관한 listener를 Agent health로 인정하면 핵심 관제 자체가 실패한다.
- **Mission/Evaluation 근거:** `b1-1-mission.md` 188~193행, `b1-1-evaluation.md` 17행.
- **재현:** Agent 이름을 인자로 가진 `tail -f` decoy와 무관한 `0.0.0.0:15034` listener를 함께 실행하거나, 같은 basename 프로세스 두 개 중 listener를 두 번째로 실행한 뒤 구버전 monitor를 실행한다.
- **권장/최종 수정:** `/proc/<pid>/exe`, NUL 구분 cmdline, 동일 UID, 자기·조상 제외로 후보를 검증하고, 모든 일치 PID 중 실제 IPv4 wildcard listener 소유 PID를 선택하도록 수정했다. missing/decoy/multi-PID/port-branch fixtures를 추가했다.
- **최종 상태:** FIXED, 격리 회귀 PASS. 실제 target Agent는 NEEDS-RUNTIME.

### B-02. root acceptance의 예측 가능한 `/tmp` 출력과 광범위 정리 — FIXED

- **Severity:** BLOCKER
- **파일/위치:** `scripts/acceptance-test.sh` PR HEAD 94~132행·188~191행, 수정본 136~183행·345~379행
- **문제:** root 실행 테스트가 고정 `/tmp/b1-1-*` 파일에 redirection하고, 공유 가능한 `0777` 디렉터리를 만들며, 종료 시 고정 경로를 `rm -rf`했다.
- **왜 문제인가:** 다른 사용자가 먼저 symlink/경로를 준비하면 root 출력 덮어쓰기 또는 의도하지 않은 삭제로 이어질 수 있다. 테스트 스크립트가 대상 서버를 위험하게 만들면 안 된다.
- **Mission/Evaluation 근거:** `b1-1-mission.md` 274~276행의 Bash/최소 sudo 제약과 260~262행의 안전한 예외 처리 원칙.
- **재현:** 구버전 실행 전에 고정 출력 경로를 다른 파일로 향하는 symlink로 만들거나 고정 정리 경로를 선점한 뒤 root acceptance를 실행한다.
- **권장/최종 수정:** root 전용 `mktemp -d`, `0770` core 디렉터리, 실행별 suffix, allowlist 정리, signal/EXIT trap, 작은 probe만 삭제하도록 변경했다. skip-cron은 최종 PASS가 아니라 exit 2 `INCOMPLETE`가 된다.
- **최종 상태:** FIXED, Bash/ShellCheck와 fixture 검토 PASS.

### B-03. archive 충돌·산술 overflow·경쟁 조건의 원본 손실 가능성 — FIXED

- **Severity:** BLOCKER
- **파일/위치:** `scripts/archive-logs.sh` PR HEAD 24~27행·83~116행, 수정본 24~33행·47~64행·94~131행
- **문제:** 제한 없는 retention 정수가 Bash 산술에서 wrap될 수 있었고, dangling target은 `-e`에 잡히지 않았으며, 사전 검사 뒤 `mv`가 새 target을 덮어쓸 경쟁 구간이 있었다.
- **왜 문제인가:** Bonus 기능이라도 기존 로그나 archive를 덮어쓰거나 압축된 원본을 복구하지 못하면 사용자 정의상 데이터 손실 BLOCKER다.
- **Mission/Evaluation 근거:** `b1-1-mission.md` 244~262행, `b1-1-evaluation.md` 46행.
- **재현:** 매우 큰 retention 값, `archive/name.log.gz -> missing` dangling symlink, 또는 사전 검사와 이동 사이에 생성되는 target을 사용한다.
- **권장/최종 수정:** retention을 1~36500으로 제한하고, `-e || -L`, `mv -n`, 이동 결과 재확인, 실패 시 source 복원, archive 경로 타입 검증을 적용했다.
- **최종 상태:** FIXED. overflow/collision/dangling/non-directory/find/permission fixtures PASS.

### B-04. 필수 evidence가 실제로 0개 — OPEN

- **Severity:** BLOCKER
- **파일/위치:** `evidence/`, `reports/test-results.md` 52~60행, `reports/execution-report.md` 145~166행, `reports/final-checklist.md` 207~223행
- **문제:** `evidence/`에는 안내용 README와 0-byte `.gitkeep`만 있고 실제 명령 출력·캡처·로그가 하나도 없다. SSH/UFW의 `TESTED` 표시는 target-reported 기록일 뿐 Codex가 원출력을 독립 검증하지 못했다.
- **왜 문제인가:** 미션 최종 산출물은 SSH/UFW/IAM/ACL/Boot/READY/monitor/cron 로그 증가의 증빙을 명시적으로 요구한다. 문서와 예상 출력은 evidence가 아니다.
- **Mission/Evaluation 근거:** `b1-1-mission.md` 24~50행, `b1-1-evaluation.md` 61~65행.
- **재현:** `find evidence -type f ! -name README.md ! -name .gitkeep -print | wc -l` 결과가 `0`이다.
- **권장 수정:** target Ubuntu에서 실제 명령을 다시 실행하고 민감정보를 가린 원출력을 요구사항 ID와 T-ID별로 저장한 뒤 map/ledger/checklist에 정확한 파일명을 연결한다.
- **Codex 처리:** evidence를 조작하거나 예상 출력을 만들지 않았다.
- **최종 상태:** **OPEN**. 최종 merge를 막는 잔여 BLOCKER다.

## 4. MAJOR

### M-01. 제공 Agent 아키텍처·ZIP 경로와 Python fallback 불일치 — FIXED

- **Severity:** MAJOR
- **파일/위치:** `scripts/monitor.sh` 111~125행; `docs/06-agent-setup.md` 35~54행·90~126행·154~190행
- **문제:** 지원하지 않는 아키텍처에서 존재가 확인되지 않은 `agent_app.py`로 fallback하고, 일부 문서는 이를 기본 실행 대상으로 설명했다.
- **영향/근거:** ZIP에는 최상위 x86-64/aarch64 ELF 두 개가 있다. 잘못된 파일 가정은 Agent 실행과 평가 항목 1을 실패시킨다 (`b1-1-mission.md` 164~170행).
- **재현:** `unzip -Z1 agent-app.zip`과 `file`로 두 ELF를 확인하고, 구버전 `resolve_process_pattern`을 지원 외 `uname -m` 결과로 호출한다.
- **수정:** x86_64/amd64→x86, aarch64/arm64→arm64, 그 외 명시적 exit 2로 통일하고 ZIP 확인 후 `install`하는 문서로 동기화했다.

### M-02. `source` 기반 env 실행과 신뢰 경계·임계값 우회 — FIXED

- **Severity:** MAJOR
- **파일/위치:** `scripts/monitor.sh` PR HEAD 11~17행, 수정본 14~81행; `config/agent.env.example` 1~12행
- **문제:** 읽을 수 있는 env 파일을 shell code로 `source`했고 symlink, owner, writable mode, 미지원/중복 키를 검증하지 않았다. target env나 cron assignment가 미션 임계값 20/10/80을 바꿔도 검증이 통과할 수 있었다.
- **영향/근거:** cron 권한으로 임의 명령 실행 또는 경고 정책 무력화가 가능하다 (`b1-1-mission.md` 144~156행·210~216행).
- **재현:** env에 단순 명령, 중복 key, group-writable mode, symlink 또는 threshold 100을 넣고 구버전을 실행한다.
- **수정:** 실행하지 않는 allowlist parser, 중복/문법 검증, regular/non-symlink·root/current-EUID owner·no group/other write 검증을 적용했다. 배포 env에서는 threshold 키를 허용하지 않는다.

### M-03. 잘못된 입력·CPU/MEM/df 실패를 정상 값처럼 기록 — FIXED

- **Severity:** MAJOR
- **파일/위치:** `scripts/monitor.sh` PR HEAD 59~94행·150~180행, 수정본 93~105행·193~238행·261~377행
- **문제:** port/threshold 입력 검증이 없고, CPU delta 0·MemAvailable 누락·`df` 실패에서 0 또는 빈 값이 로그에 들어갈 수 있었다.
- **영향/근거:** 관제 데이터가 정상처럼 보이거나 malformed 로그가 생성되어 평가 항목 1·2를 실패시킨다 (`b1-1-mission.md` 200~224행).
- **재현:** `AGENT_PORT='15034|22'`, invalid threshold, 실패하는 fake `df`, 비정상 `/proc` snapshot을 사용한다.
- **수정:** port 1~65535, threshold -1~100 fixture 범위, percentage 0~100, CPU delta/MemAvailable/df 결과를 검증하고 설정·수집·append 실패를 exit 2로 분리했다.

### M-04. Boot·key·장애 branch acceptance oracle의 거짓 PASS — FIXED

- **Severity:** MAJOR
- **파일/위치:** `scripts/acceptance-test.sh` PR HEAD 64~70행·108~143행, 수정본 53~118행·278~304행·345~390행
- **문제:** `[1/5]` 중복 5줄도 Boot 성공이었고 READY 순서를 확인하지 않았다. key는 임의 한 줄/reference도 통과할 수 있었으며 process/port 실패는 exit code만 같으면 branch가 달라도 통과했다.
- **영향/근거:** 실제 Boot 1~5, 지정 key, process/port 실패 동작을 증명하지 못한다 (`b1-1-mission.md` 158~170행·188~193행).
- **재현:** `[1/5]` 5개 뒤 READY, 잘못된 한 줄 key, 죽은 sleep과 exit 1만 반환하는 monitor를 사용한다.
- **수정:** 정확한 순서·각 1회·READY 후행 validator, secret-safe canonical digest, live process 확인, branch별 stderr 확인을 추가했다. key 값은 출력하지 않는다.

### M-05. 그룹·ACL·파일 타입 검사가 최소권한 위반을 놓침 — FIXED

- **Severity:** MAJOR
- **파일/위치:** `scripts/verify.sh` 21~45행·87~138행·378~468행; `scripts/acceptance-test.sh` 199~312행
- **문제:** 필수 사용자 포함만 보고 추가 `agent-core` 구성원을 금지하지 않았고, default ACL·교차 사용자 R/W·부모 홈 effective traverse를 검증하지 않았다. 동일 metadata의 regular file도 필수 디렉터리로 PASS할 수 있었다.
- **영향/근거:** intruder가 key/log에 접근하거나 협업 파일을 다른 core/common 사용자가 수정하지 못해 최소권한과 R/W 요구를 동시에 위반한다 (`b1-1-mission.md` 104~140행).
- **재현:** `agent-core`에 추가 사용자를 넣거나 default ACL을 제거하거나, `upload_files`를 동일 owner/group/mode의 regular file로 바꾼다.
- **수정:** primary+supplementary 전체 멤버십 exact 비교, expected file type, named/default ACL, agent-test 차단, A가 만든 umask 077 파일을 B가 append하는 교차 사용자 probe를 추가했다.

### M-06. SSH 한 context만 검사하여 Match/Include root 재허용을 놓침 — FIXED

- **Severity:** MAJOR
- **파일/위치:** `scripts/verify.sh` 47~85행·336~359행; `.github/workflows/b1-1-static.yml` 51~113행
- **문제:** `addr=127.0.0.1` 하나의 `sshd -T -C`만 검사하면 특정 원격 Address/Host Match에서 root 로그인을 다시 허용해도 PASS한다. OpenSSH의 CRLF debug 출력과 `Keyword=value` 문법도 초기 보강을 우회했다.
- **영향/근거:** Root 원격 로그인 차단이라는 직접 보안 요구를 잘못 PASS한다 (`b1-1-mission.md` 78~90행, 평가 13·35행).
- **재현:** 기본 `PermitRootLogin no` 뒤 `Match User root Address 203.0.113.0/24`와 `PermitRootLogin=yes`를 둔다. loopback context는 no지만 해당 대역은 yes다.
- **수정:** `sshd -t`, root effective context와 함께 debug parse가 실제로 로드한 모든 Include 파일을 열어 모든 PermitRootLogin 지시어가 공백형/equals형 모두 정확히 `no`인지 확인한다. CRLF와 safe/unsafe Match fixtures를 추가했다.

### M-07. verify의 listener/UFW/log metadata가 무관한 상태를 PASS — FIXED

- **Severity:** MAJOR
- **파일/위치:** `scripts/verify.sh` 361~376행·470~515행
- **문제:** 포트만 보고 sshd/Agent PID 소유를 연결하지 않았고, UFW IPv4 규칙과 예상 외 규칙을 엄격히 분리하지 않았으며, 잘못된 monitor.log metadata를 WARN으로만 남겼다.
- **영향/근거:** 현재 상태 verifier가 보안·Agent·로그 요구를 과장한다 (`b1-1-evaluation.md` 13~20행).
- **재현:** 무관한 프로세스를 20022/15034에 bind하거나 monitor.log mode를 바꾸거나 예상 외 ALLOW IN rule을 둔다.
- **수정:** sshd/systemd 및 Agent PID 소유권, IPv4 exact UFW 정책, monitor.log regular file·owner/group/0660·ACL을 FAIL gate로 변경했다.

### M-08. cron 순서·중복·환경 override를 무시 — FIXED

- **Severity:** MAJOR
- **파일/위치:** `scripts/verify.sh` 224~265행·517~523행; `.github/workflows/b1-1-static.yml` 27~49행·106~113행; `docs/08-logging-cron.md` 93~119행
- **문제:** good PATH가 job 뒤에 있거나 중복돼도 grep predicate가 통과했고, crontab에 CPU/MEM/DISK threshold 100을 넣어도 exact job이 있으면 PASS했다.
- **영향/근거:** cron 실제 실행은 앞선 잘못된 환경을 사용해 mission threshold를 무력화할 수 있다 (`b1-1-mission.md` 210~216행·230~234행).
- **재현:** `PATH=/bad`, exact job, good PATH 순서 또는 exact SHELL/PATH 뒤 threshold override와 job을 둔다.
- **수정:** 안전한 unique SHELL/PATH, 선택적 빈 MAILTO, job보다 앞선 적용, exact job 1개, 그 밖의 환경 assignment 0개를 parser와 CI fixture에서 검증한다.

### M-09. logrotate target stanza·실제 10M 동작을 검증하지 않음 — FIXED

- **Severity:** MAJOR
- **파일/위치:** `scripts/verify.sh` 267~325행·524~532행; `.github/workflows/b1-1-static.yml` 115~142행
- **문제:** 서로 다른 stanza의 `size/rotate/create`를 조합해 PASS할 수 있었고, target에 `weekly` 같은 시간 지시어가 뒤따르면 10M 회전을 막아도 통과했다. 강제 회전만으로는 size 동작을 증명하지 못했다.
- **영향/근거:** 10MB/총 10개와 회전 후 core R/W 정책을 잘못 증명한다 (`b1-1-mission.md` 226~228행, 평가 20·29행).
- **재현:** target stanza에 `size 10M`과 `weekly`, 다른 stanza에 올바른 rotate/create를 둔 뒤 11MiB 파일을 non-force 실행한다.
- **수정:** target stanza 하나의 허용 directive를 exact parse하고 다른 지시어를 거부한다. 11MiB non-force 회전 후 11회 force하여 current+9=10과 mode 0660을 확인한다.

### M-10. Test ledger·상태·요구사항 traceability 불일치 — FIXED

- **Severity:** MAJOR
- **파일/위치:** `tests/test-cases.md` 1~98행; `reports/test-results.md` 1~63행; `docs/reference/requirements-evidence-map.md` 19~141행
- **문제:** test 정의와 결과가 구조상 40개여도 실행 환경/계정/명령/exit/evidence 필드가 부족했고, ZIP·fixture·secret·runtime 상태가 보고서마다 달랐다. 범위형 crosswalk만으로는 개별 요구사항의 T-ID를 알 수 없었다.
- **영향/근거:** Mission→Test→Evidence→Evaluation 연결을 독립 재현할 수 없고 미실행 항목을 완료로 오해한다.
- **재현:** T-001~T-040 행을 비교하고 ZIP/Bonus/SUB 상태를 map, test-results, execution, checklist에서 교차 조회한다.
- **수정:** 40개 1:1, 컨텍스트·계정·명령·실제 결과·exit·evidence·상태 schema, 각 requirement별 직접 T-ID, `TESTED`와 `NEEDS-RUNTIME` 구분을 동기화했다.

### M-11. CI fixture가 중요한 거짓 PASS·정리 실패를 잡지 못함 — FIXED

- **Severity:** MAJOR
- **파일/위치:** `.github/workflows/b1-1-static.yml` 16~520행
- **문제:** Boot 중복, key oracle, process branch, multi-PID listener, env injection, `/dev/full`, logrotate size/stanza, archive overflow/collision 등 핵심 회귀가 없었고 중복 EXIT trap이 기존 cleanup을 덮었다.
- **영향/근거:** 원격 green check가 실제 코드 의미를 충분히 검증하지 못해 평가/재현성을 과장한다.
- **재현:** 위 결함을 하나씩 주입해 PR HEAD workflow를 실행하면 기존 step 일부가 여전히 성공한다.
- **수정:** Bash/ShellCheck/config digest·policy helper/Boot/report/archive/monitor/logrotate 정상·오류 fixture를 추가하고 하나의 trap으로 모든 임시 프로세스와 경로를 정리한다.

### M-12. secret 파일명 탐지가 중첩 `*.env`와 key oracle을 놓침 — FIXED

- **Severity:** MAJOR
- **파일/위치:** `.gitignore` 1~7행; `scripts/verify.sh` 535~543행; `scripts/acceptance-test.sh` 278~304행
- **문제:** `config/agent.env` 같은 중첩 `.env`가 ignore/검출 regex를 통과할 수 있었고, 임의 reference key를 source-of-truth로 신뢰할 수 있었다.
- **영향/근거:** 실제 credential 추적 또는 잘못된 key를 정상으로 판정할 위험이 있다. 현재 실노출은 없지만 통제 결함은 중요하다 (`b1-1-mission.md` 158~163행).
- **재현:** 중첩 경로에 `agent.env`를 만들거나 잘못된 한 줄 key와 같은 reference를 제공한다.
- **수정:** `*.env`, `*.env.*` ignore와 example 예외, 모든 경로 segment의 `.key`/`.env` 탐지, mission 값의 secret-safe one-way digest 비교를 적용했다. 값은 출력하지 않는다.

## 5. MINOR

### N-01. report 시간 입력이 존재하지 않는 날짜·역전 구간을 허용 — FIXED

- **Severity:** MINOR
- **파일/위치:** `scripts/report.sh` 31~85행
- **문제/근거:** 형식 regex만으로 2월 30일을 허용하고 시작이 종료보다 늦어도 실행돼 Bonus 구간 결과가 혼동됐다 (`b1-1-mission.md` 238~242행).
- **재현:** `--start '2026-02-30 00:00:00'` 또는 start>end.
- **수정:** `LC_ALL=C`, UTC GNU date round-trip과 구간 순서 검증, exit 2 fixture를 추가했다.

### N-02. archive DRY_RUN과 실제 경로 판정·표시가 다름 — FIXED

- **Severity:** MINOR
- **파일/위치:** `scripts/archive-logs.sh` 47~64행·103~106행
- **문제/근거:** dangling archive path나 executable regular file을 DRY_RUN은 성공으로 표시하고, 실제 `mv -n`과 다른 명령을 출력했다.
- **재현:** archive 경로를 dangling symlink/regular file로 지정해 DRY_RUN과 실제 실행 exit를 비교한다.
- **수정:** 두 모드의 타입 판정을 통일하고 출력도 `mv -n`으로 맞췄다.

### N-03. 문서의 Agent 기본값·logrotate mode·상태가 구현과 충돌 — FIXED

- **Severity:** MINOR
- **파일/위치:** `docs/06-agent-setup.md`, `docs/07-monitor-script.md`, `docs/10-troubleshooting.md`, `docs/12-evaluation-preparation.md`, `docs/14-final-review-submission.md`
- **문제/근거:** 일부 설명에 Python 기본값, `create 0640`, old TODO/복합 상태가 남아 실제 x86/arm64·0660·NEEDS-RUNTIME 정책과 충돌했다.
- **재현:** 관련 문자열을 전역 검색해 코드/config와 비교한다.
- **수정:** 실제 ZIP 선택, 0660 core R/W, 공통 상태 enum과 runtime/evidence 구분으로 동기화했다.

### N-04. 테스트 명령/트러블슈팅 상태 표기가 실제 CLI와 불일치 — FIXED

- **Severity:** MINOR
- **파일/위치:** `reports/test-results.md`, `reports/troubleshooting-report.md`, `docs/15-bonus.md`
- **문제/근거:** T-035에 존재하지 않는 option이 기록되고, 실제 incident 상태와 “원인 미확정”이 하나의 비표준 상태로 섞였다.
- **재현:** `scripts/report.sh --help`와 ledger를 비교하고 status 열의 enum을 검색한다.
- **수정:** `--start/--end`, 상태 `TESTED`, 원인 별도 열로 정정했다.

### N-05. 실행 bit/문서 예시와 안전한 fixture 경로 불일치 — FIXED

- **Severity:** MINOR
- **파일/위치:** `scripts/report.sh` 7~11행; `docs/15-bonus.md`; `.github/workflows/b1-1-static.yml`
- **문제/근거:** mode 0644인 report를 `./report.sh`로 안내하거나 고정 `/tmp`를 “안전한 fixture”로 설명했다.
- **재현:** repository mode에서 직접 실행하거나 fixed path를 선점한다.
- **수정:** `bash scripts/report.sh` 예시와 `mktemp`+trap fixture로 통일했다.

## 6. IMPROVEMENT

| ID | 제안 | 이유 |
|---|---|---|
| I-01 | Bash fixture를 향후 Bats 등 독립 테스트 파일로 분리 | 긴 workflow inline shell의 유지보수와 line-level 실패 진단 개선 |
| I-02 | `actions/checkout`을 검토된 commit SHA로 pin | 공급망 변경 위험 축소 |
| I-03 | evidence manifest에 파일 hash·실행 시각·host 범주·commit을 기록 | 원출력의 provenance와 재현성 강화 |
| I-04 | archive 동시 실행 방지를 위한 optional lock 추가 | cron/manual 중복 실행 시 경쟁 구간을 더 줄임 |

이 항목들은 현재 필수 미션 BLOCKER/MAJOR가 아니며 이번 수정 범위에서 강제하지 않았다.

## 7. Mission Requirement Matrix

`PASS`는 실제 구현·target 테스트·evidence 연결이 모두 끝난 경우에만 사용한다. 현재 실제 evidence가 0개이므로 PASS 행은 없다.

| 미션 영역 | 상태 | 독립 판정 |
|---|---|---|
| Ubuntu/Linux·Bash | PARTIAL | Ubuntu 24.04 격리 환경과 Bash/ShellCheck 확인; target PID 1/systemd 재확인 필요 |
| SSH 20022·Root 차단 | PARTIAL | target-reported TESTED이나 원출력 없음; 새 일반 사용자 접속과 강화 verifier 재실행 필요 |
| UFW 두 포트만 허용 | PARTIAL | target-reported TESTED이나 원출력 없음 |
| 사용자·그룹 | NEEDS-RUNTIME | 정확한 전체 멤버십 검증 코드만 준비됨 |
| 디렉터리·ACL | NEEDS-RUNTIME | 파일 타입/default ACL/교차 사용자 probe 구현; target 미실행 |
| Agent artifact/아키텍처 | PARTIAL | ZIP 최상위 x86-64/aarch64 ELF 직접 확인; evidence 파일 없음 |
| Agent env/key/non-root | NEEDS-RUNTIME | exact verifier/secret-safe oracle 구현; 실제 배치 미검증 |
| Boot 1~5·READY·15034 | NEEDS-RUNTIME | validator fixture만 검증; 실제 Agent 미실행 |
| monitor process/port | PARTIAL | 강한 격리 fixture PASS; target Agent/배치 evidence 없음 |
| monitor firewall/resources/warnings | PARTIAL | 정상·실패·경고 fixture PASS; target 값 미검증 |
| monitor.log format/append/권한 | PARTIAL | 격리 append/실패 PASS; target log 미검증 |
| cron 등록·매분 증가 | NEEDS-RUNTIME | exact config/override fixture PASS; 실제 설치·70초 증가 미실행 |
| logrotate 10M/총 10개/0660 | PARTIAL | 11MiB non-force와 반복 force fixture PASS; target dry-run/회전/재기록 미실행 |
| Recovery·재부팅·깨끗한 재현 | NEEDS-RUNTIME | 절차만 구현 |
| T-001~T-040 체계 | PARTIAL | 정의/ledger 40개 1:1; runtime/evidence 미완료 |
| 실제 evidence·최종 제출 | FAIL | 실제 파일 0개 |
| Bonus report/archive | PARTIAL | 격리 정상·오류 fixture PASS; 실제 monitor.log/evidence 없음 |
| Secret 안전 | PARTIAL | tracked 실비밀 미발견; target capture redaction 검토가 남음 |

## 8. Evaluation Matrix

평가 파일의 19개 문항과 최종 확인 3개를 행 단위로 판정했다. 설명 문서가 있어도 사용자 구두 검증과 evidence가 없으므로 설명 문항은 `PARTIAL`로 유지한다.

| 평가 행 | 질문 요약 | 상태 | 근거/잔여 |
|---|---|---|---|
| 13 | SSH 20022 + Root 차단 | PARTIAL | target-reported, evidence/새 접속 없음 |
| 14 | 방화벽 active + 두 포트만 | PARTIAL | target-reported, evidence 없음 |
| 15 | 계정·그룹 | NEEDS-RUNTIME | target 미구성/미검증 |
| 16 | Boot 5단계 + READY | NEEDS-RUNTIME | validator만 TESTED |
| 17 | monitor process/port, 실패 exit 1 | PARTIAL | 격리 branch PASS, target 미실행 |
| 18 | monitor.log 누적 | NEEDS-RUNTIME | target log 없음 |
| 19 | cron 자동 증가 | NEEDS-RUNTIME | 시간 경과 관찰 없음 |
| 20 | 10MB/10개 | PARTIAL | 격리 동작 PASS, target 회전 없음 |
| 26 | pgrep/ps·ss 선택 이유 | PARTIAL | 문서/코드 일치, 구두 검증 남음 |
| 27 | CPU/MEM/DISK 파싱·포맷 이유 | PARTIAL | 구현/설명/fixture 일치, 구두 검증 남음 |
| 28 | dev/admin/core 권한 설명 | PARTIAL | 설계 일치, target ACL·구두 검증 남음 |
| 29 | logrotate 구현 설명 | PARTIAL | 설명/fixture 일치, target evidence 없음 |
| 35 | SSH/Root 위협 모델 | PARTIAL | 문서 답안 존재, 구두 검증 남음 |
| 36 | agent-core 최소권한 | PARTIAL | 문서/테스트 설계 존재, runtime 남음 |
| 37 | WARNING과 fatal 분리 | PARTIAL | 코드/문서/fixture 일치, 구두 검증 남음 |
| 38 | `>`와 `>>` | PARTIAL | 문서/append 구현 일치, 구두 검증 남음 |
| 44 | Nginx 확장 | PARTIAL | 문서 답안 존재, 구두 검증 남음 |
| 45 | process 있음/port 없음 진단 | PARTIAL | 진단 문서와 branch fixture 존재, 구두 검증 남음 |
| 46 | 로그 급증·디스크 부족 대응 | PARTIAL | 문서/Bonus 안전성 보완, 구두 검증 남음 |
| 63 | 모든 결과 증빙 가능 | FAIL | evidence 0개 |
| 64 | monitor/cron/누적/회전 실제 동작 | NEEDS-RUNTIME | target 통합 실행 없음 |
| 65 | 설계·장애 대응 구두 설명 | NEEDS-RUNTIME | 사용자 인수 미실행 |

## 9. Files Changed by Codex

보고서 포함 총 30개 파일을 로컬 working tree에서 수정했다.

| 범주 | 파일 |
|---|---|
| CI/ignore/config | `.github/workflows/b1-1-static.yml`, `.gitignore`, `config/agent.env.example` |
| scripts | `scripts/acceptance-test.sh`, `scripts/archive-logs.sh`, `scripts/monitor.sh`, `scripts/preflight.sh`, `scripts/report.sh`, `scripts/verify.sh` |
| tests | `tests/test-cases.md` |
| reports | `reports/codex-review.md`, `reports/execution-report.md`, `reports/final-checklist.md`, `reports/test-results.md`, `reports/troubleshooting-report.md` |
| docs | `docs/01-environment.md`, `docs/02-repository-workflow.md`, `docs/05-users-groups-acl.md`, `docs/06-agent-setup.md`, `docs/07-monitor-script.md`, `docs/08-logging-cron.md`, `docs/09-testing-recovery.md`, `docs/10-troubleshooting.md`, `docs/11-execution-evidence.md`, `docs/12-evaluation-preparation.md`, `docs/13-reproducibility-test.md`, `docs/14-final-review-submission.md`, `docs/15-bonus.md` |
| references | `docs/reference/commands.md`, `docs/reference/requirements-evidence-map.md` |

원본 4개 파일, `main`, 실제 target 설정, evidence 디렉터리 내용은 수정하지 않았다. commit/push/merge도 수행하지 않았다.

## 10. Commands Executed

주요 감사·검증 명령은 다음과 같다.

```text
gh pr view 5 --json ...
gh pr checks 5
gh pr diff 5 --name-only
git status --short
git branch --show-current
git log --oneline --decorate -n 20
git diff main...HEAD --stat
git diff main...HEAD
git diff HEAD
git diff --check
unzip -Z1 agent-app.zip
unzip -p agent-app.zip <entry> | file -
bash -n scripts/*.sh
shellcheck scripts/*.sh
bash scripts/preflight.sh
bash scripts/verify.sh
logrotate -d config/agent-monitor.logrotate
find evidence -type f ! -name README.md ! -name .gitkeep
git ls-files
rg filename-only secret scans
```

GitHub workflow의 각 `run` block도 YAML에서 읽어 동일 Bash로 로컬 실행했다. monitor의 PID/socket 소유 정보는 sandbox 내부에서 가려져 정상 fixture가 한 번 exit 1이었고, 같은 3개 monitor step을 실제 `/proc`·socket PID 가시성이 있는 실행 컨텍스트에서 재실행해 모두 exit 0을 확인했다.

## 11. Test Results

| 검증 | 결과 | 비고 |
|---|---|---|
| `bash -n scripts/*.sh` | PASS, exit 0 | 6개 Bash 파일 |
| `shellcheck scripts/*.sh` | PASS, exit 0 | 최신 수정본 |
| `git diff --check` | PASS, exit 0 | whitespace 오류 없음 |
| Workflow YAML parse | PASS | `verify` job step 구조 확인 |
| Configuration invariants | PASS | cron exact env/job + mission key digest |
| verify policy helpers | PASS | file type, SSH Match/Include/equals/CRLF, cron override 거부 |
| Boot validator | PASS | 정상 0, 중복 fixture expected 1 |
| report fixture | PASS | 통계·구간·invalid date·reverse interval |
| archive fixture | PASS | 0개·7/30일·공백·충돌·dangling·non-dir·permission·find·overflow |
| logrotate fixture | PASS | 11MiB non-force 회전, current+9, new mode 0660 |
| monitor process/port | PASS | missing/decoy/live missing-port branch |
| monitor normal/warnings | PASS | multi-PID listener 선택, 세 경고, inactive firewall 계속 |
| monitor failure | PASS | invalid port/threshold/env/df, non-writable, `/dev/full` expected exit 2 |
| ZIP/ELF | PASS | top-level x86-64 + aarch64 ELF |
| T-ID 구조 | PASS | test-cases/results 각각 unique 40개 |
| Secret scan | PASS | 실제 tracked key/env/private key/token 미발견 |
| `preflight.sh` current namespace | expected FAIL, exit 1 | PID 1이 systemd가 아닌 격리 namespace; target 판정 아님 |
| `verify.sh` current namespace | expected FAIL, exit 1 | PASS 5 / WARN 3 / FAIL 28; target 계정·설정·Agent가 이 namespace에 없음 |
| target형 `logrotate -d` | INCONCLUSIVE, exit 1 | non-root namespace에서 agent-admin/core euid 전환 불가 |
| Evidence gate | FAIL | 실제 evidence 0개 |

실패한 세 진단은 코드 회귀로 숨기지 않았다. 앞의 두 개는 현재 namespace가 target Ubuntu가 아니라는 결과이고, 마지막 evidence 실패는 실제 잔여 BLOCKER다.

## 12. GitHub Actions Result

2026-08-07 최종 조회 시 PR #5는 OPEN, base=`main`, head=`fix/b1-1-pre-codex-audit`, GitHub 표시상 MERGEABLE이었다. 원격 HEAD `96c05e6`에는 같은 workflow의 `verify` check 두 건이 SUCCESS였다.

```text
run 31166960182 / verify / SUCCESS
run 31167093190 / verify / SUCCESS
```

그러나 이 성공은 Codex의 미커밋 로컬 변경보다 이전 HEAD에 대한 결과다. 현재 수정본은 로컬에서 workflow blocks를 재현해 통과했지만, push하지 않았으므로 새 GitHub Actions 결과는 없다. GitHub의 `MERGEABLE`은 충돌 여부일 뿐 미션 완료 또는 evidence 승인 판정이 아니다.

## 13. Security / Secret Review

- tracked secret-like 파일명은 `config/agent.env.example`뿐이며 허용된 예시 파일이다.
- 실제 `.key`, 실제 `.env`, private key header, password/token/credential 후보는 발견되지 않았다.
- 미션의 알려진 테스트 key literal은 Source of Truth인 `b1-1-mission.md`에만 존재한다. Codex는 이를 출력·복제하거나 evidence에 저장하지 않았다.
- key 검증은 한 줄 구조와 one-way digest만 비교하며 값은 출력하지 않는다.
- `*.env`와 `*.env.*`를 ignore/검출하고 `.env.example`만 명시적으로 허용한다.
- acceptance 임시 파일은 private `mktemp` 경로와 allowlisted cleanup을 사용한다.
- Agent 배치 문서는 `chown -R ... agent-common`을 금지해 `api_keys`의 agent-core 경계를 보존한다.
- 실제 target capture의 IP/계정/운영 로그 redaction은 evidence 생성 시 다시 검토해야 한다.

## 14. Remaining Ubuntu Runtime Tasks

다음은 격리 CI로 대체할 수 없다.

1. `preflight.sh`를 PID 1=systemd인 target Ubuntu에서 다시 실행한다.
2. 강화된 `verify.sh`를 root로 실행해 SSH 모든 Include/Match, UFW, 정확한 그룹 멤버십, 디렉터리 타입·ACL, env/key/monitor metadata를 확인한다.
3. 별도 클라이언트에서 일반 사용자 `ssh -p 20022` 새 접속을 확인하고 기존 세션을 유지한 채 복구 절차를 시험한다.
4. 아키텍처 대상 ELF를 배치하고 일반 계정으로 Boot `[1/5]`~`[5/5]`, 단일 READY, PID 소유 `0.0.0.0:15034`를 확인한다.
5. 실제 Boot capture로 root `acceptance-test.sh`를 skip 없이 실행한다.
6. agent-admin의 최소 cron 환경 수동 실행, 실제 crontab 설치, cron service active, 1~2분 log 증가를 관찰한다.
7. `/etc/logrotate.d/agent-monitor`에서 dry-run, 통제된 force, 새 파일 0660/core R/W, agent-test 차단, monitor 재기록을 확인한다.
8. SSH/monitor 장애 후 복구, 새 세션, 재부팅 후, 가능하면 깨끗한 Ubuntu 재현을 수행한다.
9. 실제 monitor.log로 Bonus report/archive를 확인한다.

## 15. Remaining Evidence Tasks

실제 명령을 실행한 뒤 다음 evidence를 생성해야 한다. 예상 출력이나 Codex fixture를 target evidence로 복사하면 안 된다.

| 경로 | 필요한 원출력 |
|---|---|
| `evidence/01-environment/` | OS, arch, PID 1/systemd, 도구 |
| `evidence/03-ssh/` | backup/cmp, `sshd -t`, effective policy, listener, 새 사용자 접속, 복구 |
| `evidence/04-firewall/` | active/default/IPv4 두 포트/예상 외 rule 없음 |
| `evidence/05-users-groups-acl/` | exact users/groups, stat/getfacl, 교차 사용자 허용·차단 |
| `evidence/06-agent/` | ZIP 선택, env/key metadata, non-root PID, Boot 1~5, READY, PID listener |
| `evidence/07-monitor/` | 배치 metadata, 정상/health 실패/warnings/log format/append 실패 |
| `evidence/08-automation/` | crontab, service, 1~2분 증가, logrotate dry/force/mode/rewrite |
| `evidence/09-testing/` | acceptance 전체, 장애→복구 |
| `evidence/14-final/` | 새 세션·재부팅·깨끗한 환경 재현과 최종 checklist |
| Bonus 위치 | 실제 monitor.log 기반 report/archive 결과 |

각 파일은 실행 시각, 환경 범주, 실행 계정, 명령, exit code, commit을 포함하고 `reports/test-results.md`의 T-ID 및 requirement map의 해당 행에 직접 연결해야 한다. 민감값과 불필요한 개인 IP/운영 데이터는 저장 전에 가린다.

## 16. Merge Recommendation

**DO NOT MERGE**

이유는 다음과 같다.

1. B-04가 미해결이며 실제 evidence 파일이 0개다.
2. IAM/ACL, 실제 Agent, Boot/READY/listener, target monitor, cron 시간 경과, target logrotate, 복구·재현이 `NEEDS-RUNTIME`이다.
3. 사용자 최종 인수가 `BLOCKED` 상태다.
4. Codex 수정은 미커밋·미push 상태라 원격 GitHub Actions가 최신 tree를 검증하지 않았다.

merge 재검토 조건은 target runtime 전 항목 성공, evidence 파일 연결, T-040 완료, 새 원격 Actions 성공, secret/redaction 재검토와 사용자 인수다. 이 조건 전에는 GitHub의 기계적 `MERGEABLE` 표시와 관계없이 main에 merge하면 안 된다.
