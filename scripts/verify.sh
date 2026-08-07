#!/usr/bin/env bash
set -u

# Read-only B1-1 final verifier.
# It inspects the current system state but does not modify SSH, UFW,
# users/groups, ACLs, cron, logrotate, Agent state, or logs.

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() { printf '[PASS] %s\n' "$*"; PASS_COUNT=$((PASS_COUNT + 1)); }
warn() { printf '[WARN] %s\n' "$*"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { printf '[FAIL] %s\n' "$*"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

has_group() {
  local user="$1" group="$2"
  id -nG "$user" 2>/dev/null | tr ' ' '\n' | grep -Fxq "$group"
}

check_stat() {
  local path="$1" expected_owner="$2" expected_group="$3" expected_mode="$4"
  if [[ ! -e "$path" ]]; then
    fail "missing: $path"
    return
  fi
  local actual
  actual="$(stat -c '%U:%G:%a' "$path" 2>/dev/null || true)"
  if [[ "$actual" == "${expected_owner}:${expected_group}:${expected_mode}" ]]; then
    pass "$path => $actual"
  else
    fail "$path => $actual (expected ${expected_owner}:${expected_group}:${expected_mode})"
  fi
}

printf 'B1-1 final verifier (read-only)\n'
printf '%s\n' '----------------------------------------'

if [[ "$EUID" -ne 0 ]]; then
  warn 'Run as root for complete verification: sudo ./scripts/verify.sh'
fi

printf '\n[ssh]\n'
SSHD_EFFECTIVE="$(sshd -T 2>/dev/null || true)"
if [[ -n "$SSHD_EFFECTIVE" ]]; then
  if grep -Fxq 'port 20022' <<<"$SSHD_EFFECTIVE"; then pass 'sshd effective port=20022'; else fail 'sshd effective port is not 20022'; fi
  if grep -Fxq 'permitrootlogin no' <<<"$SSHD_EFFECTIVE"; then pass 'PermitRootLogin=no'; else fail 'PermitRootLogin is not no'; fi
else
  warn 'sshd -T could not be evaluated in the current runtime state; checking static B1-1 drop-in instead'
  if grep -Eq '^[[:space:]]*Port[[:space:]]+20022([[:space:]]|$)' /etc/ssh/sshd_config.d/99-b1-1.conf 2>/dev/null; then pass 'static SSH Port 20022 found'; else fail 'static SSH Port 20022 not found'; fi
  if grep -Eq '^[[:space:]]*PermitRootLogin[[:space:]]+no([[:space:]]|$)' /etc/ssh/sshd_config.d/99-b1-1.conf 2>/dev/null; then pass 'static PermitRootLogin no found'; else fail 'static PermitRootLogin no not found'; fi
fi

SS_OUTPUT="$(ss -lntH 2>/dev/null || true)"
if awk '$4 ~ /:20022$/ {found=1} END {exit !found}' <<<"$SS_OUTPUT"; then pass 'TCP 20022 is LISTEN'; else fail 'TCP 20022 is not LISTEN'; fi
if awk '$4 ~ /:22$/ {found=1} END {exit !found}' <<<"$SS_OUTPUT"; then fail 'TCP 22 is still LISTEN'; else pass 'TCP 22 is not LISTEN'; fi

printf '\n[ufw]\n'
if command -v ufw >/dev/null 2>&1; then
  UFW_OUTPUT="$(ufw status verbose 2>/dev/null || true)"
  if grep -Fq 'Status: active' <<<"$UFW_OUTPUT"; then pass 'UFW active'; else fail 'UFW not confirmed active'; fi
  if grep -Eq '^Default: deny \(incoming\)' <<<"$UFW_OUTPUT"; then pass 'UFW default incoming deny'; else fail 'UFW default incoming is not deny'; fi
  if grep -E '^20022/tcp' <<<"$UFW_OUTPUT" | grep -q 'ALLOW IN'; then pass 'UFW allows 20022/tcp'; else fail 'UFW 20022/tcp allow missing'; fi
  if grep -E '^15034/tcp' <<<"$UFW_OUTPUT" | grep -q 'ALLOW IN'; then pass 'UFW allows 15034/tcp'; else fail 'UFW 15034/tcp allow missing'; fi
  UNEXPECTED_RULES="$(awk '/ALLOW IN/ && $1 != "20022/tcp" && $1 != "15034/tcp" {print}' <<<"$UFW_OUTPUT")"
  if [[ -z "$UNEXPECTED_RULES" ]]; then pass 'no unexpected UFW ALLOW IN rules'; else fail "unexpected UFW ALLOW IN rule(s): $UNEXPECTED_RULES"; fi
else
  fail 'ufw command missing'
fi

printf '\n[users-groups]\n'
for user in agent-admin agent-dev agent-test; do
  if id "$user" >/dev/null 2>&1; then pass "user exists: $user"; else fail "user missing: $user"; fi
done

if has_group agent-admin agent-common && has_group agent-dev agent-common && has_group agent-test agent-common; then pass 'agent-common membership correct'; else fail 'agent-common membership incomplete'; fi
if has_group agent-admin agent-core && has_group agent-dev agent-core && ! has_group agent-test agent-core; then pass 'agent-core membership correct'; else fail 'agent-core membership incorrect'; fi

printf '\n[filesystem-acl]\n'
check_stat /home/agent-admin/agent-app agent-admin agent-common 2750
check_stat /home/agent-admin/agent-app/upload_files agent-admin agent-common 2770
check_stat /home/agent-admin/agent-app/api_keys agent-admin agent-core 2770
check_stat /var/log/agent-app agent-admin agent-core 2770

if command -v getfacl >/dev/null 2>&1 && getfacl -cp /home/agent-admin 2>/dev/null | grep -Fxq 'group:agent-common:--x'; then
  pass 'agent-common traverse ACL exists on /home/agent-admin'
else
  warn 'agent-common traverse ACL on /home/agent-admin not confirmed'
fi

printf '\n[agent-env-key]\n'
ENV_FILE=/etc/agent-app/agent.env
if [[ -r "$ENV_FILE" ]]; then
  pass "$ENV_FILE readable"
  grep -Fxq 'AGENT_HOME=/home/agent-admin/agent-app' "$ENV_FILE" && pass 'AGENT_HOME correct' || fail 'AGENT_HOME incorrect'
  grep -Fxq 'AGENT_PORT=15034' "$ENV_FILE" && pass 'AGENT_PORT correct' || fail 'AGENT_PORT incorrect'
  grep -Fxq 'AGENT_UPLOAD_DIR=/home/agent-admin/agent-app/upload_files' "$ENV_FILE" && pass 'AGENT_UPLOAD_DIR correct' || fail 'AGENT_UPLOAD_DIR incorrect'
  grep -Fxq 'AGENT_KEY_PATH=/home/agent-admin/agent-app/api_keys/t_secret.key' "$ENV_FILE" && pass 'AGENT_KEY_PATH correct' || fail 'AGENT_KEY_PATH incorrect'
  grep -Fxq 'AGENT_LOG_DIR=/var/log/agent-app' "$ENV_FILE" && pass 'AGENT_LOG_DIR correct' || fail 'AGENT_LOG_DIR incorrect'
else
  fail "$ENV_FILE missing or unreadable"
fi

check_stat /home/agent-admin/agent-app/api_keys/t_secret.key agent-admin agent-core 660

printf '\n[agent-runtime]\n'
AGENT_PROCESS_PATTERN="agent_app.py"
if [[ -r "$ENV_FILE" ]]; then
  CONFIG_PATTERN="$(awk -F= '$1=="AGENT_PROCESS_PATTERN" {print substr($0,index($0,"=")+1); exit}' "$ENV_FILE")"
  [[ -n "$CONFIG_PATTERN" ]] && AGENT_PROCESS_PATTERN="$CONFIG_PATTERN"
fi
AGENT_PID="$(pgrep -f -- "$AGENT_PROCESS_PATTERN" | head -n 1 || true)"
if [[ -n "$AGENT_PID" ]]; then
  AGENT_USER="$(ps -o user= -p "$AGENT_PID" 2>/dev/null | tr -d '[:space:]')"
  if [[ -n "$AGENT_USER" && "$AGENT_USER" != "root" ]]; then pass "Agent process non-root: pid=$AGENT_PID user=$AGENT_USER"; else fail "Agent process owner invalid: pid=$AGENT_PID user=${AGENT_USER:-unknown}"; fi
else
  fail "Agent process not found: pattern=$AGENT_PROCESS_PATTERN"
fi

if awk '$4 == "0.0.0.0:15034" {found=1} END {exit !found}' <<<"$SS_OUTPUT"; then pass 'Agent LISTEN is 0.0.0.0:15034'; else fail '0.0.0.0:15034 LISTEN not found'; fi

printf '\n[monitor]\n'
MONITOR=/home/agent-admin/agent-app/bin/monitor.sh
check_stat "$MONITOR" agent-dev agent-core 750
if [[ -f "$MONITOR" ]] && bash -n "$MONITOR"; then pass 'deployed monitor.sh Bash syntax OK'; else fail 'deployed monitor.sh Bash syntax failed or file missing'; fi

LOG=/var/log/agent-app/monitor.log
if [[ -s "$LOG" ]]; then
  LAST_LINE="$(tail -n 1 "$LOG")"
  if grep -Eq '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] PID:[0-9]+ CPU:[0-9]+(\.[0-9]+)?% MEM:[0-9]+(\.[0-9]+)?% DISK_USED:[0-9]+%$' <<<"$LAST_LINE"; then
    pass 'monitor.log last line matches required format'
  else
    fail "monitor.log format mismatch: $LAST_LINE"
  fi
else
  fail 'monitor.log missing or empty'
fi

printf '\n[cron-logrotate]\n'
CRON_OUTPUT="$(crontab -u agent-admin -l 2>/dev/null || true)"
if grep -Eq '^\* \* \* \* \* /home/agent-admin/agent-app/bin/monitor\.sh([[:space:]]|$)' <<<"$CRON_OUTPUT"; then pass 'agent-admin cron runs monitor.sh every minute'; else fail 'agent-admin every-minute cron entry missing'; fi

ROTATE=/etc/logrotate.d/agent-monitor
if [[ -r "$ROTATE" ]]; then
  grep -Eq '^[[:space:]]*size[[:space:]]+10M([[:space:]]|$)' "$ROTATE" && pass 'logrotate size 10M' || fail 'logrotate size 10M missing'
  grep -Eq '^[[:space:]]*rotate[[:space:]]+10([[:space:]]|$)' "$ROTATE" && pass 'logrotate rotate 10' || fail 'logrotate rotate 10 missing'
else
  fail "$ROTATE missing or unreadable"
fi

printf '\n[repository-secret-check]\n'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
if command -v git >/dev/null 2>&1 && git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  TRACKED_SECRETS="$(git -C "$REPO_ROOT" ls-files | grep -E '(^|/)([^/]*\.key|\.env($|\.))' | grep -vE '\.env\.example$' || true)"
  if [[ -z "$TRACKED_SECRETS" ]]; then pass 'no obvious tracked .key/.env secret files'; else fail "possible tracked secret files: $TRACKED_SECRETS"; fi
else
  warn 'repository secret check skipped: Git worktree not detected'
fi

printf '\n[summary]\n'
printf 'PASS=%d WARN=%d FAIL=%d\n' "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"

if (( FAIL_COUNT > 0 )); then
  printf '[FAIL] B1-1 final verification has blocking items.\n'
  exit 1
fi

printf '[PASS] B1-1 read-only final verification checks passed.\n'
exit 0
