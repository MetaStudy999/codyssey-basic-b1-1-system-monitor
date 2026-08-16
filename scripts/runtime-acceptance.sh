#!/usr/bin/env bash
set -u

PASS=0
FAIL=0
WARN=0

ok() { printf '[PASS] %s\n' "$*"; PASS=$((PASS+1)); }
fail() { printf '[FAIL] %s\n' "$*"; FAIL=$((FAIL+1)); }
warn() { printf '[WARN] %s\n' "$*"; WARN=$((WARN+1)); }

check_cmd() {
  command -v "$1" >/dev/null 2>&1 || warn "command not found: $1"
}

printf 'B1-1 runtime acceptance · restart-20260816\n'
printf 'host=%s arch=%s\n\n' "$(hostname 2>/dev/null || echo unknown)" "$(uname -m)"

check_cmd sshd
check_cmd ss
check_cmd ufw
check_cmd getfacl
check_cmd logrotate

printf '\n[SSH]\n'
if command -v sshd >/dev/null 2>&1; then
  SSHD_T="$(sudo sshd -T 2>/dev/null || true)"
  grep -q '^port 20022$' <<<"$SSHD_T" && ok 'sshd port 20022' || fail 'sshd port 20022'
  grep -q '^permitrootlogin no$' <<<"$SSHD_T" && ok 'PermitRootLogin no' || fail 'PermitRootLogin no'
else
  fail 'sshd unavailable'
fi

if ss -lntH 2>/dev/null | awk '$4 ~ /:20022$/ {found=1} END{exit !found}'; then
  ok 'TCP 20022 LISTEN'
else
  fail 'TCP 20022 LISTEN'
fi
if ss -lntH 2>/dev/null | awk '$4 ~ /:22$/ {found=1} END{exit !found}'; then
  fail 'legacy TCP 22 still LISTEN'
else
  ok 'legacy TCP 22 not LISTEN'
fi

printf '\n[FIREWALL]\n'
if command -v ufw >/dev/null 2>&1; then
  UFW="$(sudo ufw status verbose 2>/dev/null || true)"
  grep -q '^Status: active' <<<"$UFW" && ok 'UFW active' || fail 'UFW active'
  grep -Eq '^20022/tcp[[:space:]]+ALLOW IN' <<<"$UFW" && ok 'UFW 20022/tcp allowed' || fail 'UFW 20022/tcp allowed'
  grep -Eq '^15034/tcp[[:space:]]+ALLOW IN' <<<"$UFW" && ok 'UFW 15034/tcp allowed' || fail 'UFW 15034/tcp allowed'
else
  fail 'ufw unavailable'
fi

printf '\n[USERS AND GROUPS]\n'
for user in agent-admin agent-dev agent-test; do
  id "$user" >/dev/null 2>&1 && ok "user exists: $user" || fail "user exists: $user"
done
for group in agent-common agent-core; do
  getent group "$group" >/dev/null 2>&1 && ok "group exists: $group" || fail "group exists: $group"
done

for user in agent-admin agent-dev; do
  id -nG "$user" 2>/dev/null | tr ' ' '\n' | grep -qx agent-common && ok "$user in agent-common" || fail "$user in agent-common"
  id -nG "$user" 2>/dev/null | tr ' ' '\n' | grep -qx agent-core && ok "$user in agent-core" || fail "$user in agent-core"
done
id -nG agent-test 2>/dev/null | tr ' ' '\n' | grep -qx agent-common && ok 'agent-test in agent-common' || fail 'agent-test in agent-common'
if id -nG agent-test 2>/dev/null | tr ' ' '\n' | grep -qx agent-core; then
  fail 'agent-test must not be in agent-core'
else
  ok 'agent-test not in agent-core'
fi

printf '\n[DIRECTORIES AND ACCESS]\n'
AGENT_HOME=/home/agent-admin/agent-app
for dir in "$AGENT_HOME/upload_files" "$AGENT_HOME/api_keys" /var/log/agent-app; do
  [[ -d "$dir" ]] && ok "directory exists: $dir" || fail "directory exists: $dir"
done

if sudo -u agent-test test -w "$AGENT_HOME/upload_files" 2>/dev/null; then ok 'agent-test can write upload_files'; else fail 'agent-test can write upload_files'; fi
if sudo -u agent-test test -r "$AGENT_HOME/api_keys" 2>/dev/null; then fail 'agent-test must not read api_keys'; else ok 'agent-test blocked from api_keys'; fi
if sudo -u agent-test test -w /var/log/agent-app 2>/dev/null; then fail 'agent-test must not write log dir'; else ok 'agent-test blocked from log dir'; fi

printf '\n[KEY]\n'
KEY="$AGENT_HOME/api_keys/t_secret.key"
if [[ -f "$KEY" ]]; then
  ok 't_secret.key exists'
  STAT="$(sudo stat -c '%U %G %a' "$KEY" 2>/dev/null || true)"
  [[ "$STAT" == 'agent-admin agent-core 660' ]] && ok 'key owner/group/mode = agent-admin agent-core 660' || fail "key owner/group/mode: ${STAT:-unknown}"
  [[ "$(sudo wc -l < "$KEY" 2>/dev/null || echo 0)" -eq 1 ]] && ok 'key contains one line' || fail 'key must contain one line'
else
  fail 't_secret.key exists'
fi

printf '\n[AGENT]\n'
AGENT_PID="$(pgrep -f 'agent-app-linux-x86|agent-app-linux-arm64|agent_app.py' | head -n 1 || true)"
if [[ -n "$AGENT_PID" ]]; then
  ok "Agent process found PID=$AGENT_PID"
  OWNER="$(ps -o user= -p "$AGENT_PID" 2>/dev/null | xargs || true)"
  if [[ -n "$OWNER" && "$OWNER" != root ]]; then ok "Agent non-root owner=$OWNER"; else fail "Agent must be non-root owner=${OWNER:-unknown}"; fi
else
  fail 'Agent process running'
fi

if ss -lntH 2>/dev/null | awk '$4 ~ /0\.0\.0\.0:15034$/ {found=1} END{exit !found}'; then
  ok 'Agent LISTEN 0.0.0.0:15034'
else
  fail 'Agent LISTEN 0.0.0.0:15034'
fi

printf '\n[MONITOR]\n'
MONITOR="$AGENT_HOME/bin/monitor.sh"
if [[ -x "$MONITOR" ]]; then
  ok 'monitor.sh executable'
  MSTAT="$(stat -c '%U %G %a' "$MONITOR" 2>/dev/null || true)"
  [[ "$MSTAT" == 'agent-dev agent-core 750' ]] && ok 'monitor owner/group/mode = agent-dev agent-core 750' || fail "monitor owner/group/mode: ${MSTAT:-unknown}"
else
  fail 'monitor.sh executable'
fi

if [[ -f /var/log/agent-app/monitor.log ]]; then
  ok 'monitor.log exists'
  tail -n 1 /var/log/agent-app/monitor.log | grep -Eq '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] PID:[0-9]+ CPU:[0-9.]+% MEM:[0-9.]+% DISK_USED:[0-9]+%$' \
    && ok 'monitor.log format' || fail 'monitor.log format'
else
  fail 'monitor.log exists'
fi

printf '\n[CRON AND LOGROTATE]\n'
CRON="$(sudo -u agent-admin crontab -l 2>/dev/null || true)"
grep -Eq '^\* \* \* \* \* /home/agent-admin/agent-app/bin/monitor\.sh' <<<"$CRON" && ok 'agent-admin cron every minute' || fail 'agent-admin cron every minute'

if [[ -f /etc/logrotate.d/agent-monitor ]]; then
  ok 'logrotate config installed'
  sudo logrotate -d /etc/logrotate.d/agent-monitor >/dev/null 2>&1 && ok 'logrotate dry-run' || fail 'logrotate dry-run'
else
  fail 'logrotate config installed'
fi

printf '\n[SUMMARY]\n'
printf 'PASS=%d FAIL=%d WARN=%d\n' "$PASS" "$FAIL" "$WARN"
if [[ "$FAIL" -eq 0 ]]; then
  printf '[PASS] Runtime acceptance checks passed. Boot Sequence/Agent READY text still requires captured Agent output evidence.\n'
  exit 0
fi
printf '[FAIL] Fix only the failed items, then run this script again.\n'
exit 1
