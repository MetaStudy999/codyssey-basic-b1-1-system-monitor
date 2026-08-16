# codyssey-basic-b1-1-system-monitor

> **2026-08-16 New Baseline**  
> 현재 미션: **B1-1** · 현재 Gate: **G2 BUILD**  
> 과거 급행 수행 상태는 `archive/pre-restart-20260816`에 보존하며, 새 기준 이후 다시 검증한 결과만 현재 PASS로 인정합니다.

코디세이 기초 B1-1 **컴퓨터가 알아서 자기 상태를 점검하게 만들기** 미션 저장소입니다.

## 지금 할 일

1. [새 기준 체크리스트](./NEW-BASELINE.md)를 기준으로 기존 구현을 빠르게 감사합니다.
2. 필수 요구사항과 일치하는 코드는 **REUSE**, 부족한 부분만 **REWRITE/보완**합니다.
3. 보너스 과제와 고도화는 Mission Clear 뒤로 미룹니다.

현재 G1 Source Lock 증빙: [evidence/new-baseline-source-lock.md](./evidence/new-baseline-source-lock.md)

## 목표

Ubuntu 환경에서 SSH·방화벽·사용자·그룹·ACL을 구성하고, 제공 Agent를 일반 사용자로 실행한 뒤 Bash 기반 `monitor.sh`로 상태를 점검·기록·자동화합니다.

새 기준의 기본 흐름은 다음과 같습니다.

`G1 Source → G2 최소 필수 구현 → G3 Test → G4 Review → G5 Runtime → G6 Evidence → G7 Learn → G8 Merge/Clear`

## 환경 기준

원본 미션의 기준은 **Ubuntu 22.04 LTS 또는 동등한 Linux 환경**입니다.

기존 실습에서 사용했던 Ubuntu 24.04 계열 환경은 재사용할 수 있지만, 실제 Runtime은 G5에서 새 기준으로 다시 확인합니다. WSL2·OrbStack·Docker 등 환경 차이는 [환경별 차이](./docs/reference/environment-differences.md)에서 관리합니다.

## 기존 학습 문서 활용

기존 `00 + 5 × 3` 학습 문서는 삭제하지 않고 참고·재사용합니다.

1. **준비와 접근 — `01~03`**: 환경 → 저장소 → SSH
2. **시스템 구성 — `04~06`**: 방화벽 → 권한 → Agent
3. **구현과 자동화 — `07~09`**: Monitor → 자동화 → 테스트
4. **검증과 평가 — `10~12`**: 장애 → 증빙 → 평가
5. **완성과 고도화 — `13~15`**: 재현 → 제출 → 보너스

단, 과거 문서의 완료 표현은 현재 PASS를 의미하지 않습니다. 새 기준에서 다시 확인한 Evidence만 현재 상태에 반영합니다.

자세한 기존 문서 인덱스: [docs/README.md](./docs/README.md)

## PASS 원칙

`필수 구현 + 신뢰 가능한 테스트 + 필요한 실제 Runtime + 평가 증빙`

위 조건을 충족해야 현재 Cycle에서 Mission Clear로 판단합니다.

## 원본 문서

- [B1-1 미션 PDF](./b1-1-mission.pdf) — 최우선
- [B1-1 미션 Markdown](./b1-1-mission.md)
- [B1-1 평가 항목](./b1-1-evaluation.md)
- `agent-app.zip` — 제공 실행 데이터

## 주요 디렉터리

- `docs/`: 입문자 실행·학습 안내서
- `scripts/`: Bash 구현 및 검증 스크립트
- `config/`: 환경변수·cron·logrotate 설정 예시
- `tests/`: 테스트 정의와 재현 절차
- `reports/`: 수행·검증 결과
- `evidence/`: 명령 출력, 로그 등 객관적 근거
- `.live/mission-status.json`: **현재 새 Cycle 상태만 기록**

## 기억할 한 문장

> **과거 결과를 믿고 이어가는 것이 아니라, 좋은 것은 재사용하고 필수 요구사항만 빠르게 다시 검증하여 B1-1을 Clear한다.**
