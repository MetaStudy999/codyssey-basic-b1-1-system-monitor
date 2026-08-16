#!/usr/bin/env bash
# B1-1 R01 Reference implementation
# Runtime install target: $AGENT_HOME/bin/monitor.sh
# This file contains no Secret and must never print Secret values.

set -u

AGENT_PORT="${AGENT_PORT:-15034}"
AGENT_LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
MONITOR_LOG="${AGENT_LOG_DIR}/monitor.log"

# The R01 Golden Path installs the selected provided binary under the canonical
# basename "agent-app". Using pgrep -x avoids false positives from directory
# names such as /opt/agent-app/bin/monitor.sh.
AGENT_PROCESS_NAME="${AGENT_PROCESS_NAME:-agent-app}"

# Official defaults. Environment overrides exist only to make warning/rotation
# behavior safely testable without stressing the real machine.
CPU_WARN_THRESHOLD="${CPU_WARN_THRESHOLD:-20}"
MEM_WARN_THRESHOLD="${MEM_WARN_THRESHOLD:-10}"
DISK_WARN_THRESHOLD="${DISK_WARN_THRESHOLD:-80}"
MAX_LOG_BYTES="${MAX_LOG_BYTES:-10485760}"
MAX_TOTAL_LOG_FILES="${MAX_TOTAL_LOG_FILES:-10}"

fail() {
    printf '[FAIL] %s\n' "$1" >&2
    exit 1
}

warn() {
    printf '[WARNING] %s\n' "$1"
}

is_over() {
    # Usage: is_over VALUE LIMIT
    # awk safely compares both integer and decimal percentages.
    awk -v value="$1" -v limit="$2" 'BEGIN { exit !(value > limit) }'
}

rotate_log_if_needed() {
    [ -f "$MONITOR_LOG" ] || return 0

    case "$MAX_TOTAL_LOG_FILES" in
        ''|*[!0-9]*) fail 'MAX_TOTAL_LOG_FILES must be a positive integer' ;;
    esac
    [ "$MAX_TOTAL_LOG_FILES" -ge 2 ] || fail 'MAX_TOTAL_LOG_FILES must be at least 2'

    local size
    size=$(stat -c '%s' "$MONITOR_LOG" 2>/dev/null || printf '0')
    [ "$size" -ge "$MAX_LOG_BYTES" ] || return 0

    # Total file count includes active monitor.log. Therefore, when the total
    # limit is 10, rotated logs are monitor.log.1 ... monitor.log.9.
    local max_rotated=$((MAX_TOTAL_LOG_FILES - 1))
    rm -f "${MONITOR_LOG}.${max_rotated}"

    local i=$((max_rotated - 1))
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

# 1) Process Health Check. Process failure is a hard failure.
PID=$(pgrep -x "$AGENT_PROCESS_NAME" 2>/dev/null | head -n 1 || true)
if [ -z "$PID" ]; then
    fail "Agent process not found (name: ${AGENT_PROCESS_NAME})"
fi
printf '[OK] Process found (name: %s, PID: %s)\n' "$AGENT_PROCESS_NAME" "$PID"

# 2) TCP 15034 Health Check. Port failure is a hard failure.
if ! command -v ss >/dev/null 2>&1; then
    fail "ss command is required to verify TCP port ${AGENT_PORT}"
fi

if ! ss -lnt 2>/dev/null | awk -v port=":${AGENT_PORT}" 'NR > 1 && $4 ~ (port "$" ) {found=1} END {exit !found}'; then
    fail "TCP ${AGENT_PORT} is not LISTEN"
fi
printf '[OK] TCP %s is LISTEN\n' "$AGENT_PORT"

# 3) Firewall is a warning-only state check. The full firewall policy is
# verified separately by environment/verify.sh.
FIREWALL_ACTIVE=0
if command -v ufw >/dev/null 2>&1; then
    if ufw status 2>/dev/null | grep -q '^Status: active$'; then
        FIREWALL_ACTIVE=1
    elif command -v sudo >/dev/null 2>&1 && sudo -n ufw status 2>/dev/null | grep -q '^Status: active$'; then
        FIREWALL_ACTIVE=1
    fi
elif command -v firewall-cmd >/dev/null 2>&1; then
    if firewall-cmd --state 2>/dev/null | grep -q '^running$'; then
        FIREWALL_ACTIVE=1
    fi
fi

if [ "$FIREWALL_ACTIVE" -eq 1 ]; then
    printf '%s\n' '[OK] Firewall is active'
else
    warn 'Firewall active state could not be confirmed'
fi

printf '%s\n' '[RESOURCE MONITORING]'

# CPU/MEM are collected for the monitored Agent process. Root filesystem disk
# usage is collected separately because it is a system-level resource.
CPU=$(ps -p "$PID" -o %cpu= 2>/dev/null | awk '{print $1 + 0}')
MEM=$(ps -p "$PID" -o %mem= 2>/dev/null | awk '{print $1 + 0}')
DISK_USED=$(df -P / 2>/dev/null | awk 'NR==2 {gsub(/%/, "", $5); print $5 + 0}')

[ -n "$CPU" ] || fail 'Unable to collect CPU usage'
[ -n "$MEM" ] || fail 'Unable to collect memory usage'
[ -n "$DISK_USED" ] || fail 'Unable to collect root filesystem usage'

printf 'CPU Usage : %s%%\n' "$CPU"
printf 'MEM Usage : %s%%\n' "$MEM"
printf 'DISK Used : %s%%\n' "$DISK_USED"

if is_over "$CPU" "$CPU_WARN_THRESHOLD"; then
    warn "CPU threshold exceeded (${CPU}% > ${CPU_WARN_THRESHOLD}%)"
fi
if is_over "$MEM" "$MEM_WARN_THRESHOLD"; then
    warn "MEM threshold exceeded (${MEM}% > ${MEM_WARN_THRESHOLD}%)"
fi
if is_over "$DISK_USED" "$DISK_WARN_THRESHOLD"; then
    warn "DISK_USED threshold exceeded (${DISK_USED}% > ${DISK_WARN_THRESHOLD}%)"
fi

# Logging requires the official log directory to exist and be writable by the
# cron executor (agent-admin).
[ -d "$AGENT_LOG_DIR" ] || fail "Log directory does not exist: ${AGENT_LOG_DIR}"
[ -w "$AGENT_LOG_DIR" ] || fail "Log directory is not writable: ${AGENT_LOG_DIR}"

rotate_log_if_needed

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
printf '[%s] PID:%s CPU:%s%% MEM:%s%% DISK_USED:%s%%\n' \
    "$TIMESTAMP" "$PID" "$CPU" "$MEM" "$DISK_USED" >> "$MONITOR_LOG"

printf '[OK] Log appended: %s\n' "$MONITOR_LOG"
printf '%s\n' '====== MONITOR COMPLETE ======'
exit 0
