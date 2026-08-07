# B1-1 테스트 케이스

이 파일은 원본 미션·평가 요구사항을 **정상 / 장애 / 권한 / 자동화 / 복구** 관점에서 실제로 검증하기 위한 테스트 매트릭스입니다.

## 상태 규칙

```text
TODO    실행 전
PASS    실제 실행 결과가 예상과 일치
FAIL    예상과 다름
BLOCKED 외부 환경 또는 선행조건 때문에 실행 불가
```

> 예시 출력만 보고 PASS 처리하지 않습니다.

## 테스트 매트릭스

| ID | 영역 | 테스트 | 예상 결과 | 복구 필요 | 상태 |
|---|---|---|---|:---:|---|
| T-001 | 환경 | Ubuntu/Linux·systemd·sudo·필수 도구 | 사전 점검 성공 | 아니오 | TODO |
| T-002 | SSH | `sshd -t` 문법 | exit 0 | 아니오 | TODO |
| T-003 | SSH | 최종 Port/Root 정책 | `port 20022`, `permitrootlogin no` | 아니오 | TODO |
| T-004 | SSH | 실제 LISTEN | 20022 있음, 22 없음 | 아니오 | TODO |
| T-005 | SSH | 일반 사용자 새 접속 | `ssh -p 20022` 성공 | 아니오 | TODO |
| T-006 | UFW | 최종 정책 | active, default deny, 20022/15034만 허용 | 아니오 | TODO |
| T-007 | IAM | 사용자·그룹 멤버십 | 요구 멤버십 일치 | 아니오 | TODO |
| T-008 | ACL | agent-test upload 쓰기 | 성공 | 테스트 파일 삭제 | TODO |
| T-009 | ACL | agent-test key 접근 | Permission denied | 아니오 | TODO |
| T-010 | ACL | agent-test log 쓰기 | Permission denied | 아니오 | TODO |
| T-011 | Agent | 일반 사용자 실행 | 프로세스 owner != root | Agent 종료 | TODO |
| T-012 | Agent | Boot Sequence | 5단계 `[OK]` | Agent 종료 | TODO |
| T-013 | Agent | READY | `Agent READY` | Agent 종료 | TODO |
| T-014 | Agent | TCP 15034 | `0.0.0.0:15034` LISTEN | Agent 종료 | TODO |
| T-015 | Monitor | Bash 문법 | `bash -n` exit 0 | 아니오 | TODO |
| T-016 | Monitor | 정상 실행 | exit 0, 로그 1줄 추가 | 아니오 | TODO |
| T-017 | Monitor | 프로세스 미검출 | exit 1 | 아니오 | TODO |
| T-018 | Monitor | 포트 미리슨 | exit 1 | 아니오 | TODO |
| T-019 | Monitor | 방화벽 비활성 판정 | `[WARNING]`, health 정상 시 계속 | 아니오 | TODO |
| T-020 | Monitor | CPU 임계값 경고 | `[WARNING]`, exit 0 | 아니오 | TODO |
| T-021 | Monitor | MEM 임계값 경고 | `[WARNING]`, exit 0 | 아니오 | TODO |
| T-022 | Monitor | DISK 임계값 경고 | `[WARNING]`, exit 0 | 아니오 | TODO |
| T-023 | Monitor | 로그 포맷 | 지정 정규식 일치 | 아니오 | TODO |
| T-024 | Monitor | 로그 쓰기 불가 | exit 2 | 아니오 | TODO |
| T-025 | Cron | 최소 환경 수동 시험 | exit 0 | 아니오 | TODO |
| T-026 | Cron | agent-admin 등록 | `crontab -l` 일치 | 아니오 | TODO |
| T-027 | Cron | 매분 자동 실행 | 1~2분 후 로그 증가 | 아니오 | TODO |
| T-028 | Logrotate | dry-run | 설정 오류 없음 | 아니오 | TODO |
| T-029 | Logrotate | 강제 회전 | 회전 파일 생성·권한 유지 | 아니오 | TODO |
| T-030 | Recovery | 장애 후 정상 복구 | monitor exit 0 재확인 | 예 | TODO |
| T-031 | Reproduce | 새 환경 재현 | 요구사항 전체 재현 | 예 | TODO |
| T-032 | Bonus | `report.sh` | 통계 출력 정확 | 아니오 | TODO |
| T-033 | Bonus | 7일 압축/아카이브 | 대상 로그만 처리 | 테스트 fixture 정리 | TODO |
| T-034 | Bonus | 30일 아카이브 삭제 | 대상 archive만 삭제 | 테스트 fixture 정리 | TODO |

---

## 안전한 장애 테스트 원칙

실제 서버를 불필요하게 망가뜨리지 않습니다.

```text
프로세스 테스트 → 실제 Agent를 죽이는 대신 process pattern override 우선
포트 테스트     → 실제 포트를 닫는 대신 미사용 포트 override 우선
CPU 테스트      → CPU 부하를 만들지 않고 threshold override
MEM 테스트      → 메모리를 채우지 않고 threshold override
DISK 테스트     → 디스크를 채우지 않고 threshold override
방화벽 테스트   → 실제 UFW disable보다 fixture/mock 우선
```

### 예: 프로세스 실패를 안전하게 만들기

```bash
AGENT_ENV_FILE=/nonexistent \
AGENT_PORT=15034 \
AGENT_LOG_DIR=/var/log/agent-app \
AGENT_PROCESS_PATTERN='__b1_1_process_that_does_not_exist__' \
/home/agent-admin/agent-app/bin/monitor.sh

echo $?
```

목표:

```text
1
```

### 예: 임계값 경고를 부하 없이 시험

정상 Agent가 실행 중일 때 실제 CPU·메모리·디스크를 위험하게 올리지 않고 임계값을 테스트용으로 낮춥니다.

```bash
CPU_WARN_THRESHOLD=-1 \
MEM_WARN_THRESHOLD=-1 \
DISK_WARN_THRESHOLD=-1 \
/home/agent-admin/agent-app/bin/monitor.sh
```

목표:

```text
CPU WARNING
MEM WARNING
DISK_USED WARNING
그리고 health가 정상이라면 exit 0
```

이 방법은 **경고 로직을 시험하는 것**이며 실제 고부하 환경을 재현하는 것은 아닙니다.

---

## 테스트 기록 원칙

각 테스트에는 가능하면 다음을 남깁니다.

```text
Test ID
실행 시각
실행 계정
사전조건
실행 명령
실제 출력
exit code
예상 결과
PASS/FAIL
복구 명령
복구 후 재검증
```

최종 결과는 `reports/test-results.md`, 핵심 원본 출력은 `evidence/09-testing/`에 연결합니다.
