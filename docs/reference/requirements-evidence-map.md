# B1-1 요구사항-구현-검증-증빙 대응표

이 문서는 B1-1의 **원본 미션 → 구현 → 테스트 → 증빙 → 평가**를 한 행 단위로 추적하는 마스터 표입니다.

## 상태 규칙

| 상태 | 의미 |
|---|---|
| `TODO` | 실제 요구사항 구현 또는 실행이 남아 있음 |
| `IMPLEMENTED` | 코드·설정·설명은 구현됐으나 실제 환경 검증/증빙이 남음 |
| `TESTED` | 실제 환경 검증은 했으나 최종 evidence 정리가 남음 |
| `PASS` | 구현 + 실제 테스트 + evidence 연결 완료 |
| `BLOCKED` | 외부 환경/선행조건 때문에 현재 완료 불가 |

> 문서가 존재하거나 예상 출력이 맞는다는 이유만으로 `PASS` 처리하지 않습니다.

---

## 1. 환경

| ID | 원본 요구사항 | 구현/검증 | evidence | 상태 |
|---|---|---|---|---|
| ENV-01 | Ubuntu 22.04 또는 동등 Linux | `docs/01`, `/etc/os-release` | `evidence/01-environment/` | TESTED |
| ENV-02 | 자동화 스크립트 Bash | `scripts/*.sh`, `bash -n` | `evidence/01-environment/` 또는 정적검증 기록 | IMPLEMENTED |
| ENV-03 | 필요한 경우만 sudo, 일반 계정 중심 | 문서/실행 절차 | 수행 기록 | IMPLEMENTED |
| ENV-04 | 제공 Agent 아키텍처 호환 | `uname -m`, `unzip -l` | `evidence/06-agent/` | TODO |

현재 실제 사례는 Ubuntu 24.04.4 LTS / x86_64이며, 원본 기준을 24.04로 변경하지 않습니다.

---

## 2. SSH

| ID | 요구사항 | 구현/검증 | evidence | 상태 |
|---|---|---|---|---|
| SSH-01 | Port 20022 | `99-b1-1.conf`, `sshd -T`, `ss` | `evidence/03-ssh/` | TESTED |
| SSH-02 | Root 원격 로그인 차단 | `PermitRootLogin no`, `sshd -T` | `evidence/03-ssh/` | TESTED |
| SSH-03 | 설정 문법 정상 | `sshd -t` | `evidence/03-ssh/` | TESTED |
| SSH-04 | 실제 20022 LISTEN, 22 미LISTEN | `ss -lntp` | `evidence/03-ssh/` | TESTED |
| SSH-05 | 일반 사용자 새 SSH 접속 | `ssh -p 20022 ...` | `evidence/03-ssh/` | TODO |
| SSH-06 | 변경 전 백업/복구 경로 | `docs/03`, backup/cmp | `evidence/03-ssh/` | TESTED |

---

## 3. 방화벽

| ID | 요구사항 | 구현/검증 | evidence | 상태 |
|---|---|---|---|---|
| FW-01 | UFW 또는 firewalld 활성 | UFW, `ufw status verbose` | `evidence/04-firewall/` | TESTED |
| FW-02 | TCP 20022 허용 | UFW rule | `evidence/04-firewall/` | TESTED |
| FW-03 | TCP 15034 허용 | UFW rule | `evidence/04-firewall/` | TESTED |
| FW-04 | 인바운드 허용은 두 포트만 | default deny + allow list 확인 | `evidence/04-firewall/` | TESTED |

---

## 4. 사용자·그룹·디렉터리·ACL

| ID | 요구사항 | 구현/검증 | evidence | 상태 |
|---|---|---|---|---|
| IAM-01 | agent-admin 생성 | `id`, `getent` | `evidence/05-users-groups-acl/` | TODO |
| IAM-02 | agent-dev 생성 | 같은 방식 | 같은 위치 | TODO |
| IAM-03 | agent-test 생성 | 같은 방식 | 같은 위치 | TODO |
| IAM-04 | agent-common = admin+dev+test | `id`, `getent group` | 같은 위치 | TODO |
| IAM-05 | agent-core = admin+dev | `id`, `getent group` | 같은 위치 | TODO |
| FS-01 | `$AGENT_HOME` 존재 | `ls -ld` | 같은 위치 | TODO |
| FS-02 | `upload_files` 존재 | `ls -ld` | 같은 위치 | TODO |
| FS-03 | `api_keys` 존재 | `ls -ld` | 같은 위치 | TODO |
| FS-04 | `/var/log/agent-app` 존재 | `ls -ld` | 같은 위치 | TODO |
| ACL-01 | upload_files: group=agent-common, R/W | `stat`, `getfacl`, agent-test 쓰기 시험 | 같은 위치 | TODO |
| ACL-02 | api_keys: agent-core ONLY, R/W | `stat`, `getfacl`, agent-test 차단 | 같은 위치 | TODO |
| ACL-03 | log dir: agent-core ONLY, R/W | 같은 검증 | 같은 위치 | TODO |
| ACL-04 | 부모 홈 통과 권한이 최소 범위로 허용 | `/home/agent-admin` ACL 확인 | 같은 위치 | TODO |

현재 실제 상태는 `agent-common`, `agent-core` **그룹 객체만 생성**된 중간 상태입니다.

---

## 5. Agent 실행환경

원본 데이터 설명은 제공 실행 대상에 `agent-app-linux-x86`, `agent-app-linux-arm64`를 명시합니다. 실제 ZIP 내부 경로는 실행 전에 `unzip -l`로 확인합니다.

| ID | 요구사항 | 구현/검증 | evidence | 상태 |
|---|---|---|---|---|
| AGENT-01 | `AGENT_HOME` | `config/agent.env.example` → 실제 env | `evidence/06-agent/` | IMPLEMENTED |
| AGENT-02 | `AGENT_PORT=15034` | 같은 env | 같은 위치 | IMPLEMENTED |
| AGENT-03 | `AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files` | 같은 env | 같은 위치 | IMPLEMENTED |
| AGENT-04 | `AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key` | 같은 env | 같은 위치 | IMPLEMENTED |
| AGENT-05 | `AGENT_LOG_DIR=/var/log/agent-app` | 같은 env | 같은 위치 | IMPLEMENTED |
| AGENT-06 | 실제 ZIP 구조/아키텍처용 실행 파일 확인 | `uname -m`, `unzip -l`, `file` | 같은 위치 | TODO |
| KEY-01 | 지정 key 파일 1줄 생성 | 실제 로컬 입력, 값 미출력 | 같은 위치 | TODO |
| KEY-02 | key owner/group/mode 보호 | `agent-admin:agent-core:660` | 같은 위치 | TODO |
| AGENT-07 | Root가 아닌 일반 계정 실행 | `ps` | 같은 위치 | TODO |
| AGENT-08 | Boot Sequence 5단계 `[OK]` | 실행 출력 | 같은 위치 | TODO |
| AGENT-09 | `Agent READY` | 실행 출력 | 같은 위치 | TODO |
| AGENT-10 | `0.0.0.0:15034` LISTEN | `ss -lntp` | 같은 위치 | TODO |
| AGENT-11 | Agent 배치가 api_keys ACL을 훼손하지 않음 | 재귀 `chown -R` 금지, 배치 후 stat/getfacl | 같은 위치 | IMPLEMENTED |

---

## 6. `monitor.sh`

| ID | 요구사항 | 구현/검증 | evidence | 상태 |
|---|---|---|---|---|
| MON-01 | `$AGENT_HOME/bin/monitor.sh` | `scripts/monitor.sh` → 실제 배치 | `evidence/07-monitor/` | IMPLEMENTED |
| MON-02 | owner=agent-dev | `stat` | 같은 위치 | TODO |
| MON-03 | group=agent-core | `stat` | 같은 위치 | TODO |
| MON-04 | mode=750 | `stat` | 같은 위치 | TODO |
| MON-05 | cron executor=agent-admin | group membership + crontab | `evidence/08-automation/` | TODO |
| MON-06 | 제공 앱 파일명 기준 process 확인 | `AGENT_PROCESS_PATTERN`, 아키텍처 기본값 | `evidence/07-monitor/` | IMPLEMENTED |
| MON-07 | process 실패 → exit 1 | `acceptance-test.sh` | 같은 위치 | IMPLEMENTED |
| MON-08 | TCP 15034 실패 → exit 1 | `acceptance-test.sh` | 같은 위치 | IMPLEMENTED |
| MON-09 | firewall inactive → WARNING 후 계속 | 통제 테스트 | 같은 위치 | IMPLEMENTED |
| MON-10 | CPU 사용률 | `/proc/stat` delta | 같은 위치 | IMPLEMENTED |
| MON-11 | MEM 사용률 | `MemTotal/MemAvailable` | 같은 위치 | IMPLEMENTED |
| MON-12 | Root DISK Used % | `df -P /` | 같은 위치 | IMPLEMENTED |
| MON-13 | CPU >20 WARNING | threshold test | 같은 위치 | IMPLEMENTED |
| MON-14 | MEM >10 WARNING | threshold test | 같은 위치 | IMPLEMENTED |
| MON-15 | DISK >80 WARNING | threshold test | 같은 위치 | IMPLEMENTED |
| MON-16 | 지정 monitor.log 포맷 | regex | `evidence/08-automation/` | IMPLEMENTED |
| MON-17 | append 누적 | `>>` / line-count test | 같은 위치 | IMPLEMENTED |
| MON-18 | 로그 파일 쓰기 실패를 성공으로 숨기지 않음 | 기존 파일 writable + append 결과 검사, exit 2 | `evidence/07-monitor/` | IMPLEMENTED |

---

## 7. cron·로그 용량 관리

| ID | 요구사항 | 구현/검증 | evidence | 상태 |
|---|---|---|---|---|
| CRON-01 | agent-admin crontab | `config/crontab.example` | `evidence/08-automation/` | IMPLEMENTED |
| CRON-02 | 매분 실행 | `* * * * *` | 같은 위치 | IMPLEMENTED |
| CRON-03 | 1~2분 내 자동 로그 증가 | acceptance observation | 같은 위치 | TODO |
| CRON-04 | 최소 cron 환경 동작 | `env -i` | `evidence/09-testing/` | TODO |
| LOG-01 | 10MB 기준 회전 | `size 10M` | `evidence/08-automation/` | IMPLEMENTED |
| LOG-02 | 최대 10개 파일 | strict policy: current 1 + rotated 9 | 같은 위치 | IMPLEMENTED |
| LOG-03 | 회전 후 core R/W 유지 | `create 0660 agent-admin agent-core` | 같은 위치 | IMPLEMENTED |
| LOG-04 | logrotate 실제 설정 파싱 | `logrotate -d` | 같은 위치 | TODO |
| LOG-05 | 강제 회전 후 monitor 재기록 | 통제 테스트 | 같은 위치 | TODO |

---

## 8. 평가 항목 2~4 설명

| ID | 평가 요구사항 | 담당 | 상태 |
|---|---|---|---|
| EVAL-01 | pgrep/ps와 ss 선택 이유 | `docs/07`, `docs/12` | IMPLEMENTED |
| EVAL-02 | CPU/MEM/DISK 추출·파싱 설명 | `docs/07`, `docs/12` | IMPLEMENTED |
| EVAL-03 | 로그 포맷 고정 이유 | 같은 문서 | IMPLEMENTED |
| EVAL-04 | owner dev / executor admin / core 권한 설명 | `docs/05`,`07`,`12` | IMPLEMENTED |
| EVAL-05 | 10MB/10개 구현 방식 설명 | `docs/08`,`12` | IMPLEMENTED |
| EVAL-06 | SSH 포트 변경과 Root 차단 위협 모델 | `docs/03`,`12` | IMPLEMENTED |
| EVAL-07 | agent-core 최소 권한 설명 | `docs/05`,`12` | IMPLEMENTED |
| EVAL-08 | WARNING과 exit 1 분리 이유 | `docs/07`,`12` | IMPLEMENTED |
| EVAL-09 | `>`와 `>>` 차이 | `docs/07`,`12` | IMPLEMENTED |
| EVAL-10 | Nginx 등 다른 서비스 확장 | `docs/10`,`12` | IMPLEMENTED |
| EVAL-11 | 프로세스 있음/포트 없음 진단 | `docs/09`,`10`,`12` | IMPLEMENTED |
| EVAL-12 | 로그 급증/디스크 부족 단기·중기 대응 | `docs/10`,`12` | IMPLEMENTED |

실제 평가 `PASS`는 위 설명이 실제 구현·증빙과 연결된 뒤 부여합니다.

---

## 9. 테스트·재현·제출

| ID | 요구사항 | 구현/검증 | 상태 |
|---|---|---|---|
| TEST-01 | 정상/장애/복구 테스트 정의 | `tests/test-cases.md` T-001~T-040 | IMPLEMENTED |
| TEST-02 | 테스트 결과 1:1 기록 | `reports/test-results.md` | IMPLEMENTED |
| TEST-03 | 실제 트러블슈팅 기록 | `reports/troubleshooting-report.md` | IMPLEMENTED |
| REP-01 | 사전 점검 | `scripts/preflight.sh` | IMPLEMENTED |
| REP-02 | read-only 현재 상태 확인 | `scripts/verify.sh` | IMPLEMENTED |
| REP-03 | runtime acceptance | `scripts/acceptance-test.sh` | IMPLEMENTED |
| REP-04 | 새 세션/재부팅 재현 | `docs/13` | TODO |
| REP-05 | 가능하면 깨끗한 Ubuntu 재현 | `docs/13` | TODO |
| SUB-01 | 요구사항 수행 내역서 | `reports/execution-report.md` | IMPLEMENTED |
| SUB-02 | 필수 evidence 완성 | `evidence/` | TODO |
| SUB-03 | 최종 checklist | `reports/final-checklist.md` | IMPLEMENTED |
| SUB-04 | 실제 secret file 미추적 | `verify.sh` + Git 검토 | TODO |
| SUB-05 | Codex 독립 감사 | `reports/codex-review.md` 예정 | TODO |
| SUB-06 | 사용자 최종 인수 | 최종 시연 | TODO |

---

## 10. 보너스

| ID | 보너스 요구사항 | 구현 | 검증 | 상태 |
|---|---|---|---|---|
| BONUS-01 | CPU/MEM/DISK 평균·최대·최소·샘플 수 | `scripts/report.sh` | fixture | IMPLEMENTED |
| BONUS-02 | 시간 구간 분석 | `scripts/report.sh` | fixture | IMPLEMENTED |
| BONUS-03 | 7일 경과 `.log` 압축 | `scripts/archive-logs.sh` | fixture | IMPLEMENTED |
| BONUS-04 | archive 이동 | 같은 스크립트 | fixture | IMPLEMENTED |
| BONUS-05 | 30일 경과 `.gz` 삭제 | 같은 스크립트 | fixture | IMPLEMENTED |
| BONUS-06 | 미존재/권한/대상0/명령 오류 처리 | 같은 스크립트 | fixture | IMPLEMENTED |
| BONUS-07 | find/gzip/mv/rm 실패를 숨기지 않음 | 같은 스크립트 | fixture | IMPLEMENTED |

---

## 최종 PASS 게이트

B1-1 필수 미션은 다음이 모두 충족되어야 `PASS`입니다.

```text
1. 필수 요구사항 구현
2. 실제 runtime 테스트
3. evidence 연결
4. 평가 설명과 실제 구현 일치
5. 재현 시험
6. 비밀정보 미노출
7. Codex 독립 검토의 BLOCKER/MAJOR 해결
8. 사용자 최종 인수 검증
```

보너스는 삭제하지 않으며 별도 상태로 끝까지 추적합니다.
