# B1-1 테스트 결과

> 실제 실행 결과만 기록합니다. 실행하지 않은 항목은 `TODO`로 유지합니다.

| 테스트 ID | 실행 일시 | 실제 결과 | 종료 코드 | 증빙 | 판정 |
|---|---|---|---|---|---|
| T-001 | TODO | TODO | TODO | `evidence/01-environment/` | TODO |
| T-002 | 2026-08-07 | `sshd -t` 성공 확인 | 0 | `evidence/03-ssh/` 정리 필요 | TESTED |
| T-003 | 2026-08-07 | `port 20022`, `permitrootlogin no` 확인 | 0 | `evidence/03-ssh/` 정리 필요 | TESTED |
| T-004 | 2026-08-07 | 20022 LISTEN, 22 미LISTEN 확인 | 0 | `evidence/03-ssh/` 정리 필요 | TESTED |
| T-005 | TODO | 외부/별도 클라이언트 새 SSH 접속 미검증 | TODO | `evidence/03-ssh/` | TODO |
| T-006 | 2026-08-07 | UFW active, default deny, 20022/15034 허용 확인 | 0 | `evidence/04-firewall/` 정리 필요 | TESTED |
| T-007 | TODO | 사용자 3개/멤버십 미완료 | TODO | `evidence/05-users-groups-acl/` | TODO |
| T-008 | TODO | TODO | TODO | `evidence/05-users-groups-acl/` | TODO |
| T-009 | TODO | TODO | TODO | `evidence/05-users-groups-acl/` | TODO |
| T-010 | TODO | TODO | TODO | `evidence/05-users-groups-acl/` | TODO |
| T-011 | TODO | 원본 데이터 설명에서 제공 파일명만 확인, ZIP 내부 실제 확인 전 | TODO | `evidence/06-agent/` | TODO |
| T-012 | TODO | TODO | TODO | `evidence/06-agent/` | TODO |
| T-013 | TODO | TODO | TODO | `evidence/06-agent/` | TODO |
| T-014 | TODO | TODO | TODO | `evidence/06-agent/` | TODO |
| T-015 | TODO | TODO | TODO | `evidence/06-agent/` | TODO |
| T-016 | 2026-08-07 | 보완 브랜치 작성본 `bash -n` 통과 | 0 | Codex/로컬 정적검증 기록 추가 예정 | IMPLEMENTED-STATIC |
| T-017 | TODO | TODO | TODO | `evidence/07-monitor/` | TODO |
| T-018 | TODO | TODO | TODO | `evidence/07-monitor/` | TODO |
| T-019 | TODO | TODO | TODO | `evidence/07-monitor/` | TODO |
| T-020 | TODO | TODO | TODO | `evidence/07-monitor/` | TODO |
| T-021 | TODO | TODO | TODO | `evidence/07-monitor/` | TODO |
| T-022 | TODO | TODO | TODO | `evidence/07-monitor/` | TODO |
| T-023 | TODO | TODO | TODO | `evidence/07-monitor/` | TODO |
| T-024 | TODO | TODO | TODO | `evidence/08-automation/` | TODO |
| T-025 | TODO | 로그 append 실패 시 `exit 2` 처리 코드 보완, runtime 미검증 | TODO | `evidence/07-monitor/` | IMPLEMENTED |
| T-026 | TODO | TODO | TODO | `evidence/09-testing/` | TODO |
| T-027 | TODO | crontab 예시 구현, 실제 설치 전 | TODO | `evidence/08-automation/` | IMPLEMENTED |
| T-028 | TODO | TODO | TODO | `evidence/08-automation/` | TODO |
| T-029 | TODO | logrotate 설정 구현, 실제 dry-run 전 | TODO | `evidence/08-automation/` | IMPLEMENTED |
| T-030 | 2026-08-07 | strict max 10 files: `size 10M`, `rotate 9`로 보완 | N/A | `config/agent-monitor.logrotate` | IMPLEMENTED |
| T-031 | TODO | TODO | TODO | `evidence/08-automation/` | TODO |
| T-032 | TODO | TODO | TODO | `evidence/09-testing/` | TODO |
| T-033 | TODO | TODO | TODO | `evidence/14-final/` | TODO |
| T-034 | TODO | `report.sh` 구현, fixture 실행 전 | TODO | `evidence/15-bonus/` | IMPLEMENTED |
| T-035 | TODO | `report.sh` 시간 구간 구현, fixture 실행 전 | TODO | `evidence/15-bonus/` | IMPLEMENTED |
| T-036 | TODO | archive 구현 및 오류 처리 보완, fixture 실행 전 | TODO | `evidence/15-bonus/` | IMPLEMENTED |
| T-037 | TODO | 30일 삭제 구현, fixture 실행 전 | TODO | `evidence/15-bonus/` | IMPLEMENTED |
| T-038 | TODO | 미존재/권한/find 실패/대상 0개 처리 보완, runtime 전 | TODO | `evidence/15-bonus/` | IMPLEMENTED |
| T-039 | TODO | `.gitignore`/verify 로직 존재, 실제 tracked-files 최종 검사 전 | TODO | `evidence/14-final/` | IMPLEMENTED |
| T-040 | TODO | requirements-evidence map 존재, 전체 PASS 전 | TODO | `docs/reference/requirements-evidence-map.md` | TODO |

## 현재 요약

```text
실제 환경 TESTED : SSH 일부(T-002~004), UFW(T-006)
정적/코드 IMPLEMENTED : monitor, cron/logrotate, bonus, acceptance gate
실제 runtime TODO : IAM/ACL, Agent, monitor, cron, logrotate, bonus fixture
증빙 정리 TODO : TESTED 항목 포함 대부분
```

`TESTED`는 실제 확인은 했지만 evidence 파일 정리가 남았다는 뜻이며, 최종 `PASS`와 구분합니다.
