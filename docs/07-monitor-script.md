# 07. `monitor.sh` 설계와 구현

## 목표

Agent의 프로세스·포트·방화벽·자원을 점검하고 지정 형식으로 로그를 기록합니다.

## 필수 기능

- 프로세스 Health Check
- TCP `15034` Health Check
- 방화벽 비활성 경고
- CPU·메모리·루트 디스크 수집
- CPU `20%`, MEM `10%`, DISK `80%` 초과 경고
- 지정 로그 형식과 누적 기록
- Health Check 실패 시 `exit 1`

## 파일 조건

- 경로: `$AGENT_HOME/bin/monitor.sh`
- 소유자: `agent-dev`
- 그룹: `agent-core`
- 권한: `750`

## 완료 조건

- [ ] `bash -n` 통과
- [ ] ShellCheck 검토
- [ ] 정상 실행 `exit 0`
- [ ] 실패 실행 `exit 1`

## 이동

- [이전: 06. Agent 실행환경](./06-agent-setup.md)
- [다음: 08. 로그와 cron](./08-logging-cron.md)
