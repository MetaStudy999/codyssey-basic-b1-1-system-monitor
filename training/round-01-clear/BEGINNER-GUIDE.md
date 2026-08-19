# B1-1 훈련 차수(Round) 01 — 입문자 가이드(Beginner Guide)

이 문서는 B1-1을 처음 수행하는 입문자가 공식 미션(Mission)/평가(Evaluation)를 기준으로 처음부터 끝까지 재현하기 위한 중심 가이드입니다.

> 현재 훈련 차수는 **R01 — CLEAR**이며, Control Tower의 현재 운영 기준은 **Phase C — 빠른 실행 방식(FAST EXECUTE) / 실제 실행(Runtime)**입니다. Phase A/B의 기준 구현(Reference Build)·설계 준비는 완료된 상태로 보고, 지금은 Ubuntu 실제 실행(Runtime) → 검증(Verification) → 증빙 자료(Evidence) → 완료(CLEAR)를 우선합니다. 실제 실행하지 않은 항목은 PASS/CLEAR로 기록하지 않습니다.

---

<a id="quick-start"></a>
## 🚀 빠른 시작(Quick Start)

> **공통 개발환경이 이미 준비되어 있고 B1-1 저장소를 받은 학습자**가 안전하게 현재 상태를 다시 확인하는 경로입니다.
> 처음 개발환경을 준비하는 경우에는 Control Tower의 `environments/START-HERE-DEVELOPMENT-ENVIRONMENT.md`를 먼저 완료한 뒤 돌아오세요.

### B1-1 진입 전 공통 환경 판정(Gate)

빠른 시작(Quick Start)을 실행하기 전에 Control Tower에서 다음 순서를 먼저 닫습니다.

```text
1. Git/GitHub 사용자 준비 상태(User Identity Readiness) 재확인
2. 공통 환경 마무리(Common Environment Closeout) 판정
3. 공통 환경 동결(Common Environment Freeze) 확인
4. 그 다음 B1-1 빠른 시작(Quick Start) → STEP 01
```

현재 운영 상태와 최종 판정은 Control Tower의 `training/round-01-clear/NEXT-ACTIONS.md`와 `environments/ubuntu/ENVIRONMENT-CLOSEOUT.md`를 기준으로 합니다.

Ubuntu Bash의 Control Tower root에서 사용자 상태를 읽기 전용으로 재확인합니다.

```bash
cd "$HOME/codyssey/codyssey-basic"
bash environments/ubuntu/verify-user-identity.sh
```

결과가 현재 Git/GitHub 작업에 필요한 수준으로 준비되었는지 확인한 뒤 `ENVIRONMENT-CLOSEOUT.md`의 Gate 1~4와 동결(Freeze) 조건을 확인합니다. **공통 환경 동결이 아직 확인되지 않았다면 SSH/UFW 변경을 시작하지 않고 STOP합니다.**

### 📍 실행 위치

```text
Host       : MAC-V OrbStack Ubuntu 24.04 또는 WIN-V WSL2 Ubuntu 24.04
Terminal   : Ubuntu Bash
Repository : $HOME/codyssey/codyssey-basic-b1-1-system-monitor
권한       : 일반 사용자
venv       : 해당 없음
```

### 빠른 상태 확인

```bash
cd "$HOME/codyssey/codyssey-basic-b1-1-system-monitor"
pwd
git branch --show-current
git status --short
cat /etc/os-release
uname -m
ps -p 1 -o comm=
bash -n training/round-01-clear/monitor.sh
```

### 줄별 의미

```text
1. cd ...
   → B1-1 저장소 루트(Repository Root)로 이동합니다.

2. pwd
   → 실제 작업 위치가 Ubuntu의 B1-1 Repository인지 확인합니다.

3. git branch --show-current
   → 현재 작업 브랜치(Branch)를 확인합니다.

4. git status --short
   → 예상하지 않은 로컬 변경이 있는지 확인합니다.

5. cat /etc/os-release
   → Ubuntu 배포판과 버전을 확인합니다.

6. uname -m
   → 제공 Agent 실행 파일 선택에 필요한 CPU 아키텍처(Architecture)를 확인합니다.

7. ps -p 1 -o comm=
   → PID 1을 확인하여 systemd 기반 실행 환경(Runtime)인지 판단합니다.

8. bash -n .../monitor.sh
   → monitor.sh를 실행하지 않고 Bash 문법만 검사합니다.
```

### 빠른 시작(Quick Start) 정상 기준

```text
[ ] Control Tower에서 공통 환경 동결(Common Environment Freeze)이 확인되었다.
[ ] pwd가 /home/<user>/codyssey/codyssey-basic-b1-1-system-monitor 계열이다.
[ ] 현재 Branch와 변경사항을 이해하고 있다.
[ ] Ubuntu 24.04 실행 환경(Runtime)이다.
[ ] CPU 아키텍처(Architecture)를 확인했다.
[ ] PID 1이 systemd이다.
[ ] monitor.sh 문법 검사에 오류가 없다.
```

```text
✅ GO
→ 공통 환경 동결이 확인되고 위 항목을 모두 만족하면 STEP 01부터 현재 실제 실행(Runtime) 상태를 확인합니다.

❌ STOP
→ 공통 환경 마무리/동결이 미완료이거나 위 항목 중 하나라도 다르면 SSH/UFW 설정을 시작하지 않습니다.
→ Control Tower 환경 판정(Gate) 또는 개발환경·저장소(Repository) 위치·브랜치(Branch)·실행 환경(Runtime)부터 먼저 바로잡습니다.
```

재실행 안전성:

```text
cd / pwd / branch / git status / OS·Architecture·systemd 확인 → 🟢 SAFE TO RERUN
bash -n monitor.sh                                      → 🟢 SAFE TO RERUN
```

> 빠른 시작(Quick Start)에서는 SSH, UFW, 사용자, ACL, Agent, cron 설정을 자동 변경하지 않습니다. 시스템 변경은 반드시 해당 상세 STEP의 Checkpoint와 STOP/GO 기준을 따라 수행합니다.

---

<a id="module-map"></a>
## 📚 학습 모듈 지도(Module Map)

B1-1의 상세 따라하기는 **전체 중앙 허브(Hub) → 모듈별 지역 목차(Local Table of Contents, Local TOC) → 세부 학습 문서(Learning Unit)**의 3계층 정보 구조(Information Architecture, IA)로 관리합니다. `BEGINNER-GUIDE.md`는 빠른 시작(Quick Start)과 전체 모듈 이동을 담당하고, 각 `guide/<module>/README.md`는 연관 개념과 STEP을 분류한 모듈 목차를 담당합니다.

> 문서 구조를 나눈 것만으로 실제 실행(Runtime), 검증(Verification), 증빙 자료(Evidence), 완료(CLEAR) 상태가 바뀌지는 않습니다.

### 권장 진행 순서

```text
00 개요
→ 01 실행 전 점검
→ 02 SSH/UFW
→ 03 사용자/그룹/ACL
→ 04 Agent Runtime
→ 05 Monitor/Log Rotation
→ 06 cron/Failure/Warning
→ 07 Verification/Evidence
→ 08 Final CLEAR
```

| 모듈 | 범위 | 바로가기 | 현재 상태 |
|---:|---|---|---|
| 00 | 개요·공식 기준·최종 산출물·전체 실행 경로 | [미션 개요와 공식 기준](guide/00-overview/README.md) | ⬜ 실제 실행 전/진행 중 |
| 01 | STEP 01~02 | [실행 전 점검과 기준 상태](guide/01-preflight-baseline/README.md) | ⬜ 실제 실행 전/진행 중 |
| 02 | STEP 03~04 | [SSH와 방화벽](guide/02-ssh-firewall/README.md) | ⬜ 실제 실행 전/진행 중 |
| 03 | STEP 05 | [사용자·그룹·접근 제어 목록](guide/03-users-groups-acl/README.md) | ⬜ 실제 실행 전/진행 중 |
| 04 | STEP 06~07 | [Agent 준비와 실제 실행](guide/04-agent-runtime/README.md) | ⬜ 실제 실행 전/진행 중 |
| 05 | STEP 08~09 | [모니터링·로그 회전](guide/05-monitor-log/README.md) | ⬜ 실제 실행 전/진행 중 |
| 06 | STEP 10~11 | [cron 자동 실행·실패·경고 분기](guide/06-cron-health-tests/README.md) | ⬜ 실제 실행 전/진행 중 |
| 07 | STEP 12~14 | [검증·증빙·평가 설명](guide/07-verification-evidence/README.md) | ⬜ 실제 실행 전/진행 중 |
| 08 | STEP 15 + Reference/Secret 원칙 | [최종 완료 판정](guide/08-final-clear/README.md) | ⬜ 실제 실행 전/진행 중 |

### 진행 원칙

- 처음 수행하면 `00 → 01 → ... → 08` 순서로 진행합니다.
- 각 모듈의 `README.md`에서 연관된 개념과 STEP의 지역 목차(Local TOC)를 먼저 확인한 뒤 세부 학습 문서로 이동합니다.
- 이미 완료한 단계가 있어도 실제 상태를 확인하지 않고 체크하지 않습니다.
- 실패하면 다음 모듈로 넘어가지 않고 해당 STEP의 STOP/복구(Recovery) 기준을 따릅니다.
- `CHECKLIST.md`는 최종 완료 여부를 관리하고, 실제 증빙은 `evidence/`에 저장합니다.

## 🔗 핵심 문서 바로가기

- [CHECKLIST.md](CHECKLIST.md) — 실제 완료 판정 체크리스트
- [requirements-mapping.md](docs/requirements-mapping.md) — 요구사항→구현→검증→증빙 연결
- [evaluation-qa.md](docs/evaluation-qa.md) — 평가 질의응답 학습
- [Evidence Guide](evidence/README.md) — 실제 증빙 수집 기준
- [Environment](environment/README.md) — B1-1 실행 환경

## 문서 분할 무결성 원칙

이번 분할은 **내용 삭제가 아니라 구조 리팩터링(Refactoring)**입니다. 기존 STEP 01~15의 상세 본문은 `guide/<module>/<learning-unit>.md`에 보존하며 공식 미션/평가 요구, 명령, STOP/GO, 복구, 재실행 안전성, 비밀정보(Secret) 보호 원칙을 유지합니다.
