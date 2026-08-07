# 10. 오류 메시지별 트러블슈팅

> **기억 문장:** 오류를 없애려 하지 말고, 원인을 분리하고 검증한 뒤 복구한다.

이 장은 B1-1 수행 중 실제로 발생한 오류와 앞으로의 검증에서 발생할 수 있는 오류를 **증상 → 원인 → 확인 → 조치 → 재검증** 순서로 정리합니다.

빠른 검색은 [오류 색인](./reference/error-index.md)을 사용합니다.

---

## 1. 트러블슈팅 기본 순서

```text
1. 오류 메시지를 그대로 보존
2. 직전에 무엇을 했는지 확인
3. 상태를 바꾸기 전에 조회 명령 실행
4. 가능한 원인을 계층별로 분리
5. 가장 작은 수정만 적용
6. 원래 검증 명령을 다시 실행
7. 정상 상태까지 복구
8. 재발 방지 기록
```

### 금지 습관

```text
오류 → chmod 777
오류 → sudo로 전부 실행
오류 → 서비스 무작정 restart 반복
오류 → 설정 파일 여러 개 동시에 수정
오류 → rm/reset으로 흔적 삭제
```

---

## 2. 실제 발생 오류 1 — `/run/sshd` 없음

### 증상

```text
Missing privilege separation directory: /run/sshd
```

발생 명령:

```bash
sudo sshd -T
```

### 당시 상태

```text
ssh.socket  = active
ssh.service = inactive
```

확인:

```bash
systemctl status ssh.service --no-pager
systemctl cat ssh.service
```

서비스 정의에서 다음을 확인했습니다.

```ini
RuntimeDirectory=sshd
RuntimeDirectoryMode=0755
```

### 근본 원인

`/run/sshd`는 사용자가 임의로 만드는 영구 디렉터리가 아니라 **systemd가 `ssh.service`를 시작할 때 관리하는 런타임 디렉터리**였습니다.

### 조치

수동 `mkdir /run/sshd`를 하지 않고:

```bash
sudo systemctl start ssh.service
```

로 systemd에게 디렉터리와 서비스를 준비하도록 했습니다.

### 재검증

```bash
systemctl status ssh.service --no-pager
sudo sshd -T | grep -E '^(port|permitrootlogin) '
```

결과:

```text
Active: active (running)
port 22              # 변경 전 확인 시점
permitrootlogin without-password
```

이후 B1-1 설정을 적용한 뒤 최종값은:

```text
port 20022
permitrootlogin no
```

로 확인했습니다.

### 재발 방지

> `/run` 아래 경로가 없다고 바로 만들지 않고 **service unit의 `RuntimeDirectory=` 여부부터 확인**한다.

---

## 3. 실제 발생 메시지 2 — `ssh.socket changed on disk`

### 증상

```text
Warning: ssh.socket changed on disk,
the version systemd has loaded is outdated.
...
Run 'systemctl daemon-reload' to reload units.
```

### 원인

systemd 관련 설정 파일이 디스크에서 변경됐지만 PID 1의 systemd manager가 아직 새 unit 정의를 다시 읽지 않은 상태였습니다.

### 조치

```bash
sudo systemctl daemon-reload
```

### 재검증

```bash
systemctl cat ssh.socket
```

Ubuntu 24.04.4 환경에서 `sshd-socket-generator`가 생성한 다음 설정을 확인했습니다.

```text
ListenStream=0.0.0.0:20022
ListenStream=[::]:20022
```

### 재발 방지

> systemd unit/drop-in 변경 후에는 **daemon-reload와 실제 effective config 확인**을 한 세트로 수행한다.

---

## 4. 실제 발생 메시지 3 — `triggering units are still active`

### 증상

```text
Stopping 'ssh.service', but its triggering units are still active:
ssh.socket
```

### 해석

이 메시지는 당시 오류가 아니라 **ssh.service를 다시 시작시킬 수 있는 ssh.socket이 아직 활성 상태**라는 안내였습니다.

### 확인

```bash
systemctl is-active ssh.service ssh.socket
```

실제 결과:

```text
inactive
active
```

### 조치

새 socket 설정이 준비된 상태에서:

```bash
sudo systemctl restart ssh.socket
```

### 재검증

```bash
sudo ss -lntp | grep -E ':(22|20022)\b' || true
```

결과:

```text
20022 LISTEN
22 없음
```

### 재발 방지

> 메시지에 `warning` 또는 안내가 나온다고 즉시 실패로 단정하지 않고 **service와 socket의 역할을 분리해 상태를 확인**한다.

---

## 5. 실제 점검 사례 — UFW 규칙이 한 번에 보이지 않음

### 상황

`15034/tcp` 허용 명령에서:

```text
Rules updated
Rules updated (v6)
```

가 나왔지만 첫 `ufw show added` 확인에서는 `20022/tcp`만 보였습니다.

### 대응

추측하지 않고:

```bash
sudo ufw allow 15034/tcp
sudo ufw show added
```

로 다시 적용·확인했습니다.

최종 결과:

```text
ufw allow 20022/tcp
ufw allow 15034/tcp
```

### 재발 방지

> **명령의 성공 메시지보다 최종 상태 조회 결과를 우선한다.**

---

## 6. 사용자·그룹 오류

아래 항목은 05장 실제 구현 시 확인할 오류 유형입니다.

### `useradd: user ... already exists`

삭제 후 다시 만드는 대신:

```bash
getent passwd <사용자>
id <사용자>
```

로 기존 계정 상태를 확인합니다.

### `groupadd: group ... already exists`

```bash
getent group <그룹>
```

으로 기존 그룹과 멤버십을 확인합니다.

### 그룹을 추가했는데 현재 셸에서 안 보임

그룹 멤버십은 새 로그인 세션에 반영되는 경우가 있습니다.

시스템 등록값 확인:

```bash
id agent-admin
id agent-dev
id agent-test
```

---

## 7. ACL / Permission denied

### 증상

하위 디렉터리 권한은 맞아 보이는데 접근이 거부됩니다.

### 확인 순서

```bash
namei -l <전체경로>
getfacl <부모경로>
getfacl <대상경로>
```

Linux 디렉터리는 **모든 부모 경로에 통과 권한 `x`가 있어야** 하위 경로에 접근할 수 있습니다.

### ACL mask 확인

`getfacl`에서:

```text
mask::...
```

도 확인합니다. ACL 항목에 권한이 있어도 mask가 더 좁으면 실제 유효 권한이 제한됩니다.

---

## 8. Agent가 READY가 되지 않음

06장에서 실제 Agent를 실행할 때 사용할 분리 순서입니다.

```text
1. 실행 사용자 확인
2. 환경변수 확인
3. key 파일 존재·권한 확인
4. upload/log 경로 권한 확인
5. Boot Sequence에서 최초 실패 단계 확인
6. 프로세스 확인
7. 15034 LISTEN 확인
```

명령 예:

```bash
id agent-admin
sudo -u agent-admin bash -c 'set -a; source /etc/agent-app/agent.env; set +a; printenv | grep "^AGENT_" | sort'
sudo stat /home/agent-admin/agent-app/api_keys/t_secret.key
pgrep -af '<실제 앱 파일명>'
sudo ss -lntp | grep ':15034\b' || true
```

키 내용 자체는 출력하지 않습니다.

---

## 9. 프로세스는 있는데 15034가 없음

평가문항에서도 중요한 장애 시나리오입니다.

가능한 원인 범주:

```text
앱 초기화는 되었지만 서버 bind 전 실패
AGENT_PORT가 잘못됨
15034가 다른 프로세스에 이미 사용됨
앱이 다른 주소/포트에 바인딩됨
권한·환경변수·키 오류
```

확인 순서:

```bash
pgrep -af '<실제 앱 파일명>'
sudo ss -lntp | grep ':15034\b' || true
sudo ss -lntp | grep '<PID 또는 프로세스 관련 정보>' || true
```

프로세스가 존재한다는 이유만으로 정상 판정하지 않습니다.

---

## 10. `monitor.sh`가 프로세스를 못 찾음

### 확인

```bash
pgrep -af '<실제 앱 파일명>'
```

저장소 기본값은:

```text
AGENT_PROCESS_PATTERN=agent_app.py
```

입니다.

실제 제공 파일명이 다르면 환경 설정에서 정확한 파일명으로 지정합니다.

패턴을 `python`처럼 지나치게 넓게 만들지 않습니다.

---

## 11. `monitor.sh` 포트 실패

### 증상

```text
[ERROR] Agent port is not LISTEN: tcp/15034
```

### 확인

```bash
ss -lntH
printenv AGENT_PORT
```

원인을 다음 두 가지로 먼저 분리합니다.

```text
Agent 자체가 15034에 bind하지 않음
monitor가 잘못된 AGENT_PORT를 보고 있음
```

---

## 12. `monitor.log` Permission denied

### 확인

```bash
id agent-admin
ls -ld /var/log/agent-app
getfacl /var/log/agent-app
ls -l /var/log/agent-app/monitor.log 2>/dev/null || true
```

목표는 `agent-admin`이 `agent-core` 멤버십으로 로그를 기록할 수 있는 것입니다.

### 하지 않는 조치

```bash
sudo chmod -R 777 /var/log/agent-app
```

권한 설계를 무너뜨리므로 사용하지 않습니다.

---

## 13. 수동 monitor 성공, cron 실패

### 원인 범주

```text
cron PATH 차이
로그인 셸 환경변수에만 의존
실행 계정이 agent-admin이 아님
cron 서비스 미실행
monitor.sh 실행 권한 문제
```

### 확인 순서

```bash
sudo -u agent-admin crontab -l
systemctl status cron --no-pager
sudo -u agent-admin env -i \
  HOME=/home/agent-admin \
  USER=agent-admin \
  LOGNAME=agent-admin \
  SHELL=/bin/bash \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  /home/agent-admin/agent-app/bin/monitor.sh
```

최소 환경에서 수동 실행이 성공하면 cron 자체의 등록·서비스 상태를 집중적으로 확인합니다.

---

## 14. logrotate 오류

### `insecure permissions`

05장에서 로그 디렉터리를 `agent-core` 그룹 writable로 만들었기 때문에 logrotate 설정의:

```text
su agent-admin agent-core
```

와 실제 사용자·그룹 상태를 확인합니다.

### 회전 후 로그 쓰기 실패

```bash
ls -l /var/log/agent-app/monitor.log
getfacl /var/log/agent-app
```

`create 0640 agent-admin agent-core`가 반영됐는지 확인합니다.

---

## 15. 디스크 로그 급증 대응

평가문항의 운영 대응을 다음 두 층으로 나눕니다.

### 단기 대응

```text
로그 증가 원인 확인
현재 디스크 사용률 확인
불필요한 임시/회전 로그 확인
서비스 장애 방지를 위한 공간 확보
로그 회전 상태 확인
```

### 중기 대응

```text
로그 발생량 원인 수정
logrotate 정책 검토
보존 기간과 아카이브 정책 설계
알림/관측 추가
보너스 7일 압축·30일 삭제 적용 검토
```

로그를 무조건 삭제하는 것을 첫 조치로 삼지 않습니다.

---

## 16. 기록 템플릿

오류 하나당 다음 형태로 기록합니다.

```text
증상:
재현 조건:
실행 계정:
첫 확인 명령:
가설:
검증 결과:
근본 원인:
조치:
복구:
재검증:
재발 방지:
```

상세 기록은:

```text
reports/troubleshooting-report.md
```

에 누적합니다.

---

## 17. 이번 단계 기억하기

### 한 문장

> **오류를 없애려 하지 말고, 원인을 분리하고 검증한 뒤 복구한다.**

### 핵심어 3개

```text
SYMPTOM · CAUSE · RECOVERY
```

### 핵심 질문 3개

```text
무엇이 실패했는가?
어느 계층에서 실패했는가?
복구 후 같은 검증이 통과하는가?
```

---

## 18. 완료 체크

- [x] 실제 `/run/sshd` 오류 원인·조치 기록
- [x] 실제 systemd daemon-reload 경고 기록
- [x] 실제 ssh.service/ssh.socket 메시지 기록
- [x] 실제 UFW 규칙 재확인 사례 기록
- [x] 권한·ACL 진단 순서 작성
- [x] Agent 장애 진단 순서 작성
- [x] monitor 장애 진단 순서 작성
- [x] cron/logrotate 진단 순서 작성
- [x] 평가용 디스크 로그 급증 대응 작성
- [ ] 05~09 실제 수행 중 추가 오류를 발생 시 계속 기록
- [ ] 11장에서 핵심 오류 증빙 연결

10단계는 **현재까지 실제 발생 오류 기록 + 이후 진단 체계 구현 완료** 상태입니다.

---

## 이동

- [이전: 09. 정상·장애·복구 테스트](./09-testing-recovery.md)
- [다음: 11. 수행 내역과 증빙](./11-execution-evidence.md)
- [전체 목차](./README.md)
