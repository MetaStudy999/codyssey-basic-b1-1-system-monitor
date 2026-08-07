# 09. 정상·장애·복구 테스트

> **기억 문장:** 정상만 확인하지 말고, 실패를 안전하게 만들고 다시 정상으로 돌아오는지 확인한다.

이 장에서는 B1-1 전체를 **정상 → 장애 → 복구 → 재검증** 순서로 시험합니다.

상세 테스트 목록은 다음 파일에서 관리합니다.

```text
tests/test-cases.md
```

---

## 1. 목표

테스트는 단순히 `monitor.sh`가 한 번 실행되는지만 보는 것이 아닙니다.

```text
환경
SSH
UFW
사용자·그룹·ACL
Agent
monitor.sh
cron
logrotate
복구
보너스
```

까지 전체 요구사항을 연결합니다.

---

## 2. 테스트 원칙

### 원칙 1 — 한 번에 한 장애만 만든다

두 가지 장애를 동시에 만들면 실패 원인을 구분하기 어렵습니다.

### 원칙 2 — 실제 시스템을 불필요하게 위험하게 만들지 않는다

```text
CPU 100% 부하 생성     ❌
메모리 고갈            ❌
디스크 실제 가득 채움   ❌
원격 상태에서 UFW 무작정 disable/enable ❌
```

가능하면 환경변수·fixture·mock으로 실패 조건을 만듭니다.

### 원칙 3 — 장애 시험 후 반드시 복구한다

```text
장애 생성
→ 예상 실패 확인
→ 원상복구
→ 정상 실행 재확인
```

### 원칙 4 — 예시와 실제 결과를 구분한다

문서의 예상 출력은 증빙이 아닙니다. 실제 Ubuntu 환경에서 나온 결과만 `evidence/`에 저장합니다.

---

## 3. Phase A — 전체 정상 상태 확인

먼저 장애를 만들기 전에 모든 기본 상태를 확인합니다.

### SSH

```bash
sudo sshd -t
sudo sshd -T | grep -E '^(port|permitrootlogin) '
sudo ss -lntp | grep -E ':(22|20022)\b' || true
```

목표:

```text
port 20022
permitrootlogin no
20022 LISTEN
22 없음
```

### UFW

```bash
sudo ufw status verbose
```

목표:

```text
active
default deny incoming
20022/tcp ALLOW
15034/tcp ALLOW
```

### 사용자·그룹

```bash
id agent-admin
id agent-dev
id agent-test
```

### Agent

```bash
pgrep -af '<실제 제공 앱 파일명>'
sudo ss -lntp | grep ':15034\b'
```

### monitor.sh

```bash
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
echo $?
```

목표:

```text
exit 0
monitor.log 1줄 증가
```

---

## 4. Phase B — 프로세스 실패 `exit 1`

실제 Agent를 반드시 종료할 필요는 없습니다. 프로세스 패턴을 존재하지 않는 값으로 바꿔 Health Check만 안전하게 시험할 수 있습니다.

```bash
AGENT_ENV_FILE=/nonexistent \
AGENT_PORT=15034 \
AGENT_LOG_DIR=/var/log/agent-app \
AGENT_PROCESS_PATTERN='__b1_1_process_that_does_not_exist__' \
/home/agent-admin/agent-app/bin/monitor.sh

echo $?
```

목표:

```text
[ERROR] Agent process not found ...
1
```

### 복구

별도 시스템 변경을 하지 않았으므로 환경변수 override를 제거하고 정상 명령을 다시 실행합니다.

```bash
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
echo $?
```

목표: `0`.

---

## 5. Phase C — 포트 실패 `exit 1`

실제 Agent가 실행 중일 때 미사용 포트를 테스트 값으로 지정하는 방식이 안전합니다.

단, `monitor.sh`가 기본 환경 파일을 다시 읽지 않도록 테스트용 실행에서는 `AGENT_ENV_FILE=/nonexistent`를 사용하고 필요한 값을 명시합니다.

예시 구조:

```bash
AGENT_ENV_FILE=/nonexistent \
AGENT_PORT=65534 \
AGENT_LOG_DIR=/var/log/agent-app \
AGENT_PROCESS_PATTERN='<실제 제공 앱 파일명>' \
/home/agent-admin/agent-app/bin/monitor.sh

echo $?
```

전제: `65534`가 실제로 사용 중이지 않은지 먼저 확인합니다.

```bash
ss -lntH | grep ':65534\b' || true
```

목표 종료 코드:

```text
1
```

---

## 6. Phase D — 자원 WARNING을 안전하게 시험

실제 CPU·메모리·디스크를 위험하게 올리지 않습니다.

정상 Agent가 실행 중일 때 테스트용 임계값만 낮춥니다.

```bash
CPU_WARN_THRESHOLD=-1 \
MEM_WARN_THRESHOLD=-1 \
DISK_WARN_THRESHOLD=-1 \
/home/agent-admin/agent-app/bin/monitor.sh

echo $?
```

목표:

```text
[WARNING] CPU ...
[WARNING] MEM ...
[WARNING] DISK_USED ...
exit 0
```

이 테스트는 **임계값 판정 로직**을 검증합니다. 실제 서버 부하 시험과는 구분합니다.

---

## 7. Phase E — 방화벽 WARNING

원본 요구사항은 방화벽 비활성 시 WARNING 후 계속 실행입니다.

실제 UFW를 끄는 방식은 SSH 안전성에 영향을 줄 수 있으므로 우선 mock/fixture 방식으로 검증하는 것을 권장합니다.

실제 방화벽 상태 변경 시험은 로컬 콘솔과 복구 절차가 확보된 경우에만 별도로 수행합니다.

### 검증 포인트

```text
방화벽 판정 실패
→ [WARNING]
→ Agent health 정상
→ 자원 수집 계속
→ 로그 기록
→ exit 0
```

---

## 8. Phase F — 로그 권한 오류

Agent health는 정상인데 로그 디렉터리에 쓸 수 없는 경우는 Health 실패와 구분하여 설정 오류로 처리합니다.

테스트는 실제 `/var/log/agent-app` 권한을 망가뜨리지 않고, 쓰기 불가능한 안전한 테스트 경로를 `AGENT_LOG_DIR`로 지정하는 방식을 사용합니다.

목표:

```text
[ERROR] log directory ...
exit 2
```

시험 후 정상 환경으로 실행해 `exit 0`을 다시 확인합니다.

---

## 9. Phase G — ACL 허용/차단 시험

### agent-test upload 허용

```bash
sudo -u agent-test bash -c \
  'touch /home/agent-admin/agent-app/upload_files/.b1-1-test && rm /home/agent-admin/agent-app/upload_files/.b1-1-test'
```

목표: 성공.

### agent-test key 차단

```bash
sudo -u agent-test test -r \
  /home/agent-admin/agent-app/api_keys/t_secret.key \
  && echo '[FAIL] readable' \
  || echo '[PASS] blocked'
```

### agent-test log 차단

```bash
sudo -u agent-test test -w /var/log/agent-app \
  && echo '[FAIL] writable' \
  || echo '[PASS] blocked'
```

---

## 10. Phase H — cron 자동 실행

수동 실행이 성공한 뒤 수행합니다.

```bash
sudo -u agent-admin crontab -l
wc -l /var/log/agent-app/monitor.log
```

1~2분 후:

```bash
wc -l /var/log/agent-app/monitor.log
tail -n 3 /var/log/agent-app/monitor.log
```

목표: 사람이 직접 실행하지 않아도 로그 증가.

---

## 11. Phase I — logrotate

먼저 dry-run:

```bash
sudo logrotate -d /etc/logrotate.d/agent-monitor
```

설정 오류가 없을 때만 통제된 강제 시험:

```bash
sudo logrotate -f /etc/logrotate.d/agent-monitor
ls -lh /var/log/agent-app/monitor.log*
```

그 후:

```bash
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
tail -n 1 /var/log/agent-app/monitor.log
```

으로 회전 후에도 새 로그를 쓸 수 있는지 확인합니다.

---

## 12. Phase J — 복구 완료 판정

모든 장애 시험의 마지막은 동일합니다.

```text
원래 설정 복구
→ Agent 정상
→ 15034 LISTEN
→ monitor.sh exit 0
→ monitor.log 정상 기록
```

최종 핵심 확인:

```bash
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
echo $?
tail -n 1 /var/log/agent-app/monitor.log
```

`exit 0`이 다시 확인되지 않으면 장애 시험은 완료된 것이 아닙니다.

---

## 13. 테스트 결과 기록

각 테스트는 다음 정보를 남깁니다.

```text
Test ID
실행 시각
실행 계정
사전조건
명령
실제 출력
종료 코드
PASS / FAIL
복구 과정
복구 후 결과
```

보고서:

```text
reports/test-results.md
```

원본 출력:

```text
evidence/09-testing/
```

---

## 14. 현재 상태

현재 저장소 기준:

```text
테스트 매트릭스 작성       = 완료
안전한 failure injection 설계 = 완료
monitor.sh 코드 구현        = 완료
cron/logrotate 설정 구현     = 완료
실제 Agent 기반 런타임 테스트 = 아직
```

따라서 09단계는 **테스트 설계 IMPLEMENTED / 실제 실행 TODO**입니다.

---

## 15. 이번 단계 기억하기

### 한 문장

> **정상만 확인하지 말고, 실패를 안전하게 만들고 다시 정상으로 돌아오는지 확인한다.**

### 핵심어 3개

```text
NORMAL · FAILURE · RECOVERY
```

### 핵심 명령 3개

```bash
/home/agent-admin/agent-app/bin/monitor.sh
echo $?
tail -n 1 /var/log/agent-app/monitor.log
```

### 내가 설명할 수 있어야 할 것

> 왜 장애 테스트 후 `exit 0`을 다시 확인해야 하는가?

답의 핵심은 **장애를 발견하는 능력뿐 아니라 정상 상태로 복구하는 능력까지 운영 품질의 일부이기 때문**입니다.

---

## 16. 완료 체크

- [x] 전체 테스트 매트릭스 작성
- [x] 정상 테스트 절차 작성
- [x] 프로세스 실패 안전 시험 설계
- [x] 포트 실패 안전 시험 설계
- [x] 임계값 WARNING 안전 시험 설계
- [x] ACL 허용/차단 시험 설계
- [x] cron 시험 설계
- [x] logrotate 시험 설계
- [x] 복구 후 재검증 절차 작성
- [ ] 실제 Ubuntu에서 T-001~T-034 실행
- [ ] `reports/test-results.md` 기록
- [ ] `evidence/09-testing/` 증빙 정리

현재 상태: **IMPLEMENTED / 실제 TEST 전**.

---

## 이동

- [이전: 08. 로그와 cron](./08-logging-cron.md)
- [다음: 10. 트러블슈팅](./10-troubleshooting.md)
- [전체 목차](./README.md)
