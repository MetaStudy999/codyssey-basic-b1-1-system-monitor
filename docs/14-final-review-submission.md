# 14. 최종 검수와 제출

> **기억 문장:** 제출은 파일을 올리는 일이 아니라, 요구사항마다 실제 근거가 연결된 상태를 확정하는 일이다.

이 장에서는 **정적검증 → 현재상태 확인 → runtime acceptance → evidence → Codex → 사용자 인수** 순서로 최종 검수합니다.

---

## 1. FINAL PASS 조건

```text
원본 요구사항 구현
+ 실제 runtime 테스트
+ evidence 연결
+ 평가 설명 가능
+ 재현 가능
+ 민감정보 없음
+ 독립 검토
= FINAL PASS
```

`verify.sh` 한 번 통과만으로 FINAL PASS를 선언하지 않습니다.

---

## 2. 최종 게이트

```text
① Git/원본 보존 확인
② Bash·설정 정적검증
③ preflight
④ verify — 현재 상태 read-only
⑤ acceptance-test — 실제 기능·장애·cron
⑥ 수동으로 남은 SSH/logrotate/재현 검증
⑦ test-results 갱신
⑧ evidence 연결
⑨ requirements-evidence-map 최종 대조
⑩ Codex 독립 Audit
⑪ BLOCKER/MAJOR 수정 및 재검증
⑫ 사용자 최종 인수
⑬ 제출
⑭ Bonus 최종 검증·고도화
```

---

## 3. Git과 원본 파일

```bash
git status --short
git branch --show-current
git rev-parse HEAD
```

다음 원본은 임의 수정하지 않습니다.

```text
b1-1-mission.md
b1-1-mission.pdf
b1-1-evaluation.md
agent-app.zip
```

---

## 4. 정적검증

```bash
bash -n scripts/preflight.sh
bash -n scripts/monitor.sh
bash -n scripts/verify.sh
bash -n scripts/acceptance-test.sh
bash -n scripts/report.sh
bash -n scripts/archive-logs.sh
```

선택:

```bash
shellcheck scripts/*.sh
```

설정:

```bash
sudo sshd -t
sudo logrotate -d /etc/logrotate.d/agent-monitor
```

---

## 5. 현재 상태 검증

```bash
sudo bash scripts/verify.sh
```

이 도구는 다음과 같은 **현재 구성 상태**를 확인합니다.

```text
SSH/UFW
사용자·그룹
주요 디렉터리 권한
환경 파일/key 메타데이터
Agent process/15034
monitor 배치/로그 포맷
cron 등록
logrotate 설정
tracked secret file 패턴
```

성공해도 Boot Sequence와 실제 장애 동작까지 증명한 것은 아닙니다.

---

## 6. Runtime Acceptance

Agent 시작 출력을 안전하게 저장한 뒤:

```bash
sudo bash scripts/acceptance-test.sh \
  --agent-boot-log <Agent 시작 출력 파일>
```

주요 확인:

```text
Boot 5 [OK]
Agent READY
ACL 허용/차단
monitor 정상 exit 0
process failure exit 1
port failure exit 1
threshold WARNING + 계속
monitor.log 포맷
cron 자동 증가
logrotate dry-run
```

`acceptance-test.sh`도 evidence 자체를 자동 완성하는 도구는 아닙니다. 실제 출력과 결과를 `reports/test-results.md`와 `evidence/`에 연결합니다.

---

## 7. 수동으로 남는 핵심 검증

자동화하기보다 사람이 확인하는 편이 안전한 항목:

```text
외부/별도 클라이언트 SSH 20022 접속
Agent 실제 ZIP 경로/파일 선택 확인
logrotate 강제 회전과 최대 파일 수 확인
재부팅 후 지속성
가능하면 깨끗한 Ubuntu 재현
평가 질문 구두 설명
```

---

## 8. evidence와 테스트 ledger

테스트 정의:

```text
tests/test-cases.md
```

실제 결과:

```text
reports/test-results.md
```

마스터 추적:

```text
docs/reference/requirements-evidence-map.md
```

각 필수 요구사항에는:

```text
구현 위치
검증 방법
실제 결과
증빙 경로
최종 상태
```

가 연결되어야 합니다.

---

## 9. 민감정보

```bash
git ls-files | grep -E '(^|/)([^/]*\.key|[^/]*\.env($|\.))' \
  | grep -vE '\.env\.example$' || true
```

허용 예시는 `.env.example`입니다.

실제 key 값, 비밀번호, token, private key, 불필요한 개인 IP, 전체 운영 로그를 제출물에 넣지 않습니다.

원본 미션 문서에 포함된 테스트 key 문구는 Source of Truth이므로 원본 파일을 변경하지 않되, 이를 구현 문서·reports·evidence에 복제하지 않습니다.

---

## 10. Codex 독립 검증

Codex에는 다음 우선순위로 감사하도록 요청합니다.

```text
1. b1-1-mission.md / PDF
2. b1-1-evaluation.md
3. 실제 scripts/config
4. requirements-evidence-map
5. docs/00~15
6. tests/reports/evidence
```

Codex도 문서 주장만으로 PASS하지 않도록 합니다.

최종 리뷰 결과:

```text
reports/codex-review.md
```

권장 분류:

```text
BLOCKER
MAJOR
MINOR
IMPROVEMENT
NEEDS-RUNTIME
```

---

## 11. 사용자 최종 인수

Codex의 BLOCKER/MAJOR를 해결한 후 사용자는 제작 과정을 전부 반복하지 않고 핵심 시연에 집중합니다.

```text
SSH/UFW
사용자·ACL
Agent READY/15034
monitor 정상/장애
monitor.log
cron 자동 증가
logrotate
평가 설명
```

---

## 12. 현재 상태

```text
Pre-Codex 코드/문서 보완   진행 완료 단계
SSH/UFW                   TESTED / evidence pending
IAM/ACL                   NEEDS-RUNTIME
Agent ZIP/static          TESTED
Agent runtime             NEEDS-RUNTIME
monitor 격리 fixture      TESTED / target NEEDS-RUNTIME
cron/logrotate runtime    NEEDS-RUNTIME
acceptance runtime        NEEDS-RUNTIME
전체 evidence             TODO (actual files 0)
Codex audit               TESTED
사용자 acceptance         BLOCKED (runtime 선행)
FINAL PASS                NO
```

---

## 이동

- [이전: 13. 재현 시험](./13-reproducibility-test.md)
- [다음: 15. 보너스](./15-bonus.md)
- [전체 목차](./README.md)
