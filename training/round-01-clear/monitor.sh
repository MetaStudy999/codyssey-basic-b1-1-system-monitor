#!/usr/bin/env bash
# B1-1 Reference implementation
# Runtime install target: $AGENT_HOME/bin/monitor.sh
# This file contains no Secret and must not print Secret values.

set -u

AGENT_PORT="${AGENT_PORT:-15034}"
AGENT_LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
MONITOR_LOG="${AGENT_LOG_DIR}/monitor.log"
AGENT_PROCESS_PATTERN="${AGENT_PROCESS_PATTERN:-agent-app|agent_app.py}"
MAX_LOG_BYTES=$((10 * 1024 * 1024))
MAX_TOTAL_LOG_FILES=10

fail() {
    printf '[FAIL] %s\n' "$1" >&2
    exit 1
}

warn() {
    printf '[WARNING] %s\n' "$1"
}

is_over() {
    # Usage: is_over VALUE LIMIT
    # awk is used so decimal CPU/MEM values can be compared safely.
    awk -v value="$1" -v limit="$2" 'BEGIN { exit !(value > limit) }'
}

rotate_log_if_needed() {
    # Keep at most 10 files total: monitor.log + monitor.log.1 ... monitor.log.9
    [ -f "$MONITOR_LOG" ] || return 0

    local size
    size=$(stat -c '%s' "$MONITOR_LOG" 2>/dev/null || printf '0')
    [ "$size" -ge "$MAX_LOG_BYTES" ] || return 0

    rm -f "${MONITOR_LOG}.9"

    local i=8
    while [ "$i" -ge 1 ]; do
        if [ -f "${MONITOR_LOG}.${i}" ]; then
            mv "${MONITOR_LOG}.${i}" "${MONITOR_LOG}.$((i + 1))"
        fi
        i=$((i - 1))
    done

    mv "$MONITOR_LOG" "${MONITOR_LOG}.1"
}

printf '%s\n' '====== SYSTEM MONITOR RESULT ======'
printf '%s\n' '[HEALTH CHECK]'

# 1) Process Health Check
PID=$(pgrep -f "$AGENT_PROCESS_PATTERN" 2>/dev/null | head -n 1 || true)
if [ -z "$PID" ]; then
    fail "Agent process not found (pattern: ${AGENT_PROCESS_PATTERN})"
fi
printf '[OK] Process found (PID: %s)\n' "$PID"

# 2) TCP 15034 Health Check
if ! command -v ss >/dev/null 2>&1; then
    fail "ss command is required to verify TCP port ${AGENT_PORT}"
fi

if ! ss -lnt 2>/dev/null | awk -v port=":${AGENT_PORT}" 'NR > 1 && index($4, port) && $4 ~ (port "$" ) {found=1} END {exit !found}'; then
    fail "TCP ${AGENT_PORT} is not LISTEN"
fi
printf '[OK] TCP %s is LISTEN\n' "$AGENT_PORT"

# 3) Firewall state: warning only, not a health-check failure.
FIREWALL_ACTIVE=0
if command -v systemctl >/dev/null 2>&1; then
    if command -v ufw >/dev/null 2>&1 && systemctl is-active --quiet ufw 2>/dev/null; then
        FIREWALL_ACTIVE=1
    elif command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
        FIREWALL_ACTIVE=1
    fi
fi

if [ "$FIREWALL_ACTIVE" -eq 1 ]; then
    printf '%s\n' '[OK] Firewall service is active'
else
    warn 'Firewall active state could not be confirmed'
fi

printf '%s\n' '[RESOURCE MONITORING]'

# Process CPU/MEM usage. The official mission asks for CPU/MEM percentages;
# this reference implementation measures the monitored Agent process.
CPU=$(ps -p "$PID" -o %cpu= 2>/dev/null | awk '{print $1 + 0}')
MEM=$(ps -p "$PID" -o %mem= 2>/dev/null | awk '{print $1 + 0}')
DISK_USED=$(df -P / 2>/dev/null | awk 'NR==2 {gsub(/%/, "", $5); print $5 + 0}')

[ -n "$CPU" ] || fail 'Unable to collect CPU usage'
[ -n "$MEM" ] || fail 'Unable to collect memory usage'
[ -n "$DISK_USED" ] || fail 'Unable to collect root filesystem usage'

printf 'CPU Usage : %s%%\n' "$CPU"
printf 'MEM Usage : %s%%\n' "$MEM"
printf 'DISK Used : %s%%\n' "$DISK_USED"

if is_over "$CPU" 20; then
    warn "CPU threshold exceeded (${CPU}% > 20%)"
fi
if is_over "$MEM" 10; then
    warn "MEM threshold exceeded (${MEM}% > 10%)"
fi
if is_over "$DISK_USED" 80; then
    warn "DISK_USED threshold exceeded (${DISK_USED}% > 80%)"
fi

# Logging requires the official log directory to exist and be writable.
[ -d "$AGENT_LOG_DIR" ] || fail "Log directory does not exist: ${AGENT_LOG_DIR}"
[ -w "$AGENT_LOG_DIR" ] || fail "Log directory is not writable: ${AGENT_LOG_DIR}"

rotate_log_if_needed

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
printf '[%s] PID:%s CPU:%s%% MEM:%s%% DISK_USED:%s%%\n' \
    "$TIMESTAMP" "$PID" "$CPU" "$MEM" "$DISK_USED" >> "$MONITOR_LOG"

printf '[OK] Log appended: %s\n' "$MONITOR_LOG"
printf '%s\n' '====== MONITOR COMPLETE ======'
exit 0
