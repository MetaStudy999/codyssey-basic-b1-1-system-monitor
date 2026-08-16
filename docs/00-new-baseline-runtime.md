# B1-1 · New Baseline 빠른 실행 가이드

> 목표: **필수 미션을 빠르게 Clear하기 위한 현재 실행 경로**입니다. 과거 `01~15` 문서는 참고자료이며, 실제 수행은 이 문서의 순서를 우선합니다.

## 현재 위치

- G1 SOURCE: PASS
- G2 BUILD: PASS
- G3 TEST: PASS
- G4 REVIEW: 이 문서와 안전한 실행 절차를 확정하는 단계
- 다음: G5 실제 Ubuntu Runtime

## 실행 원칙

1. 한 번에 한 블록만 실행합니다.
2. 각 블록 끝의 확인 결과가 정상일 때 다음으로 갑니다.
3. `t_secret.key` 값은 화면·Git·채팅에 붙여넣지 않습니다.
4. 기존 급행 수행 결과는 참고만 하고 현재 PASS로 자동 승계하지 않습니다.
5. `chmod 777`, 광범위한 `chown -R`, Root Agent 실행은 사용하지 않습니다.

---

# A. 사전 확인

Ubuntu에서 저장소 루트로 이동한 뒤:

```bash
uname -a
uname -m
id
pwd
git status --short
```

필수 도구:

```bash
sudo apt-get update
sudo apt-get install -y openssh-server ufw acl unzip iproute2 procps logrotate
```

---

# B. SSH 20022 + Root 원격 차단

먼저 현재 세션이 원격 SSH라면 기존 접속을 닫지 않습니다.

```bash
printf 'SSH_CONNECTION=%s\n' "$SSH_CONNECTION"
sudo ufw allow 20022/tcp
```

설정:

```bash
sudo tee /etc/ssh/sshd_config.d/99-b1-1.conf >/dev/null <<'EOF'
Port 20022
PermitRootLogin no
EOF

sudo mkdir -p /run/sshd
sudo sshd -t
sudo systemctl daemon-reload
sudo systemctl restart ssh.socket 2>/dev/null || sudo systemctl restart ssh
```

확인:

```bash
sudo sshd -T | grep -E '^(port|permitrootlogin) '
sudo ss -lntp | grep -E ':(22|20022)\b' || true
```

정상 목표:

```text
port 20022
permitrootlogin no
20022 LISTEN
22 LISTEN 없음
```

---

# C. UFW — 20022 / 15034만 인바운드 허용

```bash
sudo ufw allow 15034/tcp
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw --force enable
sudo ufw status verbose
```

정상 목표:

```text
Status: active
Default: deny (incoming)
20022/tcp ALLOW IN
15034/tcp ALLOW IN
```

불필요한 22/tcp 허용 규칙이 있다면 **현재 20022 새 접속 가능 여부를 먼저 확인한 후** 제거합니다.

---

# D. 사용자·그룹 생성

```bash
for group in agent-common agent-core; do
  getent group "$group" >/dev/null || sudo groupadd "$group"
done

for user in agent-admin agent-dev agent-test; do
  id "$user" >/dev/null 2>&1 || sudo useradd -m -s /bin/bash "$user"
done

sudo usermod -aG agent-common,agent-core agent-admin
sudo usermod -aG agent-common,agent-core agent-dev
sudo usermod -aG agent-common agent-test
```

확인:

```bash
id agent-admin
id agent-dev
id agent-test
```

정상 목표:

```text
agent-admin → agent-common + agent-core
agent-dev   → agent-common + agent-core
agent-test  → agent-common만
```

---

# E. 디렉터리·ACL

```bash
AGENT_HOME=/home/agent-admin/agent-app
sudo mkdir -p \
  "$AGENT_HOME/upload_files" \
  "$AGENT_HOME/api_keys" \
  /var/log/agent-app

sudo setfacl -m g:agent-common:--x /home/agent-admin
sudo chown agent-admin:agent-common "$AGENT_HOME"
sudo chmod 2750 "$AGENT_HOME"

sudo chown agent-admin:agent-common "$AGENT_HOME/upload_files"
sudo chmod 2770 "$AGENT_HOME/upload_files"
sudo setfacl -m d:u::rwx,d:g::rwx,d:o::--- "$AGENT_HOME/upload_files"

sudo chown agent-admin:agent-core "$AGENT_HOME/api_keys"
sudo chmod 2770 "$AGENT_HOME/api_keys"
sudo setfacl -m d:u::rwx,d:g::rwx,d:o::--- "$AGENT_HOME/api_keys"

sudo chown agent-admin:agent-core /var/log/agent-app
sudo chmod 2770 /var/log/agent-app
sudo setfacl -m d:u::rwx,d:g::rwx,d:o::--- /var/log/agent-app
```

접근 시험:

```bash
sudo -u agent-test bash -c \
  'touch /home/agent-admin/agent-app/upload_files/.test && rm /home/agent-admin/agent-app/upload_files/.test'

sudo -u agent-test test -r /home/agent-admin/agent-app/api_keys \
  && echo '[ERROR] agent-test can read api_keys' \
  || echo '[OK] agent-test blocked from api_keys'

sudo -u agent-test test -w /var/log/agent-app \
  && echo '[ERROR] agent-test can write log dir' \
  || echo '[OK] agent-test blocked from log dir'
```

---

# F. Agent 설치·키·실행

[06. Agent 실행환경 · New Baseline](./06-agent-setup.md)을 따라 실제 `agent-app.zip` 구조를 확인한 뒤 **실제 실행 파일만** 설치합니다.

중요:

```text
금지: sudo chown -R agent-admin:agent-common /home/agent-admin/agent-app
```

이는 `api_keys` 보안 경계를 깨뜨릴 수 있습니다.

Agent 실행 성공 후 다음이 보여야 합니다.

```text
Boot Sequence 1 [OK]
Boot Sequence 2 [OK]
Boot Sequence 3 [OK]
Boot Sequence 4 [OK]
Boot Sequence 5 [OK]
Agent READY
```

다른 터미널:

```bash
pgrep -af 'agent-app-linux|agent_app.py'
sudo ss -lntp | grep ':15034\b'
```

---

# G. monitor.sh 설치

```bash
REPO_DIR="$(git rev-parse --show-toplevel)"
AGENT_HOME=/home/agent-admin/agent-app
sudo install -d -o agent-admin -g agent-core -m 0750 "$AGENT_HOME/bin"
sudo install -o agent-dev -g agent-core -m 0750 \
  "$REPO_DIR/scripts/monitor.sh" \
  "$AGENT_HOME/bin/monitor.sh"
```

확인:

```bash
stat -c 'owner=%U group=%G mode=%a path=%n' "$AGENT_HOME/bin/monitor.sh"
```

정상 목표:

```text
owner=agent-dev group=agent-core mode=750
```

직접 실행:

```bash
sudo -u agent-admin -H bash -c '
  set -a
  source /etc/agent-app/agent.env
  set +a
  /home/agent-admin/agent-app/bin/monitor.sh
'
```

로그:

```bash
sudo tail -n 5 /var/log/agent-app/monitor.log
```

---

# H. cron + logrotate

cron:

```bash
sudo -u agent-admin crontab "$REPO_DIR/config/crontab.example"
sudo -u agent-admin crontab -l
```

1~2분 뒤:

```bash
sudo stat -c 'size=%s mtime=%y' /var/log/agent-app/monitor.log
sudo tail -n 5 /var/log/agent-app/monitor.log
```

logrotate 설치:

```bash
sudo install -o root -g root -m 0644 \
  "$REPO_DIR/config/agent-monitor.logrotate" \
  /etc/logrotate.d/agent-monitor
sudo logrotate -d /etc/logrotate.d/agent-monitor
```

현재 정책은 `monitor.log` + rotated 9개 = **최대 10개**, 각 파일 최대 10MB 기준입니다.

---

# I. 한 번에 상태 점검

저장소의 검증 스크립트:

```bash
bash tests/new-baseline-static.sh
bash tests/new-baseline-monitor-behavior.sh
```

실제 시스템 상태는 다음을 한 번에 저장합니다.

```bash
bash scripts/runtime-acceptance.sh | tee /tmp/b1-1-runtime.txt
```

`[FAIL]`이 있으면 그 항목만 고칩니다. 전체를 처음부터 다시 하지 않습니다.

---

# J. Clear 전에 필요한 것

- SSH 20022 / Root remote no
- UFW active / inbound 20022·15034
- 3 users / 2 groups / ACL 실제 확인
- Agent 5 OK + READY + non-root + 0.0.0.0:15034
- monitor 정상·장애 동작
- cron 자동 로그 증가
- logrotate 정책 확인
- 평가 항목별 Evidence
- 핵심 명령·이유 설명

위 항목을 실제로 확인하면 G5/G6을 완료하고 G7/G8로 넘어갑니다.
