# 13. 처음부터 다시 수행하는 재현 시험

> **기억 문장:** 한 번 된 것이 아니라, 다시 해도 같은 결과가 나와야 한다.

이 장에서는 B1-1을 새 세션·재부팅·가능하면 깨끗한 Ubuntu에서 다시 확인합니다.

---

## 1. 목표

재현성은 다음 질문으로 확인합니다.

```text
문서만 보고 다시 구성할 수 있는가?
새 세션에서도 설정이 유지되는가?
실제 기능 테스트가 다시 통과하는가?
증빙과 상태표가 실제 결과와 일치하는가?
```

저장소 도구:

```text
scripts/preflight.sh       환경 사전 점검, read-only
scripts/verify.sh          현재 시스템 상태 점검, read-only
scripts/acceptance-test.sh 실제 기능·장애·cron 관찰 테스트
```

---

## 2. 세 도구의 역할을 섞지 않는다

### `preflight.sh`

변경 전에 OS/systemd/sudo/필수 도구와 Agent 아키텍처 대상을 확인합니다.

```bash
bash scripts/preflight.sh
```

### `verify.sh`

현재 구성 상태를 수정 없이 검사합니다.

```bash
sudo bash scripts/verify.sh
```

이 스크립트가 통과해도 **Boot Sequence, 장애 주입, cron 자동 증가, evidence 완성까지 증명한 것은 아닙니다.**

### `acceptance-test.sh`

05~08 실제 구성 후 동작을 확인합니다.

```bash
sudo bash scripts/acceptance-test.sh \
  --agent-boot-log <Agent 시작 출력 파일>
```

검증 범위:

```text
Boot 5 [OK] + Agent READY 증빙
ACL 허용/차단
monitor 정상 exit 0
프로세스 장애 exit 1
프로세스 있음 + 포트 없음 exit 1
임계값 WARNING 후 계속
로그 포맷
agent-admin cron 등록
1분대 자동 로그 증가
logrotate dry-run
```

---

## 3. 저장소 Bash 정적 검사

실제 Codex/로컬 검토 환경에서 다음을 수행합니다.

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

> **상태 기록 원칙:** 실제 명령을 실행한 결과가 없으면 “통과했다”고 문서에 선행 기록하지 않습니다. 실행 환경과 결과를 `reports/test-results.md`에 남긴 뒤 상태를 올립니다.

---

## 4. 재현 시험 A — 새 터미널

새 터미널에서:

```bash
whoami
git rev-parse HEAD
sudo bash scripts/verify.sh
```

확인:

```text
임시 export 없이 환경 파일 사용
SSH/UFW 지속
사용자·그룹·권한 지속
Agent 실행 절차 재현 가능
cron 등록 지속
```

---

## 5. 재현 시험 B — cron 최소 환경

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

재부팅 가능한 실습 환경에서만 수행합니다.

```bash
systemctl is-active ssh.socket || systemctl is-active ssh
systemctl is-active ufw
systemctl is-active cron
sudo ss -lntp | grep -E ':(22|20022|15034)\b' || true
sudo -u agent-admin crontab -l
```

원본 미션은 Agent 자동 시작을 필수로 요구하지 않으므로, 재부팅 후 Agent는 06장 절차대로 다시 실행해 `READY`와 15034를 확인합니다.

---

## 7. 재현 시험 D — 깨끗한 Ubuntu

가능하면 새 Ubuntu 환경에서:

```text
preflight
→ 01~08 수행
→ acceptance tests
→ verify
→ evidence 연결
```

순서로 진행합니다.

원본 기준:

```text
Ubuntu 22.04 또는 동등 Linux 환경
```

현재 실제 실습 사례인 Ubuntu 24.04.4의 socket activation 차이를 원본 요구사항으로 일반화하지 않습니다.

---

## 8. 실패 시 돌아갈 위치

| 실패 | 담당 장 |
|---|---|
| OS/systemd/tool | 01 |
| Git/비밀정보 | 02 |
| SSH | 03 |
| UFW | 04 |
| 사용자·ACL | 05 |
| Agent | 06 |
| monitor | 07 |
| cron/logrotate | 08 |
| 기능·장애 테스트 | 09 |
| 원인 분석 | 10 |
| 증빙 | 11 |
| 평가 설명 | 12 |

13장에서 임시 우회하지 않고 원래 담당 코드·문서로 돌아가 수정합니다.

---

## 9. 결과 기록

`reports/test-results.md`에 다음을 기록합니다.

```text
환경
commit SHA
검증 명령
실제 결과
exit code
증빙 경로
수정 commit
재검증 결과
```

---

## 10. 현재 상태

```text
preflight.sh       IMPLEMENTED
verify.sh          IMPLEMENTED
acceptance-test.sh IMPLEMENTED
보완 브랜치 Bash 구문 검사  수행
사용자 Ubuntu 전체 재현      NEEDS-RUNTIME
재부팅 후 검증               NEEDS-RUNTIME
깨끗한 Ubuntu 재현           NEEDS-RUNTIME
최종 evidence                 TODO (actual files 0)
```

보완 브랜치에서 수행한 정적검증과 사용자 Ubuntu의 최종 증빙은 구분해 기록합니다.

---

## 11. 이번 단계 기억하기

### 한 문장

> **상태 확인과 기능 검증을 분리하고, 다시 실행해도 같은 결과가 나오는지 확인한다.**

### 핵심어 3개

```text
PREFLIGHT · VERIFY · ACCEPT
```

---

## 이동

- [이전: 12. 평가 대비](./12-evaluation-preparation.md)
- [다음: 14. 최종 검수와 제출](./14-final-review-submission.md)
- [전체 목차](./README.md)
