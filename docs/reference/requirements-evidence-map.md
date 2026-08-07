# B1-1 요구사항-구현-검증-증빙 대응표

이 문서는 B1-1에서 **원본 미션과 평가 요구사항을 하나도 빠뜨리지 않기 위한 마스터 추적표**입니다.

## 상태 규칙

| 상태 | 의미 |
|---|---|
| `TODO` | 실제 요구사항 구현 또는 실행이 아직 남아 있음 |
| `IMPLEMENTED` | 코드·설정·설명은 구현됐으나 실제 환경 검증 또는 증빙이 남음 |
| `TESTED` | 실제 환경에서 검증됐으나 최종 증빙 정리가 남음 |
| `PASS` | **구현 + 실제 테스트 + 증빙** 완료 |
| `BLOCKED` | 외부 환경·계정·사용자 행동 등으로 현재 완료할 수 없음 |

> 문서나 예시 파일이 존재한다는 이유만으로 `PASS` 처리하지 않습니다.

---

## 1. 환경과 기본 전제

| ID | 원본 요구사항 | 담당 문서 | 구현/설정 위치 | 검증 | 증빙 | 상태 |
|---|---|---|---|---|---|---|
| ENV-01 | Ubuntu 22.04 또는 동등 Linux 환경 | 01 | 실제 환경 | `cat /etc/os-release` | `evidence/01-environment/` | TESTED |
| ENV-02 | Bash 기반 수행 | 01, 07, 13, 15 | `scripts/*.sh` | shebang, `bash -n` | `evidence/01-environment/` | IMPLEMENTED |
| ENV-03 | systemd·sudo·필수 도구 사용 가능 | 01 | 실제 환경 | `systemctl`, `sudo`, `command -v` | `evidence/01-environment/` | TESTED |

현재 실제 검증 환경은 **Ubuntu 24.04.4 LTS**입니다. 이는 원본의 `Ubuntu 22.04 또는 동등 환경`과 구분해 기록합니다.

---

## 2. SSH 보안

| ID | 원본 요구사항 | 담당 문서 | 구현/설정 위치 | 검증 | 예상 결과 | 증빙 | 상태 |
|---|---|---|---|---|---|---|---|
| SSH-01 | SSH 포트 `20022` | 03 | `/etc/ssh/sshd_config.d/99-b1-1.conf` | `sshd -T`, `ss -lntp` | `port 20022`, LISTEN | `evidence/03-ssh/` | TESTED |
| SSH-02 | Root 원격 로그인 차단 | 03 | 같은 파일 | `sshd -T` | `permitrootlogin no` | `evidence/03-ssh/` | TESTED |
| SSH-03 | 설정 변경 전 백업·문법검사·복구 가능 | 03, 10 | SSH backup/절차 | `cmp`, `sshd -t` | 성공 | `evidence/03-ssh/` | TESTED |
| SSH-04 | 실제 일반 사용자 새 SSH 접속 확인 | 03, 13 | 실제 SSH client | `ssh -p 20022 ...` | 접속 성공 | `evidence/03-ssh/` | TODO |

---

## 3. 방화벽과 네트워크

| ID | 원본 요구사항 | 담당 문서 | 구현/설정 위치 | 검증 | 예상 결과 | 증빙 | 상태 |
|---|---|---|---|---|---|---|---|
| FW-01 | UFW 또는 firewalld 활성화 | 04 | UFW | `ufw status verbose` | `Status: active` | `evidence/04-firewall/` | TESTED |
| FW-02 | TCP `20022` 허용 | 04 | UFW rule | `ufw status verbose` | ALLOW | `evidence/04-firewall/` | TESTED |
| FW-03 | TCP `15034` 허용 | 04 | UFW rule | `ufw status verbose` | ALLOW | `evidence/04-firewall/` | TESTED |
| FW-04 | 인바운드 허용은 20022·15034만 | 04, 09 | UFW policy | `ufw status verbose` | default deny + 두 포트 | `evidence/04-firewall/` | TESTED |

---

## 4. 사용자·그룹·디렉터리·ACL

| ID | 원본 요구사항 | 담당 문서 | 구현/설정 위치 | 검증 | 예상 결과 | 증빙 | 상태 |
|---|---|---|---|---|---|---|---|
| IAM-01 | `agent-admin`, `agent-dev`, `agent-test` 생성 | 05 | OS accounts | `id`, `getent passwd` | 세 계정 존재 | `evidence/05-users-groups-acl/` | TODO |
| IAM-02 | `agent-common` = admin/dev/test | 05 | OS group | `id`, `getent group` | 세 사용자 포함 | `evidence/05-users-groups-acl/` | TODO |
| IAM-03 | `agent-core` = admin/dev | 05 | OS group | `id`, `getent group` | admin/dev만 포함 | `evidence/05-users-groups-acl/` | TODO |
| FS-01 | `$AGENT_HOME`, `upload_files`, `api_keys`, `/var/log/agent-app` | 05 | filesystem | `ls -ld`, `find` | 모두 존재 | `evidence/05-users-groups-acl/` | TODO |
| ACL-01 | `upload_files`: `agent-common` R/W | 05, 09 | chmod/setgid/ACL | `getfacl`, 쓰기 시험 | common R/W | `evidence/05-users-groups-acl/` | TODO |
| ACL-02 | `api_keys`: `agent-core`만 R/W | 05, 09 | chmod/setgid/ACL | `getfacl`, 접근 시험 | test 차단 | `evidence/05-users-groups-acl/` | TODO |
| ACL-03 | `/var/log/agent-app`: `agent-core`만 R/W | 05, 09 | chmod/setgid/ACL | `getfacl`, 접근 시험 | test 차단 | `evidence/05-users-groups-acl/` | TODO |

> 실제 현재 상태는 `agent-common`, `agent-core` **그룹 객체만 생성됨**입니다. 사용자와 그룹 멤버십은 아직 미완료이므로 IAM-02/03을 완료로 표시하지 않습니다.

---

## 5. Agent 실행환경

| ID | 원본 요구사항 | 담당 문서 | 구현/설정 위치 | 검증 | 예상 결과 | 증빙 | 상태 |
|---|---|---|---|---|---|---|---|
| AGENT-01 | `AGENT_HOME` | 06 | `config/agent.env.example` → 실제 env | `printenv` | `/home/agent-admin/agent-app` | `evidence/06-agent/` | IMPLEMENTED |
| AGENT-02 | `AGENT_PORT=15034` | 06 | 같은 env | `printenv` | `15034` | `evidence/06-agent/` | IMPLEMENTED |
| AGENT-03 | `AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files` | 06 | 같은 env | `printenv` | 경로 일치 | `evidence/06-agent/` | IMPLEMENTED |
| AGENT-04 | `AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key` | 06 | 같은 env | 경로 확인 | 경로 일치 | `evidence/06-agent/` | IMPLEMENTED |
| AGENT-05 | `AGENT_LOG_DIR=/var/log/agent-app` | 06 | 같은 env | `printenv` | 경로 일치 | `evidence/06-agent/` | IMPLEMENTED |
| KEY-01 | 지정 키 파일 생성·보호 | 06 | 실제 key file | 존재·권한 확인, 값 미노출 | 1줄·권한 정상 | `evidence/06-agent/` | TODO |
| AGENT-06 | Root가 아닌 일반 사용자 실행 | 06 | 제공 Agent | `ps` | non-root | `evidence/06-agent/` | TODO |
| AGENT-07 | Boot Sequence 5단계 `[OK]` | 06 | 제공 Agent | 실행 출력 | 5개 `[OK]` | `evidence/06-agent/` | TODO |
| AGENT-08 | `Agent READY` | 06 | 제공 Agent | 실행 출력 | READY | `evidence/06-agent/` | TODO |
| AGENT-09 | `0.0.0.0:15034` LISTEN | 06, 09 | 제공 Agent | `ss -lntp` | 15034 LISTEN | `evidence/06-agent/` | TODO |

---

## 6. `monitor.sh`

| ID | 원본 요구사항 | 담당 문서 | 구현/설정 위치 | 검증 | 예상 결과 | 증빙 | 상태 |
|---|---|---|---|---|---|---|---|
| MON-01 | `$AGENT_HOME/bin/monitor.sh` | 07 | `scripts/monitor.sh` → 배치 | 파일 확인 | 지정 위치 | `evidence/07-monitor/` | IMPLEMENTED |
| MON-02 | owner=`agent-dev`, group=`agent-core`, mode=`750` | 07 | 실제 배치 파일 | `stat` | dev:core 750 | `evidence/07-monitor/` | TODO |
| MON-03 | 프로세스 확인, 실패 시 `exit 1` | 07, 09 | `scripts/monitor.sh` | failure injection | exit 1 | `evidence/07-monitor/` | IMPLEMENTED |
| MON-04 | TCP 15034 확인, 실패 시 `exit 1` | 07, 09 | `scripts/monitor.sh` | unused-port test | exit 1 | `evidence/07-monitor/` | IMPLEMENTED |
| MON-05 | 방화벽 비활성 WARNING 후 계속 | 07, 09 | `scripts/monitor.sh` | 통제 테스트 | WARNING | `evidence/07-monitor/` | IMPLEMENTED |
| MON-06 | CPU 사용률 수집 | 07 | `scripts/monitor.sh` | 수동 실행 | 숫자 `%` | `evidence/07-monitor/` | IMPLEMENTED |
| MON-07 | MEM 사용률 수집 | 07 | `scripts/monitor.sh` | 수동 실행 | 숫자 `%` | `evidence/07-monitor/` | IMPLEMENTED |
| MON-08 | Root DISK 사용률 수집 | 07 | `scripts/monitor.sh` | 수동 실행 | 숫자 `%` | `evidence/07-monitor/` | IMPLEMENTED |
| MON-09 | CPU >20% WARNING | 07, 09 | `scripts/monitor.sh` | threshold override | WARNING | `evidence/07-monitor/` | IMPLEMENTED |
| MON-10 | MEM >10% WARNING | 07, 09 | `scripts/monitor.sh` | threshold override | WARNING | `evidence/07-monitor/` | IMPLEMENTED |
| MON-11 | DISK_USED >80% WARNING | 07, 09 | `scripts/monitor.sh` | threshold override | WARNING | `evidence/07-monitor/` | IMPLEMENTED |
| MON-12 | 지정 포맷 `monitor.log` 누적 | 07, 08 | `scripts/monitor.sh` | `tail`, regex | 형식 일치 | `evidence/08-automation/` | IMPLEMENTED |

---

## 7. 로그 관리와 cron

| ID | 원본 요구사항 | 담당 문서 | 구현/설정 위치 | 검증 | 예상 결과 | 증빙 | 상태 |
|---|---|---|---|---|---|---|---|
| LOG-01 | monitor.log `10MB / 10개` 관리 | 08, 09 | `config/agent-monitor.logrotate` | dry-run/force | 정책 일치 | `evidence/08-automation/` | IMPLEMENTED |
| CRON-01 | cron 실행 계정 `agent-admin` | 08 | `config/crontab.example` → 실제 crontab | `crontab -u agent-admin -l` | agent-admin | `evidence/08-automation/` | IMPLEMENTED |
| CRON-02 | `monitor.sh` 매분 실행 | 08, 09 | crontab example | `crontab -l` | `* * * * *` | `evidence/08-automation/` | IMPLEMENTED |
| CRON-03 | 1~2분 후 monitor.log 자동 증가 | 08, 09 | 실제 cron | 전후 줄 수/시각 | 증가 | `evidence/08-automation/` | TODO |
| CRON-04 | cron 최소 환경 정상 실행 | 08, 09, 13 | monitor env loading | `env -i` 시험 | exit 0 | `evidence/09-testing/` | TODO |

---

## 8. 설명·운영·장애 대응 평가

| ID | 평가 요구사항 | 담당 문서 | 확인 방식 | 기록 | 상태 |
|---|---|---|---|---|---|
| EVAL-01 | 프로세스·포트 명령과 선택 이유 | 07, 12 | 설명 + 코드 | `reports/execution-report.md` | IMPLEMENTED |
| EVAL-02 | CPU/MEM/DISK 추출·파싱과 로그 포맷 이유 | 07, 12 | 설명 + 코드 | 같은 보고서 | IMPLEMENTED |
| EVAL-03 | owner/dev, executor/admin, core 권한 정책 | 05, 07, 12 | 설명 | 같은 보고서 | IMPLEMENTED |
| EVAL-04 | 10MB/10개 로그 관리 구현 이유 | 08, 12 | 설명 | 같은 보고서 | IMPLEMENTED |
| EVAL-05 | SSH 포트 변경·Root 차단 위협 모델 | 03, 12 | 설명 | 같은 보고서 | IMPLEMENTED |
| EVAL-06 | `agent-core` 제한과 최소 권한 | 05, 12 | 설명 | 같은 보고서 | IMPLEMENTED |
| EVAL-07 | WARNING과 즉시 실패 분리 이유 | 07, 12 | 설명 | 같은 보고서 | IMPLEMENTED |
| EVAL-08 | `>`와 `>>` 차이 | 07, 08, 12 | 설명 | 같은 보고서 | IMPLEMENTED |
| EVAL-09 | Nginx 등 다른 서비스로 확장 | 10, 12 | 응용 설명 | `reports/troubleshooting-report.md` | IMPLEMENTED |
| EVAL-10 | 프로세스 있음/포트 없음 진단 | 09, 10, 12 | 장애 설명 | 같은 보고서 | IMPLEMENTED |
| EVAL-11 | 로그 급증·디스크 부족 단기/중기 대응 | 10, 12 | 장애 설명 | 같은 보고서 | IMPLEMENTED |

> 실제 평가에서 말로 설명하고 구현·증빙과 연결하는 확인은 14장에서 최종 수행합니다.

---

## 9. 테스트·제출·재현

| ID | 요구사항 | 담당 문서 | 구현/검증 위치 | 증빙/결과 | 상태 |
|---|---|---|---|---|---|
| TEST-01 | 정상·장애·복구 테스트 매트릭스 | 09 | `tests/test-cases.md` | `reports/test-results.md` | IMPLEMENTED |
| TEST-02 | 장애 후 정상 복구 재확인 | 09 | 실제 Ubuntu | `evidence/09-testing/` | TODO |
| SUB-01 | 요구사항 수행 내역서 완성 | 11, 14 | `reports/execution-report.md` | 최종 보고서 | TODO |
| SUB-02 | 필수 증거 자료 완성 | 11, 14 | `evidence/` | evidence inventory | TODO |
| SUB-03 | 평가문항 전체 대조 | 12, 14 | 평가 체크 | `reports/final-checklist.md` | IMPLEMENTED |
| REP-01 | 새 환경에서 처음부터 재현 | 13 | `preflight.sh`, `verify.sh` | `reports/test-results.md` | TODO |
| REP-02 | 최종 제출 상태 비밀정보 미추적 | 13, 14 | `verify.sh`, Git 검사 | `reports/final-checklist.md` | IMPLEMENTED |
| VERIFY-01 | read-only 사전 점검 | 13 | `scripts/preflight.sh` | 실행 결과 | IMPLEMENTED |
| VERIFY-02 | read-only 최종 검증 | 13, 14 | `scripts/verify.sh` | 최종 결과 | IMPLEMENTED |
| AUDIT-01 | Codex 독립 검증 | 14 | 원본+repo 전체 | Codex review | TODO |
| ACCEPT-01 | 사용자 최종 인수 검증 | 14 | 실제 환경 | final evidence | TODO |

---

## 10. 보너스 과제

보너스는 삭제하지 않고 원본 미션의 선택 과제를 실제 코드로 구현합니다.

| ID | 보너스 요구사항 | 담당 문서 | 구현 위치 | 검증 | 상태 |
|---|---|---|---|---|---|
| BONUS-01 | `report.sh` 요약 리포트 | 15 | `scripts/report.sh` | fixture/실로그 | IMPLEMENTED |
| BONUS-02 | CPU/MEM/DISK 평균·최대·최소·샘플 수 | 15 | `scripts/report.sh` | 기준 데이터 비교 | IMPLEMENTED |
| BONUS-03 | 선택 시간 구간 분석 | 15 | `scripts/report.sh` | start/end 시험 | IMPLEMENTED |
| BONUS-04 | 7일 경과 `.log` 압축 | 15 | `scripts/archive-logs.sh` | fixture mtime | IMPLEMENTED |
| BONUS-05 | `/var/log/monitor/agent-app/archive/` 이동 | 15 | `scripts/archive-logs.sh` | 위치 확인 | IMPLEMENTED |
| BONUS-06 | 30일 경과 `.gz` 삭제 | 15 | `scripts/archive-logs.sh` | fixture 삭제 | IMPLEMENTED |
| BONUS-07 | 예외 처리·Dry Run | 15 | 두 bonus scripts | 오류 입력·DRY_RUN | IMPLEMENTED |

---

## 11. 현재 상태 요약

| 영역 | 상태 |
|---|---|
| 환경 | TESTED |
| SSH | TESTED — 외부 새 접속 증빙 남음 |
| UFW | TESTED |
| 사용자·그룹·ACL | TODO — 그룹 객체 2개만 생성됨 |
| Agent | 설정 코드 IMPLEMENTED / 실제 실행 TODO |
| monitor.sh | IMPLEMENTED / 실제 runtime TODO |
| cron·logrotate | IMPLEMENTED / 실제 설치·runtime TODO |
| 테스트 | IMPLEMENTED / 실제 실행 TODO |
| 평가 설명 | IMPLEMENTED |
| 재현 도구 | IMPLEMENTED / 전체 재현 TODO |
| 증빙 | TODO |
| Codex audit | TODO |
| 사용자 인수 | TODO |
| Bonus | IMPLEMENTED / fixture·실환경 TEST TODO |

---

## 최종 PASS 조건

B1-1 필수 미션은 다음을 모두 만족할 때 최종 `PASS`로 처리합니다.

1. 모든 **필수 요구사항** 행이 `PASS`
2. 평가문항 설명·응용 항목을 실제 구현과 연결해 설명 가능
3. 실제 환경 검증 및 증빙 확보
4. 재현 시험 통과
5. 저장소에 비밀정보가 포함되지 않음
6. 요구사항 수행 내역서와 `monitor.sh` 제출 준비 완료
7. Codex 독립 검증의 BLOCKER/MAJOR 해결
8. 사용자 최종 인수 검증 통과

보너스는 필수 PASS와 별도 상태로 유지하되, **삭제하지 않고 구현·테스트·증빙까지 계속 관리**합니다.
