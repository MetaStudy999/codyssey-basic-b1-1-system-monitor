# 09. 정상·장애·복구 테스트

> **기억 문장:** 정상만 보지 말고, 실패를 안전하게 만들고 다시 정상으로 돌아오는지 확인한다.

이 장에서는 B1-1 전체를 **정상 → 장애 → 복구 → 재검증** 순서로 시험합니다.

상세 테스트 목록:

```text
tests/test-cases.md   T-001~T-040
```

실제 결과:

```text
reports/test-results.md
```

---

## 1. 테스트 원칙

```text
한 번에 한 장애만 만든다.
실제 서버에 과도한 부하를 만들지 않는다.
설정 파괴보다 override/fixture를 우선한다.
장애 시험 후 반드시 정상 상태를 재확인한다.
예상 출력과 실제 결과를 구분한다.
```

---

## 2. 정상 상태 먼저 확인

```bash
sudo sshd -t
sudo sshd -T | grep -E '^(port|permitrootlogin) '
sudo ufw status verbose
id agent-admin
id agent-dev
id agent-test
sudo ss -lntp | grep -E ':(22|20022|15034)\b' || true
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
echo $?
```

정상 기준:

```text
SSH 20022 / Root login no
UFW active + 20022/15034 only
사용자·그룹·ACL 정상
Agent non-root / READY / 15034
monitor exit 0
monitor.log 증가
```

---

## 3. 통합 runtime acceptance

05~08이 완료되고 Agent 시작 출력이 확보되면:

```bash
sudo bash scripts/acceptance-test.sh \
  --agent-boot-log <Agent 시작 출력 파일>
```

이 스크립트는 다음을 묶어 확인합니다.

```text
Boot 5 [OK] + Agent READY evidence
agent-test upload 허용
agent-test api_keys/log 쓰기 차단
monitor 정상 exit 0
process 없음 exit 1
process 있음 + port 없음 exit 1
CPU/MEM/DISK warning logic
monitor.log 포맷
agent-admin cron 등록
cron 자동 증가
logrotate dry-run
```

SSH/UFW 설정 자체를 변경하지 않습니다.

---

## 4. 프로세스 실패

실제 Agent를 끄지 않고 존재하지 않는 pattern으로 시험합니다.

```bash
AGENT_ENV_FILE=/nonexistent \
AGENT_PROCESS_PATTERN='__b1_1_process_that_does_not_exist__' \
AGENT_PORT=15034 \
AGENT_LOG_DIR=/tmp \
/home/agent-admin/agent-app/bin/monitor.sh

echo $?
```

목표: `exit 1`.

---

## 5. 프로세스는 있으나 포트 없음

실제 Agent를 깨뜨리지 않고 짧은 테스트 프로세스와 미사용 포트를 사용합니다. `acceptance-test.sh`가 이 조건을 자동 구성합니다.

목표:

```text
process found
port missing
exit 1
```

---

## 6. 임계값 WARNING

실제 CPU·메모리·디스크를 채우지 않습니다.

```bash
CPU_WARN_THRESHOLD=-1 \
MEM_WARN_THRESHOLD=-1 \
DISK_WARN_THRESHOLD=-1 \
/home/agent-admin/agent-app/bin/monitor.sh
```

Agent가 건강하다면:

```text
CPU WARNING
MEM WARNING
DISK WARNING
exit 0
```

이어야 합니다.

---

## 7. 로그 쓰기 오류

다음 두 상황을 구분합니다.

```text
로그 디렉터리 없음/쓰기 불가
기존 monitor.log 파일 자체 쓰기 불가
```

현재 `monitor.sh`는 두 경우 모두 성공으로 숨기지 않고 `exit 2`로 처리하도록 보완했습니다.

실제 `/var/log/agent-app` 권한을 망가뜨리기보다 안전한 테스트 경로/fixture를 사용합니다.

---

## 8. ACL 실제 접근시험

```bash
sudo -u agent-test bash -c \
  'touch /home/agent-admin/agent-app/upload_files/.b1-1-test && rm -f /home/agent-admin/agent-app/upload_files/.b1-1-test'
```

목표: 성공.

```bash
sudo -u agent-test touch \
  /home/agent-admin/agent-app/api_keys/.should-fail
```

목표: `Permission denied`.

```bash
sudo -u agent-test touch /var/log/agent-app/.should-fail
```

목표: `Permission denied`.

---

## 9. cron 자동 증가

```bash
sudo -u agent-admin crontab -l
wc -l /var/log/agent-app/monitor.log
sleep 70
wc -l /var/log/agent-app/monitor.log
```

사람이 직접 실행하지 않았는데 로그가 증가해야 합니다.

---

## 10. logrotate

먼저:

```bash
sudo logrotate -d /etc/logrotate.d/agent-monitor
```

설정 핵심:

```text
size 10M
rotate 9
current + 9 rotated = maximum 10 files
create 0660 agent-admin agent-core
```

강제 회전은 통제된 시점에만:

```bash
sudo logrotate -f /etc/logrotate.d/agent-monitor
```

그 후 monitor가 다시 로그를 쓸 수 있어야 합니다.

---

## 11. 복구 완료 판정

장애 시험마다 마지막에:

```bash
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
echo $?
tail -n 1 /var/log/agent-app/monitor.log
```

을 다시 확인합니다.

`exit 0`과 정상 로그가 돌아오지 않으면 복구가 끝난 것이 아닙니다.

---

## 12. 실제 결과 기록

`reports/test-results.md`의 동일 테스트 ID에 다음을 기록합니다.

```text
실행 일시
환경/commit
실행 명령
실제 결과
exit code
evidence
판정
```

현재 T-001~T-040이 1:1로 준비되어 있습니다.

---

## 13. 현재 상태

```text
테스트 정의/ledger         IMPLEMENTED
acceptance-test.sh        IMPLEMENTED
SSH/UFW 일부              TESTED / evidence pending
IAM/ACL runtime           TODO
Agent runtime             TODO
monitor runtime           TODO
cron/logrotate runtime    TODO
recovery runtime          TODO
bonus fixture             TODO
```

---

## 이동

- [이전: 08. 로그와 cron](./08-logging-cron.md)
- [다음: 10. 트러블슈팅](./10-troubleshooting.md)
- [전체 목차](./README.md)
