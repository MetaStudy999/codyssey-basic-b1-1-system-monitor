# 14. 최종 검수와 제출

> **기억 문장:** 제출은 파일을 올리는 일이 아니라, 요구사항마다 증거가 있는 상태를 확정하는 일이다.

이 장에서는 B1-1의 필수 요구사항을 최종 검수하고 **자동 검증 → Codex 독립 검증 → 수정 → 사용자 최종 검증 → 제출** 순서로 완료합니다.

---

## 1. 최종 완료 조건

B1-1 필수 미션은 다음 조건을 모두 만족해야 합니다.

```text
구현 완료
+ 실제 테스트 완료
+ 증빙 존재
+ 평가 설명 가능
+ 재현 가능
+ 민감정보 없음
= FINAL PASS
```

`docs/reference/requirements-evidence-map.md`에 `TODO`, `BLOCKED`, 미해결 `FAIL`이 남아 있으면 제출 완료로 처리하지 않습니다.

---

## 2. 최종 검증 순서

```text
① Git 상태 확인
② Bash/설정 정적 검증
③ 실제 시스템 read-only 검증
④ 테스트 결과 확인
⑤ 증빙 연결 확인
⑥ 평가문항 설명 확인
⑦ 비밀정보 검사
⑧ Codex 독립 검증
⑨ 지적사항 수정·재검증
⑩ 사용자 최종 인수 검증
⑪ 제출
⑫ 15 보너스 고도화
```

---

## 3. Git 상태 확인

```bash
git status --short
git branch --show-current
git log --oneline -n 10
```

확인:

```text
의도하지 않은 파일 없음
실제 key/.env/log 없음
임시 백업 없음
변경 이유를 설명할 수 있음
```

---

## 4. 정적 검증

### Bash

```bash
bash -n scripts/preflight.sh
bash -n scripts/monitor.sh
bash -n scripts/verify.sh
```

보너스 Bash가 있으면 함께 검사합니다.

ShellCheck가 설치된 환경에서는 추가로 사용할 수 있습니다.

```bash
shellcheck scripts/*.sh
```

ShellCheck는 원본 필수 요구사항이 아니라 보조 품질 검사입니다.

### 설정 파일

실제 Ubuntu에 설치된 logrotate 설정:

```bash
sudo logrotate -d /etc/logrotate.d/agent-monitor
```

SSH:

```bash
sudo sshd -t
```

---

## 5. 최종 read-only 검증

저장소 루트에서:

```bash
sudo bash scripts/verify.sh
```

목표 최종 줄:

```text
[PASS] B1-1 read-only final verification checks passed.
```

하나라도 `[FAIL]`이 있으면 해당 담당 장으로 돌아갑니다.

---

## 6. 테스트 결과 확인

마스터 테스트:

```text
tests/test-cases.md
```

실제 결과:

```text
reports/test-results.md
```

최소 핵심 테스트:

```text
정상 monitor exit 0
프로세스 실패 exit 1
포트 실패 exit 1
WARNING은 계속 실행
로그 포맷
cron 자동 증가
logrotate
복구 후 정상
```

테스트 상태가 `TODO`인데 보고서만 PASS라고 쓰지 않습니다.

---

## 7. 증빙 연결 확인

마스터 추적표:

```text
docs/reference/requirements-evidence-map.md
```

각 필수 행에서 다음이 모두 있어야 합니다.

```text
담당 문서
구현 위치
검증 방법
증빙 위치
상태 PASS
```

증빙 파일이 실제로 존재하는지도 확인합니다.

---

## 8. 민감정보 검사

`.gitignore` 확인과 함께 실제 추적 파일을 검사합니다.

```bash
git ls-files | grep -E '(^|/)([^/]*\.key|\.env($|\.))' || true
```

허용 예:

```text
*.env.example
```

확인할 것:

```text
실제 key 내용 없음
비밀번호 없음
token 없음
private key 없음
불필요한 개인 IP 없음
운영 로그 전체 없음
```

이미 커밋된 비밀값이 발견되면 단순 파일 삭제만으로 끝내지 않고 Git 기록 노출 여부까지 검토합니다.

---

## 9. Codex 독립 검증

Codex에는 구현자의 자체 평가를 그대로 믿게 하지 않고 다음 자료를 기준으로 독립 검증하도록 합니다.

```text
1. b1-1-mission.md
2. b1-1-evaluation.md
3. docs/reference/requirements-evidence-map.md
4. README.md + docs/00~15
5. scripts/
6. config/
7. tests/
8. reports/
9. evidence/
```

### Codex 검증 요청 형식

```text
B1-1 저장소를 독립적으로 감사하라.

1. 원본 mission 요구사항을 모두 추출한다.
2. evaluation 문항을 모두 추출한다.
3. 요구사항별 구현 파일과 근거를 찾는다.
4. 실제 실행 가능한 검증 명령을 확인한다.
5. 누락·과잉구현·보안문제·재현성 문제를 찾는다.
6. 각 항목을 PASS / PARTIAL / FAIL / BLOCKED로 판정한다.
7. 판정마다 파일 경로와 근거를 제시한다.
8. 예시 출력이나 문서 주장만으로 PASS하지 않는다.
9. 실제 환경 증빙이 필요한 것은 별도로 표시한다.
10. 수정 우선순위를 BLOCKER / MAJOR / MINOR로 제시한다.
```

### 중요한 원칙

Codex 결과도 자동으로 진실로 간주하지 않습니다.

```text
Codex 지적
→ 원본 mission/evaluation 재확인
→ 실제 코드/환경 검증
→ 수정
→ 다시 Codex/verify
```

순서로 처리합니다.

---

## 10. 사용자 최종 인수 검증

Codex까지 통과한 뒤 사용자는 모든 제작 과정을 반복할 필요가 없습니다.

최종 핵심 검증만 수행합니다.

```bash
sudo bash scripts/verify.sh
```

그리고 핵심 시연:

```text
1. SSH/UFW
2. Agent READY/15034
3. monitor 정상
4. monitor 장애 exit 1
5. monitor.log
6. cron 자동 증가
7. logrotate
```

사용자는 **Acceptance Tester(인수 검증자)** 역할에 집중합니다.

---

## 11. 최종 시연 순서

평가자 앞에서 빠르게 보여 줄 때:

```text
① 요구사항 한 문장 설명
② sshd -T + ss
③ ufw status
④ id + getfacl
⑤ Agent READY + 15034
⑥ monitor.sh 수동 실행
⑦ monitor.log
⑧ agent-admin crontab
⑨ logrotate 정책
⑩ 장애 하나 + exit 1 + 복구
```

이 순서는 B1-1 전체를 짧게 설명하기 위한 시연 흐름입니다.

---

## 12. 제출 파일

원본 필수 산출물:

```text
요구사항 수행 내역서
monitor.sh
```

이 저장소에서는 이를 뒷받침하기 위해 추가로:

```text
README/docs
config
scripts
테스트
reports
evidence
```

를 관리합니다.

추가 자료가 원본 필수 산출물을 가리거나 대체해서는 안 됩니다.

---

## 13. 최종 체크리스트

상세 체크:

```text
reports/final-checklist.md
```

최종적으로 해당 파일의 필수 요구사항과 제출 안전 항목을 모두 확인합니다.

---

## 14. 현재 상태

현재 저장소는 다음 수준입니다.

```text
00~14 수행 문서 구조     구현 진행
SSH/UFW 실제 설정        TESTED
monitor.sh               IMPLEMENTED
cron/logrotate config    IMPLEMENTED
preflight/verify          IMPLEMENTED
IAM/ACL 실제 구성        미완료
Agent 실제 실행          미완료
monitor runtime           미완료
cron/logrotate runtime    미완료
전체 evidence             미완료
Codex 최종 감사           미실행
사용자 최종 인수          미실행
```

따라서 아직 최종 제출 PASS로 표시하지 않습니다.

---

## 15. 이번 단계 기억하기

### 한 문장

> **제출은 파일을 올리는 일이 아니라, 요구사항마다 증거가 있는 상태를 확정하는 일이다.**

### 핵심어 3개

```text
VERIFY · AUDIT · ACCEPT
```

### 내가 설명할 수 있어야 할 것

> 왜 ChatGPT가 만든 뒤 Codex와 사용자가 다시 검증하는가?

답의 핵심은 **제작자와 검증자의 관점을 분리해 누락과 자기확증을 줄이기 위해서**입니다.

---

## 16. 완료 체크

- [x] 최종 검수 절차 정의
- [x] read-only verify 절차 정의
- [x] 비밀정보 검사 정의
- [x] Codex 독립 검증 기준 정의
- [x] 사용자 최종 인수 흐름 정의
- [x] 최종 시연 순서 정의
- [ ] 필수 요구사항 실제 전체 PASS
- [ ] evidence 전체 연결
- [ ] Codex 독립 검증
- [ ] Codex BLOCKER/MAJOR 수정 완료
- [ ] 사용자 최종 인수 검증
- [ ] 최종 제출

현재 14단계는 **최종 게이트 설계 완료 / 제출 전**입니다.

---

## 이동

- [이전: 13. 재현 시험](./13-reproducibility-test.md)
- [다음: 15. 보너스](./15-bonus.md)
- [전체 목차](./README.md)
