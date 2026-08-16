#!/usr/bin/env bash
# B1-1 R01 verification-only script. It must not modify the system.

set -u

PASS=0
FAIL=0
AGENT_HOME="${AGENT_HOME:-/home/agent-admin/agent-app}"
AGENT_LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
MONITOR_LOG="${AGENT_LOG_DIR}/monitor.log"

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }

check_cmd() {
    if command -v "$1" >/dev/null 2>&1; then pass "command exists: $1"; else fail "command missing: $1"; fi
}

for cmd in bash ss ps pgrep df stat getent id crontab; do check_cmd "$cmd"; done

# SSH effective configuration and listen port.
if command -v sshd >/dev/null 2>&1; then
    SSHD_T=$(sshd -T 2>/dev/null || sudo -n sshd -T 2>/dev/null || true)
    if echo "$SSHD_T" | grep -Eq '^port 20022$'; then pass "SSH effective port is 20022"; else fail "SSH effective port 20022 not confirmed"; fi
    if echo "$SSHD_T" | grep -Eq '^permitrootlogin no$'; then pass "PermitRootLogin no"; else fail "Root remote login block not confirmed"; fi
else
    fail "sshd command missing"
fi

if ss -lnt 2>/dev/null | awk '$4 ~ /:20022$/ {ok=1} END{exit !ok}'; then pass "TCP 20022 LISTEN"; else fail "TCP 20022 not LISTEN"; fi

# Firewall: require one supported firewall to be active and both required ports present.
FW_OK=0
if command -v ufw >/dev/null 2>&1; then
    UFW_OUT=$(sudo -n ufw status 2>/dev/null || ufw status 2>/dev/null || true)
    if echo "$UFW_OUT" | grep -q 'Status: active'; then
        if echo "$UFW_OUT" | grep -q '20022/tcp' && echo "$UFW_OUT" | grep -q '15034/tcp'; then FW_OK=1; fi
    fi
elif command -v firewall-cmd >/dev/null 2>&1; then
    if firewall-cmd --state 2>/dev/null | grep -q running; then
        PORTS=$(firewall-cmd --list-ports 2>/dev/null || true)
        if echo "$PORTS" | grep -qw '20022/tcp' && echo "$PORTS" | grep -qw '15034/tcp'; then FW_OK=1; fi
    fi
fi
if [ "$FW_OK" -eq 1 ]; then pass "Firewall active with required ports"; else fail "Firewall active/required ports not confirmed"; fi

# Users and groups.
for u in agent-admin agent-dev agent-test; do
    if id "$u" >/dev/null 2>&1; then pass "user exists: $u"; else fail "user missing: $u"; fi
done
for g in agent-common agent-core; do
    if getent group "$g" >/dev/null 2>&1; then pass "group exists: $g"; else fail "group missing: $g"; fi
done

id -nG agent-admin 2>/dev/null | grep -qw agent-common && id -nG agent-admin 2>/dev/null | grep -qw agent-core && pass "agent-admin group membership" || fail "agent-admin group membership"
id -nG agent-dev 2>/dev/null | grep -qw agent-common && id -nG agent-dev 2>/dev/null | grep -qw agent-core && pass "agent-dev group membership" || fail "agent-dev group membership"
id -nG agent-test 2>/dev/null | grep -qw agent-common && pass "agent-test group membership" || fail "agent-test group membership"

for d in "$AGENT_HOME" "$AGENT_HOME/upload_files" "$AGENT_HOME/api_keys" "$AGENT_LOG_DIR"; do
    [ -d "$d" ] && pass "directory exists: $d" || fail "directory missing: $d"
done

[ -f "$AGENT_HOME/api_keys/t_secret.key" ] && pass "Secret file exists (value not read)" || fail "Secret file missing"

MONITOR="$AGENT_HOME/bin/monitor.sh"
if [ -f "$MONITOR" ]; then
    OWNER=$(stat -c '%U' "$MONITOR" 2>/dev/null || true)
    GROUP=$(stat -c '%G' "$MONITOR" 2>/dev/null || true)
    MODE=$(stat -c '%a' "$MONITOR" 2>/dev/null || true)
    [ "$OWNER" = agent-dev ] && pass "monitor.sh owner agent-dev" || fail "monitor.sh owner is $OWNER"
    [ "$GROUP" = agent-core ] && pass "monitor.sh group agent-core" || fail "monitor.sh group is $GROUP"
    [ "$MODE" = 750 ] && pass "monitor.sh mode 750" || fail "monitor.sh mode is $MODE"
else
    fail "monitor.sh missing at $MONITOR"
fi

# Agent process/port runtime checks.
PATTERN="${AGENT_PROCESS_PATTERN:-agent-app|agent_app.py}"
PID=$(pgrep -f "$PATTERN" 2>/dev/null | head -n1 || true)
[ -n "$PID" ] && pass "Agent process running (PID $PID)" || fail "Agent process not running"
if ss -lnt 2>/dev/null | awk '$4 ~ /:15034$/ {ok=1} END{exit !ok}'; then pass "TCP 15034 LISTEN"; else fail "TCP 15034 not LISTEN"; fi

# Runtime log and format.
if [ -s "$MONITOR_LOG" ]; then
    pass "monitor.log exists and is non-empty"
    LAST=$(tail -n1 "$MONITOR_LOG")
    if echo "$LAST" | grep -Eq '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] PID:[0-9]+ CPU:[0-9.]+% MEM:[0-9.]+% DISK_USED:[0-9.]+%$'; then
        pass "monitor.log format"
    else
        fail "monitor.log format"
    fi
else
    fail "monitor.log missing or empty"
fi

# Log retention: active + numbered rotated logs must be <= 10 files.
LOG_COUNT=$(find "$AGENT_LOG_DIR" -maxdepth 1 -type f \( -name 'monitor.log' -o -name 'monitor.log.[0-9]*' \) 2>/dev/null | wc -l)
[ "$LOG_COUNT" -le 10 ] && pass "monitor log file count <= 10" || fail "monitor log file count is $LOG_COUNT"

# Cron: require agent-admin entry invoking monitor.sh every minute.
CRON=$(crontab -u agent-admin -l 2>/dev/null || sudo -n crontab -u agent-admin -l 2>/dev/null || true)
if echo "$CRON" | grep -Eq '^\* \* \* \* \* .*monitor\.sh'; then pass "agent-admin cron every minute"; else fail "agent-admin cron entry not confirmed"; fi

# Repository Secret tracking check. No Secret contents are read.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd)
if command -v git >/dev/null 2>&1 && git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    TRACKED=$(git -C "$REPO_ROOT" ls-files | grep -E '(^|/)(\.env($|\.)|.*\.(key|pem)$|secrets/)' || true)
    [ -z "$TRACKED" ] && pass "no tracked Secret-pattern files" || fail "tracked Secret-pattern files detected"
fi

echo
printf 'Result: %d PASS / %d FAIL\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
