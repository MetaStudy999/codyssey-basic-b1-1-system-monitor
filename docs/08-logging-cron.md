# 08. 로그 관리와 cron 자동화

> **기억 문장:** 기록은 누적하고, 실행은 반복하고, 로그 파일 수와 권한은 명확히 제한한다.

이 장에서는 `monitor.sh`를 `agent-admin`의 cron으로 매분 실행하고, `monitor.log`를 원본 미션의 **10MB / 최대 10개 파일** 정책으로 관리합니다.

---

## 1. 목표

```text
cron 실행 계정 = agent-admin
실행 주기      = 매분
로그           = /var/log/agent-app/monitor.log
로그 크기      = 10MB 기준
전체 파일 수   = 최대 10개
```

저장소 구현:

```text
config/crontab.example
config/agent-monitor.logrotate
```

---

## 2. 역할 분리

```text
monitor.sh → 상태 확인 + 로그 append
cron       → monitor.sh 매분 실행
logrotate  → 크기/보존 파일 수/새 파일 권한 관리
```

---

## 3. 사전 조건

05~07이 먼저 완료되어야 합니다.

```bash
id agent-admin
stat /home/agent-admin/agent-app/bin/monitor.sh
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
```

수동 실행이 `exit 0`이 아니면 cron 등록으로 넘어가지 않습니다.

---

## 4. monitor.log 권한 목표

05장의 `agent-core R/W` 정책과 일치시키기 위해 다음을 목표로 합니다.

```text
owner = agent-admin
group = agent-core
mode  = 0660
```

확인:

```bash
stat -c '%U:%G:%a %n' /var/log/agent-app/monitor.log
```

---

## 5. cron 최소 환경 시험

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
exit 0
monitor.log 증가
```

`monitor.sh`가 `/etc/agent-app/agent.env`를 직접 읽으므로 터미널의 임시 `export`에만 의존하지 않습니다.

---

## 6. crontab 설치

저장소 예시:

```cron
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
MAILTO=""
* * * * * /home/agent-admin/agent-app/bin/monitor.sh >/dev/null 2>&1
```

설치:

```bash
sudo -u agent-admin crontab < config/crontab.example
```

검증:

```bash
sudo -u agent-admin crontab -l
systemctl is-active cron
```

Root나 현재 `ubuntu` 사용자의 crontab에 대신 설치하면 요구사항과 다릅니다.
또한 crontab에 `CPU_WARN_THRESHOLD`, `MEM_WARN_THRESHOLD`, `DISK_WARN_THRESHOLD`나 다른 실행환경 override를 추가하지 않습니다. 위의 `SHELL`, `PATH`, 빈 `MAILTO`만 사용해야 미션의 기본 임계값 `20/10/80`과 검증된 실행환경이 유지됩니다.

---

## 7. 1~2분 자동 증가 확인

```bash
wc -l /var/log/agent-app/monitor.log
sleep 70
wc -l /var/log/agent-app/monitor.log
tail -n 3 /var/log/agent-app/monitor.log
```

성공 조건:

```text
사람이 직접 monitor.sh를 실행하지 않았는데 로그가 증가
새 timestamp 존재
```

통합 acceptance 스크립트에서도 이 관찰을 수행할 수 있습니다.

```bash
sudo bash scripts/acceptance-test.sh \
  --agent-boot-log <Agent 시작 출력 파일>
```

---

## 8. `10MB / 최대 10개 파일` 해석

원본 문구는:

```text
monitor.log가 커지면 최대 10MB / 10개 파일 유지
```

입니다.

logrotate의 `rotate N`은 일반적으로 **현재 파일을 제외한 회전본 개수**를 뜻합니다. 따라서 `rotate 10`을 사용하면:

```text
현재 monitor.log 1개
+ 회전본 최대 10개
= 최대 11개
```

가 될 수 있습니다.

이 저장소는 원본의 **최대 10개 파일**을 엄격하게 해석하여:

```text
현재 monitor.log 1개
+ 회전본 최대 9개
= 최대 10개
```

로 구성합니다.

따라서 현재 설정은:

```conf
size 10M
rotate 9
```

입니다.

평가 시 `rotate 9`를 사용한 이유를 위처럼 설명할 수 있어야 합니다.

---

## 9. logrotate 설정

```conf
/var/log/agent-app/monitor.log {
    size 10M
    rotate 9
    compress
    missingok
    notifempty
    su agent-admin agent-core
    create 0660 agent-admin agent-core
}
```

핵심 의미:

```text
size 10M                 → 실행 시 10MB 이상이면 회전 대상
rotate 9                 → 현재 + 회전본을 최대 10개로 제한
compress                 → 회전본 압축
su agent-admin agent-core→ 해당 사용자/그룹 컨텍스트로 회전
create 0660 ...           → 새 로그에도 core R/W 정책 유지
```

### 중요한 한계

`size 10M`은 **logrotate가 실행되는 시점에** 검사합니다. 즉 설정 파일만 두었다고 10MB를 넘는 즉시 자동 회전되는 것은 아닙니다.

다만 이 미션의 monitor 로그는 매분 한 줄 수준이므로 일반적인 logrotate 실행 주기로도 충분한지 실제 환경에서 확인합니다. 평가에서는 **설정과 실행 주기는 별개**라는 점을 설명할 수 있어야 합니다.

---

## 10. 설치와 정적 확인

```bash
sudo install -o root -g root -m 0644 \
  config/agent-monitor.logrotate \
  /etc/logrotate.d/agent-monitor

sudo logrotate -d /etc/logrotate.d/agent-monitor
```

다음 오류가 있으면 강제 회전으로 넘어가지 않습니다.

```text
syntax error
unknown user/group
insecure permissions
permission denied
```

---

## 11. 통제된 강제 회전

실습 로그를 회전해도 되는 시점에만:

```bash
sudo logrotate -f /etc/logrotate.d/agent-monitor
```

확인:

```bash
ls -lh /var/log/agent-app/monitor.log*
stat -c '%U:%G:%a %n' /var/log/agent-app/monitor.log
```

회전 후에도 `agent-admin`이 새 로그를 쓸 수 있어야 합니다.

```bash
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
```

---

## 12. 현재 상태

```text
crontab.example           IMPLEMENTED
logrotate strict max-10   IMPLEMENTED
0660 core R/W 격리 fixture TESTED
실제 crontab 설치          NEEDS-RUNTIME
cron 자동 증가             NEEDS-RUNTIME
실제 설정 logrotate dry-run NEEDS-RUNTIME
실제 설정 강제 회전         NEEDS-RUNTIME
회전 후 monitor 재기록      NEEDS-RUNTIME
```

실제 Ubuntu 검증 전에는 `PASS`로 올리지 않습니다.

---

## 13. 증빙 후보

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

## 14. 이번 단계 기억하기

### 한 문장

> **기록은 누적하고, 실행은 반복하고, 로그 파일 수와 권한은 명확히 제한한다.**

### 핵심어 3개

```text
CRON · SIZE · ROTATE
```

### 핵심 명령

```bash
sudo -u agent-admin crontab -l
sudo logrotate -d /etc/logrotate.d/agent-monitor
stat -c '%U:%G:%a %n' /var/log/agent-app/monitor.log
```

---

## 이동

- [이전: 07. monitor.sh](./07-monitor-script.md)
- [다음: 09. 정상·장애·복구 테스트](./09-testing-recovery.md)
- [전체 목차](./README.md)
