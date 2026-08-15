# B1-1 주요 명령어 참고

> 이 문서는 빠른 복습용 색인입니다. 실제 실행 순서·안전 조건은 각 `docs/01~15` 문서를 따릅니다.

## 환경

```bash
whoami
cat /etc/os-release
uname -m
ps -p 1 -o comm=
sudo -v
```

## SSH

```bash
sudo sshd -t
sudo sshd -T | grep -E '^(port|permitrootlogin) '
systemctl status ssh.socket --no-pager
systemctl cat ssh.socket
sudo ss -lntp | grep -E ':(22|20022)\b' || true
```

## 방화벽

```bash
sudo ufw status verbose
sudo ufw allow 20022/tcp
sudo ufw allow 15034/tcp
```

## 사용자·그룹

```bash
id agent-admin
id agent-dev
id agent-test
getent group agent-common agent-core
```

## 권한·ACL

```bash
stat -c '%U:%G:%a %n' <path>
getfacl <path>
setfacl -m ... <path>
namei -l <path>
```

## Agent

```bash
unzip -l agent-app.zip
uname -m
file <Agent 실행 파일>
pgrep -af 'agent-app-linux-x86'
ps -o user,pid,ppid,cmd -p <PID>
sudo ss -lntp | grep ':15034\b'
```

## monitor

```bash
bash -n scripts/monitor.sh
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
echo $?
tail -n 5 /var/log/agent-app/monitor.log
```

## cron

```bash
sudo -u agent-admin crontab -l
systemctl is-active cron
```

## logrotate

```bash
sudo logrotate -d /etc/logrotate.d/agent-monitor
sudo logrotate -f /etc/logrotate.d/agent-monitor
```

## 최종 검증

```bash
bash scripts/preflight.sh
sudo bash scripts/verify.sh
sudo bash scripts/acceptance-test.sh --agent-boot-log <FILE>
```

## 보너스

```bash
bash scripts/report.sh --log <monitor.log>
DRY_RUN=1 bash scripts/archive-logs.sh
```

## 기억 원칙

```text
상태 확인 → 변경 → 즉시 검증 → 실패 시 복구 → evidence
```
