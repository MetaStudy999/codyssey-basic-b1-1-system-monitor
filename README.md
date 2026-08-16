# codyssey-basic-b1-1-system-monitor

> **2026-08-16 New Baseline**  
> 현재 미션: **B1-1** · 현재 Gate: **G5 RUNTIME · NEEDS-RUNTIME**  
> G1 Source · G2 Build · G3 Test · G4 Review는 새 기준으로 다시 검증했습니다.

코디세이 기초 B1-1 **컴퓨터가 알아서 자기 상태를 점검하게 만들기** 미션 저장소입니다.

## 지금 할 일

이제 Repository 수정이 아니라 **실제 Ubuntu Runtime**을 확인합니다.

1. [B1-1 New Baseline 빠른 실행 가이드](./docs/00-new-baseline-runtime.md)를 순서대로 수행합니다.
2. 마지막에 다음 명령으로 실제 상태를 한 번에 확인합니다.

```bash
bash scripts/runtime-acceptance.sh | tee /tmp/b1-1-runtime.txt
```

3. `[FAIL]` 항목만 수정하고 다시 실행합니다.
4. Agent의 **Boot Sequence 1~5 `[OK]` + `Agent READY`** 출력도 별도로 증빙합니다.

키 값은 채팅·Git·증빙 파일에 기록하지 않습니다.

## 새 기준 진행 현황

```text
G1 SOURCE    PASS
G2 BUILD     PASS
G3 TEST      PASS
G4 REVIEW    PASS
G5 RUNTIME   NEEDS-RUNTIME  ← 현재
G6 EVIDENCE  TODO
G7 LEARN     TODO
G8 MERGE     TODO
```

현재 근거:

- [G1 Source Lock](./evidence/new-baseline-source-lock.md)
- [G2 Build Audit](./evidence/new-baseline-build-audit.md)
- [G3 Test Results](./evidence/new-baseline-test-results.md)
- [G4 Review](./evidence/new-baseline-review.md)

## 목표

Ubuntu 환경에서 SSH·방화벽·사용자·그룹·ACL을 구성하고, 제공 Agent를 일반 사용자로 실행한 뒤 Bash 기반 `monitor.sh`로 상태를 점검·기록·자동화합니다.

## 환경 기준

원본 미션의 기준은 **Ubuntu 22.04 LTS 또는 동등한 Linux 환경**입니다. Ubuntu 24.04 계열도 동등 환경으로 실습할 수 있지만 실제 상태는 G5에서 다시 검증합니다.

## 현재 사용 문서

- [NEW-BASELINE.md](./NEW-BASELINE.md) — 필수 통과 체크리스트
- [빠른 실행 가이드](./docs/00-new-baseline-runtime.md) — 현재 실행 경로
- [Agent 실행환경 · New Baseline](./docs/06-agent-setup.md) — 안전한 Agent 배치·실행
- [상세 문서 인덱스](./docs/README.md) — 기존 학습자료 참고

기존 `00~15` 문서는 학습자료로 보존하지만 과거 문서의 `실제 결과`, `완료`, `TESTED` 표현은 현재 PASS를 의미하지 않습니다.

## 구현·검증

핵심 파일:

- `scripts/monitor.sh`
- `config/agent.env.example`
- `config/crontab.example`
- `config/agent-monitor.logrotate`
- `tests/new-baseline-static.sh`
- `tests/new-baseline-monitor-behavior.sh`
- `scripts/runtime-acceptance.sh`

Repository 자동검증:

```bash
bash tests/new-baseline-static.sh
bash tests/new-baseline-monitor-behavior.sh
```

## PASS 원칙

`필수 구현 + 신뢰 가능한 테스트 + 실제 Runtime + 평가 Evidence`

실제 Ubuntu 확인이 끝나기 전에는 Mission PASS로 처리하지 않습니다.

## 원본 Source

- [B1-1 미션 PDF](./b1-1-mission.pdf) — 최우선
- [B1-1 미션 Markdown](./b1-1-mission.md)
- [B1-1 평가 항목](./b1-1-evaluation.md)
- `agent-app.zip` — 제공 실행 데이터

## 이전 결과 보존

2026-08-16 이전 급행 수행 상태는 `archive/pre-restart-20260816` 브랜치에서 보존합니다. 좋은 구현은 다시 검증해 재사용하지만 과거 상태를 현재 PASS로 자동 승계하지 않습니다.

> **현재는 G5 Runtime만 수행하면 됩니다. Repository 구조를 다시 설계하거나 보너스를 추가하지 않습니다.**
