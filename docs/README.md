# B1-1 실습 문서 · 2026-08-16 New Baseline

## 지금은 이 문서부터 사용합니다

> **[B1-1 New Baseline 빠른 실행 가이드](./00-new-baseline-runtime.md)**

기존 `00~15` 문서는 이전 급행 수행 중 만들어진 상세 학습 자료로 보존합니다. 현재 Mission Clear를 위해서는 위 **빠른 실행 가이드 → 실제 Runtime → Evidence** 순서를 우선합니다.

## 현재 원칙

`사전 확인 → 실행 → 정상 결과 비교 → 실패 항목만 수정 → 재검증 → 증빙`

- 과거 문서에 적힌 `실제 결과`, `완료`, `TESTED` 표기는 **현재 2026-08-16 Cycle PASS를 뜻하지 않습니다.**
- 새 기준 이후 다시 확인한 Evidence만 현재 상태에 반영합니다.
- `chmod 777`, Root Agent 실행, `$AGENT_HOME` 전체에 대한 광범위한 `chown -R`은 사용하지 않습니다.
- 필수 Mission Clear 전에 보너스/고도화를 하지 않습니다.

## 현재 빠른 경로

```text
NEW-BASELINE.md
      ↓
00-new-baseline-runtime.md
      ↓
03 SSH
      ↓
04 UFW
      ↓
05 Users / Groups / ACL
      ↓
06 Agent · New Baseline
      ↓
07 Monitor
      ↓
08 Cron / Logrotate
      ↓
runtime-acceptance.sh
      ↓
Evidence
      ↓
평가 대응 / Clear
```

## 세부 참고 문서

### 전체 지도
- [00. 이전 상세 시작 안내](./00-start-here.md)
- **[00. 현재 빠른 실행 가이드](./00-new-baseline-runtime.md)**

### 준비와 접근
- [01. 환경 준비](./01-environment.md)
- [02. 저장소 작업 체계](./02-repository-workflow.md)
- [03. SSH 보안](./03-ssh-security.md)

### 시스템 구성
- [04. 방화벽과 네트워크](./04-firewall-network.md)
- [05. 사용자·그룹·ACL](./05-users-groups-acl.md)
- **[06. Agent 실행환경 · New Baseline](./06-agent-setup.md)**

### 구현과 자동화
- [07. monitor.sh](./07-monitor-script.md)
- [08. 로그와 cron](./08-logging-cron.md)
- [09. 정상·장애·복구 테스트](./09-testing-recovery.md)

### 검증과 평가
- [10. 트러블슈팅](./10-troubleshooting.md)
- [11. 수행 내역과 증빙](./11-execution-evidence.md)
- [12. 평가 대비](./12-evaluation-preparation.md)

### 완성과 고도화
- [13. 재현 시험](./13-reproducibility-test.md)
- [14. 최종 검수와 제출](./14-final-review-submission.md)
- [15. 보너스](./15-bonus.md) — **필수 Clear 후**

## 자동 검증

Repository 검증:

```bash
bash tests/new-baseline-static.sh
bash tests/new-baseline-monitor-behavior.sh
```

실제 Ubuntu 상태 한 번에 점검:

```bash
bash scripts/runtime-acceptance.sh | tee /tmp/b1-1-runtime.txt
```

`[FAIL]` 항목만 수정한 뒤 다시 실행합니다.

## 요구사항 추적

- [요구사항-검증-증빙 대응표](./reference/requirements-evidence-map.md)
- [주요 명령어](./reference/commands.md)
- [환경별 차이](./reference/environment-differences.md)
- [오류 색인](./reference/error-index.md)

## 기억 문장

> **현재 빠른 가이드 하나를 따라가고, 실패한 항목만 고쳐서, Evidence가 모이면 Clear한다.**
