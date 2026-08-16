# Codyssey Basic B1-1

## 구분

- 필수 미션 (REQUIRED)
- 현재 훈련 체계: **Round 01 — CLEAR**
- 현재 상태: **🟡 ACTIVE**
- 현재 운영 모드: **Phase A — REFERENCE BUILD**

## 시작 위치

- `training/round-01-clear/REFERENCE-BUILD.md` — 기준 구현 준비 현황
- `training/round-01-clear/BEGINNER-GUIDE.md` — 나중에 실제 Runtime에서 처음부터 따라가는 가이드
- `training/round-01-clear/CHECKLIST.md` — 공식 Mission/Evaluation 누락 및 CLEAR Gate 확인

현재는 사용자 Runtime을 기다리지 않고 **Reference Complete Version을 먼저 준비**합니다. 실제 Ubuntu/WSL 실행, sudo 작업, SSH/Firewall 적용, 프로세스/포트, cron, Evidence는 이후 Phase C에서 수행합니다.

## 공식 원본

- `b1-1-mission.pdf`
- `b1-1-mission.md`
- `b1-1-evaluation.md`
- `agent-app.zip`

공식 원본은 수정하지 않습니다. 훈련 결과는 `training/` 아래에서 차수별로 독립 관리합니다.

## Round 01 원칙

1. 공식 Mission/Evaluation/제공 파일을 가장 먼저 확인합니다.
2. ChatGPT가 전체 Reference Complete Path를 먼저 설계합니다.
3. Phase A에서는 실제 환경 없이 만들 수 있는 구현·문서·검증 도구를 먼저 완성합니다.
4. Phase C Runtime에서 입문자는 현재 Step에 필요한 용어와 개념만 JIT 방식으로 학습합니다.
5. 각 Step은 `왜 → 무엇 → 용어/개념 → 명령/코드 → 예상 결과 → 의미 → 오류 해결 → 완료 확인` 흐름으로 진행합니다.
6. 환경 변경은 `현재 상태 확인 → 백업 → 변경 → 문법 검사 → 적용 → 검증 → Evidence` 순서를 지킵니다.
7. Round 01에서는 주요 명령을 사용자가 직접 실행하며 이해합니다. 자동화 스크립트는 재현·복구 보조 수단입니다.
8. Secret, Password, API Key, Token, Private Key, 실제 `*.key` 값은 GitHub·채팅·로그·Evidence에 저장하지 않습니다.
9. 실제 실행·검증·필요 Evidence가 끝나기 전에는 CLEAR로 표시하지 않습니다.
10. 현재 미션 통과에 필요하지 않은 보너스/고도화는 뒤로 미룹니다.

## Reference 구현

- `training/round-01-clear/monitor.sh` — 공식 요구사항을 기준으로 한 Bash 관제 스크립트
- `training/round-01-clear/environment/setup.sh` — 비네트워크 환경 재현 보조
- `training/round-01-clear/environment/verify.sh` — 검증 전용
- `training/round-01-clear/environment/reset.sh` — 보수적 초기화 보조
- `training/round-01-clear/docs/requirements-mapping.md` — 요구사항/검증/Evidence 연결
- `training/round-01-clear/docs/evaluation-qa.md` — 평가 설명형 문항 기준 답안
- `training/round-01-clear/evidence/README.md` — 실제 Evidence 수집 계획

## 상태

**🟡 ACTIVE — Reference Build 진행 중. Runtime PASS/CLEAR는 아직 주장하지 않습니다.**
