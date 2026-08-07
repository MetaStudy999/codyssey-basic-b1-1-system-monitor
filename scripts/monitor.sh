#!/usr/bin/env bash
set -u

# B1-1 system monitor
# - Agent process/port health failures: exit 1
# - Firewall/resource threshold issues: WARNING only
# - Resource log: /var/log/agent-app/monitor.log

umask 0027

ENV_FILE="${AGENT_ENV_FILE:-/etc/agent-app/agent.env}"
if [[ -r "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

AGENT_HOME="${AGENT_HOME:-/home/agent-admin/agent-app}"
AGENT_PORT="${AGENT_PORT:-15034}"
AGENT_LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
AGENT_PROCESS_PATTERN="${AGENT_PROCESS_PATTERN:-agent_app.py}"
LOG_FILE="${AGENT_LOG_DIR}/monitor.log"

CPU_WARN_THRESHOLD="${CPU_WARN_THRESHOLD:-20}"
MEM_WARN_THRESHOLD="${MEM_WARN_THRESHOLD:-10}"
DISK_WARN_THRESHOLD="${DISK_WARN_THRESHOLD:-80}"

warn() {
  printf '[WARNING] %s\n' "$*"
}

error() {
  printf '[ERROR] %s\n' "$*" >&2
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    error "required command not found: $1"
    exit 2
  fi
}

is_greater_than() {
  awk -v value="$1" -v limit="$2" 'BEGIN { exit !(value > limit) }'
}

read_cpu_snapshot() {
  awk '/^cpu / {
    total = 0
    # user, nice, system, idle, iowait, irq, softirq, steal
    # guest/guest_nice are already included in user/nice and are not added again.
    for (i = 2; i <= 9 && i <= NF; i++) total += $i
    idle = $5 + $6
    printf "%.0f %.0f\n", total, idle
    exit
  }' /proc/stat
}

collect_cpu_percent() {
  local total1 idle1 total2 idle2
  read -r total1 idle1 < <(read_cpu_snapshot)
  sleep 0.2
  read -r total2 idle2 < <(read_cpu_snapshot)

  awk -v t1="$total1" -v i1="$idle1" -v t2="$total2" -v i2="$idle2" 'BEGIN {
    dt = t2 - t1
    di = i2 - i1
    if (dt <= 0) {
      printf "0.00"
    } else {
      printf "%.2f", 100 * (dt - di) / dt
    }
  }'
}

collect_mem_percent() {
  awk '
    /^MemTotal:/     { total = $2 }
    /^MemAvailable:/ { available = $2 }
    END {
      if (total <= 0) {
        printf "0.00"
      } else {
        printf "%.2f", 100 * (total - available) / total
      }
    }
  ' /proc/meminfo
}

collect_disk_percent() {
  df -P / | awk 'NR == 2 { gsub(/%/, "", $5); printf "%d", $5 }'
}

firewall_is_active() {
  # monitor.sh is intended to run from agent-admin's cron without interactive sudo.
  # systemctl status is therefore used instead of privileged `ufw status`.
  if command -v systemctl >/dev/null 2>&1; then
    if command -v ufw >/dev/null 2>&1 && systemctl is-active --quiet ufw 2>/dev/null; then
      return 0
    fi
    if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

require_command awk
require_command df
require_command pgrep
require_command ss

# 1) Health check: process. Failure must terminate with exit 1.
AGENT_PID="$(pgrep -f -- "$AGENT_PROCESS_PATTERN" | head -n 1 || true)"
if [[ -z "$AGENT_PID" ]]; then
  error "Agent process not found: pattern=$AGENT_PROCESS_PATTERN"
  exit 1
fi

# 2) Health check: TCP port. Failure must terminate with exit 1.
if ! ss -lntH 2>/dev/null | awk -v port="$AGENT_PORT" '$4 ~ (":" port "$") { found = 1 } END { exit !found }'; then
  error "Agent port is not LISTEN: tcp/$AGENT_PORT"
  exit 1
fi

# 3) Firewall: warning only.
if ! firewall_is_active; then
  warn "firewall is inactive or could not be confirmed active"
fi

# 4) Resource collection.
CPU="$(collect_cpu_percent)"
MEM="$(collect_mem_percent)"
DISK_USED="$(collect_disk_percent)"

# 5) Thresholds: warning only.
if is_greater_than "$CPU" "$CPU_WARN_THRESHOLD"; then
  warn "CPU usage ${CPU}% exceeds ${CPU_WARN_THRESHOLD}%"
fi

if is_greater_than "$MEM" "$MEM_WARN_THRESHOLD"; then
  warn "MEM usage ${MEM}% exceeds ${MEM_WARN_THRESHOLD}%"
fi

if is_greater_than "$DISK_USED" "$DISK_WARN_THRESHOLD"; then
  warn "DISK_USED ${DISK_USED}% exceeds ${DISK_WARN_THRESHOLD}%"
fi

# 6) Logging prerequisites.
if [[ ! -d "$AGENT_LOG_DIR" ]]; then
  error "log directory does not exist: $AGENT_LOG_DIR"
  exit 2
fi

if [[ ! -w "$AGENT_LOG_DIR" ]]; then
  error "log directory is not writable: $AGENT_LOG_DIR"
  exit 2
fi

# 7) Required log format.
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
LOG_LINE="[$TIMESTAMP] PID:$AGENT_PID CPU:${CPU}% MEM:${MEM}% DISK_USED:${DISK_USED}%"
printf '%s\n' "$LOG_LINE" >> "$LOG_FILE"
printf '%s\n' "$LOG_LINE"

exit 0
