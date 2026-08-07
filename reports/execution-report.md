# B1-1 요구사항 수행 내역서

> 실제 수행 결과와 저장소 구현, Codex 격리 fixture를 구분합니다. 문서나 예상 출력만으로 `TESTED`/`PASS`를 부여하지 않으며, `evidence/` 원출력이 없으면 최종 `PASS`가 아닙니다.

## 1. 환경과 실행 컨텍스트

| 컨텍스트 | 확인 내용 | 상태 |
|---|---|---|
| Pre-Codex target 기록 | Ubuntu 24.04.4 LTS, x86_64, PID 1 systemd, systemd 255, 사용자 ubuntu | TESTED / evidence pending |
| 원본 기준 | Ubuntu 22.04 또는 동등 Linux | 기준 |
| Codex 격리 namespace | Ubuntu 24.04, x86_64이나 PID/network/systemd가 target과 분리됨 | 감사·fixture 전용 |

Codex namespace에서 `bash scripts/preflight.sh`는 PID 1이 systemd가 아니므로 exit 1이었습니다. 이는 target 실패가 아니라 해당 환경에서는 runtime 판정을 할 수 없다는 뜻이며 `NEEDS-RUNTIME`으로 남깁니다.

## 2. SSH

Pre-Codex target 수행 기록에는 다음 결과가 있습니다.

```text
sshd_config 백업과 비교
Port 20022
PermitRootLogin no
sshd -t 성공
sshd -T 최종값 확인
Ubuntu 24.04 ssh.socket / sshd-socket-generator 동작 확인
20022 LISTEN / 22 미LISTEN
```

현재 상태는 `TESTED`입니다. 다만 `evidence/03-ssh/`에 원출력이 없어서 Codex가 독립 확인하지 못했고, 외부/별도 클라이언트의 일반 사용자 새 접속도 `NEEDS-RUNTIME`입니다.

## 3. 방화벽

Pre-Codex target 수행 기록에는 UFW active, default deny incoming, `20022/tcp`와 `15034/tcp` 허용, 별도 `22/tcp` 허용 없음이 확인됐다고 적혀 있습니다.

현재 상태는 `TESTED`입니다. `evidence/04-firewall/` 원출력 수집과 독립 재확인은 남아 있습니다.

## 4. 사용자·그룹·ACL

Pre-Codex 기록은 `agent-common`, `agent-core` 그룹 객체만 생성된 중간 상태였습니다. Codex namespace에서 보이는 계정은 target과 동일한 상태라는 보장이 없으므로 현재 계정·멤버십·디렉터리·ACL 판정에 사용하지 않았습니다.

구현된 정책은 다음과 같습니다.

```text
agent-common = agent-admin + agent-dev + agent-test
agent-core   = agent-admin + agent-dev
upload_files = agent-common 읽기·쓰기
api_keys     = agent-core만 읽기·쓰기
log dir      = agent-core만 읽기·쓰기
```

`acceptance-test.sh`는 허용 계정의 읽기·쓰기와 `agent-test`의 읽기·쓰기·디렉터리 목록 차단을 모두 시험하고, root 전용 임시 경로와 안전한 정리 목록을 사용하도록 보완했습니다. 실제 적용과 접근 시험은 `NEEDS-RUNTIME`입니다.

## 5. Agent 실행환경

Codex가 `agent-app.zip`을 직접 확인한 결과 ZIP 최상위에 다음 두 파일이 있습니다.

```text
agent-app-linux-x86    : ELF 64-bit x86-64
agent-app-linux-arm64  : ELF 64-bit aarch64
```

따라서 선택 규칙은 다음과 같습니다.

```text
x86_64 / amd64  → agent-app-linux-x86
aarch64 / arm64 → agent-app-linux-arm64
그 밖의 아키텍처 → 명시적 실패
```

자동 Python `agent_app.py` fallback은 제거했습니다. 배치 절차는 ZIP 실제 목록을 먼저 확인하고 임시 디렉터리에 추출한 뒤 정확한 실행 파일만 설치하며, `chown -R ... agent-common`으로 `api_keys` 정책을 훼손하지 않습니다.

ZIP/ELF 정적 확인은 `TESTED`입니다. 환경변수·key 권한·non-root 실행·Boot 1~5·READY·Agent가 소유한 `0.0.0.0:15034`는 `NEEDS-RUNTIME`입니다.

## 6. monitor.sh

저장소 구현과 Codex 격리 fixture에서 다음을 확인했습니다.

```text
허용 목록 기반 env 파서: shell code, symlink, 미지원·중복 키 거부
/proc/<pid>/exe와 NUL cmdline 기반 exact signature 및 동일 UID 확인
자기 자신·부모 shell·이름만 인자로 포함한 decoy 거부
선택한 Agent PID가 소유한 IPv4 0.0.0.0:<port>만 정상 처리
잘못된 port·threshold 및 CPU/MEM/df 수집 실패 → exit 2
process/port health 실패 → exit 1
firewall inactive 및 CPU/MEM/DISK 초과 → WARNING 후 계속
지정 로그 형식 append
사전 권한 실패와 실제 append 실패(/dev/full) → exit 2
```

`bash -n scripts/*.sh`와 `shellcheck scripts/*.sh`는 통과했습니다. synthetic Agent/listener fixture의 코드 경로는 `TESTED`이지만, `$AGENT_HOME/bin/monitor.sh` 배치·소유권·실제 Agent/로그 실행은 `NEEDS-RUNTIME`입니다.

## 7. cron·logrotate

cron 예시는 `agent-admin`, `* * * * *`, 절대 경로와 최소 PATH를 사용합니다. logrotate 설정은 다음 정책입니다.

```text
size 10M
rotate 9
current monitor.log 1 + rotated 9 = 최대 10개
create 0660 agent-admin agent-core
```

격리 강제 회전 fixture에서 최대 10개와 새 파일 `0660`을 확인했습니다. 실제 `/etc/logrotate.d` 설정의 dry-run·강제 회전·monitor 재기록, agent-admin crontab 설치와 1~2분 자동 증가는 `NEEDS-RUNTIME`입니다. `size 10M`은 logrotate 실행 주기 사이에 일시 초과될 수 있습니다.

## 8. 테스트 체계

`tests/test-cases.md`와 `reports/test-results.md`는 T-001~T-040을 정확히 1:1로 유지합니다. ledger에는 환경/commit 컨텍스트, 계정, 명령·참조, 실제 결과, exit code, evidence, 진행 상태를 기록합니다.

검증 도구 역할은 다음과 같습니다.

```text
preflight.sh       = 사전 환경 확인
verify.sh          = 현재 상태 read-only 검사
acceptance-test.sh = 실제 기능·장애·ACL·cron 관찰
```

`verify.sh`나 CI만으로 Boot/READY, cron 시간 경과, evidence 완성, 사용자 인수를 최종 PASS로 선언하지 않습니다.

## 9. 실제 트러블슈팅

`reports/troubleshooting-report.md`의 실제 관찰 항목은 다음 세 건입니다.

```text
TS-001 /run/sshd RuntimeDirectory
TS-002 ssh.socket / daemon-reload / sshd-socket-generator
TS-003 UFW 15034 규칙 재확인 (근본원인은 원출력 부재로 미확정)
```

나머지는 예상 사례로 분리했습니다.

## 10. 보너스

격리 fixture에서 다음을 `TESTED`했습니다.

```text
report.sh: CPU/MEM/DISK 평균·최소·최대·샘플 수·시간 구간
report.sh: 잘못된 실제 달력 날짜와 역전 구간 거부
archive-logs.sh: 공백 파일명, 7일 압축·이동, 실제 30일 삭제
archive-logs.sh: 대상 0개, 미존재/명령 실패, 충돌·dangling symlink
archive-logs.sh: 잘못된 retention과 산술 overflow 입력 거부
```

실제 `monitor.log`와 보너스 evidence는 `NEEDS-RUNTIME`입니다. 보너스는 필수 미션 설정을 변경하지 않습니다.

## 11. Evidence와 보안

`evidence/`에는 안내 README와 0-byte `.gitkeep`만 있으며 실제 증적 파일은 0개입니다. 따라서 어떤 요구사항도 최종 `PASS`가 아닙니다.

tracked 파일 검토에서는 실제 `.key`, 실제 env, private key, password/token/credential이 발견되지 않았습니다. 원본 `b1-1-mission.md`의 미션 예시 key 문구는 Source of Truth이므로 노출로 오판하지 않았고 수정하지 않았습니다. `.gitignore`와 `verify.sh`는 중첩 경로의 `*.env`도 잡도록 보완했습니다.

## 12. 현재 종합 상태

```text
SSH/UFW target 기록       TESTED / evidence pending
Agent ZIP·Bash·격리 fixture TESTED
IAM/ACL target            NEEDS-RUNTIME
Agent runtime             NEEDS-RUNTIME
monitor target runtime    NEEDS-RUNTIME
cron/logrotate target     NEEDS-RUNTIME
복구·재현·사용자 인수      NEEDS-RUNTIME
실제 evidence             TODO (0개)
Codex 독립 감사           TESTED
FINAL PASS                NO
```

최종 `PASS`는 구현, target runtime 테스트, 실제 evidence 연결, 재현, 보안 검토와 사용자 인수가 모두 끝난 뒤에만 부여합니다.
