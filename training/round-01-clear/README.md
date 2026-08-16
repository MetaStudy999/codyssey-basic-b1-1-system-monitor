# B1-1 Round 01 — CLEAR

## 현재 상태

- Runtime Mission: **🟡 ACTIVE**
- Phase A Reference Build: **CORE READY**
- Runtime/Evidence: **미검증**
- CLEAR: **아님**

## 시작 순서

1. `REFERENCE-STATUS.md` — Phase A 자체감사 결과
2. `REFERENCE-BUILD.md` — Reference 설계와 보완 내용
3. `BEGINNER-GUIDE.md` — Phase C 실제 15-Step 따라하기
4. `CHECKLIST.md` — Mission/Evaluation/CLEAR Gate

## Golden Path

```text
Ubuntu 22.04 LTS 또는 동등 Linux
+ systemd
+ OpenSSH Server
+ UFW
+ Bash
+ AGENT_HOME=/opt/agent-app
```

## 폴더 역할

- `environment/` — prerequisites, versions, setup/verify/reset
- `docs/` — requirements mapping, evaluation Q&A
- `evidence/` — 실제 Runtime Evidence 수집 규칙
- `monitor.sh` — 기준 Bash 관제 구현

## 핵심 운영 규칙

Phase A에서 Reference가 준비되었더라도 실제 SSH/UFW/사용자 권한/Agent/15034/monitor/cron/로그 회전/Evidence를 확인하지 않았다면 `✅ CLEAR`가 아닙니다.

실제 Secret 값은 GitHub·채팅·로그·Evidence에 저장하지 않습니다.
