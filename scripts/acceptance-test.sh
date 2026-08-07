#!/usr/bin/env bash
# shellcheck disable=SC2015,SC2024,SC2317
# PASS/FAIL helpers always return success; root intentionally captures command
# output only inside this run's private mktemp directory; cleanup is trap-called.
set -u

# B1-1 runtime acceptance tests.
# This script does not change SSH/UFW/users/groups/ACL definitions.
# It does create/remove small test files in mission directories and appends
# normal monitor samples. Run only after 05~08 are configured.

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
INCOMPLETE_COUNT=0
AGENT_BOOT_LOG="${AGENT_BOOT_LOG:-}"
WAIT_SECONDS="${CRON_WAIT_SECONDS:-70}"
MISSION_KEY_SHA256='98f9221b6ea6e516a800246d3163969c3f718e22c79f184f8cb6d60b84b9e5cb'

pass() { printf '[PASS] %s\n' "$*"; PASS_COUNT=$((PASS_COUNT + 1)); }
warn() { printf '[WARN] %s\n' "$*"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { printf '[FAIL] %s\n' "$*"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

group_members_are_exact() {
  local group_name="$1" group_line group_gid listed_members actual expected
  local -a listed=()
  shift

  group_line="$(getent group "$group_name" 2>/dev/null)" || return 1
  IFS=: read -r _ _ group_gid listed_members <<< "$group_line"
  IFS=, read -r -a listed <<< "$listed_members"
  actual="$({
    printf '%s\n' "${listed[@]}"
    getent passwd | awk -F: -v gid="$group_gid" '$4 == gid { print $1 }'
  } | sed '/^$/d' | sort -u)"
  expected="$(printf '%s\n' "$@" | sort -u)"
  [[ "$actual" == "$expected" ]]
}

usage() {
  cat <<'USAGE'
Usage: sudo bash scripts/acceptance-test.sh --agent-boot-log FILE [--skip-cron-wait]
       bash scripts/acceptance-test.sh --boot-evidence-only --agent-boot-log FILE

--agent-boot-log FILE  captured Agent startup output containing the five [OK]
                       boot checks and Agent READY
--skip-cron-wait       skip the cron observation and finish INCOMPLETE (exit 2)
--boot-evidence-only   validate only the supplied Boot/READY capture; this is
                       not a runtime acceptance PASS
USAGE
}

boot_evidence_is_valid() {
  local file="$1"
  awk '
    BEGIN { expected = 1; valid = 1; ready_count = 0; last_ok_line = 0 }
    {
      matched = 0
      for (step = 1; step <= 5; step++) {
        pattern = "\\[" step "/5\\].*\\[OK\\]"
        if ($0 ~ pattern) {
          matched++
          if (step != expected) valid = 0
          expected++
          last_ok_line = NR
        }
      }
      if (matched > 1) valid = 0
      if (index($0, "Agent READY") > 0) {
        ready_count++
        ready_line = NR
      }
    }
    END { exit !(valid && expected == 6 && ready_count == 1 && ready_line > last_ok_line) }
  ' "$file"
}

SKIP_CRON_WAIT=0
BOOT_EVIDENCE_ONLY=0
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
    --boot-evidence-only)
      BOOT_EVIDENCE_ONLY=1
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

if [[ "$BOOT_EVIDENCE_ONLY" -eq 1 ]]; then
  if [[ -z "$AGENT_BOOT_LOG" || ! -r "$AGENT_BOOT_LOG" ]]; then
    printf '[ERROR] --boot-evidence-only requires a readable --agent-boot-log FILE\n' >&2
    exit 2
  fi
  if boot_evidence_is_valid "$AGENT_BOOT_LOG"; then
    printf '[PASS] Boot evidence structure is valid. Full runtime acceptance and evidence provenance remain separate.\n'
    exit 0
  fi
  printf '[FAIL] Boot evidence structure is invalid.\n' >&2
  exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
  printf '[ERROR] run with sudo/root so user-switch and ACL tests are reliable\n' >&2
  exit 2
fi

if ! command -v sha256sum >/dev/null 2>&1; then
  printf '[ERROR] required command not found: sha256sum\n' >&2
  exit 2
fi

if [[ ! "$WAIT_SECONDS" =~ ^[0-9]{1,3}$ ]] \
  || (( 10#$WAIT_SECONDS < 1 || 10#$WAIT_SECONDS > 300 )); then
  printf '[ERROR] CRON_WAIT_SECONDS must be an integer from 1 to 300\n' >&2
  exit 2
fi

MONITOR=/home/agent-admin/agent-app/bin/monitor.sh
LOG=/var/log/agent-app/monitor.log
KEY=/home/agent-admin/agent-app/api_keys/t_secret.key
TEST_TMP_DIR="$(mktemp -d /tmp/b1-1-acceptance.XXXXXX)" || {
  printf '[ERROR] could not create private acceptance directory\n' >&2
  exit 2
}
TEST_LOG_DIR="$(mktemp -d /tmp/b1-1-monitor-test.XXXXXX)" || {
  printf '[ERROR] could not create isolated monitor test directory\n' >&2
  case "$TEST_TMP_DIR" in
    /tmp/b1-1-acceptance.*) rm -rf -- "$TEST_TMP_DIR" ;;
  esac
  exit 2
}
TEST_SUFFIX="${TEST_TMP_DIR##*.}"
SLEEP_PID=""
RUNTIME_PROBES=()

cleanup() {
  if [[ "$SLEEP_PID" =~ ^[0-9]+$ ]]; then
    kill "$SLEEP_PID" >/dev/null 2>&1 || true
    wait "$SLEEP_PID" 2>/dev/null || true
  fi
  for probe_path in "${RUNTIME_PROBES[@]}"; do
    case "$probe_path" in
      /home/agent-admin/agent-app/upload_files/.b1-1-*|\
      /home/agent-admin/agent-app/api_keys/.b1-1-*|\
      /var/log/agent-app/.b1-1-*)
        rm -f -- "$probe_path"
        ;;
    esac
  done
  case "$TEST_TMP_DIR" in
    /tmp/b1-1-acceptance.*) rm -rf -- "$TEST_TMP_DIR" ;;
  esac
  case "$TEST_LOG_DIR" in
    /tmp/b1-1-monitor-test.*) rm -rf -- "$TEST_LOG_DIR" ;;
  esac
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP

if ! chown agent-admin:agent-core "$TEST_LOG_DIR" \
  || ! chmod 0770 "$TEST_LOG_DIR"; then
  printf '[ERROR] could not prepare agent-admin:agent-core acceptance directory\n' >&2
  exit 2
fi

printf 'B1-1 runtime acceptance tests\n'
printf '%s\n' '----------------------------------------'

printf '\n[agent-boot-evidence]\n'
if [[ -n "$AGENT_BOOT_LOG" && -r "$AGENT_BOOT_LOG" ]]; then
  if boot_evidence_is_valid "$AGENT_BOOT_LOG"; then
    pass 'Agent Boot Sequence has ordered [1/5]~[5/5] [OK] steps followed by one Agent READY'
  else
    fail 'Agent Boot evidence must contain each ordered [1/5]~[5/5] [OK] exactly once, then one Agent READY'
  fi
else
  fail 'Agent boot evidence not supplied/readable; use --agent-boot-log FILE'
fi

printf '\n[identity-runtime]\n'
if group_members_are_exact agent-common agent-admin agent-dev agent-test; then
  pass 'agent-common contains exactly agent-admin, agent-dev, agent-test'
else
  fail 'agent-common membership has a missing or unexpected user'
fi
if group_members_are_exact agent-core agent-admin agent-dev; then
  pass 'agent-core contains exactly agent-admin, agent-dev'
else
  fail 'agent-core membership has a missing or unexpected user'
fi

printf '\n[acl-runtime]\n'
UPLOAD_PROBE="/home/agent-admin/agent-app/upload_files/.b1-1-acceptance-${TEST_SUFFIX}"
RUNTIME_PROBES+=("$UPLOAD_PROBE")
if sudo -u agent-test bash -c '
  probe="$1"
  umask 007
  printf "probe\n" > "$probe" && test -r "$probe" && printf "append\n" >> "$probe" && rm -f "$probe"
' bash "$UPLOAD_PROBE"; then
  pass 'agent-test can read/write upload_files'
else
  fail 'agent-test cannot read/write upload_files'
fi

UPLOAD_CROSS_PROBE="/home/agent-admin/agent-app/upload_files/.b1-1-cross-${TEST_SUFFIX}"
RUNTIME_PROBES+=("$UPLOAD_CROSS_PROBE")
if sudo -u agent-test bash -c 'umask 077; printf "created\n" > "$1"' bash "$UPLOAD_CROSS_PROBE" \
  && sudo -u agent-dev bash -c 'test -r "$1" && printf "collaborated\n" >> "$1"' bash "$UPLOAD_CROSS_PROBE"; then
  pass 'upload default ACL lets agent-dev append a file created by agent-test with umask 077'
else
  fail 'upload default ACL does not preserve cross-user agent-common R/W'
fi

for core_user in agent-admin agent-dev; do
  for core_dir in /home/agent-admin/agent-app/api_keys /var/log/agent-app; do
    probe="${core_dir}/.b1-1-acceptance-${TEST_SUFFIX}-${core_user}"
    RUNTIME_PROBES+=("$probe")
    if sudo -u "$core_user" bash -c '
      probe="$1"
      umask 007
      printf "probe\n" > "$probe" && test -r "$probe" && printf "append\n" >> "$probe" && rm -f "$probe"
    ' bash "$probe"; then
      pass "$core_user can read/write $core_dir"
    else
      fail "$core_user cannot read/write $core_dir"
    fi
  done
done

for core_dir in /home/agent-admin/agent-app/api_keys /var/log/agent-app; do
  core_cross_probe="${core_dir}/.b1-1-cross-${TEST_SUFFIX}"
  RUNTIME_PROBES+=("$core_cross_probe")
  if sudo -u agent-admin bash -c 'umask 077; printf "created\n" > "$1"' bash "$core_cross_probe" \
    && sudo -u agent-dev bash -c 'test -r "$1" && printf "collaborated\n" >> "$1"' bash "$core_cross_probe"; then
    pass "$core_dir default ACL preserves cross-user agent-core R/W"
  else
    fail "$core_dir default ACL does not preserve cross-user agent-core R/W"
  fi
done

API_DENY_PROBE="/home/agent-admin/agent-app/api_keys/.b1-1-deny-${TEST_SUFFIX}"
RUNTIME_PROBES+=("$API_DENY_PROBE")
if sudo -u agent-test bash -c 'printf "should-not-exist\n" > "$1"' bash "$API_DENY_PROBE" >/dev/null 2>&1; then
  rm -f -- "$API_DENY_PROBE"
  fail 'agent-test can write api_keys (must be blocked)'
else
  pass 'agent-test is blocked from writing api_keys'
fi

LOG_DENY_PROBE="/var/log/agent-app/.b1-1-deny-${TEST_SUFFIX}"
RUNTIME_PROBES+=("$LOG_DENY_PROBE")
if sudo -u agent-test bash -c 'printf "should-not-exist\n" > "$1"' bash "$LOG_DENY_PROBE" >/dev/null 2>&1; then
  rm -f -- "$LOG_DENY_PROBE"
  fail 'agent-test can write /var/log/agent-app (must be blocked)'
else
  pass 'agent-test is blocked from writing /var/log/agent-app'
fi

if [[ -f "$KEY" ]]; then
  if awk 'NR == 1 { nonempty = (length($0) > 0) } NR > 1 { extra = 1 } END { exit !(nonempty && !extra) }' "$KEY"; then
    pass 'key file contains exactly one non-empty line without printing its value'
  else
    fail 'key file must contain exactly one non-empty line'
  fi
  KEY_SHA256="$(sha256sum -- "$KEY" | awk '{ print $1 }')"
  if [[ "$KEY_SHA256" == "$MISSION_KEY_SHA256" ]]; then
    pass 'key file matches the mission value by one-way digest without printing the value'
  else
    fail 'key file does not match the mission value'
  fi
  for core_user in agent-admin agent-dev; do
    if sudo -u "$core_user" bash -c 'test -r "$1" && test -w "$1"' bash "$KEY"; then
      pass "$core_user can read/write the key file without printing its value"
    else
      fail "$core_user cannot read/write the key file"
    fi
  done
  if sudo -u agent-test bash -c 'test -r "$1" || test -w "$1"' bash "$KEY"; then
    fail 'agent-test can read or write the key file (both must be blocked)'
  else
    pass 'agent-test is blocked from reading and writing the key file'
  fi
else
  fail "key file is missing: $KEY"
fi

for protected_dir in /home/agent-admin/agent-app/api_keys /var/log/agent-app; do
  if sudo -u agent-test test -r "$protected_dir"; then
    fail "agent-test can list/read protected directory: $protected_dir"
  else
    pass "agent-test is blocked from listing protected directory: $protected_dir"
  fi
done

printf '\n[monitor-normal]\n'
if [[ -x "$MONITOR" ]]; then
  BEFORE_LINES="$(wc -l < "$LOG" 2>/dev/null || printf '0')"
  if sudo -u agent-admin "$MONITOR" >"$TEST_TMP_DIR/monitor-normal.out" 2>"$TEST_TMP_DIR/monitor-normal.err"; then
    pass 'monitor normal run exit=0'
    AFTER_LINES="$(wc -l < "$LOG" 2>/dev/null || printf '0')"
    (( AFTER_LINES > BEFORE_LINES )) && pass 'monitor normal run appended a log line' || fail 'monitor normal run did not append a log line'
  else
    fail 'monitor normal run did not exit 0'
  fi
else
  fail "monitor is missing/not executable: $MONITOR"
fi

if [[ -f "$LOG" ]]; then
  for core_user in agent-admin agent-dev; do
    if sudo -u "$core_user" bash -c 'test -r "$1" && test -w "$1"' bash "$LOG"; then
      pass "$core_user can read/write monitor.log"
    else
      fail "$core_user cannot read/write monitor.log"
    fi
  done
  if sudo -u agent-test bash -c 'test -r "$1" || test -w "$1"' bash "$LOG"; then
    fail 'agent-test can read or write monitor.log (both must be blocked)'
  else
    pass 'agent-test is blocked from reading and writing monitor.log'
  fi
else
  fail 'monitor.log is missing after normal monitor run'
fi

printf '\n[monitor-process-failure]\n'
sudo -u agent-admin env \
  AGENT_ENV_FILE=/nonexistent \
  AGENT_PROCESS_PATTERN='__b1_1_process_that_does_not_exist__' \
  AGENT_PORT=15034 \
  AGENT_LOG_DIR="$TEST_LOG_DIR" \
  "$MONITOR" >"$TEST_TMP_DIR/monitor-process.out" 2>"$TEST_TMP_DIR/monitor-process.err"
RC=$?
if [[ "$RC" -eq 1 ]] && grep -Fq 'Agent process not found' "$TEST_TMP_DIR/monitor-process.err"; then
  pass 'missing Agent process returns exit 1 from the process-health branch'
else
  fail "missing Agent process branch mismatch: exit=$RC"
fi

printf '\n[monitor-port-failure]\n'
sudo -u agent-admin sleep 120 &
SLEEP_PID=$!
sudo -u agent-admin env \
  AGENT_ENV_FILE=/nonexistent \
  AGENT_PROCESS_PATTERN='sleep 120' \
  AGENT_PORT=65534 \
  AGENT_LOG_DIR="$TEST_LOG_DIR" \
  "$MONITOR" >"$TEST_TMP_DIR/monitor-port.out" 2>"$TEST_TMP_DIR/monitor-port.err"
RC=$?
SLEEP_ALIVE=0
kill -0 "$SLEEP_PID" >/dev/null 2>&1 && SLEEP_ALIVE=1
kill "$SLEEP_PID" >/dev/null 2>&1 || true
wait "$SLEEP_PID" 2>/dev/null || true
SLEEP_PID=""
if [[ "$RC" -eq 1 && "$SLEEP_ALIVE" -eq 1 ]] \
  && grep -Fq 'no matching Agent PID owns' "$TEST_TMP_DIR/monitor-port.err"; then
  pass 'live process with missing port returns exit 1 from the port-health branch'
else
  fail "port failure branch mismatch: exit=$RC process_alive=$SLEEP_ALIVE"
fi

printf '\n[monitor-warning-thresholds]\n'
WARNING_OUTPUT="$(sudo -u agent-admin env AGENT_ENV_FILE=/nonexistent CPU_WARN_THRESHOLD=-1 MEM_WARN_THRESHOLD=-1 DISK_WARN_THRESHOLD=-1 "$MONITOR" 2>&1)"
RC=$?
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
  INCOMPLETE_COUNT=$((INCOMPLETE_COUNT + 1))
fi

printf '\n[logrotate-runtime]\n'
ROTATE=/etc/logrotate.d/agent-monitor
if [[ -r "$ROTATE" ]]; then
  if logrotate -d "$ROTATE" >"$TEST_TMP_DIR/logrotate-debug.out" 2>&1; then
    pass 'logrotate dry-run/debug parse succeeded'
  else
    fail 'logrotate dry-run/debug reported an error'
  fi
else
  fail "$ROTATE missing or unreadable"
fi

printf '\n[summary]\n'
printf 'PASS=%d WARN=%d FAIL=%d INCOMPLETE=%d\n' "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT" "$INCOMPLETE_COUNT"
if (( FAIL_COUNT > 0 )); then
  printf '[FAIL] Runtime acceptance has blocking items.\n'
  exit 1
fi

if (( INCOMPLETE_COUNT > 0 )); then
  printf '[INCOMPLETE] Required cron-growth observation was skipped.\n'
  exit 2
fi

printf '[PASS] Runtime acceptance checks in this script passed. Evidence review is still required for final mission PASS.\n'
exit 0
