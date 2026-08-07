# B1-1 요구사항 및 증빙 추적표

이 문서는 미션 요구사항을 **구현 위치 → 검증 방법 → 증빙 자료**로 연결하여 누락을 방지하기 위한 통제표입니다.

## 1. 최종 산출물

- [ ] 요구사항 수행 내역서 1개
- [ ] Bash 기반 `monitor.sh` 소스코드
- [ ] 필수 명령 출력 또는 화면 캡처
- [ ] 정상·장애 테스트 결과

## 2. 요구사항 추적 매트릭스

| ID | 요구사항 | 구현 위치 | 검증 명령·방법 | 증빙 파일 예시 | 상태 |
|---|---|---|---|---|:---:|
| SEC-01 | SSH 포트를 `20022`로 변경 | `/etc/ssh/sshd_config` 또는 배포판별 설정 | `sudo sshd -t`, `sudo sshd -T \| grep '^port'`, `ss -tulnp` | `evidence/02-sshd-config.txt`, `03-ssh-listen.txt` | [ ] |
| SEC-02 | Root 원격 로그인 차단 | SSH 설정 | `sudo sshd -T \| grep permitrootlogin` | `evidence/02-sshd-config.txt` | [ ] |
| FW-01 | UFW 또는 firewalld 활성화 | 방화벽 설정 | `sudo ufw status numbered` 또는 `firewall-cmd --list-all` | `evidence/04-firewall-status.txt` | [ ] |
| FW-02 | 인바운드 `20022/tcp`, `15034/tcp` 허용 | 방화벽 규칙 | 방화벽 규칙과 외부 접속 확인 | `evidence/04-firewall-status.txt` | [ ] |
| IAM-01 | `agent-admin`, `agent-dev`, `agent-test` 생성 | Linux 계정 | `id agent-admin`, `id agent-dev`, `id agent-test` | `evidence/05-users-groups.txt` | [ ] |
| IAM-02 | `agent-common`, `agent-core` 생성 및 구성 | Linux 그룹 | `getent group agent-common`, `getent group agent-core` | `evidence/05-users-groups.txt` | [ ] |
| IAM-03 | `upload_files`를 `agent-common`이 R/W 가능 | 소유권·권한·ACL | `ls -ld`, `getfacl`, 계정별 생성 시험 | `evidence/06-directory-acl.txt` | [ ] |
| IAM-04 | `api_keys`, 로그 디렉터리를 `agent-core`로 제한 | 소유권·권한·ACL | `getfacl`, `agent-test` 접근 실패 확인 | `evidence/06-directory-acl.txt` | [ ] |
| APP-01 | 필수 환경변수 설정 | 사용자 환경 또는 실행 스크립트 | 변수 이름과 값의 존재 확인; 비밀값은 마스킹 | `evidence/07-agent-env.txt` | [ ] |
| APP-02 | 키 파일 생성 및 권한 적용 | `$AGENT_HOME/api_keys/t_secret.key` | 파일 존재·권한 확인; 내용은 공개 증빙에서 마스킹 | `evidence/07-agent-env.txt` | [ ] |
| APP-03 | 일반 사용자로 Agent 실행 | 제공 애플리케이션 | 실행 계정과 Boot 로그 확인 | `evidence/08-agent-boot.txt` | [ ] |
| APP-04 | Boot Sequence 5단계 `[OK]`와 `Agent READY` | 제공 애플리케이션 | 실행 로그 | `evidence/08-agent-boot.txt` | [ ] |
| APP-05 | `0.0.0.0:15034` LISTEN | Agent 프로세스 | `ss -tulnp \| grep ':15034'` | `evidence/09-agent-port.txt` | [ ] |
| MON-01 | `monitor.sh` 위치·소유자·그룹·권한 충족 | `$AGENT_HOME/bin/monitor.sh` | `stat`, `ls -l` | `evidence/10-monitor-permission.txt` | [ ] |
| MON-02 | 프로세스 Health Check | `monitor.sh` | Agent 실행·종료 전후 실행, `$?` 확인 | `evidence/11-monitor-process-test.txt` | [ ] |
| MON-03 | 포트 Health Check | `monitor.sh` | 프로세스 존재·포트 미리슨 상황 시험 | `evidence/12-monitor-port-test.txt` | [ ] |
| MON-04 | 프로세스·포트 실패 시 `exit 1` | `monitor.sh` | `echo $?` | `evidence/11-monitor-process-test.txt`, `12-monitor-port-test.txt` | [ ] |
| MON-05 | 방화벽 비활성 시 WARNING 후 계속 실행 | `monitor.sh` | 방화벽 상태 변경 후 실행 | `evidence/13-monitor-warning-test.txt` | [ ] |
| MON-06 | CPU, MEM, DISK 수집 | `monitor.sh` | 콘솔 출력과 원본 명령 비교 | `evidence/14-monitor-resource.txt` | [ ] |
| MON-07 | CPU `>20%`, MEM `>10%`, DISK `>80%` 경고 | `monitor.sh` | 임계값 시험 또는 재현 가능한 테스트 방식 | `evidence/13-monitor-warning-test.txt` | [ ] |
| LOG-01 | 지정 로그 포맷으로 누적 기록 | `/var/log/agent-app/monitor.log` | `tail`, 반복 실행 전후 비교 | `evidence/15-monitor-log.txt` | [ ] |
| LOG-02 | 로그 관리 `10MB / 10개` 적용 | logrotate 또는 Bash | 설정 확인과 강제 회전 시험 | `evidence/16-logrotate.txt` | [ ] |
| CRON-01 | `agent-admin` crontab에서 매분 실행 | crontab | `sudo -u agent-admin crontab -l` | `evidence/17-crontab.txt` | [ ] |
| CRON-02 | 1~2분 후 로그 자동 증가 | cron + monitor.log | 실행 전후 줄 수·시간 비교 | `evidence/18-cron-before-after.txt` | [ ] |
| DOC-01 | 설정·명령·결과 문서화 | `docs/execution-record.md` | 문서 검토 | 문서 자체 | [ ] |
| DOC-02 | 오류와 해결 과정 문서화 | `docs/troubleshooting.md` | 증상→가설→검증→조치→결과→재발방지 확인 | 문서 자체 | [ ] |

## 3. 필수 환경변수

| 이름 | 요구 값·역할 |
|---|---|
| `AGENT_HOME` | Agent 기준 디렉터리 |
| `AGENT_PORT` | `15034` |
| `AGENT_UPLOAD_DIR` | `$AGENT_HOME/upload_files` |
| `AGENT_KEY_PATH` | `$AGENT_HOME/api_keys/t_secret.key` |
| `AGENT_LOG_DIR` | `/var/log/agent-app` 권장 |

> 저장소 문서와 증빙에는 실제 비밀값을 기록하지 않습니다.

## 4. 종료 정책

| 상황 | 기대 동작 |
|---|---|
| 프로세스 정상 + 포트 정상 | 자원 수집·로그 기록 후 `exit 0` |
| 프로세스 없음 | 오류 출력 후 `exit 1` |
| 포트 미리슨 | 오류 출력 후 `exit 1` |
| 방화벽 비활성 | `[WARNING]` 출력 후 계속 실행 |
| 자원 임계값 초과 | `[WARNING]` 출력 후 계속 실행 |
| 환경·경로·권한 오류 | 명확한 오류를 출력하고 비정상 종료 |

## 5. 완료 정의

다음 조건을 모두 만족하면 B1-1 필수 범위를 완료한 것으로 판단합니다.

- [ ] 추적 매트릭스의 모든 필수 항목이 완료됨
- [ ] `bash -n` 문법 검사 통과
- [ ] 가능하면 ShellCheck 주요 오류 해결
- [ ] 정상 테스트와 실패 테스트 모두 실행됨
- [ ] cron 자동 실행과 로그 회전이 실제 환경에서 검증됨
- [ ] 민감정보가 Git 이력에 포함되지 않음
- [ ] 새 환경에서 문서만으로 주요 설정과 검증 절차를 재현할 수 있음
