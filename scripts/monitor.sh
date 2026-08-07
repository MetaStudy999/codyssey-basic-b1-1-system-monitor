#!/usr/bin/env bash
set -u

# B1-1 system monitor
# - Agent process/port health failures: exit 1
# - Firewall/resource threshold issues: WARNING only
# - Runtime/config/logging failures: exit 2

umask 0007

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
LOG_FILE="${AGENT_LOG_DIR}/monitor.log"

CPU_WARN_THRESHOLD="${CPU_WARN_THRESHOLD:-20}"
MEM_WARN_THRESHOLD="${MEM_WARN_THRESHOLD:-10}"
DISK_WARN_THRESHOLD="${DISK_WARN_THRESHOLD:-80}"

warn() { printf '[WARNING] %s\n' "$*"; }
error() { printf '[ERROR] %s\n' "$*" >&2; }

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    error "required command not found: $1"
    exit 2
  fi
}

is_greater_than() {
  awk -v value="$1" -v limit="$2" 'BEGIN { exit !(value > limit) }'
}

resolve_process_pattern() {
  if [[ -n "${AGENT_PROCESS_PATTERN:-}" ]]; then
    printf '%s' "$AGENT_PROCESS_PATTERN"
    return
  fi

  case "$(uname -m 2>/dev/null || true)" in
    x86_64|amd64) printf '%s' 'agent-app-linux-x86' ;;
    aarch64|arm64) printf '%s' 'agent-app-linux-arm64' ;;
    *) printf '%s' 'agent_app.py' ;;
  esac
}

read_cpu_snapshot() {
  awk '/^cpu / {
    total = 0
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
    if (dt <= 0) printf "0.00"; else printf "%.2f", 100 * (dt - di) / dt
  }'
}

collect_mem_percent() {
  awk '
    /^MemTotal:/     { total = $2 }
    /^MemAvailable:/ { available = $2 }
    END {
      if (total <= 0) printf "0.00"; else printf "%.2f", 100 * (total - available) / total
    }
  ' /proc/meminfo
}

collect_disk_percent() {
  df -P / | awk 'NR == 2 { gsub(/%/, "", $5); printf "%d", $5 }'
}

firewall_is_active() {
  if command -v ufw >/dev/null 2>&1; then
    if ufw status 2>/dev/null | grep -Fq 'Status: active'; then
      return 0
    fi
    if [[ -r /etc/ufw/ufw.conf ]] \
      && grep -Eq '^[[:space:]]*ENABLED[[:space:]]*=[[:space:]]*yes([[:space:]]|$)' /etc/ufw/ufw.conf \
      && command -v systemctl >/dev/null 2>&1 \
      && systemctl is-active --quiet ufw 2>/dev/null; then
      return 0
    fi
  fi

  if command -v firewall-cmd >/dev/null 2>&1 \
    && firewall-cmd --state 2>/dev/null | grep -Fxq running; then
    return 0
  fi

  return 1
}

require_command awk
require_command date
require_command df
require_command grep
require_command head
require_command pgrep
require_command sleep
require_command ss
require_command uname

AGENT_PROCESS_PATTERN="$(resolve_process_pattern)"

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
if is_greater_than "$CPU" "$CPU_WARN_THRESHOLD"; then warn "CPU usage ${CPU}% exceeds ${CPU_WARN_THRESHOLD}%"; fi
if is_greater_than "$MEM" "$MEM_WARN_THRESHOLD"; then warn "MEM usage ${MEM}% exceeds ${MEM_WARN_THRESHOLD}%"; fi
if is_greater_than "$DISK_USED" "$DISK_WARN_THRESHOLD"; then warn "DISK_USED ${DISK_USED}% exceeds ${DISK_WARN_THRESHOLD}%"; fi

# 6) Logging prerequisites.
if [[ ! -d "$AGENT_LOG_DIR" ]]; then
  error "log directory does not exist: $AGENT_LOG_DIR"
  exit 2
fi
if [[ ! -w "$AGENT_LOG_DIR" ]]; then
  error "log directory is not writable: $AGENT_LOG_DIR"
  exit 2
fi
if [[ -e "$LOG_FILE" && ! -w "$LOG_FILE" ]]; then
  error "log file exists but is not writable: $LOG_FILE"
  exit 2
fi

# 7) Required log format. A failed append must never be reported as success.
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
LOG_LINE="[$TIMESTAMP] PID:$AGENT_PID CPU:${CPU}% MEM:${MEM}% DISK_USED:${DISK_USED}%"
if ! printf '%s\n' "$LOG_LINE" >> "$LOG_FILE"; then
  error "failed to append log: $LOG_FILE"
  exit 2
fi
printf '%s\n' "$LOG_LINE"

exit 0
