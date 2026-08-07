# B1-1 실습 문서 인덱스

## 수행 원칙

`사전 확인 → 실행 → 정상 결과 비교 → GO/STOP 판정 → 오류 해결 → 복구 → 재검증 → 증빙`

각 단계는 **구현 + 테스트 + 증빙**이 모두 갖춰져야 `PASS`로 처리합니다.

## 기억 구조: `00 + 5 × 3`

`00`은 전체 지도입니다. 실제 수행 단계 `01~15`는 15개를 따로 외우지 않고 5개 묶음으로 기억합니다.

```text
00 전체 지도

① 준비와 접근      01 환경 → 02 저장소 → 03 SSH
② 시스템 구성      04 방화벽 → 05 권한 → 06 Agent
③ 구현과 자동화    07 Monitor → 08 자동화 → 09 테스트
④ 검증과 평가      10 장애 → 11 증빙 → 12 평가
⑤ 완성과 고도화    13 재현 → 14 제출 → 15 보너스
```

> **환경을 준비하고 → 시스템을 구성하고 → 모니터를 구현하고 → 검증하고 → 재현·제출·고도화한다.**

## 전체 진행 문서

### 00 — 전체 지도
- [00. 시작 안내](./00-start-here.md)

### 1단계 — 준비와 접근 `01~03`
- [01. 환경 준비](./01-environment.md) — 환경
- [02. 저장소 작업 체계](./02-repository-workflow.md) — 기록
- [03. SSH 보안](./03-ssh-security.md) — 접속

### 2단계 — 시스템 구성 `04~06`
- [04. 방화벽과 네트워크](./04-firewall-network.md) — 문
- [05. 사용자·그룹·ACL](./05-users-groups-acl.md) — 권한
- [06. Agent 실행환경](./06-agent-setup.md) — 프로그램

### 3단계 — 구현과 자동화 `07~09`
- [07. monitor.sh](./07-monitor-script.md) — 감시
- [08. 로그와 cron](./08-logging-cron.md) — 반복
- [09. 정상·장애·복구 테스트](./09-testing-recovery.md) — 시험

### 4단계 — 검증과 평가 `10~12`
- [10. 트러블슈팅](./10-troubleshooting.md) — 고치기
- [11. 수행 내역과 증빙](./11-execution-evidence.md) — 증명
- [12. 평가 대비](./12-evaluation-preparation.md) — 평가

### 5단계 — 완성과 고도화 `13~15`
- [13. 재현 시험](./13-reproducibility-test.md) — 다시
- [14. 최종 검수와 제출](./14-final-review-submission.md) — 완성
- [15. 보너스](./15-bonus.md) — 확장

## 검증 도구

세 도구의 역할을 구분합니다.

```text
scripts/preflight.sh
  → 변경 전 환경 점검, read-only

scripts/verify.sh
  → 현재 시스템 설정/상태 점검, read-only

scripts/acceptance-test.sh
  → 실제 기능·장애·ACL·cron runtime 검증
```

`verify.sh`만 통과했다고 최종 미션 PASS로 처리하지 않습니다. 최종 PASS에는 runtime acceptance와 evidence가 필요합니다.

## 문서 공통 형식

각 `01~15` 문서는 가능한 한 다음 패턴을 사용합니다.

`목표 → 이해 → 실행 → 확인 → 오류·복구 → 기억`

각 장의 기억 장치:

- 한 문장
- 핵심어
- 핵심 명령 또는 동작
- 스스로 설명할 질문
- 다음 단계

## 요구사항 누락 방지

`원본 요구사항 ↔ 구현 파일 ↔ 테스트 ↔ 증빙 ↔ 평가 항목`

연결은 [요구사항-검증-증빙 대응표](./reference/requirements-evidence-map.md)에서 관리합니다.

## 참고 자료

- [주요 명령어](./reference/commands.md)
- [환경별 차이](./reference/environment-differences.md)
- [백업과 복구](./reference/backup-recovery.md)
- [오류 색인](./reference/error-index.md)
- [요구사항-검증-증빙 대응표](./reference/requirements-evidence-map.md)
