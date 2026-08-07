# B1-1 오류 메시지 색인

오류 문구를 보고 담당 장과 확인 순서를 빠르게 찾기 위한 색인입니다.

| 오류/증상 | 먼저 볼 장 | 핵심 확인 |
|---|---|---|
| `Missing privilege separation directory: /run/sshd` | 03, 10 | `ssh.service`의 `RuntimeDirectory=sshd`, service 상태 |
| `ssh.socket changed on disk` | 03, 10 | `systemctl daemon-reload`, `systemctl cat ssh.socket` |
| `Connection refused` | 03, 06, 10 | 실제 LISTEN, 프로세스, 포트 |
| `Connection timed out` | 04, 10 | UFW/호스트 방화벽/NAT/주소 |
| `Permission denied` | 05, 06, 07, 10 | `id`, `namei -l`, `stat`, `getfacl` |
| `Exec format error` | 06 | `uname -m`, x86/arm64 실행 파일 선택, `file` |
| `Address already in use` | 06, 10 | `ss -lntp`, 15034 기존 프로세스 |
| `Agent process not found` | 07, 09 | 실제 제공 파일명, `AGENT_PROCESS_PATTERN`, `pgrep -af` |
| `Agent port is not LISTEN` | 06, 07, 09 | Agent Boot 출력, `AGENT_PORT`, `ss` |
| `log directory does not exist` | 05, 07 | `/var/log/agent-app` 존재/권한 |
| `log file exists but is not writable` | 07, 08 | monitor.log owner/group/mode, logrotate create 정책 |
| `failed to append log` | 07, 08 | 디스크 여유, 파일 권한, ACL |
| `insecure permissions` (logrotate) | 05, 08 | log dir mode, `su agent-admin agent-core` |
| cron 등록됐지만 로그가 늘지 않음 | 08, 09, 10 | agent-admin crontab, cron service, 최소 환경 |
| archive `find failed` | 15 | 디렉터리 read/traverse 권한 |
| archive `move failed` | 15 | archive write 권한/동일 대상/복원 결과 |
| `Command not found` | 01 | `preflight.sh`, 패키지/도구 설치 여부 |
| `No such file or directory` | 01, 05, 06 | 현재 경로, ZIP 실제 경로, 필수 디렉터리 |

실제 발생한 장애는 `reports/troubleshooting-report.md`에 별도로 기록합니다.
