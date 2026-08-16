# B1-1 R01 — Requirement / Implementation / Verification / Evidence Mapping

실제 실행하지 않은 항목은 Evidence 완료로 표시하지 않습니다.

R01 Golden Path는 `AGENT_HOME=/opt/agent-app`, UFW를 사용합니다.

| ID | Requirement | Reference Implementation | Runtime Verification | Evidence |
|---|---|---|---|---|
| R01 | SSH 포트 20022 | `BEGINNER-GUIDE.md` 안전 전환 절차 | `sshd -T`, `ss -lntp`, 실제 새 접속 | SSH effective config + LISTEN + 새 세션 |
| R02 | Root 원격 로그인 차단 | SSH drop-in/수동 절차 | `sshd -T`에서 `permitrootlogin no` | effective config 출력 |
| R03 | Firewall 활성, 20022/15034만 인바운드 허용 | UFW Golden Path | `ufw status verbose`: active, default deny incoming, extra ALLOW IN 없음 | Firewall 전체 상태 출력 |
| R04 | agent 사용자 3개 | 수동 절차 + `environment/setup.sh` 보조 | `id agent-*` | 계정 출력 |
| R05 | agent-common/core 그룹 | 수동 절차 + setup 보조 | `getent group`, `id -nG`; test는 core 아님 | 그룹/멤버십 출력 |
| R06 | upload/api_keys/log 권한 | `/opt/agent-app` + setgid + ACL | `ls -ld`, `getfacl`, `runuser ... test`로 역할별 실제 R/W 확인 | 권한/ACL + effective access 출력 |
| R07 | 필수 환경변수 | `$AGENT_HOME/env.sh` 비밀값 제외 | env.sh의 변수명/경로 확인 | 비밀값 없는 환경 설정 출력 |
| R08 | Secret 파일 존재 | Runtime에서만 생성 | `test -s`, `stat`만 사용 | 파일 존재/owner/group/mode, 값 제외 |
| R09 | 일반 사용자 Agent 실행 | 제공 바이너리를 canonical `agent-app`으로 설치 | `pgrep -x agent-app`, `ps -o user,pid,comm,args` | 실행 사용자 출력 |
| R10 | Boot Sequence 5단계 OK + Agent READY | 제공 앱 | 실제 앱 stdout | Secret 없는 실행 로그 |
| R11 | TCP 15034 LISTEN | Agent 실행 | `ss -lntp` | 포트 출력 |
| R12 | monitor.sh 위치/소유/권한 | `monitor.sh`, setup 설치 | `stat`, `runuser` 실행권한 | owner/group/mode 출력 |
| R13 | Process Health Check + exit 1 | `pgrep -x` 기반 `monitor.sh` | 정상 실행 + `AGENT_PROCESS_NAME` 안전 override 실패 테스트 | exit code/출력 |
| R14 | Port Health Check + exit 1 | `ss` 기반 `monitor.sh` | Process는 존재하지만 `AGENT_PORT`를 미사용 포트로 override | exit code/출력 |
| R15 | Firewall 비활성 Warning | `monitor.sh` Warning-only 분기 | 코드 확인 + 필요 시 격리 환경 테스트 | Warning 출력/코드 위치 |
| R16 | CPU/MEM/DISK 수집 | `ps`, `df`, `awk` | 실제 실행 | resource 출력 |
| R17 | 20/10/80 임계값 Warning | 공식값이 기본값인 threshold 변수 | 테스트 시 threshold만 안전하게 낮춰 Warning 분기 확인 | Warning 출력 + 기본값 코드 |
| R18 | monitor.log 공식 포맷 누적 | `>>` append | `tail` + regex 검증 | 최근 로그 라인 |
| R19 | 10MB / 10개 관리 | `monitor.sh` 자체 회전 | `/tmp`에서 10MB sparse active log + 번호 로그 회전 검증 | 회전 전/후 파일 목록/크기 |
| R20 | agent-admin cron 매분 | 수동 등록 | `crontab -u agent-admin -l`, 1~2분 Before/After | crontab + 로그 줄수/시간 증가 |
| R21 | 통합 검증 | `environment/verify.sh` | `sudo bash .../verify.sh` | `[PASS]/[FAIL]`, `Result: N PASS / 0 FAIL` |
| R22 | Secret 미노출 | `.gitignore`, Secret-safe commands | `git ls-files` + Evidence 수동 검토 | Secret 값 없는 결과 |

## Evaluation 설명 항목

Evaluation의 설명형 항목은 `docs/evaluation-qa.md`에서 다음 주제를 준비합니다.

- `pgrep -x`/`ps`, `ss`를 선택한 이유
- CPU/MEM/DISK 파싱 방식
- owner/group/mode/ACL와 cron 실행 권한
- effective permission을 사용자별로 다시 검증하는 이유
- 10MB/10개 로그 회전 방식
- SSH/Root 보안의 위협 모델
- `agent-core` 최소 권한
- Health Failure와 Warning의 차이
- `>`와 `>>` 차이
- Nginx 등 다른 프로세스로 확장하는 방법
- Process는 있으나 Port가 없는 장애의 확인 순서
- 로그 폭증 시 단기/중기 대응

## Runtime 전용 Gate

다음은 Reference 파일이 존재해도 PASS 처리하지 않습니다.

- 실제 SSH 새 연결 성공
- 실제 UFW 최종 정책
- 실제 사용자별 effective permission
- 실제 Agent Boot 5/5/READY
- 실제 15034 LISTEN
- 실제 monitor 정상/실패/Warning 경로
- 실제 cron 1~2분 자동 증가
- 실제 10MB/10개 회전
- 실제 Evidence
