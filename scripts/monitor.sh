#!/usr/bin/env bash
set -u

# B1-1 system monitor
# - Agent process/port health failures: exit 1
# - Firewall/resource threshold issues: WARNING only
# - Runtime/config/logging failures: exit 2

umask 0007

warn() { printf '[WARNING] %s\n' "$*"; }
error() { printf '[ERROR] %s\n' "$*" >&2; }

load_env_file() {
  local file="$1" line key value line_number=0
  local -A seen=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_number=$((line_number + 1))
    line="${line%$'\r'}"
    [[ "$line" =~ ^[[:space:]]*$ || "$line" =~ ^[[:space:]]*# ]] && continue

    if [[ ! "$line" =~ ^([A-Z][A-Z0-9_]*)=(.*)$ ]]; then
      error "invalid env assignment at ${file}:${line_number}"
      return 1
    fi
    key="${BASH_REMATCH[1]}"
    value="${BASH_REMATCH[2]}"

    case "$key" in
      AGENT_HOME|AGENT_PORT|AGENT_UPLOAD_DIR|AGENT_KEY_PATH|AGENT_LOG_DIR|AGENT_PROCESS_PATTERN) ;;
      *)
        error "unsupported env key at ${file}:${line_number}: $key"
        return 1
        ;;
    esac
    if [[ -n "${seen[$key]+present}" ]]; then
      error "duplicate env key at ${file}:${line_number}: $key"
      return 1
    fi

    printf -v "$key" '%s' "$value"
    seen["$key"]=1
  done < "$file"
}

ENV_FILE="${AGENT_ENV_FILE:-/etc/agent-app/agent.env}"
if [[ -L "$ENV_FILE" ]]; then
  error "env file must not be a symbolic link: $ENV_FILE"
  exit 2
elif [[ -e "$ENV_FILE" ]]; then
  if [[ ! -f "$ENV_FILE" || ! -r "$ENV_FILE" ]]; then
    error "env file is not a readable regular file: $ENV_FILE"
    exit 2
  fi
  if ! command -v stat >/dev/null 2>&1; then
    error 'required command not found: stat'
    exit 2
  fi
  ENV_OWNER="$(stat -c '%u' -- "$ENV_FILE" 2>/dev/null || true)"
  ENV_MODE="$(stat -c '%a' -- "$ENV_FILE" 2>/dev/null || true)"
  if [[ ! "$ENV_OWNER" =~ ^[0-9]+$ || ( "$ENV_OWNER" != 0 && "$ENV_OWNER" != "$EUID" ) \
    || ! "$ENV_MODE" =~ ^[0-7]{3,4}$ ]]; then
    error "env file owner/mode is not trusted: $ENV_FILE"
    exit 2
  fi
  if (( (8#$ENV_MODE & 022) != 0 )); then
    error "env file owner/mode is not trusted: $ENV_FILE"
    exit 2
  fi
  load_env_file "$ENV_FILE" || exit 2
fi

AGENT_HOME="${AGENT_HOME:-/home/agent-admin/agent-app}"
AGENT_PORT="${AGENT_PORT:-15034}"
AGENT_LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
LOG_FILE="${AGENT_LOG_DIR}/monitor.log"

CPU_WARN_THRESHOLD="${CPU_WARN_THRESHOLD:-20}"
MEM_WARN_THRESHOLD="${MEM_WARN_THRESHOLD:-10}"
DISK_WARN_THRESHOLD="${DISK_WARN_THRESHOLD:-80}"

LC_ALL=C
export LC_ALL

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    error "required command not found: $1"
    exit 2
  fi
}

is_greater_than() {
  awk -v value="$1" -v limit="$2" 'BEGIN { exit !(value > limit) }'
}

valid_percent() {
  [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]] \
    && awk -v value="$1" 'BEGIN { exit !(value >= 0 && value <= 100) }'
}

valid_threshold() {
  [[ "$1" =~ ^-?[0-9]+([.][0-9]+)?$ ]] \
    && awk -v value="$1" 'BEGIN { exit !(value >= -1 && value <= 100) }'
}

escape_ere() {
  printf '%s' "$1" | sed 's/[][(){}.^$*+?|\\]/\\&/g'
}

resolve_process_pattern() {
  if [[ -n "${AGENT_PROCESS_PATTERN:-}" ]]; then
    printf '%s' "$AGENT_PROCESS_PATTERN"
    return
  fi

  case "$(uname -m 2>/dev/null || true)" in
    x86_64|amd64) printf '%s' 'agent-app-linux-x86' ;;
    aarch64|arm64) printf '%s' 'agent-app-linux-arm64' ;;
    *)
      error 'unsupported architecture; set AGENT_PROCESS_PATTERN only after verifying the provided executable'
      return 1
      ;;
  esac
}

is_self_or_ancestor_pid() {
  local candidate="$1" current="$$" parent

  while [[ "$current" =~ ^[0-9]+$ ]] && (( current > 0 )); do
    [[ "$candidate" == "$current" ]] && return 0
    parent="$(awk '/^PPid:/ { print $2; exit }' "/proc/${current}/status" 2>/dev/null || true)"
    [[ "$parent" =~ ^[0-9]+$ && "$parent" != "$current" ]] || break
    current="$parent"
  done
  return 1
}

process_signature_matches() {
  local pid="$1" exe_path exe_base expected_base process_uid arg index
  local -a expected=() actual=()

  exe_path="$(readlink -f -- "/proc/${pid}/exe" 2>/dev/null || true)"
  [[ -n "$exe_path" ]] || return 1
  exe_base="${exe_path##*/}"
  process_uid="$(awk '/^Uid:/ { print $2; exit }' "/proc/${pid}/status" 2>/dev/null || true)"
  [[ "$process_uid" == "$EUID" ]] || return 1

  [[ -r "/proc/${pid}/cmdline" ]] || return 1
  while IFS= read -r -d '' arg; do
    actual+=("$arg")
  done < "/proc/${pid}/cmdline"
  (( ${#actual[@]} > 0 )) || return 1

  read -r -a expected <<< "$AGENT_PROCESS_PATTERN"
  (( ${#expected[@]} > 0 )) || return 1

  if (( ${#expected[@]} == 1 )) && [[ "${expected[0]}" == *.py ]]; then
    case "$exe_base" in
      python|python[0-9]*|pypy|pypy[0-9]*) ;;
      *) return 1 ;;
    esac
    for (( index = 1; index < ${#actual[@]}; index++ )); do
      [[ "${actual[index]##*/}" == "${expected[0]##*/}" ]] && return 0
    done
    return 1
  fi

  expected_base="${expected[0]##*/}"
  [[ "$exe_base" == "$expected_base" ]] || return 1
  [[ "${actual[0]##*/}" == "$expected_base" ]] || return 1
  (( ${#actual[@]} >= ${#expected[@]} )) || return 1
  for (( index = 1; index < ${#expected[@]}; index++ )); do
    [[ "${actual[index]}" == "${expected[index]}" ]] || return 1
  done
  return 0
}

find_agent_pids() {
  local pid found=1

  while IFS= read -r pid; do
    [[ "$pid" =~ ^[0-9]+$ ]] || continue
    is_self_or_ancestor_pid "$pid" && continue
    if process_signature_matches "$pid"; then
      printf '%s\n' "$pid"
      found=0
    fi
  done < <(pgrep -f -- "$AGENT_PROCESS_REGEX" 2>/dev/null || true)
  return "$found"
}

read_cpu_snapshot() {
  awk '/^cpu / {
    if (NF < 5) exit 1
    total = 0
    for (i = 2; i <= 9 && i <= NF; i++) total += $i
    idle = $5 + $6
    printf "%.0f %.0f\n", total, idle
    exit
  }' /proc/stat
}

collect_cpu_percent() {
  local total1 idle1 total2 idle2
  read -r total1 idle1 < <(read_cpu_snapshot) || return 1
  sleep 0.2 || return 1
  read -r total2 idle2 < <(read_cpu_snapshot) || return 1

  awk -v t1="$total1" -v i1="$idle1" -v t2="$total2" -v i2="$idle2" 'BEGIN {
    dt = t2 - t1
    di = i2 - i1
    if (dt <= 0 || di < 0 || di > dt) exit 1
    printf "%.2f", 100 * (dt - di) / dt
  }'
}

collect_mem_percent() {
  awk '
    /^MemTotal:/     { total = $2; total_seen = 1 }
    /^MemAvailable:/ { available = $2; available_seen = 1 }
    END {
      if (!total_seen || !available_seen || total <= 0 || available < 0 || available > total) exit 1
      printf "%.2f", 100 * (total - available) / total
    }
  ' /proc/meminfo
}

collect_disk_percent() {
  local output
  output="$(df -P -- / 2>/dev/null)" || return 1
  awk 'NR == 2 && $5 ~ /^[0-9]+%$/ {
    gsub(/%/, "", $5)
    printf "%d", $5
    found = 1
  }
  END { if (!found) exit 1 }' <<< "$output"
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
require_command pgrep
require_command readlink
require_command sed
require_command sleep
require_command ss
require_command uname

if [[ ! "$AGENT_PORT" =~ ^[0-9]{1,5}$ ]] \
  || (( 10#$AGENT_PORT < 1 || 10#$AGENT_PORT > 65535 )); then
  error "AGENT_PORT must be an integer from 1 to 65535: $AGENT_PORT"
  exit 2
fi
for threshold_name in CPU_WARN_THRESHOLD MEM_WARN_THRESHOLD DISK_WARN_THRESHOLD; do
  if ! valid_threshold "${!threshold_name}"; then
    error "$threshold_name must be a number from -1 to 100: ${!threshold_name}"
    exit 2
  fi
done
if [[ "$AGENT_LOG_DIR" != /* ]]; then
  error "AGENT_LOG_DIR must be an absolute path: $AGENT_LOG_DIR"
  exit 2
fi

AGENT_PROCESS_PATTERN="$(resolve_process_pattern)" || exit 2
if [[ -z "$AGENT_PROCESS_PATTERN" \
  || "$AGENT_PROCESS_PATTERN" =~ ^[[:space:]] \
  || "$AGENT_PROCESS_PATTERN" =~ [[:space:]]$ \
  || "$AGENT_PROCESS_PATTERN" == *$'\n'* ]]; then
  error 'AGENT_PROCESS_PATTERN must be a non-empty, single-line command signature without outer whitespace'
  exit 2
fi
AGENT_PROCESS_REGEX="(^|[[:space:]/])$(escape_ere "$AGENT_PROCESS_PATTERN")([[:space:]]|$)"

# 1) Health check: process. Failure must terminate with exit 1.
# pgrep supplies candidates; /proc executable/cmdline verification rejects decoys,
# this script, and its ancestor shells.
mapfile -t AGENT_PIDS < <(find_agent_pids || true)
if (( ${#AGENT_PIDS[@]} == 0 )); then
  error "Agent process not found: pattern=$AGENT_PROCESS_PATTERN"
  exit 1
fi

# 2) Health check: the selected Agent PID must own the required IPv4 wildcard listener.
SS_OUTPUT="$(ss -lntp4H 2>/dev/null)" || {
  error 'could not inspect TCP listeners with ss'
  exit 2
}
AGENT_PID=""
for candidate_pid in "${AGENT_PIDS[@]}"; do
  if awk -v port="$AGENT_PORT" -v pid="$candidate_pid" '
    {
      local_address = $4
      port_value = local_address
      sub(/^.*:/, "", port_value)
      pid_pattern = "pid=" pid "([^0-9]|$)"
      if ((local_address ~ /^0[.]0[.]0[.]0:/ || local_address ~ /^[*]:/) && port_value == port && $0 ~ pid_pattern) found = 1
    }
    END { exit !found }
  ' <<< "$SS_OUTPUT"; then
    AGENT_PID="$candidate_pid"
    break
  fi
done
if [[ -z "$AGENT_PID" ]]; then
  error "no matching Agent PID owns 0.0.0.0:$AGENT_PORT LISTEN"
  exit 1
fi

# 3) Firewall: warning only.
if ! firewall_is_active; then
  warn "firewall is inactive or could not be confirmed active"
fi

# 4) Resource collection.
if ! CPU="$(collect_cpu_percent)" || ! valid_percent "$CPU"; then
  error 'failed to collect a valid CPU percentage'
  exit 2
fi
if ! MEM="$(collect_mem_percent)" || ! valid_percent "$MEM"; then
  error 'failed to collect a valid MEM percentage from MemAvailable'
  exit 2
fi
if ! DISK_USED="$(collect_disk_percent)" || ! valid_percent "$DISK_USED"; then
  error 'failed to collect a valid root DISK_USED percentage'
  exit 2
fi

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
