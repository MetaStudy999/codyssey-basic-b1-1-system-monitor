# B1-1 R01 — Requirement / Verification / Evidence Mapping

실제 실행하지 않은 항목은 Evidence 완료로 표시하지 않습니다.

| ID | Requirement | Reference Implementation | Runtime Verification | Evidence |
|---|---|---|---|---|
| R01 | SSH 포트 20022 | `BEGINNER-GUIDE.md` 수동 절차 | `sshd -T`, `ss -lntp`, 실제 새 접속 | SSH 설정/포트 출력 |
| R02 | Root 원격 로그인 차단 | `BEGINNER-GUIDE.md` | `sshd -T`에서 `permitrootlogin no` | effective config 출력 |
| R03 | Firewall 활성, 20022/15034 허용 | 수동 안전 절차 | `ufw status verbose` 또는 firewalld | Firewall 상태 출력 |
| R04 | agent 사용자 3개 | `environment/setup.sh` 보조 | `id agent-*` | 계정 출력 |
| R05 | agent-common/core 그룹 | `environment/setup.sh` 보조 | `getent group`, `id -nG` | 그룹/멤버십 출력 |
| R06 | upload/api_keys/log 권한 | setup + ACL | `ls -ld`, `getfacl` | 권한/ACL 출력 |
| R07 | 필수 환경변수 | `$AGENT_HOME/env.sh` 비밀값 제외 | `env | grep '^AGENT_'` 단 Secret 값 출력 금지 | 변수명/경로 마스킹 출력 |
| R08 | Secret 파일 존재 | Runtime에서만 생성 | `test -f`, `stat`만 사용 | 파일 존재/권한, 값 제외 |
| R09 | 일반 사용자 Agent 실행 | 제공 앱 실행 절차 | `ps -o user,pid,cmd` | 실행 사용자 출력 |
| R10 | Boot Sequence 5단계 OK + Agent READY | 제공 앱 | 실제 앱 stdout | Secret 없는 실행 로그 |
| R11 | TCP 15034 LISTEN | Agent 실행 | `ss -lntp` | 포트 출력 |
| R12 | monitor.sh 위치/소유/권한 | `monitor.sh`, setup 설치 | `stat` | owner/group/mode 출력 |
| R13 | Process Health Check + exit 1 | `monitor.sh` | 정상/프로세스 중단 시 실행 | exit code/출력 |
| R14 | Port Health Check + exit 1 | `monitor.sh` | 정상/포트 미오픈 시 실행 | exit code/출력 |
| R15 | Firewall 비활성 Warning | `monitor.sh` | 안전한 테스트 환경에서 확인 | Warning 출력 |
| R16 | CPU/MEM/DISK 수집 | `monitor.sh` | 실제 실행 | resource 출력 |
| R17 | 20/10/80 임계값 Warning | `monitor.sh` | 임계값 조건 또는 코드+안전 재현 | Warning 출력 |
| R18 | monitor.log 공식 포맷 누적 | `monitor.sh` | `tail` + regex 검증 | 최근 로그 라인 |
| R19 | 10MB / 10개 관리 | `monitor.sh` 자체 회전 | 안전한 테스트 파일로 회전 검증 | 파일 목록/크기 |
| R20 | agent-admin cron 매분 | 수동 등록 | `crontab -u agent-admin -l`, 1~2분 로그 증가 | crontab + Before/After |
| R21 | 통합 검증 | `environment/verify.sh` | 실제 실행 | `[PASS]/[FAIL]`, Result |
| R22 | Secret 미노출 | `.gitignore`, verify Secret-pattern check | `git ls-files` 및 Evidence 검토 | Secret 값 없는 결과 |

## Evaluation 설명 항목

Evaluation의 설명형 항목은 `docs/evaluation-qa.md`에서 다음 주제를 준비합니다.

- `pgrep/ps`, `ss`를 선택한 이유
- CPU/MEM/DISK 파싱 방식
- owner/group/mode와 cron 실행 권한
- 10MB/10개 로그 회전 방식
- SSH/Root 보안의 위협 모델
- `agent-core` 최소 권한
- Health Failure와 Warning의 차이
- `>`와 `>>` 차이
- Nginx 등 다른 프로세스로 확장하는 방법
- Process는 있으나 Port가 없는 장애의 확인 순서
- 로그 폭증 시 단기/중기 대응
