# B1-1 트러블슈팅 보고서

> 실제로 관찰한 문제만 `확인`으로 기록하고, 아직 재현하지 않은 시나리오는 별도 TODO로 둡니다.

| ID | 증상 | 원인 | 조치 | 재검증 | 상태 | 증빙 |
|---|---|---|---|---|---|---|
| TS-001 | `sshd -T`에서 `Missing privilege separation directory: /run/sshd` | Ubuntu 24.04.4에서 `ssh.service`가 inactive 상태라 systemd의 `RuntimeDirectory=sshd`가 아직 생성되지 않음 | 임의 `mkdir` 대신 `sudo systemctl start ssh.service`로 systemd가 런타임 디렉터리를 준비하도록 함 | 이후 `sshd -t`/`sshd -T` 성공 확인 | TESTED | `evidence/03-ssh/` 정리 필요 |
| TS-002 | `ssh.socket changed on disk` 또는 socket 설정 반영 필요 | `Port 20022` 변경 후 systemd generator/socket 정의를 다시 읽어야 함 | `sudo systemctl daemon-reload` 후 `systemctl cat ssh.socket`과 실제 LISTEN 재확인 | `sshd-socket-generator`가 20022 주소를 생성하고 최종 20022 LISTEN 확인 | TESTED | `evidence/03-ssh/` 정리 필요 |
| TS-003 | 첫 `ufw show added` 확인에서 `15034/tcp`가 기대대로 보이지 않음 | 규칙 적용/확인 흐름에서 15034 추가 상태를 다시 확인할 필요가 있었음 | `sudo ufw allow 15034/tcp`를 재확인 적용하고 `ufw status verbose`로 최종 정책 확인 | 20022/tcp, 15034/tcp 허용과 default deny 확인 | TESTED | `evidence/04-firewall/` 정리 필요 |

## 향후 실제 runtime에서 추가할 항목

| ID | 시나리오 | 상태 |
|---|---|---|
| TS-004 | Agent 프로세스는 있으나 15034가 LISTEN하지 않음 | TODO |
| TS-005 | monitor.log 쓰기 권한 오류 | TODO |
| TS-006 | cron 수동 실행 성공 / 자동 실행 실패 | TODO |
| TS-007 | logrotate 후 새 monitor.log 권한 오류 | TODO |
| TS-008 | 로그 급증·디스크 부족 대응 | TODO |

## 기록 원칙

각 실제 장애는 다음 순서로 기록합니다.

```text
증상
→ 원인 가설
→ 확인 명령
→ 실제 원인
→ 최소 수정
→ 재검증
→ 재발 방지
→ evidence
```

문서상 예시만 존재하는 장애를 실제 발생한 것처럼 기록하지 않습니다.
