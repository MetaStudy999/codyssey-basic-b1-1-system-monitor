# B1-1 New Baseline · G1 Source Lock

- Cycle: `restart-20260816`
- Date: `2026-08-16`
- Gate: `G1_SOURCE`

## 확인한 Source

| 우선순위 | Source | 결과 |
|---|---|---|
| 1 | `b1-1-mission.pdf` | VALID · 8쪽, B1-1 제목/기능 요구/개발환경/제약/결과 예시/제공 데이터 확인 |
| 2 | `b1-1-mission.md` | VALID · PDF 요구사항을 Markdown으로 구조화한 내용과 핵심 요구 일치 |
| 3 | `b1-1-evaluation.md` | VALID · 구현·설명·보안/운영·장애대응 평가 체크리스트 확인 |
| 4 | `agent-app.zip` | PRESENT · G5 Runtime에서 실제 제공 바이너리/실행 절차 재검증 예정 |

## 공식 Mission에서 고정한 필수 범위

- SSH `20022`, Root 원격 로그인 차단
- 방화벽 TCP `20022`, `15034`만 허용
- `agent-admin/dev/test`, `agent-common/core`
- `upload_files`, `api_keys`, `/var/log/agent-app` 권한/ACL
- Agent 환경변수와 `t_secret.key`
- Boot Sequence 5단계 `[OK]`, `Agent READY`, `0.0.0.0:15034` LISTEN
- Bash `monitor.sh`
- process/port Health Check 실패 시 `exit 1`
- firewall/resource warning 정책
- CPU/MEM/DISK 수집 및 임계값 WARNING
- `/var/log/agent-app/monitor.log` 지정 포맷 누적
- `10MB / 10개` 로그 용량 관리
- `agent-admin` crontab 매분 실행과 자동 로그 증가
- 요구사항 수행 내역서 + `monitor.sh` + 실제 Evidence

## 이번 Clear에서 분리한 선택 범위

- `report.sh` 통계 리포트
- 7일 로그 압축 / 30일 아카이브 삭제

위 항목은 공식 문서의 **보너스 과제(선택)** 이므로 필수 Mission Clear를 지연시키지 않는다.

## 개발 환경 Source 주의

공식 PDF는 **Ubuntu 22.04 LTS 또는 동등 Linux 환경**을 제시한다. 특정 로컬 실습 환경을 공식 필수 버전으로 바꾸지 않는다.

## G1 판정

`PASS`

이 PASS는 Source와 필수 범위가 고정되었다는 뜻이다. 기존 구현·테스트·Runtime 결과는 자동 승계하지 않으며 G2 이후 새 기준으로 다시 검증한다.
