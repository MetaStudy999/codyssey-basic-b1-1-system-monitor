#!/usr/bin/env bash
set -u

LC_ALL=C
export LC_ALL

# B1-1 Bonus 1: summarize monitor.log statistics.
# Usage:
#   bash scripts/report.sh
#   bash scripts/report.sh --log /path/to/monitor.log
#   bash scripts/report.sh --start '2026-08-07 09:00:00' --end '2026-08-07 18:00:00'

LOG_FILE="${MONITOR_LOG_FILE:-/var/log/agent-app/monitor.log}"
START_TIME=""
END_TIME=""

usage() {
  cat <<'EOF'
Usage: report.sh [options]

Options:
  --log FILE               monitor.log path
  --start 'YYYY-MM-DD HH:MM:SS'
                           include samples at or after this time
  --end 'YYYY-MM-DD HH:MM:SS'
                           include samples at or before this time
  -h, --help               show this help
EOF
}

valid_timestamp() {
  local value="$1" normalized
  [[ "$value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2}$ ]] || return 1
  normalized="$(LC_ALL=C TZ=UTC0 date -d "$value" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)" || return 1
  [[ "$normalized" == "$value" ]]
}

while (( $# > 0 )); do
  case "$1" in
    --log)
      [[ $# -ge 2 ]] || { printf '[ERROR] --log requires a file path\n' >&2; exit 2; }
      LOG_FILE="$2"
      shift 2
      ;;
    --start)
      [[ $# -ge 2 ]] || { printf '[ERROR] --start requires a timestamp\n' >&2; exit 2; }
      START_TIME="$2"
      shift 2
      ;;
    --end)
      [[ $# -ge 2 ]] || { printf '[ERROR] --end requires a timestamp\n' >&2; exit 2; }
      END_TIME="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '[ERROR] unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! command -v date >/dev/null 2>&1; then
  printf '[ERROR] required command not found: date\n' >&2
  exit 2
fi

if [[ -n "$START_TIME" ]] && ! valid_timestamp "$START_TIME"; then
  printf '[ERROR] invalid --start format: %s\n' "$START_TIME" >&2
  exit 2
fi

if [[ -n "$END_TIME" ]] && ! valid_timestamp "$END_TIME"; then
  printf '[ERROR] invalid --end format: %s\n' "$END_TIME" >&2
  exit 2
fi

if [[ -n "$START_TIME" && -n "$END_TIME" && "$START_TIME" > "$END_TIME" ]]; then
  printf '[ERROR] --start must not be later than --end\n' >&2
  exit 2
fi

if [[ ! -r "$LOG_FILE" ]]; then
  printf '[ERROR] log file is not readable: %s\n' "$LOG_FILE" >&2
  exit 2
fi

awk -v start="$START_TIME" -v end="$END_TIME" '
function strip_metric(token, prefix, value) {
  value = token
  sub("^" prefix, "", value)
  sub(/%$/, "", value)
  return value + 0
}

function update_metric(name, value, ts) {
  sum[name] += value

  if (!(name in min) || value < min[name]) {
    min[name] = value
    min_ts[name] = ts
  }

  if (!(name in max) || value > max[name]) {
    max[name] = value
    max_ts[name] = ts
  }
}

/^\[[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]\] PID:[0-9]+ CPU:[0-9]+([.][0-9]+)?% MEM:[0-9]+([.][0-9]+)?% DISK_USED:[0-9]+([.][0-9]+)?%$/ {
  ts = substr($1, 2) " " substr($2, 1, length($2) - 1)

  if (start != "" && ts < start) next
  if (end != "" && ts > end) next

  cpu = strip_metric($4, "CPU:")
  mem = strip_metric($5, "MEM:")
  disk = strip_metric($6, "DISK_USED:")

  count++
  update_metric("CPU", cpu, ts)
  update_metric("MEM", mem, ts)
  update_metric("DISK", disk, ts)
}

END {
  if (count == 0) {
    print "[ERROR] no matching monitor samples" > "/dev/stderr"
    exit 1
  }

  printf "samples=%d\n", count
  printf "CPU  avg=%.2f%% min=%.2f%% (%s) max=%.2f%% (%s)\n", sum["CPU"] / count, min["CPU"], min_ts["CPU"], max["CPU"], max_ts["CPU"]
  printf "MEM  avg=%.2f%% min=%.2f%% (%s) max=%.2f%% (%s)\n", sum["MEM"] / count, min["MEM"], min_ts["MEM"], max["MEM"], max_ts["MEM"]
  printf "DISK avg=%.2f%% min=%.2f%% (%s) max=%.2f%% (%s)\n", sum["DISK"] / count, min["DISK"], min_ts["DISK"], max["DISK"], max_ts["DISK"]
}
' "$LOG_FILE"
