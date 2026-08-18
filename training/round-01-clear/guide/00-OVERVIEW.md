# B1-1 모듈 00 — 미션 개요와 공식 기준

> 범위: **개요·공식 기준·최종 산출물·전체 실행 경로**  
> [← 입문자 가이드 허브](../BEGINNER-GUIDE.md) · [입문자 가이드 허브](../BEGINNER-GUIDE.md) · [다음: 모듈 01 →](01-PREFLIGHT-AND-BASELINE.md)

## 📑 이 모듈 목차

- [00. 미션 한눈에 보기](#overview)
- [01. 공식 기준(Source of Truth)](#source-of-truth)
- [02. 최종적으로 만들어야 하는 것](#final-deliverables)
- [03. R01 실제 실행 경로(Runtime Path)](#runtime-path)

---

<a id="overview"></a>
## 00. 미션 한눈에 보기

- 미션: **B1-1 — 컴퓨터가 알아서 자기 상태를 점검하게 만들기**
- 구분: **필수 미션 (REQUIRED)**
- 분야: **Linux와 OS**
- 실행 환경(Runtime) 상태: **🟡 ACTIVE**
- 현재 운영 모드: **Phase C — 빠른 실행 방식(FAST EXECUTE) / 실제 실행(Runtime)**
- R01 기본 표준 실행 경로(Primary Golden Path): **MAC-V — macOS → OrbStack → Ubuntu 24.04 + systemd + UFW + Bash**
- 보조 확인(Secondary Check): **WIN-V — Windows 11 Pro → WSL2 Ubuntu 24.04**
- Docker: **선택 실습(Lab)**이며 B1-1 완료(CLEAR)의 기본 선행조건이 아님
- 기준 `AGENT_HOME`: **`/opt/agent-app`**
- 목표: Linux 운영 환경을 안전하게 구성하고 Bash `monitor.sh`로 시스템 상태를 점검·기록·자동 실행한 뒤 공식 평가항목을 증빙 자료(Evidence)로 증명합니다.

공식 미션(Mission)은 `$AGENT_HOME`의 예시 경로를 제시하지만 고정 경로로 요구하지 않습니다. R01은 공유 디렉터리의 상위 경로 권한 문제를 줄이고 `agent-common`/`agent-core` 최소 권한을 명확히 검증하기 위해 `/opt/agent-app`을 기준으로 사용합니다.

현재 운영 상태가 달라질 수 있으므로 Phase/Active/CLEAR 같은 진행 상태는 Control Tower `training/round-01-clear/NEXT-ACTIONS.md`를 최종 운영 기준으로 확인합니다.

<a id="source-of-truth"></a>
## 01. 공식 기준(Source of Truth)

1. `b1-1-mission.pdf`
2. `b1-1-mission.md`
3. `b1-1-evaluation.md`
4. `agent-app.zip`
5. 이번 훈련 차수(Round)의 실제 실행(Runtime) 결과와 증빙 자료(Evidence)

공식 원본은 수정하지 않습니다.

<a id="final-deliverables"></a>
## 02. 최종적으로 만들어야 하는 것

1. SSH `20022`, Root 원격 로그인 차단
2. UFW에서 인바운드 `20022/tcp`, `15034/tcp`만 허용
3. `agent-admin`, `agent-dev`, `agent-test`
4. `agent-common`, `agent-core`
5. `/opt/agent-app/upload_files`, `/opt/agent-app/api_keys`, `/var/log/agent-app` 권한/ACL
6. 제공 Agent 앱의 부팅 순서(Boot Sequence) 5단계 `[OK]`, `Agent READY`, `0.0.0.0:15034` LISTEN
7. Bash `monitor.sh`
8. 프로세스/포트 상태 점검(Process/Port Health Check)과 실패 시 `exit 1`
9. CPU/MEM/DISK 수집과 경고(Warning)
10. `/var/log/agent-app/monitor.log` 누적
11. `10MB / 10개` 로그 관리
12. `agent-admin` cron 매분 실행
13. 요구사항(Requirement) → 구현(Implementation) → 검증(Verification) → 증빙 자료(Evidence) 연결

<a id="runtime-path"></a>
## 03. R01 실제 실행 경로(Runtime Path)

```text
SOURCE
  ↓
Baseline / Preflight
  ↓
Golden Path / Prerequisites
  ↓
SSH 20022 안전 전환
  ↓
UFW 최종 정책
  ↓
Users / Groups / ACL
  ↓
Agent archive / environment / Secret(local only)
  ↓
Agent READY + 15034 LISTEN
  ↓
monitor.sh
  ↓
Log rotation
  ↓
cron
  ↓
Failure / Warning tests
  ↓
verify.sh
  ↓
Evidence + Evaluation Q&A
  ↓
✅ CLEAR
```

---

---

## 다음 이동

[← 입문자 가이드 허브](../BEGINNER-GUIDE.md) · [입문자 가이드 허브](../BEGINNER-GUIDE.md) · [다음: 모듈 01 →](01-PREFLIGHT-AND-BASELINE.md)
