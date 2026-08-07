# B1-1 요구사항-구현-검증-증빙 대응표

이 문서는 B1-1에서 **요구사항을 하나도 빠뜨리지 않기 위한 마스터 추적표**입니다.

## 상태 규칙

- `TODO`: 아직 구현 전
- `IMPLEMENTED`: 구현은 되었으나 실제 검증 또는 증빙이 부족함
- `TESTED`: 실제 검증은 통과했으나 증빙 정리가 남음
- `PASS`: **구현 + 테스트 + 증빙**을 모두 충족
- `BLOCKED`: 외부 환경·계정·사용자 행동 등으로 현재 완료할 수 없음

> 문서를 작성했다는 사실만으로 `PASS` 처리하지 않습니다.

## 1. 환경과 기본 전제

| ID | 원본 요구사항 | 담당 문서 | 구현/설정 위치 | 검증 방법 | 증빙 위치 | 상태 |
|---|---|---|---|---|---|---|
| ENV-01 | Ubuntu 22.04 또는 동등 Linux 환경 | 01 | 실제 실습 환경 | `cat /etc/os-release` | `evidence/01-environment/` | TESTED |
| ENV-02 | Bash 기반 수행 | 01, 07 | `scripts/*.sh` | shebang·실행 셸 확인 | `evidence/01-environment/` | TODO |
| ENV-03 | systemd·sudo·필수 도구 사용 가능 | 01 | 실제 실습 환경 | `systemctl --version`, `sudo -v`, `command -v ...` | `evidence/01-environment/` | TESTED |

현재 실제 검증 환경은 Ubuntu 24.04.4 LTS이며, 이는 원본의 `Ubuntu 22.04 또는 동등 환경` 조건과 구분해 기록합니다.

## 2. SSH 보안

| ID | 원본 요구사항 | 담당 문서 | 구현/설정 위치 | 검증 방법 | 예상 결과 | 증빙 위치 | 상태 |
|---|---|---|---|---|---|---|---|
| SSH-01 | SSH 포트 `20022` 사용 | 03 | `/etc/ssh/sshd_config.d/99-b1-1.conf` | `sudo sshd -T`, `sudo ss -lntp` | `port 20022`, LISTEN 20022 | `evidence/03-ssh/` | TESTED |
| SSH-02 | Root 원격 로그인 차단 | 03 | `/etc/ssh/sshd_config.d/99-b1-1.conf` | `sudo sshd -T` | `permitrootlogin no` | `evidence/03-ssh/` | TESTED |
| SSH-03 | SSH 설정 변경 전 백업·문법검사·복구 가능 | 03, 10 | SSH 백업 파일·복구 절차 | `cmp`, `sshd -t` | 백업 동일, 문법 성공 | `evidence/03-ssh/` | TESTED |

## 3. 방화벽과 네트워크

| ID | 원본 요구사항 | 담당 문서 | 구현/설정 위치 | 검증 방법 | 예상 결과 | 증빙 위치 | 상태 |
|---|---|---|---|---|---|---|---|
| FW-01 | UFW 또는 firewalld 활성화 | 04 | UFW | `sudo ufw status verbose` | `Status: active` | `evidence/04-firewall/` | TESTED |
| FW-02 | TCP `20022` 허용 | 04 | UFW rule | `sudo ufw status verbose` | `20022/tcp ALLOW` | `evidence/04-firewall/` | TESTED |
| FW-03 | TCP `15034` 허용 | 04 | UFW rule | `sudo ufw status verbose` | `15034/tcp ALLOW` | `evidence/04-firewall/` | TESTED |
| FW-04 | 인바운드 허용 포트는 20022·15034만 | 04, 09 | UFW policy | `sudo ufw status verbose` | default deny, 두 포트만 허용 | `evidence/04-firewall/` | TESTED |

## 4. 사용자·그룹·디렉터리·ACL

| ID | 원본 요구사항 | 담당 문서 | 구현/설정 위치 | 검증 방법 | 예상 결과 | 증빙 위치 | 상태 |
|---|---|---|---|---|---|---|---|
| IAM-01 | `agent-admin`, `agent-dev`, `agent-test` 생성 | 05 | OS accounts | `id` / `getent passwd` | 세 계정 존재 | `evidence/05-users-groups-acl/` | TODO |
| IAM-02 | `agent-common` = admin/dev/test | 05 | OS group | `getent group`, `id` | 세 사용자 포함 | `evidence/05-users-groups-acl/` | IMPLEMENTED |
| IAM-03 | `agent-core` = admin/dev | 05 | OS group | `getent group`, `id` | admin/dev만 포함 | `evidence/05-users-groups-acl/` | IMPLEMENTED |
| FS-01 | `$AGENT_HOME`, `upload_files`, `api_keys`, `/var/log/agent-app` 구성 | 05 | 파일시스템 | `find`, `ls -ld` | 요구 디렉터리 존재 | `evidence/05-users-groups-acl/` | TODO |
| ACL-01 | `upload_files`: group=`agent-common`, R/W | 05 | 권한/ACL | `ls -ld`, `getfacl`, 사용자별 쓰기 시험 | common 멤버 R/W | `evidence/05-users-groups-acl/` | TODO |
| ACL-02 | `api_keys`: `agent-core`만 R/W | 05 | 권한/ACL | `getfacl`, 사용자별 접근 시험 | test 접근 거부 | `evidence/05-users-groups-acl/` | TODO |
| ACL-03 | `/var/log/agent-app`: `agent-core`만 R/W | 05 | 권한/ACL | `getfacl`, 사용자별 접근 시험 | test 접근 거부 | `evidence/05-users-groups-acl/` | TODO |

## 5. Agent 실행환경

| ID | 원본 요구사항 | 담당 문서 | 구현/설정 위치 | 검증 방법 | 예상 결과 | 증빙 위치 | 상태 |
|---|---|---|---|---|---|---|---|
| AGENT-01 | `AGENT_HOME` 설정 | 06 | `config/agent.env.example` / 실제 환경 | `env`, `printenv` | 경로 일치 | `evidence/06-agent/` | TODO |
| AGENT-02 | `AGENT_PORT=15034` | 06 | 환경변수 | `printenv AGENT_PORT` | `15034` | `evidence/06-agent/` | TODO |
| AGENT-03 | `AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files` | 06 | 환경변수 | `printenv` | 경로 일치 | `evidence/06-agent/` | TODO |
| AGENT-04 | `AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key` | 06 | 환경변수 | 경로·권한 확인 | 키 경로 일치 | `evidence/06-agent/` | TODO |
| AGENT-05 | `AGENT_LOG_DIR=/var/log/agent-app` | 06 | 환경변수 | `printenv` | 경로 일치 | `evidence/06-agent/` | TODO |
| KEY-01 | 키 파일 생성, 내용은 저장소/증빙에서 마스킹 | 06 | 실제 key file | 존재·권한·비밀값 마스킹 확인 | 파일 존재, secret 미노출 | `evidence/06-agent/` | TODO |
| AGENT-06 | Agent를 Root가 아닌 일반 사용자로 실행 | 06 | 제공 Agent | 프로세스 소유자 확인 | non-root | `evidence/06-agent/` | TODO |
| AGENT-07 | Boot Sequence 5단계 `[OK]` | 06 | 제공 Agent | 실행 출력 | 5단계 모두 `[OK]` | `evidence/06-agent/` | TODO |
| AGENT-08 | `Agent READY` 출력 | 06 | 제공 Agent | 실행 출력 | `Agent READY` | `evidence/06-agent/` | TODO |
| AGENT-09 | `0.0.0.0:15034` LISTEN | 06, 09 | 제공 Agent | `ss -lntp` | 15034 LISTEN | `evidence/06-agent/` | TODO |

## 6. `monitor.sh`

| ID | 원본 요구사항 | 담당 문서 | 구현/설정 위치 | 검증 방법 | 예상 결과 | 증빙 위치 | 상태 |
|---|---|---|---|---|---|---|---|
| MON-01 | `$AGENT_HOME/bin/monitor.sh` | 07 | `scripts/monitor.sh` → 실제 배치 | 파일 존재 확인 | 지정 위치 | `evidence/07-monitor/` | TODO |
| MON-02 | owner=`agent-dev`, group=`agent-core`, mode=`750` | 07 | 실제 파일 권한 | `stat`, `ls -l` | `agent-dev:agent-core`, 750 | `evidence/07-monitor/` | TODO |
| MON-03 | Agent 프로세스 상태 확인, 실패 시 `exit 1` | 07, 09 | `scripts/monitor.sh` | 프로세스 정상/중지 테스트 | 비정상 exit 1 | `evidence/07-monitor/` | TODO |
| MON-04 | TCP 15034 LISTEN 확인, 실패 시 `exit 1` | 07, 09 | `scripts/monitor.sh` | 포트 정상/실패 테스트 | 비정상 exit 1 | `evidence/07-monitor/` | TODO |
| MON-05 | 방화벽 비활성 시 WARNING, 종료하지 않음 | 07, 09 | `scripts/monitor.sh` | UFW 상태 모의/실제 테스트 | WARNING 후 계속 | `evidence/07-monitor/` | TODO |
| MON-06 | CPU 사용률 수집 | 07 | `scripts/monitor.sh` | 수동 실행 | 숫자 `%` | `evidence/07-monitor/` | TODO |
| MON-07 | 메모리 사용률 수집 | 07 | `scripts/monitor.sh` | 수동 실행 | 숫자 `%` | `evidence/07-monitor/` | TODO |
| MON-08 | Root 디스크 사용률 수집 | 07 | `scripts/monitor.sh` | 수동 실행 | 숫자 `%` | `evidence/07-monitor/` | TODO |
| MON-09 | CPU >20% 경고 | 07, 09 | `scripts/monitor.sh` | 임계값 테스트 | `[WARNING]` | `evidence/07-monitor/` | TODO |
| MON-10 | MEM >10% 경고 | 07, 09 | `scripts/monitor.sh` | 임계값 테스트 | `[WARNING]` | `evidence/07-monitor/` | TODO |
| MON-11 | DISK_USED >80% 경고 | 07, 09 | `scripts/monitor.sh` | 임계값 테스트 | `[WARNING]` | `evidence/07-monitor/` | TODO |
| MON-12 | 지정 포맷으로 `monitor.log` 누적 | 07, 08 | `scripts/monitor.sh` | `tail`·정규식 확인 | `[YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%` | `evidence/08-automation/` | TODO |

## 7. 로그 관리와 cron

| ID | 원본 요구사항 | 담당 문서 | 구현/설정 위치 | 검증 방법 | 예상 결과 | 증빙 위치 | 상태 |
|---|---|---|---|---|---|---|---|
| LOG-01 | monitor.log 최대 10MB / 최대 10개 관리 | 08, 09 | `config/agent-monitor.logrotate` 또는 스크립트 | logrotate dry-run/강제시험 | 정책 일치 | `evidence/08-automation/` | TODO |
| CRON-01 | cron 실행 계정 `agent-admin` | 08 | `config/crontab.example` / 실제 crontab | `sudo -u agent-admin crontab -l` | agent-admin 등록 | `evidence/08-automation/` | TODO |
| CRON-02 | `monitor.sh` 매분 실행 | 08, 09 | crontab | crontab 확인 | `* * * * *` | `evidence/08-automation/` | TODO |
| CRON-03 | 1~2분 후 monitor.log 자동 증가 | 08, 09 | 실제 cron | 전후 `stat`/`tail` 비교 | 새 로그 누적 | `evidence/08-automation/` | TODO |
| CRON-04 | cron 최소 환경에서도 정상 실행 | 08, 09, 13 | 스크립트/환경설정 | 최소 PATH 환경 재현 | 정상 동작 | `evidence/09-testing/` | TODO |

## 8. 설명·운영·장애 대응 평가

| ID | 평가 요구사항 | 담당 문서 | 확인 방식 | 증빙/기록 | 상태 |
|---|---|---|---|---|---|
| EVAL-01 | 프로세스·포트 확인 명령과 선택 이유 설명 | 07, 12 | 구두/문서 설명 | `reports/execution-report.md` | TODO |
| EVAL-02 | CPU/MEM/DISK 추출·파싱 방식과 로그 포맷 이유 설명 | 07, 12 | 구두/문서 설명 | `reports/execution-report.md` | TODO |
| EVAL-03 | owner/dev, executor/admin, group/core 권한 정책 설명 | 05, 07, 12 | 구두/문서 설명 | `reports/execution-report.md` | TODO |
| EVAL-04 | 10MB/10개 로그 관리 구현 이유 설명 | 08, 12 | 구두/문서 설명 | `reports/execution-report.md` | TODO |
| EVAL-05 | SSH 포트 변경·Root 차단의 위협 모델 설명 | 03, 12 | 구두/문서 설명 | `reports/execution-report.md` | TODO |
| EVAL-06 | `agent-core` 제한과 최소 권한 원칙 설명 | 05, 12 | 구두/문서 설명 | `reports/execution-report.md` | TODO |
| EVAL-07 | WARNING 항목과 즉시 실패 항목을 나눈 운영 이유 설명 | 07, 12 | 구두/문서 설명 | `reports/execution-report.md` | TODO |
| EVAL-08 | `>`와 `>>` 차이 및 로그 누적 이유 설명 | 07, 08, 12 | 구두/문서 설명 | `reports/execution-report.md` | TODO |
| EVAL-09 | Nginx 등 다른 서비스로 변경 시 수정 항목 설명 | 10, 12 | 응용 질문 | `reports/troubleshooting-report.md` | TODO |
| EVAL-10 | 프로세스 실행/포트 미오픈 장애의 원인·확인 순서 설명 | 09, 10, 12 | 장애 시나리오 | `reports/troubleshooting-report.md` | TODO |
| EVAL-11 | 로그 급증·디스크 부족의 단기/중기 대응 설명 | 10, 12 | 장애 시나리오 | `reports/troubleshooting-report.md` | TODO |

## 9. 제출·재현

| ID | 요구사항 | 담당 문서 | 검증 방법 | 증빙/결과 | 상태 |
|---|---|---|---|---|---|
| SUB-01 | 요구사항 수행 내역서 완성 | 11, 14 | 원본 요구사항과 대조 | `reports/execution-report.md` | TODO |
| SUB-02 | 필수 증거 자료 완성 | 11, 14 | evidence inventory | `evidence/` | TODO |
| SUB-03 | 평가문항 전체 대조 | 12, 14 | 평가 체크리스트 | `reports/final-checklist.md` | TODO |
| REP-01 | 깨끗한 환경에서 처음부터 재현 | 13 | `preflight.sh`, `verify.sh`, 수동 절차 | `reports/test-results.md` | TODO |
| REP-02 | 최종 제출 상태에서 비밀정보 미추적 | 13, 14 | `git grep`, `.gitignore` 확인 | `reports/final-checklist.md` | TODO |

## 10. 보너스 과제

보너스는 삭제하지 않으며, 필수 요구사항을 손상시키지 않는 범위에서 **실제 구현·검증 대상**으로 유지합니다.

| ID | 보너스 요구사항 | 담당 문서 | 구현 위치 | 검증 방법 | 상태 |
|---|---|---|---|---|---|
| BONUS-01 | `report.sh` 요약 리포트 | 15 | `scripts/report.sh` 예정 | 샘플 로그 분석 | TODO |
| BONUS-02 | CPU/MEM/DISK 평균·최대·최소·샘플 수 | 15 | `scripts/report.sh` 예정 | 기준 데이터와 비교 | TODO |
| BONUS-03 | 선택 시간 구간 분석 | 15 | `scripts/report.sh` 예정 | 시작/종료 입력 테스트 | TODO |
| BONUS-04 | 7일 경과 로그 압축 | 15 | 보존 스크립트/설정 예정 | fixture 파일 시간 조작 테스트 | TODO |
| BONUS-05 | archive 디렉터리 이동 | 15 | `/var/log/monitor/agent-app/archive/` | 압축 후 위치 확인 | TODO |
| BONUS-06 | 30일 경과 `.gz` 삭제 | 15 | 보존 스크립트/설정 예정 | fixture 삭제 테스트 | TODO |
| BONUS-07 | 보너스 예외 처리 | 15 | 관련 스크립트 | 잘못된 입력·파일 테스트 | TODO |

## 최종 PASS 조건

B1-1은 다음을 모두 만족할 때 최종 `PASS`로 처리합니다.

1. 필수 요구사항 행이 모두 `PASS`
2. 평가문항 설명·응용 항목 확인 완료
3. 실제 환경 검증 및 증빙 파일 확보
4. 재현 시험 통과
5. 비밀정보가 저장소에 포함되지 않음
6. 최종 제출물 완성
7. 보너스는 별도 상태로 구현·검증 결과 기록
