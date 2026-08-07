# 08. 로그 관리와 cron 자동화

> **기억 문장:** 기록은 누적하고, 실행은 반복하고, 로그 크기는 제한한다.

이 장에서는 `monitor.sh`를 `agent-admin` 계정의 cron으로 **매분 자동 실행**하고, `/var/log/agent-app/monitor.log`를 **10MB / 10개 정책**으로 관리합니다.

---

## 1. 목표

원본 미션 요구사항:

```text
cron 실행 계정 = agent-admin
실행 주기      = 매분
로그           = /var/log/agent-app/monitor.log
로그 크기 정책 = 10MB / 10개
```

저장소 구현 파일:

```text
config/crontab.example
config/agent-monitor.logrotate
```

---

## 2. 이해 — 역할을 분리한다

```text
monitor.sh
   └─ 상태 확인 + 한 줄 기록

cron
   └─ monitor.sh를 매분 실행

logrotate
   └─ monitor.log의 크기와 보관 수 관리
```

하나의 Bash 파일에 모든 운영 기능을 넣지 않고 역할을 분리합니다.

---

## 3. 사전 조건

08장을 실제 실행하려면 다음이 먼저 완료되어야 합니다.

```text
05 사용자/그룹/권한
06 Agent READY + 15034 LISTEN
07 monitor.sh 실제 배치 + 수동 정상 실행
```

확인:

```bash
id agent-admin
stat /home/agent-admin/agent-app/bin/monitor.sh
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
```

수동 실행부터 실패한다면 cron 등록으로 넘어가지 않습니다.

---

## 4. monitor.log 권한 확인

```bash
ls -l /var/log/agent-app/monitor.log
getfacl /var/log/agent-app
```

권장 상태:

```text
monitor.log owner = agent-admin
group             = agent-core
mode              = 640 수준
```

디렉터리는 05장의 `agent-core` R/W 정책을 유지합니다.

---

## 5. cron 최소 환경 시험

cron은 로그인 터미널보다 환경변수가 적습니다. 등록 전에 비슷한 최소 환경으로 `monitor.sh`를 직접 시험합니다.

```bash
sudo -u agent-admin env -i \
  HOME=/home/agent-admin \
  USER=agent-admin \
  LOGNAME=agent-admin \
  SHELL=/bin/bash \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  /home/agent-admin/agent-app/bin/monitor.sh
```

정상 조건:

```text
exit 0
monitor.log 한 줄 증가
```

`monitor.sh`는 `/etc/agent-app/agent.env`를 직접 읽으므로 interactive shell의 `export` 상태에만 의존하지 않습니다.

---

## 6. cron 설정 파일

저장소의 `config/crontab.example`은 다음 정책을 구현합니다.

```text
SHELL=/bin/bash
고정 PATH
MAILTO=""
* * * * * monitor.sh
```

실제 핵심 스케줄:

```cron
* * * * * /home/agent-admin/agent-app/bin/monitor.sh >/dev/null 2>&1
```

### `* * * * *`의 의미

```text
분   시   일   월   요일
*    *    *    *    *

= 매 1분
```

---

## 7. agent-admin crontab 설치

저장소 루트에서:

```bash
sudo -u agent-admin crontab < config/crontab.example
```

확인:

```bash
sudo -u agent-admin crontab -l
```

반드시 **agent-admin의 crontab**에 등록되어 있어야 합니다.

Root crontab이나 현재 `ubuntu` 사용자의 crontab에 대신 등록하면 원본 요구사항과 다릅니다.

---

## 8. cron 서비스 확인

```bash
systemctl is-active cron
```

목표:

```text
active
```

필요하면 자세히 확인합니다.

```bash
systemctl status cron --no-pager
```

---

## 9. 매분 자동 실행 검증

먼저 현재 로그 줄 수를 기록합니다.

```bash
wc -l /var/log/agent-app/monitor.log
```

1분 이상 기다린 뒤 다시 확인합니다.

```bash
wc -l /var/log/agent-app/monitor.log
tail -n 3 /var/log/agent-app/monitor.log
```

성공 조건:

```text
로그 줄 수 증가
새 timestamp 추가
사람이 직접 monitor.sh를 실행하지 않았음
```

원본 미션은 등록 후 **1~2분 내 새 로그 누적**을 확인하도록 요구합니다.

---

## 10. 로그 포맷 확인

```bash
tail -n 1 /var/log/agent-app/monitor.log
```

형태:

```text
[YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%
```

정규식 검증 예시:

```bash
tail -n 1 /var/log/agent-app/monitor.log | \
  grep -E '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] PID:[0-9]+ CPU:[0-9]+(\.[0-9]+)?% MEM:[0-9]+(\.[0-9]+)?% DISK_USED:[0-9]+%$'
```

---

## 11. logrotate 구현

저장소 파일:

```text
config/agent-monitor.logrotate
```

핵심 정책:

```conf
/var/log/agent-app/monitor.log {
    size 10M
    rotate 10
    compress
    missingok
    notifempty
    su agent-admin agent-core
    create 0640 agent-admin agent-core
}
```

### 각 설정의 의미

```text
size 10M                  10MB 이상일 때 회전 대상
rotate 10                 회전본 10개 보관
compress                  이전 로그 압축
missingok                 로그가 없어도 오류로 중단하지 않음
notifempty                 빈 로그는 회전하지 않음
su agent-admin agent-core  해당 사용자/그룹으로 회전
create 0640 ...            회전 후 새 monitor.log 권한 고정
```

> 원본 미션의 표현은 `10MB/10개 파일 유지`입니다. 이 저장소는 일반적인 logrotate 구성인 `size 10M`, `rotate 10`으로 구현하고, 12장 평가 대비에서 이 정책의 의미를 설명할 수 있도록 합니다.

---

## 12. logrotate 설정 설치

```bash
sudo install -o root -g root -m 0644 \
  config/agent-monitor.logrotate \
  /etc/logrotate.d/agent-monitor
```

확인:

```bash
sudo cat /etc/logrotate.d/agent-monitor
```

---

## 13. logrotate dry-run

실제 파일을 회전시키기 전에 디버그 모드로 설정을 확인합니다.

```bash
sudo logrotate -d /etc/logrotate.d/agent-monitor
```

### `[STOP]`

다음 종류의 오류가 있으면 강제 회전으로 넘어가지 않습니다.

```text
syntax error
insecure permissions
unknown user/group
permission denied
```

먼저 05장의 사용자·그룹·로그 디렉터리 권한과 설정 파일 문법을 복구합니다.

---

## 14. 통제된 강제 회전 시험

Agent와 cron이 정상이고 중요한 로그를 별도로 보존할 필요가 없는 실습 시점에 수행합니다.

```bash
sudo logrotate -f /etc/logrotate.d/agent-monitor
```

확인:

```bash
ls -lh /var/log/agent-app/monitor.log*
```

목표:

```text
현재 monitor.log 존재
회전된 이전 로그 존재
소유권 agent-admin:agent-core 유지
```

압축 설정으로 회전 파일 이름은 환경과 시점에 따라 `.gz`가 붙을 수 있습니다.

---

## 15. 회전 후 monitor.sh 재실행

```bash
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
```

다시:

```bash
tail -n 1 /var/log/agent-app/monitor.log
```

정상적으로 새 로그를 쓸 수 있어야 합니다.

logrotate가 성공해도 이후 `monitor.sh`가 쓰지 못하면 운영 구성은 완료된 것이 아닙니다.

---

## 16. 왜 `su`와 `create`를 사용하는가

05장에서 `/var/log/agent-app`는 `agent-core`가 쓰는 디렉터리로 설계했습니다.

logrotate가 권한을 잘못 바꾸면 다음 cron부터:

```text
Permission denied
```

가 발생할 수 있습니다.

따라서 회전 이후에도:

```text
agent-admin이 쓰기 가능
agent-core 정책 유지
agent-test 차단
```

이 되도록 소유권과 모드를 명시합니다.

---

## 17. cron 출력은 왜 `/dev/null`로 보내는가

`monitor.sh`의 정상 상태 데이터는 이미 `monitor.log`에 기록됩니다.

cron이 매분 같은 정상 출력까지 별도 메일이나 파일로 다시 남기면 중복 기록이 생길 수 있어 예시 crontab에서는:

```text
>/dev/null 2>&1
```

을 사용합니다.

장애 원인 분석은 09·10장에서 수동 실행, cron 상태, 시스템 로그를 함께 확인합니다.

---

## 18. 오류와 복구

### 수동 실행 성공, cron 실행 실패

우선 최소 환경 시험을 다시 실행합니다.

확인 순서:

```text
agent-admin 실행 권한
/etc/agent-app/agent.env 읽기
PATH
cron 서비스 상태
crontab 소유 계정
로그 디렉터리 쓰기 권한
```

### cron은 등록됐는데 로그가 늘지 않음

```bash
sudo -u agent-admin crontab -l
systemctl status cron --no-pager
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
echo $?
```

으로 자동화 문제와 스크립트 문제를 분리합니다.

### logrotate `insecure permissions`

`/var/log/agent-app`가 그룹 writable이므로 `su agent-admin agent-core` 설정과 실제 사용자·그룹 존재 여부를 확인합니다.

### 회전 후 로그 쓰기 실패

```bash
ls -l /var/log/agent-app/monitor.log
getfacl /var/log/agent-app
```

에서 `agent-admin` 쓰기 가능 여부를 확인합니다.

---

## 19. 검증과 요구사항 추적

현재 저장소 코드 상태:

| ID | 요구사항 | 저장소 구현 | 실제 환경 테스트 |
|---|---|---|---|
| `LOG-01` | 10MB / 10개 로그 정책 | 구현 | 미검증 |
| `CRON-01` | agent-admin crontab | 예시 구현 | 미설치 |
| `CRON-02` | 매분 실행 | 구현 | 미검증 |
| `CRON-03` | 1~2분 후 로그 증가 | 테스트 절차 작성 | 미검증 |
| `CRON-04` | 최소 cron 환경 | 테스트 절차 작성 | 미검증 |

현재 08단계는 **설정 파일 IMPLEMENTED / 실제 Ubuntu 적용·검증 전**입니다.

---

## 20. 증빙 후보

```text
evidence/08-automation/
├── crontab-agent-admin.txt
├── cron-service-status.txt
├── cron-log-before-after.txt
├── logrotate-config.txt
├── logrotate-dry-run.txt
├── logrotate-force-test.txt
└── log-after-rotation.txt
```

---

## 21. 이번 단계 기억하기

### 한 문장

> **기록은 누적하고, 실행은 반복하고, 로그 크기는 제한한다.**

### 핵심어 3개

```text
cron · append · rotate
```

### 핵심 명령 3개

```bash
sudo -u agent-admin crontab -l
tail -n 3 /var/log/agent-app/monitor.log
sudo logrotate -d /etc/logrotate.d/agent-monitor
```

### 내가 설명할 수 있어야 할 것

> 왜 수동 실행 성공만으로 cron 성공이라고 말할 수 없는가?

답의 핵심은 **cron은 로그인 셸과 다른 최소 환경에서 실행되므로 환경변수·PATH·실행 계정 차이로 실패할 수 있기 때문**입니다.

---

## 22. 완료 체크

- [x] `config/crontab.example` 구현
- [x] 매분 `* * * * *` 설정
- [x] agent-admin 절대 경로 실행 설계
- [x] cron 최소 PATH 정의
- [x] `config/agent-monitor.logrotate` 구현
- [x] `size 10M` 설정
- [x] `rotate 10` 설정
- [x] 압축·권한 유지 설정
- [ ] 실제 최소 환경 monitor 실행
- [ ] agent-admin crontab 설치
- [ ] cron 서비스 확인
- [ ] 1~2분 후 로그 증가
- [ ] logrotate dry-run
- [ ] logrotate 강제 회전
- [ ] 회전 후 로그 재기록
- [ ] 11장에서 증빙 정리

현재 상태: **설정 IMPLEMENTED / 실제 환경 TEST 전**.

---

## 이동

- [이전: 07. monitor.sh](./07-monitor-script.md)
- [다음: 09. 정상·장애·복구 테스트](./09-testing-recovery.md)
- [전체 목차](./README.md)
