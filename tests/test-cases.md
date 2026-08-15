# B1-1 테스트 케이스

원본 미션·평가 요구사항을 **환경 / 보안 / 권한 / Agent / monitor / 자동화 / 복구 / 보너스** 관점에서 실제로 검증합니다.

## 상태 규칙

```text
TODO    실행 전
PASS    실제 결과가 예상과 일치
FAIL    예상과 다름
BLOCKED 외부 환경·선행조건 때문에 실행 불가
```

예상 출력이나 문서 존재만으로 PASS 처리하지 않습니다.

## 테스트 매트릭스

| ID | 영역 | 테스트 | 예상 결과 | 자동/수동 |
|---|---|---|---|---|
| T-001 | 환경 | Ubuntu/Linux·systemd·sudo·필수 도구 | preflight GO 또는 설명 가능한 WARN만 존재 | `preflight.sh` |
| T-002 | SSH | `sshd -t` 문법 | exit 0 | 수동/verify |
| T-003 | SSH | 최종 Port/Root 정책 | `port 20022`, `permitrootlogin no` | verify |
| T-004 | SSH | 실제 LISTEN | 20022 있음, 22 없음 | verify |
| T-005 | SSH | 일반 사용자 새 접속 | `ssh -p 20022` 성공 | 수동 |
| T-006 | UFW | 최종 정책 | active, default deny, 20022/15034만 허용 | verify |
| T-007 | IAM | 사용자·그룹 멤버십 | 요구 멤버십 일치 | verify |
| T-008 | ACL | agent-test upload 쓰기 | 성공 | acceptance |
| T-009 | ACL | agent-test key 쓰기 | Permission denied | acceptance |
| T-010 | ACL | agent-test log 쓰기 | Permission denied | acceptance |
| T-011 | Agent | 아키텍처용 실행 파일 확인 | x86→`agent-app-linux-x86`, arm64→`agent-app-linux-arm64` | 수동 |
| T-012 | Agent | 일반 사용자 실행 | process owner != root | verify |
| T-013 | Agent | Boot Sequence | `[1/5]~[5/5]` 모두 `[OK]` | acceptance/evidence |
| T-014 | Agent | READY | `Agent READY` | acceptance/evidence |
| T-015 | Agent | TCP 15034 | `0.0.0.0:15034` LISTEN | verify |
| T-016 | Monitor | Bash 문법 | `bash -n` exit 0 | 정적 |
| T-017 | Monitor | 정상 실행 | exit 0, 로그 1줄 증가 | acceptance |
| T-018 | Monitor | 프로세스 미검출 | exit 1 | acceptance |
| T-019 | Monitor | 프로세스 있음·포트 미LISTEN | exit 1 | acceptance |
| T-020 | Monitor | 방화벽 비활성 판정 | `[WARNING]`, health 정상 시 계속 | 통제 테스트 |
| T-021 | Monitor | CPU 임계값 경고 | `[WARNING]`, exit 0 | acceptance |
| T-022 | Monitor | MEM 임계값 경고 | `[WARNING]`, exit 0 | acceptance |
| T-023 | Monitor | DISK 임계값 경고 | `[WARNING]`, exit 0 | acceptance |
| T-024 | Monitor | 로그 포맷 | 지정 정규식 일치 | acceptance/verify |
| T-025 | Monitor | 로그 디렉터리/파일 쓰기 불가 | exit 2, 성공으로 처리하지 않음 | 통제 테스트 |
| T-026 | Cron | 최소 환경 수동 시험 | exit 0 | 수동 |
| T-027 | Cron | agent-admin 등록 | `crontab -l` 일치 | verify |
| T-028 | Cron | 매분 자동 실행 | 1~2분 내 로그 증가 | acceptance |
| T-029 | Logrotate | 설정 dry-run | 오류 없음 | acceptance |
| T-030 | Logrotate | 엄격한 최대 10개 정책 | `size 10M`, `rotate 9`, current+9 | verify |
| T-031 | Logrotate | 강제 회전 | 회전 파일 생성, 새 로그 0660 core R/W | 수동 |
| T-032 | Recovery | 장애 후 정상 복구 | monitor exit 0 재확인 | 수동 |
| T-033 | Reproduce | 새 세션/재부팅/가능하면 깨끗한 환경 | 문서만으로 재현 | 수동 |
| T-034 | Bonus | `report.sh` 통계 | 평균/최대/최소/샘플 수 정확 | fixture |
| T-035 | Bonus | 시간 구간 분석 | 지정 범위 샘플만 분석 | fixture |
| T-036 | Bonus | 7일 압축·아카이브 | 대상 로그만 `.gz`로 이동 | fixture |
| T-037 | Bonus | 30일 아카이브 삭제 | 대상 `.gz`만 삭제 | fixture |
| T-038 | Bonus | 예외 처리 | 미존재/권한/대상 0개에서 안전한 오류·안내 | fixture |
| T-039 | 제출안전 | 비밀 파일 추적 여부 | 실제 `.key`/`.env` 미추적 | verify/manual |
| T-040 | 최종 | 요구사항-증빙 매핑 | 필수 행 모두 근거 존재 | 수동/Codex |

---

## 안전한 장애 테스트 원칙

실제 서버에 고의로 과부하를 만들지 않습니다.

```text
프로세스 실패 → 존재하지 않는 process pattern override
포트 실패     → 짧은 sleep 프로세스 + 미사용 포트
CPU/MEM/DISK  → 실제 부하 대신 threshold를 -1로 override
ACL            → 작은 임시 파일 생성 후 즉시 삭제
cron           → 로그 줄 수 전후 비교
logrotate      → dry-run 우선, force는 통제된 실습 시점만
```

통합 가능한 항목은:

```bash
sudo bash scripts/acceptance-test.sh \
  --agent-boot-log <Agent 시작 출력 파일>
```

으로 실행합니다.

## 기록 원칙

각 테스트 결과는 `reports/test-results.md`의 동일 ID 행에 기록하고, 원본 출력은 해당 `evidence/` 디렉터리에 연결합니다.

```text
테스트 ID
실행 시각
실행 환경/commit
실행 계정
실행 명령
실제 결과
exit code
증빙
판정
```
