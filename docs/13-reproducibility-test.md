# 13. 처음부터 다시 수행하는 재현 시험

> **기억 문장:** 내 컴퓨터에서 한 번 된 것이 아니라, 다시 해도 같은 결과가 나와야 한다.

이 장에서는 B1-1을 새 세션·재부팅·가능하면 깨끗한 Ubuntu 환경에서 다시 확인합니다.

---

## 1. 목표

재현 시험은 다음 두 질문에 답해야 합니다.

```text
문서만 보고 다시 만들 수 있는가?
다시 시작해도 같은 검증 결과가 나오는가?
```

최종 자동 점검 도구:

```text
scripts/preflight.sh
scripts/verify.sh
```

두 스크립트는 **조회 전용**으로 설계했습니다. 사용자·SSH·방화벽·ACL·cron을 자동 수정하지 않습니다.

---

## 2. `preflight.sh` 역할

시스템을 변경하기 전 환경을 빠르게 점검합니다.

확인 범위:

```text
실행 사용자
Ubuntu/Linux 정보
CPU 아키텍처 기록
systemd
sudo
sshd
ufw
cron
ACL
ss
logrotate
pgrep/awk/df
unzip/python3
현재 주요 포트
Root 디스크
```

실행:

```bash
bash scripts/preflight.sh
```

결과 형식:

```text
[PASS]
[WARN]
[FAIL]
[GO] 또는 [STOP]
```

`WARN`은 반드시 실패를 뜻하지 않습니다. 예를 들어 Ubuntu 24.04는 원본 22.04 기준과 다른 동등 환경이므로 실제 동작 검증이 필요하다는 경고를 표시할 수 있습니다.

---

## 3. `verify.sh` 역할

최종 시스템 상태를 **수정 없이 검사**합니다.

완전한 검증을 위해 Root 권한으로 실행합니다.

```bash
sudo bash scripts/verify.sh
```

검증 범위:

```text
SSH 20022
Root login no
22 미LISTEN
UFW active/default deny/허용 포트
사용자 3개
그룹 멤버십
디렉터리 owner/group/mode
부모 ACL
환경변수 파일
key 파일 권한
Agent non-root
0.0.0.0:15034
monitor.sh owner/group/750
monitor Bash 문법
monitor.log 포맷
agent-admin cron
logrotate 10M/10
저장소 secret 추적 여부
```

### 왜 verify.sh가 설정을 고치지 않는가

검증 도구가 시스템을 자동 수정하면:

```text
시험 전에 잘못되어 있었는지
검증 도구가 고쳐서 정상처럼 보이는지
```

구분하기 어렵습니다.

그래서:

```text
verify = 관찰만
repair = 사람이 담당 장의 절차로 수행
```

으로 분리합니다.

---

## 4. 재현 시험 A — 새 터미널

현재 터미널에서만 우연히 설정된 값이 없는지 확인합니다.

새 터미널을 열고:

```bash
whoami
sudo bash scripts/verify.sh
```

확인 포인트:

```text
로그인 셸의 임시 export 없이도 환경 구성 동작
SSH/UFW 지속
사용자·그룹 지속
파일 권한 지속
cron 등록 지속
```

---

## 5. 재현 시험 B — cron 최소 환경

08장의 최소 환경 시험을 다시 수행합니다.

```bash
sudo -u agent-admin env -i \
  HOME=/home/agent-admin \
  USER=agent-admin \
  LOGNAME=agent-admin \
  SHELL=/bin/bash \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  /home/agent-admin/agent-app/bin/monitor.sh
```

목표:

```text
Agent 정상 상태에서 exit 0
monitor.log 증가
```

---

## 6. 재현 시험 C — 재부팅 후

재부팅은 현재 작업과 다른 서비스에 영향을 줄 수 있으므로 **사용자가 재부팅 가능한 실습 환경에서만** 수행합니다.

재부팅 후 최소 확인:

```bash
systemctl is-active ssh.socket
systemctl is-active ufw
systemctl is-active cron
sudo ss -lntp | grep -E ':(22|20022|15034)\b' || true
sudo -u agent-admin crontab -l
```

Agent가 자동 시작되도록 요구된 미션이 아니라면 Agent는 미션 절차에 따라 다시 실행한 뒤 `15034`와 monitor를 확인합니다.

> 원본 미션이 Agent의 systemd 자동 시작을 필수로 요구한다고 문서에서 추가 가정하지 않습니다.

---

## 7. 재현 시험 D — 깨끗한 Ubuntu

가능하면 최종적으로 새로운 Ubuntu 환경에서 수행합니다.

기준 우선순위:

```text
원본 기준: Ubuntu 22.04 또는 동등 환경
현재 검증 사례: Ubuntu 24.04.4 LTS
```

깨끗한 환경에서는:

```text
preflight
→ 01~08 수행
→ 09 테스트
→ verify
```

순서로 진행합니다.

### 중요한 원칙

현재 환경의 숨은 설정을 복사해서 성공시키지 않습니다. 문서와 저장소 파일만 사용해 재현해야 합니다.

---

## 8. 재현 실패 시 수정 위치

| 실패 | 돌아갈 장 |
|---|---|
| OS/systemd/tool | 01 |
| Git/비밀정보 | 02 |
| SSH | 03 |
| UFW | 04 |
| 사용자·ACL | 05 |
| Agent | 06 |
| monitor | 07 |
| cron/logrotate | 08 |
| 장애 시험 | 09 |
| 오류 분석 | 10 |
| 증빙 | 11 |
| 설명/평가 | 12 |

재현 시험에서 발견한 문제는 13장에서 임시 우회하지 않고 **원래 담당 문서와 코드로 되돌아가 수정**합니다.

---

## 9. 재현 결과 기록

```text
reports/test-results.md
```

에 다음을 기록합니다.

```text
환경
commit SHA
실행 순서
preflight 결과
verify 결과
실패 항목
수정 commit
재검증 결과
```

최종 원본 결과는:

```text
evidence/14-final/
```

로 연결할 수 있습니다.

---

## 10. 현재 스크립트 상태

```text
scripts/preflight.sh = 구현 완료, read-only
scripts/verify.sh    = 구현 완료, read-only
```

두 파일 모두 작성 단계에서 Bash 구문 검사를 통과하도록 구성했습니다.

실제 B1-1 환경의 전체 상태가 아직 완성되지 않았으므로 `verify.sh` 전체 PASS는 아직 기대하지 않습니다. 현재는 미완성 항목을 `[FAIL]`로 드러내는 것이 정상입니다.

---

## 11. 이번 단계 기억하기

### 한 문장

> **내 컴퓨터에서 한 번 된 것이 아니라, 다시 해도 같은 결과가 나와야 한다.**

### 핵심어 3개

```text
PREFLIGHT · VERIFY · REPRODUCE
```

### 핵심 명령 3개

```bash
bash scripts/preflight.sh
sudo bash scripts/verify.sh
git rev-parse HEAD
```

### 내가 설명할 수 있어야 할 것

> 왜 verify.sh가 문제를 자동으로 고치지 않는가?

답의 핵심은 **검증과 수정을 분리해야 실제 상태를 정확하게 평가할 수 있기 때문**입니다.

---

## 12. 완료 체크

- [x] read-only `preflight.sh` 구현
- [x] read-only `verify.sh` 구현
- [x] 새 터미널 재현 절차 작성
- [x] cron 최소 환경 절차 작성
- [x] 재부팅 후 확인 절차 작성
- [x] 깨끗한 환경 재현 흐름 작성
- [ ] 현재 환경 05~09 완료 후 verify 전체 실행
- [ ] 재부팅 후 검증
- [ ] 가능하면 깨끗한 Ubuntu 재현
- [ ] 실패 항목 담당 문서로 환류
- [ ] 최종 증빙 저장

현재 13단계는 **재현 도구와 절차 IMPLEMENTED / 전체 실제 재현 전**입니다.

---

## 이동

- [이전: 12. 평가 대비](./12-evaluation-preparation.md)
- [다음: 14. 최종 검수와 제출](./14-final-review-submission.md)
- [전체 목차](./README.md)
