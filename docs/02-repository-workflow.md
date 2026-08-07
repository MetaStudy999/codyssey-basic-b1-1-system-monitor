# 02. 저장소와 작업 기록 체계

> **기억 문장:** 작업은 다시 설명하고 검증할 수 있게 기록한다.

이 장에서는 B1-1을 구현하면서 코드·문서·테스트·증빙이 뒤섞이지 않도록 **Git 저장소의 역할과 작업 흐름을 고정**합니다.

---

## 1. 목표

이 장을 마치면 다음을 설명할 수 있어야 합니다.

- 원본 미션과 구현 파일을 왜 분리하는가
- `docs/`, `scripts/`, `config/`, `tests/`, `reports/`, `evidence/`의 역할
- 어떤 파일을 Git에 올리고 어떤 파일은 제외하는가
- 브랜치와 커밋을 어떤 단위로 사용하는가
- 요구사항 하나가 구현·테스트·증빙까지 어떻게 연결되는가

이 장의 목적은 Git 명령어를 많이 외우는 것이 아니라 **작업을 잃지 않고, 나중에 Codex와 사람이 독립적으로 검증할 수 있게 만드는 것**입니다.

---

## 2. 이해 — B1-1 저장소의 3개 층

저장소는 머릿속에서 다음 세 층으로 기억합니다.

```text
① 기준
   mission / evaluation

② 구현·학습
   docs / scripts / config / tests

③ 검증·증명
   reports / evidence / requirements map
```

### 2.1 기준 자료

```text
b1-1-mission.md
b1-1-evaluation.md
b1-1-mission.pdf
agent-app.zip
```

원본 미션과 평가 문서는 **Source of Truth**입니다. 구현 편의를 위해 요구사항을 임의로 고쳐 쓰지 않습니다.

`agent-app.zip`은 제공 프로그램 원본이므로, 원본을 직접 수정하기보다 실제 실습 디렉터리에서 복사·해제하여 사용합니다.

### 2.2 구현·학습 자료

```text
docs/      실행·학습 안내
scripts/   Bash 구현 및 검증 스크립트
config/    환경변수·cron·logrotate 설정 예시
tests/     테스트 정의
```

### 2.3 검증·증명 자료

```text
reports/   사람이 읽는 수행·검증 보고서
evidence/  실제 명령 출력·로그·스크린샷 등의 근거
```

그리고 다음 파일이 전체 요구사항을 연결합니다.

```text
docs/reference/requirements-evidence-map.md
```

---

## 3. 저장소 구조

현재 B1-1의 핵심 구조는 다음과 같습니다.

```text
codyssey-basic-b1-1-system-monitor/
├── README.md
├── b1-1-mission.md
├── b1-1-evaluation.md
├── b1-1-mission.pdf
├── agent-app.zip
│
├── docs/
│   ├── README.md
│   ├── 00-start-here.md
│   ├── 01-environment.md
│   ├── 02-repository-workflow.md
│   ├── 03-ssh-security.md
│   ├── 04-firewall-network.md
│   ├── 05-users-groups-acl.md
│   ├── 06-agent-setup.md
│   ├── 07-monitor-script.md
│   ├── 08-logging-cron.md
│   ├── 09-testing-recovery.md
│   ├── 10-troubleshooting.md
│   ├── 11-execution-evidence.md
│   ├── 12-evaluation-preparation.md
│   ├── 13-reproducibility-test.md
│   ├── 14-final-review-submission.md
│   ├── 15-bonus.md
│   ├── reference/
│   └── templates/
│
├── scripts/
├── config/
├── tests/
├── reports/
├── evidence/
└── .gitignore
```

### 기억 방법

```text
문서 = docs
코드 = scripts
설정 = config
시험 = tests
설명 = reports
증거 = evidence
```

---

## 4. 실행 — 작업 브랜치 확인

현재 B1-1 문서·환경 정리는 다음 작업 브랜치에서 진행합니다.

```text
docs/b1-1-environment-guide
```

로컬 저장소에서 현재 브랜치를 확인할 때:

```bash
git branch --show-current
```

예상 결과:

```text
docs/b1-1-environment-guide
```

### 왜 `main`에서 바로 작업하지 않나요?

작업 브랜치를 사용하면 다음이 가능합니다.

```text
변경 전 main 보존
→ 작업 브랜치에서 수정
→ diff/테스트/Codex 검토
→ 문제 수정
→ 검증 완료 후 main 반영
```

실수했을 때 복구하기 쉽고, 변경 범위를 독립적으로 검토할 수 있습니다.

---

## 5. 실행 — 변경 상태 확인

로컬에서는 다음 명령으로 변경 파일을 확인합니다.

```bash
git status --short
```

변경 내용을 자세히 확인하려면:

```bash
git diff
```

이미 스테이징한 파일은:

```bash
git diff --cached
```

으로 확인합니다.

### 원칙

커밋하기 전에 최소한 다음 질문에 답할 수 있어야 합니다.

```text
무엇을 바꿨는가?
왜 바꿨는가?
어떤 요구사항과 연결되는가?
어떻게 검증했는가?
비밀정보가 들어가지는 않았는가?
```

---

## 6. 파일 하나씩, 커밋은 의미 단위로

B1-1은 **파일을 하나씩 완성**하되, 커밋은 지나치게 잘게 쪼개지 않습니다.

권장 흐름:

```text
파일 하나 선택
→ 원본 미션/평가 확인
→ 작성·수정
→ 자체 검토
→ 관련 추적표 갱신
→ 다음 관련 파일
→ 하나의 기능 묶음 완성
→ 테스트
→ commit
→ Codex 검증
```

### 좋은 커밋 단위 예시

```text
환경 안내 + 환경 추적표
SSH 구현 + SSH 검증 문서
monitor.sh + 테스트
cron + logrotate + 운영 문서
최종 증빙 + 평가 매핑
```

파일 하나에 한 커밋을 강제하지 않습니다. **한 커밋이 하나의 설명 가능한 목적**을 가지는 것이 더 중요합니다.

---

## 7. 요구사항 추적 방식

B1-1에서는 모든 요구사항을 다음 흐름으로 연결합니다.

```text
원본 요구사항
    ↓
담당 docs 장
    ↓
실제 코드/설정
    ↓
검증 명령 또는 테스트
    ↓
증빙
    ↓
평가 문항
```

마스터 파일:

```text
docs/reference/requirements-evidence-map.md
```

예시:

```text
SSH-01
요구사항 : SSH 포트 20022
문서     : docs/03-ssh-security.md
설정     : /etc/ssh/sshd_config.d/99-b1-1.conf
검증     : sshd -T, ss -lntp
증빙     : evidence/03-ssh/
상태     : TODO → IMPLEMENTED → TESTED → PASS
```

### 상태 규칙

```text
TODO        아직 구현 전
IMPLEMENTED 구현됨, 실제 검증 전
TESTED      실제 검증 성공, 증빙 정리 전
PASS        구현 + 테스트 + 증빙 완료
NEEDS-RUNTIME 실제 Ubuntu 없이는 수행·검증할 수 없음
BLOCKED     외부 조건 때문에 현재 완료 불가
```

**문서가 존재한다는 이유만으로 PASS를 부여하지 않습니다.**

---

## 8. reports와 evidence를 구분한다

### `reports/`

사람이 읽고 이해하기 위한 설명입니다.

예:

```text
어떤 설정을 했는가
왜 이 방법을 선택했는가
테스트 결과가 무엇인가
어떤 오류가 발생했는가
어떻게 복구했는가
```

### `evidence/`

주장을 뒷받침하는 실제 근거입니다.

예:

```text
sshd -T 출력
ufw status 출력
id/getfacl 출력
Agent READY 출력
monitor.log 일부
crontab 확인 결과
```

쉽게 기억하면:

```text
report   = 설명
 evidence = 증명
```

---

## 9. 증빙 파일 규칙

현재 `evidence/README.md`의 원칙을 따릅니다.

- 단계 번호와 작업명을 파일명에 포함
- 가능한 경우 실행 명령·계정·시각·종료 코드 기록
- 실제 비밀번호·API 키·토큰은 저장하지 않음
- 불필요한 개인 IP는 마스킹
- 시스템 백업 원본이나 전체 운영 로그는 Git에 커밋하지 않음

권장 파일명 예시:

```text
01-os-release.txt
03-sshd-effective-config.txt
04-ufw-status.txt
05-agent-groups.txt
06-agent-ready.txt
07-monitor-success.txt
09-monitor-process-failure.txt
14-final-verification.txt
```

### 증빙 원칙

예시 출력을 복사해서 증빙으로 만들지 않습니다.

```text
실제 실행
→ 필요한 부분만 보존
→ 비밀값 마스킹
→ evidence에 저장
```

---

## 10. `.gitignore` 확인

현재 `.gitignore`는 다음 종류를 Git에서 제외합니다.

```text
.env / .env.*
*.key / *.pem
local-backup/ / backup/
*.log / *.log.* / logs/
편집기·OS 임시파일
```

`*.env.example`은 예외적으로 추적할 수 있으므로 실제 비밀값이 없는 설정 예시를 저장할 수 있습니다.

### 확인 명령

```bash
git check-ignore -v .env t_secret.key example.log 2>/dev/null || true
```

### 주의

`.gitignore`는 **이미 Git에 커밋된 비밀정보를 자동으로 삭제해 주지 않습니다.** 따라서 커밋 전 검사가 중요합니다.

---

## 11. 비밀정보 점검

커밋 전에는 최소한 다음 유형을 사람이 확인합니다.

```text
비밀번호
API Key
Token
Private Key
실제 secret 파일 내용
불필요한 개인정보
```

B1-1 원본 미션의 테스트 키 값은 실제 시스템에서 요구될 수 있지만, **저장소의 증빙·보고서에는 값을 그대로 노출하지 않습니다.** 경로, 존재 여부, 소유권, 권한 중심으로 증명합니다.

---

## 12. Codex 검증을 위한 준비

Codex가 독립적으로 검토할 때는 다음 순서로 자료를 제공합니다.

```text
1. b1-1-mission.md
2. b1-1-evaluation.md
3. requirements-evidence-map.md
4. 구현 파일
5. tests
6. reports/evidence
```

검토 기준은 다음과 같습니다.

```text
요구사항 누락 여부
과잉·잘못된 구현 여부
테스트 가능 여부
재현 가능 여부
비밀정보 노출 여부
평가문항과 증빙의 연결 여부
```

Codex 검증 결과가 있다고 해서 자동 PASS로 처리하지 않습니다. 지적사항을 실제 코드·문서에 수정하고 재검증합니다.

---

## 13. 오류와 복구

### 잘못된 브랜치에서 작업함

현재 변경을 잃지 말고 먼저 `git status`를 확인합니다. 무작정 `reset --hard`를 사용하지 않습니다.

### 비밀 파일을 실수로 stage함

커밋 전이라면 해당 파일을 스테이징에서 제거하고 `.gitignore`를 확인합니다.

### 증빙과 보고서가 서로 다름

보고서 문장을 실제 증빙에 맞춰 수정합니다. 증빙을 보고서에 맞추기 위해 꾸미지 않습니다.

### 원본 미션 파일을 실수로 수정함

변경 내용을 확인한 뒤 원본 버전으로 복구하고 구현 내용은 별도 docs/config/scripts 파일로 옮깁니다.

---

## 14. 검증

이 장을 다음 질문으로 검증합니다.

```text
원본 자료와 구현 자료가 분리되어 있는가?
현재 작업 브랜치를 설명할 수 있는가?
reports와 evidence의 차이를 설명할 수 있는가?
비밀정보가 Git에서 제외되는가?
요구사항을 requirements map에서 추적할 수 있는가?
커밋 전 diff를 확인하는 절차가 있는가?
Codex가 독립적으로 검토할 자료 구조가 준비되어 있는가?
```

이 항목들은 저장소 운영 품질을 위한 절차이며, 원본 B1-1의 기능 요구사항을 대체하지 않습니다.

---

## 15. 이번 단계 기억하기

### 한 문장

> **작업은 다시 설명하고 검증할 수 있게 기록한다.**

### 핵심어 3개

```text
branch · trace · evidence
```

### 핵심 명령 3개

```bash
git branch --show-current
git status --short
git diff
```

### 내가 설명할 수 있어야 할 것

> 왜 코드만 남기지 않고 요구사항·테스트·증빙을 함께 연결하는가?

답의 핵심은 **미션 누락을 막고, 다른 사람이나 Codex가 독립적으로 재검증할 수 있게 하기 위해서**입니다.

---

## 16. 완료 체크

- [x] 원본 미션·평가 문서를 기준 자료로 분리
- [x] `docs/scripts/config/tests/reports/evidence` 역할 정의
- [x] 요구사항 추적표 위치 확정
- [x] `.gitignore`의 비밀정보·백업·로그 제외 정책 확인
- [x] 증빙 저장 원칙 확정
- [x] 현재 작업 브랜치 `docs/b1-1-environment-guide` 확인
- [x] Codex 독립 검증을 위한 기본 자료 구조 확정

02단계의 저장소 작업 체계는 준비되었습니다. 실제 기능 구현의 PASS 여부는 각 담당 장에서 별도로 판정합니다.

---

## 이동

- [이전: 01. 환경 준비](./01-environment.md)
- [다음: 03. SSH 보안](./03-ssh-security.md)
- [전체 목차](./README.md)
