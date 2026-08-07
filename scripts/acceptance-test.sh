#!/usr/bin/env bash
set -u

# B1-1 runtime acceptance tests.
# This script does not change SSH/UFW/users/groups/ACL definitions.
# It does create/remove small test files in mission directories and appends
# normal monitor samples. Run only after 05~08 are configured.

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
AGENT_BOOT_LOG="${AGENT_BOOT_LOG:-}"
WAIT_SECONDS="${CRON_WAIT_SECONDS:-70}"

pass() { printf '[PASS] %s\n' "$*"; PASS_COUNT=$((PASS_COUNT + 1)); }
warn() { printf '[WARN] %s\n' "$*"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { printf '[FAIL] %s\n' "$*"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

usage() {
  cat <<'USAGE'
Usage: sudo bash scripts/acceptance-test.sh [--agent-boot-log FILE] [--skip-cron-wait]

--agent-boot-log FILE  captured Agent startup output containing the five [OK]
                       boot checks and Agent READY
--skip-cron-wait       skip the 70-second automatic cron growth observation
USAGE
}

SKIP_CRON_WAIT=0
while (( $# > 0 )); do
  case "$1" in
    --agent-boot-log)
      [[ $# -ge 2 ]] || { printf '[ERROR] --agent-boot-log requires FILE\n' >&2; exit 2; }
      AGENT_BOOT_LOG="$2"
      shift 2
      ;;
    --skip-cron-wait)
      SKIP_CRON_WAIT=1
      shift
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

if [[ "$EUID" -ne 0 ]]; then
  printf '[ERROR] run with sudo/root so user-switch and ACL tests are reliable\n' >&2
  exit 2
fi

MONITOR=/home/agent-admin/agent-app/bin/monitor.sh
LOG=/var/log/agent-app/monitor.log

printf 'B1-1 runtime acceptance tests\n'
printf '%s\n' '----------------------------------------'

printf '\n[agent-boot-evidence]\n'
if [[ -n "$AGENT_BOOT_LOG" && -r "$AGENT_BOOT_LOG" ]]; then
  OK_COUNT="$(grep -Ec '\[[1-5]/5\].*\[OK\]' "$AGENT_BOOT_LOG" || true)"
  [[ "$OK_COUNT" -eq 5 ]] && pass 'Agent Boot Sequence contains five [OK] steps' || fail "Agent Boot Sequence [OK] count=$OK_COUNT (expected 5)"
  grep -Fq 'Agent READY' "$AGENT_BOOT_LOG" && pass 'Agent READY found in captured output' || fail 'Agent READY missing from captured output'
else
  fail 'Agent boot evidence not supplied/readable; use --agent-boot-log FILE'
fi

printf '\n[acl-runtime]\n'
if sudo -u agent-test bash -c 'f=/home/agent-admin/agent-app/upload_files/.b1-1-acceptance-$$; touch "$f" && rm -f "$f"'; then
  pass 'agent-test can write upload_files'
else
  fail 'agent-test cannot write upload_files'
fi

if sudo -u agent-test bash -c 'touch /home/agent-admin/agent-app/api_keys/.b1-1-should-fail' >/dev/null 2>&1; then
  rm -f /home/agent-admin/agent-app/api_keys/.b1-1-should-fail
  fail 'agent-test can write api_keys (must be blocked)'
else
  pass 'agent-test is blocked from writing api_keys'
fi

if sudo -u agent-test bash -c 'touch /var/log/agent-app/.b1-1-should-fail' >/dev/null 2>&1; then
  rm -f /var/log/agent-app/.b1-1-should-fail
  fail 'agent-test can write /var/log/agent-app (must be blocked)'
else
  pass 'agent-test is blocked from writing /var/log/agent-app'
fi

printf '\n[monitor-normal]\n'
if [[ -x "$MONITOR" ]]; then
  BEFORE_LINES="$(wc -l < "$LOG" 2>/dev/null || printf '0')"
  if sudo -u agent-admin "$MONITOR" >/tmp/b1-1-monitor-normal.out 2>/tmp/b1-1-monitor-normal.err; then
    pass 'monitor normal run exit=0'
    AFTER_LINES="$(wc -l < "$LOG" 2>/dev/null || printf '0')"
    (( AFTER_LINES > BEFORE_LINES )) && pass 'monitor normal run appended a log line' || fail 'monitor normal run did not append a log line'
  else
    fail 'monitor normal run did not exit 0'
  fi
else
  fail "monitor is missing/not executable: $MONITOR"
fi

printf '\n[monitor-process-failure]\n'
TMP_LOG_DIR="$(mktemp -d /tmp/b1-1-monitor-test.XXXXXX)"
chmod 0777 "$TMP_LOG_DIR"
set +e
sudo -u agent-admin env \
  AGENT_ENV_FILE=/nonexistent \
  AGENT_PROCESS_PATTERN='__b1_1_process_that_does_not_exist__' \
  AGENT_PORT=15034 \
  AGENT_LOG_DIR="$TMP_LOG_DIR" \
  "$MONITOR" >/tmp/b1-1-monitor-process.out 2>/tmp/b1-1-monitor-process.err
RC=$?
set -e
[[ "$RC" -eq 1 ]] && pass 'missing Agent process returns exit 1' || fail "missing Agent process exit=$RC (expected 1)"

printf '\n[monitor-port-failure]\n'
sleep 120 &
SLEEP_PID=$!
set +e
sudo -u agent-admin env \
  AGENT_ENV_FILE=/nonexistent \
  AGENT_PROCESS_PATTERN='sleep 120' \
  AGENT_PORT=65534 \
  AGENT_LOG_DIR="$TMP_LOG_DIR" \
  "$MONITOR" >/tmp/b1-1-monitor-port.out 2>/tmp/b1-1-monitor-port.err
RC=$?
set -e
kill "$SLEEP_PID" >/dev/null 2>&1 || true
wait "$SLEEP_PID" 2>/dev/null || true
[[ "$RC" -eq 1 ]] && pass 'process-present/port-missing returns exit 1' || fail "port failure exit=$RC (expected 1)"

printf '\n[monitor-warning-thresholds]\n'
set +e
WARNING_OUTPUT="$(sudo -u agent-admin env CPU_WARN_THRESHOLD=-1 MEM_WARN_THRESHOLD=-1 DISK_WARN_THRESHOLD=-1 "$MONITOR" 2>&1)"
RC=$?
set -e
if [[ "$RC" -eq 0 ]]; then
  pass 'threshold-warning run continues with exit 0'
  grep -Fq 'CPU usage' <<<"$WARNING_OUTPUT" && pass 'CPU warning emitted' || fail 'CPU warning missing'
  grep -Fq 'MEM usage' <<<"$WARNING_OUTPUT" && pass 'MEM warning emitted' || fail 'MEM warning missing'
  grep -Fq 'DISK_USED' <<<"$WARNING_OUTPUT" && pass 'DISK warning emitted' || fail 'DISK warning missing'
else
  fail "threshold-warning run exit=$RC (expected 0; Agent must be healthy)"
fi

printf '\n[monitor-log-format]\n'
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

printf '\n[cron-runtime]\n'
CRON_OUTPUT="$(crontab -u agent-admin -l 2>/dev/null || true)"
if grep -Eq '^\* \* \* \* \* /home/agent-admin/agent-app/bin/monitor\.sh([[:space:]]|$)' <<<"$CRON_OUTPUT"; then
  pass 'agent-admin every-minute cron entry exists'
else
  fail 'agent-admin every-minute cron entry missing'
fi

if [[ "$SKIP_CRON_WAIT" -eq 0 ]]; then
  BEFORE_LINES="$(wc -l < "$LOG" 2>/dev/null || printf '0')"
  printf '[INFO] waiting %s seconds for cron observation...\n' "$WAIT_SECONDS"
  sleep "$WAIT_SECONDS"
  AFTER_LINES="$(wc -l < "$LOG" 2>/dev/null || printf '0')"
  (( AFTER_LINES > BEFORE_LINES )) && pass 'cron automatically increased monitor.log' || fail 'monitor.log did not increase during cron observation window'
else
  warn 'cron growth wait skipped by option'
fi

printf '\n[logrotate-runtime]\n'
ROTATE=/etc/logrotate.d/agent-monitor
if [[ -r "$ROTATE" ]]; then
  if logrotate -d "$ROTATE" >/tmp/b1-1-logrotate-debug.out 2>&1; then
    pass 'logrotate dry-run/debug parse succeeded'
  else
    fail 'logrotate dry-run/debug reported an error'
  fi
else
  fail "$ROTATE missing or unreadable"
fi

rm -rf "$TMP_LOG_DIR" /tmp/b1-1-monitor-normal.out /tmp/b1-1-monitor-normal.err \
  /tmp/b1-1-monitor-process.out /tmp/b1-1-monitor-process.err \
  /tmp/b1-1-monitor-port.out /tmp/b1-1-monitor-port.err \
  /tmp/b1-1-logrotate-debug.out

printf '\n[summary]\n'
printf 'PASS=%d WARN=%d FAIL=%d\n' "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"
if (( FAIL_COUNT > 0 )); then
  printf '[FAIL] Runtime acceptance has blocking items.\n'
  exit 1
fi

printf '[PASS] Runtime acceptance checks in this script passed. Evidence review is still required for final mission PASS.\n'
exit 0
