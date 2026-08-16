#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MONITOR="$ROOT/scripts/monitor.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

REAL_PATH="$PATH"
MOCK_BIN="$TMP/bin"
LOG_DIR="$TMP/log"
mkdir -p "$MOCK_BIN" "$LOG_DIR"

cat > "$MOCK_BIN/pgrep" <<'EOF'
#!/usr/bin/env bash
if [[ "${MOCK_PROCESS:-0}" == "1" ]]; then
  printf '4242\n'
  exit 0
fi
exit 1
EOF

cat > "$MOCK_BIN/ss" <<'EOF'
#!/usr/bin/env bash
if [[ "${MOCK_PORT:-0}" == "1" ]]; then
  printf 'LISTEN 0 128 0.0.0.0:15034 0.0.0.0:*\n'
fi
EOF
chmod +x "$MOCK_BIN/pgrep" "$MOCK_BIN/ss"

run_monitor() {
  env \
    PATH="$MOCK_BIN:$REAL_PATH" \
    AGENT_ENV_FILE="$TMP/no-env-file" \
    AGENT_LOG_DIR="$LOG_DIR" \
    AGENT_PORT=15034 \
    AGENT_PROCESS_PATTERN='agent-app-linux-x86' \
    "$@" \
    bash "$MONITOR"
}

expect_exit() {
  local expected="$1"
  shift
  set +e
  "$@" >"$TMP/stdout" 2>"$TMP/stderr"
  local actual=$?
  set -e
  if [[ "$actual" -ne "$expected" ]]; then
    printf 'FAIL: expected exit %s, got %s\nstdout:\n' "$expected" "$actual" >&2
    cat "$TMP/stdout" >&2 || true
    printf 'stderr:\n' >&2
    cat "$TMP/stderr" >&2 || true
    exit 1
  fi
}

printf '[1/5] missing process -> exit 1\n'
expect_exit 1 run_monitor MOCK_PROCESS=0 MOCK_PORT=0

grep -q 'Agent process not found' "$TMP/stderr"

printf '[2/5] process present / port missing -> exit 1\n'
expect_exit 1 run_monitor MOCK_PROCESS=1 MOCK_PORT=0
grep -q 'Agent port is not LISTEN' "$TMP/stderr"

printf '[3/5] healthy process+port -> exit 0 and required log format\n'
: > "$LOG_DIR/monitor.log"
expect_exit 0 run_monitor MOCK_PROCESS=1 MOCK_PORT=1
LOG_LINE="$(tail -n 1 "$LOG_DIR/monitor.log")"
if ! [[ "$LOG_LINE" =~ ^\[[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\]\ PID:4242\ CPU:[0-9]+([.][0-9]+)?%\ MEM:[0-9]+([.][0-9]+)?%\ DISK_USED:[0-9]+%$ ]]; then
  printf 'FAIL: unexpected log format: %s\n' "$LOG_LINE" >&2
  exit 1
fi

printf '[4/5] resource thresholds warn but still exit 0\n'
: > "$LOG_DIR/monitor.log"
expect_exit 0 run_monitor MOCK_PROCESS=1 MOCK_PORT=1 CPU_WARN_THRESHOLD=-1 MEM_WARN_THRESHOLD=-1 DISK_WARN_THRESHOLD=-1
WARN_OUTPUT="$(cat "$TMP/stdout" "$TMP/stderr")"
grep -q 'CPU usage' <<<"$WARN_OUTPUT"
grep -q 'MEM usage' <<<"$WARN_OUTPUT"
grep -q 'DISK_USED' <<<"$WARN_OUTPUT"

printf '[5/5] log append failure -> exit 2\n'
rm -f "$LOG_DIR/monitor.log"
mkdir "$LOG_DIR/monitor.log"
expect_exit 2 run_monitor MOCK_PROCESS=1 MOCK_PORT=1
grep -Eq 'log file is not writable|failed to append monitor log' "$TMP/stderr"

printf 'PASS: B1-1 monitor new-baseline behavior\n'
