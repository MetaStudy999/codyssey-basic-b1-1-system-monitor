#!/usr/bin/env bash
set -u

# B1-1 read-only state verifier.
# It checks current configuration/state only. It does NOT prove Boot Sequence,
# failure-injection behavior, cron growth, or evidence completeness.

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
  if [[ ! -e "$path" ]]; then fail "missing: $path"; return; fi
  local actual
  actual="$(stat -c '%U:%G:%a' "$path" 2>/dev/null || true)"
  [[ "$actual" == "${expected_owner}:${expected_group}:${expected_mode}" ]] \
    && pass "$path => $actual" \
    || fail "$path => $actual (expected ${expected_owner}:${expected_group}:${expected_mode})"
}

resolve_process_pattern() {
  local env_file="$1" pattern=""
  if [[ -r "$env_file" ]]; then
    pattern="$(awk -F= '$1=="AGENT_PROCESS_PATTERN" {print substr($0,index($0,"=")+1); exit}' "$env_file")"
  fi
  if [[ -n "$pattern" ]]; then printf '%s' "$pattern"; return; fi
  case "$(uname -m 2>/dev/null || true)" in
    x86_64|amd64) printf '%s' 'agent-app-linux-x86' ;;
    aarch64|arm64) printf '%s' 'agent-app-linux-arm64' ;;
    *) printf '%s' 'agent_app.py' ;;
  esac
}

printf 'B1-1 read-only state verifier\n'
printf '%s\n' '----------------------------------------'
[[ "$EUID" -eq 0 ]] || warn 'Run as root for complete verification: sudo bash scripts/verify.sh'

printf '\n[ssh]\n'
if command -v sshd >/dev/null 2>&1; then
  SSHD_EFFECTIVE="$(sshd -T 2>/dev/null || true)"
  if [[ -n "$SSHD_EFFECTIVE" ]]; then
    grep -Fxq 'port 20022' <<<"$SSHD_EFFECTIVE" && pass 'sshd effective port=20022' || fail 'sshd effective port is not 20022'
    grep -Fxq 'permitrootlogin no' <<<"$SSHD_EFFECTIVE" && pass 'PermitRootLogin=no' || fail 'PermitRootLogin is not no'
  else
    warn 'sshd -T unavailable; static drop-in will be checked'
    grep -Eq '^[[:space:]]*Port[[:space:]]+20022([[:space:]]|$)' /etc/ssh/sshd_config.d/99-b1-1.conf 2>/dev/null && pass 'static SSH Port 20022 found' || fail 'static SSH Port 20022 not found'
    grep -Eq '^[[:space:]]*PermitRootLogin[[:space:]]+no([[:space:]]|$)' /etc/ssh/sshd_config.d/99-b1-1.conf 2>/dev/null && pass 'static PermitRootLogin no found' || fail 'static PermitRootLogin no not found'
  fi
else
  fail 'sshd command missing'
fi

SS_OUTPUT="$(ss -lntH 2>/dev/null || true)"
awk '$4 ~ /:20022$/ {found=1} END {exit !found}' <<<"$SS_OUTPUT" && pass 'TCP 20022 is LISTEN' || fail 'TCP 20022 is not LISTEN'
awk '$4 ~ /:22$/ {found=1} END {exit !found}' <<<"$SS_OUTPUT" && fail 'TCP 22 is still LISTEN' || pass 'TCP 22 is not LISTEN'

printf '\n[ufw]\n'
if command -v ufw >/dev/null 2>&1; then
  UFW_OUTPUT="$(ufw status verbose 2>/dev/null || true)"
  grep -Fq 'Status: active' <<<"$UFW_OUTPUT" && pass 'UFW active' || fail 'UFW not confirmed active'
  grep -Eq '^Default: deny \(incoming\)' <<<"$UFW_OUTPUT" && pass 'UFW default incoming deny' || fail 'UFW default incoming is not deny'
  grep -E '^20022/tcp' <<<"$UFW_OUTPUT" | grep -q 'ALLOW IN' && pass 'UFW allows 20022/tcp' || fail 'UFW 20022/tcp allow missing'
  grep -E '^15034/tcp' <<<"$UFW_OUTPUT" | grep -q 'ALLOW IN' && pass 'UFW allows 15034/tcp' || fail 'UFW 15034/tcp allow missing'
  UNEXPECTED_RULES="$(awk '/ALLOW IN/ && $1 != "20022/tcp" && $1 != "15034/tcp" {print}' <<<"$UFW_OUTPUT")"
  [[ -z "$UNEXPECTED_RULES" ]] && pass 'no unexpected UFW ALLOW IN rules' || fail "unexpected UFW ALLOW IN rule(s): $UNEXPECTED_RULES"
else
  fail 'ufw command missing'
fi

printf '\n[users-groups]\n'
for user in agent-admin agent-dev agent-test; do
  id "$user" >/dev/null 2>&1 && pass "user exists: $user" || fail "user missing: $user"
done
has_group agent-admin agent-common && has_group agent-dev agent-common && has_group agent-test agent-common \
  && pass 'agent-common membership correct' || fail 'agent-common membership incomplete'
has_group agent-admin agent-core && has_group agent-dev agent-core && ! has_group agent-test agent-core \
  && pass 'agent-core membership correct' || fail 'agent-core membership incorrect'

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
AGENT_PROCESS_PATTERN="$(resolve_process_pattern "$ENV_FILE")"
AGENT_PID="$(pgrep -f -- "$AGENT_PROCESS_PATTERN" | head -n 1 || true)"
if [[ -n "$AGENT_PID" ]]; then
  AGENT_USER="$(ps -o user= -p "$AGENT_PID" 2>/dev/null | tr -d '[:space:]')"
  [[ -n "$AGENT_USER" && "$AGENT_USER" != root ]] && pass "Agent process non-root: pid=$AGENT_PID user=$AGENT_USER pattern=$AGENT_PROCESS_PATTERN" || fail "Agent process owner invalid: pid=$AGENT_PID user=${AGENT_USER:-unknown}"
else
  fail "Agent process not found: pattern=$AGENT_PROCESS_PATTERN"
fi
awk '$4 == "0.0.0.0:15034" {found=1} END {exit !found}' <<<"$SS_OUTPUT" && pass 'Agent LISTEN is 0.0.0.0:15034' || fail '0.0.0.0:15034 LISTEN not found'

printf '\n[monitor]\n'
MONITOR=/home/agent-admin/agent-app/bin/monitor.sh
check_stat "$MONITOR" agent-dev agent-core 750
[[ -f "$MONITOR" ]] && bash -n "$MONITOR" && pass 'deployed monitor.sh Bash syntax OK' || fail 'deployed monitor.sh Bash syntax failed or file missing'
LOG=/var/log/agent-app/monitor.log
if [[ -s "$LOG" ]]; then
  LAST_LINE="$(tail -n 1 "$LOG")"
  grep -Eq '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] PID:[0-9]+ CPU:[0-9]+(\.[0-9]+)?% MEM:[0-9]+(\.[0-9]+)?% DISK_USED:[0-9]+%$' <<<"$LAST_LINE" \
    && pass 'monitor.log last line matches required format' || fail "monitor.log format mismatch: $LAST_LINE"
  LOG_STAT="$(stat -c '%U:%G:%a' "$LOG" 2>/dev/null || true)"
  [[ "$LOG_STAT" == 'agent-admin:agent-core:660' ]] && pass 'monitor.log owner/group/mode=agent-admin:agent-core:660' || warn "monitor.log metadata=$LOG_STAT (target agent-admin:agent-core:660)"
else
  fail 'monitor.log missing or empty'
fi

printf '\n[cron-logrotate]\n'
CRON_OUTPUT="$(crontab -u agent-admin -l 2>/dev/null || true)"
grep -Eq '^\* \* \* \* \* /home/agent-admin/agent-app/bin/monitor\.sh([[:space:]]|$)' <<<"$CRON_OUTPUT" && pass 'agent-admin cron runs monitor.sh every minute' || fail 'agent-admin every-minute cron entry missing'
ROTATE=/etc/logrotate.d/agent-monitor
if [[ -r "$ROTATE" ]]; then
  grep -Eq '^[[:space:]]*size[[:space:]]+10M([[:space:]]|$)' "$ROTATE" && pass 'logrotate size 10M' || fail 'logrotate size 10M missing'
  grep -Eq '^[[:space:]]*rotate[[:space:]]+9([[:space:]]|$)' "$ROTATE" && pass 'logrotate rotate 9 => current + 9 rotations = max 10 files' || fail 'strict max-10-file policy (rotate 9) missing'
  grep -Eq '^[[:space:]]*create[[:space:]]+0660[[:space:]]+agent-admin[[:space:]]+agent-core([[:space:]]|$)' "$ROTATE" && pass 'logrotate create 0660 agent-admin agent-core' || fail 'logrotate create metadata incorrect'
else
  fail "$ROTATE missing or unreadable"
fi

printf '\n[repository-secret-files]\n'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
if command -v git >/dev/null 2>&1 && git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  TRACKED_SECRETS="$(git -C "$REPO_ROOT" ls-files | grep -E '(^|/)([^/]*\.key|\.env($|\.))' | grep -vE '\.env\.example$' || true)"
  [[ -z "$TRACKED_SECRETS" ]] && pass 'no obvious tracked .key/.env secret files' || fail "possible tracked secret files: $TRACKED_SECRETS"
else
  warn 'repository secret-file check skipped: Git worktree not detected'
fi

printf '\n[summary]\n'
printf 'PASS=%d WARN=%d FAIL=%d\n' "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"
if (( FAIL_COUNT > 0 )); then
  printf '[FAIL] B1-1 current-state verification has blocking items.\n'
  exit 1
fi

printf '[PASS] B1-1 current-state checks passed.\n'
printf '[NEXT] Final mission PASS still requires runtime acceptance tests, Boot/READY evidence, cron-growth observation, and evidence review.\n'
exit 0
