# B1-1 테스트 결과

> 실행 결과(`PASS`/`FAIL`)와 요구사항 진행 상태를 분리합니다. 진행 상태는 `TODO / IMPLEMENTED / NEEDS-RUNTIME / TESTED / PASS / BLOCKED`만 사용합니다. `TESTED`여도 `evidence/` 원본 출력이 없으면 최종 `PASS`가 아닙니다.

## 실행 컨텍스트

- `target-reported`: Pre-Codex 수행 내역에 기록된 Ubuntu 24.04.4 결과입니다. SSH/UFW가 실제 확인됐다는 사용자 제공 사실을 유지하되, 현재 `evidence/`에는 원출력이 없어 Codex가 독립 재검증하지 못했습니다.
- `codex-isolated`: PR #5 기준 커밋 `96c05e6` 위 로컬 수정 working tree를 사용한 격리 fixture입니다. PID/network/systemd가 target Ubuntu와 분리되어 있어 target runtime을 대체하지 않습니다.
- 실행일은 모두 2026-08-07이며, Codex 격리 명령은 일반 계정 `ubuntu`로 실행했습니다.

| 테스트 ID | 컨텍스트 / 계정 | 실행 명령·참조 | 실제 결과 | 종료 코드 | evidence | 진행 상태 |
|---|---|---|---|---|---|---|
| T-001 | codex-isolated / ubuntu | `bash scripts/preflight.sh` | FAIL: PID 1이 systemd가 아닌 격리 namespace라 target 사전조건을 확인할 수 없음 | 1 | `reports/codex-review.md`; target 원출력 없음 | NEEDS-RUNTIME |
| T-002 | target-reported / sudo-root | `sshd -t` | PASS로 기록됨 | 0 | `evidence/03-ssh/` 원출력 없음 | TESTED |
| T-003 | target-reported + codex-isolated / sudo-root·ubuntu | target `sshd -T`; isolated safe/unsafe Match policy fixtures | target에 `port 20022`, `permitrootlogin no` 확인으로 기록됨; verifier는 다른 Match/Include의 root-login 재허용을 거부 | target 0, fixtures 0 | `reports/codex-review.md`; `evidence/03-ssh/` 원출력 없음 | TESTED |
| T-004 | target-reported / sudo-root | `ss -lntp` | 20022 LISTEN, 22 미LISTEN 확인으로 기록됨 | 0 | `evidence/03-ssh/` 원출력 없음 | TESTED |
| T-005 | target / 일반 사용자 | `ssh -p 20022 ...` | 미실행 | N/A | `evidence/03-ssh/` 예정 | NEEDS-RUNTIME |
| T-006 | target-reported / sudo-root | `ufw status verbose` | active, default deny, 20022/15034 허용 확인으로 기록됨 | 0 | `evidence/04-firewall/` 원출력 없음 | TESTED |
| T-007 | target + codex-isolated / root·ubuntu | `verify.sh` IAM/FS/env 구간; 파일 타입 helper fixtures | directory/regular 타입 오인 방지 fixture는 PASS; target 사용자·그룹·필수 경로·env 값/메타데이터는 미검증 | fixture 0, target N/A | `reports/codex-review.md`; `evidence/05-users-groups-acl/`, `evidence/06-agent/` 예정 | NEEDS-RUNTIME |
| T-008 | target / root→agent-test | `acceptance-test.sh` ACL 구간 | upload 읽기·쓰기 미검증 | N/A | `evidence/05-users-groups-acl/` 예정 | NEEDS-RUNTIME |
| T-009 | target / root→admin,dev,test | `verify.sh` + `acceptance-test.sh` key 구간 | key 한 줄·metadata와 디렉터리 허용/차단 미검증 | N/A | `evidence/05-users-groups-acl/`, `evidence/06-agent/` 예정 | NEEDS-RUNTIME |
| T-010 | target / root→admin,dev,test | `acceptance-test.sh` ACL 구간 | log 디렉터리 허용·차단 미검증 | N/A | `evidence/05-users-groups-acl/` 예정 | NEEDS-RUNTIME |
| T-011 | codex-isolated / ubuntu | `unzip -l agent-app.zip`; `file` | PASS: ZIP 최상위 x86 ELF와 arm64 ELF 확인 | 0 | `reports/codex-review.md`; `evidence/06-agent/` 예정 | TESTED |
| T-012 | target / agent-admin | `ps -o user,pid,args` | non-root 실제 실행 미검증 | N/A | `evidence/06-agent/` 예정 | NEEDS-RUNTIME |
| T-013 | codex-isolated validator / ubuntu | `acceptance-test.sh --boot-evidence-only` fixtures | validator PASS: 정상 순서 수락, 중복·역순 거부; 실제 Agent Boot 미실행 | 정상 0, 오류 1 | `reports/codex-review.md`; 실제 Boot 원출력 없음 | NEEDS-RUNTIME |
| T-014 | target / agent-admin | Agent 시작 출력 | `Agent READY` 미검증 | N/A | `evidence/06-agent/` 예정 | NEEDS-RUNTIME |
| T-015 | target / root | `ss -lntp` | Agent 소유 `0.0.0.0:15034` 미검증 | N/A | `evidence/06-agent/` 예정 | NEEDS-RUNTIME |
| T-016 | codex-isolated / ubuntu | `bash -n scripts/*.sh`; target `stat` 예정 | PASS: Bash 스크립트 6개 구문 정상; 배치 경로·owner/group/750은 미검증 | 정적 0 | `reports/codex-review.md`; `evidence/07-monitor/` 예정 | NEEDS-RUNTIME |
| T-017 | codex-isolated / ubuntu | synthetic Agent + owned listener fixture | PASS: 정상 health에서 로그 1줄 증가 | 0 | `reports/codex-review.md`; target 원출력 없음 | TESTED |
| T-018 | codex-isolated / ubuntu | missing-process 및 argv-decoy fixture | PASS: 두 경우 모두 거부 | 1 (expected) | `reports/codex-review.md` | TESTED |
| T-019 | codex-isolated / ubuntu | process-present / unrelated-or-missing-port fixture | PASS: 선택한 PID가 포트를 소유하지 않으면 거부 | 1 (expected) | `reports/codex-review.md` | TESTED |
| T-020 | codex-isolated / ubuntu | firewall-inactive fixture | PASS: WARNING 후 정상 health 계속 | 0 | `reports/codex-review.md` | TESTED |
| T-021 | codex-isolated / ubuntu | `CPU_WARN_THRESHOLD=-1` fixture | PASS: CPU WARNING | 0 | `reports/codex-review.md` | TESTED |
| T-022 | codex-isolated / ubuntu | `MEM_WARN_THRESHOLD=-1` fixture | PASS: MEM WARNING | 0 | `reports/codex-review.md` | TESTED |
| T-023 | codex-isolated / ubuntu | `DISK_WARN_THRESHOLD=-1` fixture | PASS: DISK_USED WARNING | 0 | `reports/codex-review.md` | TESTED |
| T-024 | codex-isolated / ubuntu | monitor output regex fixture | PASS: 지정 한 줄 포맷 일치 | 0 | `reports/codex-review.md` | TESTED |
| T-025 | codex-isolated / ubuntu | 사전 권한 실패 및 `/dev/full` append fixture | PASS: 쓰기 실패를 성공으로 숨기지 않음 | 2 (expected) | `reports/codex-review.md` | TESTED |
| T-026 | target / agent-admin | `env -i ... monitor.sh` | 실제 배치·Agent 기준 최소 환경 미검증 | N/A | `evidence/09-testing/` 예정 | NEEDS-RUNTIME |
| T-027 | target + codex-isolated / root·ubuntu | `crontab -u agent-admin -l`; exact/override policy fixtures | 예시는 exact job·안전한 env로 구현되고 threshold override 거부 fixture PASS; 실제 등록 미검증 | fixture 0, target N/A | `reports/codex-review.md`; `evidence/08-automation/` 예정 | NEEDS-RUNTIME |
| T-028 | target / root | 1~2분 line-count 관찰 | 미실행 | N/A | `evidence/08-automation/` 예정 | NEEDS-RUNTIME |
| T-029 | codex-isolated / ubuntu | `logrotate -d config/agent-monitor.logrotate` | INCONCLUSIVE: target 사용자 전환·상태 파일 권한이 없는 격리 환경에서 실패 | 1 | `reports/codex-review.md`; target 원출력 없음 | NEEDS-RUNTIME |
| T-030 | codex-isolated / ubuntu | 임시 경로·상태 파일을 쓴 11MiB non-force + 반복 force fixture | PASS: 10M 기준 실제 회전, current 1 + rotated 9 = 최대 10, 새 파일 0660 | 0 | `reports/codex-review.md`; target 원출력 없음 | TESTED |
| T-031 | target / root | 실제 설정 강제 회전 후 재기록 | 미실행 | N/A | `evidence/08-automation/` 예정 | NEEDS-RUNTIME |
| T-032 | codex-isolated / ubuntu | 장애/정상 monitor fixtures; target SSH 백업 복구 예정 | monitor 개별 실패·정상 경로는 PASS; target SSH/monitor 복구 시나리오는 미실행 | N/A | `evidence/03-ssh/`, `evidence/09-testing/` 예정 | NEEDS-RUNTIME |
| T-033 | target / 사용자 | 새 세션·재부팅·깨끗한 Ubuntu 절차 | 미실행 | N/A | `evidence/14-final/` 예정 | NEEDS-RUNTIME |
| T-034 | codex-isolated / ubuntu | `report.sh` 통계 fixture | PASS: CPU/MEM/DISK 평균·최소·최대·샘플 수 정확 | 0 | `reports/codex-review.md` | TESTED |
| T-035 | codex-isolated / ubuntu | `report.sh --start/--end` fixture | PASS: 지정 구간 샘플만 집계 | 0 | `reports/codex-review.md` | TESTED |
| T-036 | codex-isolated / ubuntu | 공백 파일명 포함 7일 archive fixture | PASS: 대상만 압축·이동 | 0 | `reports/codex-review.md` | TESTED |
| T-037 | codex-isolated / ubuntu | 실제 30일 초과 `.gz` fixture | PASS: 대상만 삭제 | 0 | `reports/codex-review.md` | TESTED |
| T-038 | codex-isolated / ubuntu | 0개·미존재·명령 실패·충돌·invalid/overflow fixture | PASS: 예상 보존·오류 종료, dangling symlink 덮어쓰기 없음 | 예상 0/1/2 | `reports/codex-review.md` | TESTED |
| T-039 | codex-isolated / ubuntu | `git ls-files`; secret filename/content scan | PASS: tracked `.key`/실제 env/private key/token 없음; 원본 미션의 예시 key만 제외 확인 | 0 | `reports/codex-review.md`; 별도 evidence 없음 | TESTED |
| T-040 | codex-isolated / ubuntu | T-ID/map/evidence 교차 감사 | FAIL: T-001~040 구조는 1:1이나 실제 evidence 파일은 0개 | N/A | `reports/codex-review.md`; `docs/reference/requirements-evidence-map.md` | NEEDS-RUNTIME |

## 현재 요약

```text
target-reported TESTED : SSH T-002~004, UFW T-006 (원출력 evidence 없음)
Codex 격리 TESTED      : ZIP, monitor 코드 경로, logrotate 정책, Bonus, secret scan
NEEDS-RUNTIME          : IAM/ACL, 실제 Agent, cron, 실제 logrotate, 복구·재현, evidence
PASS                   : 0 (evidence 연결 미완료)
```

격리 fixture의 `PASS`는 해당 코드 경로의 실행 결과입니다. target Ubuntu 요구사항이나 최종 미션 `PASS`로 확대 해석하지 않습니다.
